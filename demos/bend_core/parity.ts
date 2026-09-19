import * as assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";
import * as Bend from "../../bend2/bend.ts";

const ROOT = import.meta.dirname;
const REPO = path.resolve(ROOT, "../..");
const CLI = path.join(REPO, "bend2/main.ts");

type Term =
  | ["Var", number]
  | ["Lam", Term]
  | ["App", Term, Term]
  | ["Let", Term, Term]
  | ["Ref", number]
  | ["Ann", Term, Term];

type Def = { name: number; arity: number; body: Term };

const v = (i: number): Term => ["Var", i];
const r = (i: number): Term => ["Ref", i];
const lam = (body: Term): Term => ["Lam", body];
const app = (fn: Term, arg: Term): Term => ["App", fn, arg];
const let_ = (value: Term, body: Term): Term => ["Let", value, body];

const defs: Def[] = [
  { name: 0, arity: 2, body: lam(lam(v(1))) },
  { name: 1, arity: 0, body: r(9) },
  { name: 2, arity: 0, body: r(2) },
];

const cases: [string, Term][] = [
  ["beta identity", app(lam(v(0)), r(9))],
  ["capture avoidance", app(lam(lam(v(1))), r(9))],
  ["shadowing", app(lam(lam(v(0))), r(9))],
  ["let substitution", let_(r(9), v(0))],
  ["annotation erasure", ["Ann", r(9), r(8)]],
  ["stuck variable", app(v(0), r(9))],
  ["stuck reference", app(r(9), r(8))],
  ["underapplied definition", app(r(0), r(9))],
  ["fully applied definition", app(app(r(0), r(9)), r(8))],
  ["extra argument", app(app(app(r(0), r(9)), r(8)), r(7))],
  ["nullary definition", r(1)],
  ["open argument under binder", app(lam(lam(v(1))), v(0))],
  ["nested let under binder", app(lam(let_(v(0), lam(v(2)))), r(9))],
  ["duplicated argument", app(lam(app(v(0), v(0))), r(9))],
  ["lazy argument", app(lam(r(9)), r(2))],
  ["annotated function", app(["Ann", lam(v(0)), r(7)], r(8))],
];

// TypeScript memoizes a used variable cell. Substitution is equivalent, but
// readback can retain an unreduced copy in a neutral argument.
const sharingCases: [string, Term][] = [
  ["shared let value", let_(app(lam(r(9)), r(8)), app(v(0), v(0)))],
  ["shared beta argument", app(lam(app(v(0), v(0))), app(lam(r(9)), r(8)))],
];

const eqCases: [string, Term, Term, boolean][] = [
  ["same variable", v(0), v(0), true],
  ["different variables", v(0), v(1), false],
  ["same binder", lam(v(0)), lam(v(0)), true],
  ["different binder bodies", lam(v(0)), lam(v(1)), false],
  ["beta", app(lam(v(0)), r(9)), r(9), true],
  ["beta in neutral argument", app(v(0), app(lam(v(0)), r(9))), app(v(0), r(9)), true],
  ["annotation in neutral argument", app(v(0), ["Ann", r(9), r(8)]), app(v(0), r(9)), true],
  ["different neutral heads", app(v(0), r(9)), app(v(1), r(9)), false],
  ["different neutral arguments", app(v(0), r(9)), app(v(0), r(8)), false],
  ["let", let_(r(9), v(0)), r(9), true],
  ["annotation", ["Ann", r(9), r(8)], r(9), true],
  ["nullary reference", r(1), r(9), true],
  ["underapplied reference", app(r(0), r(9)), app(r(0), r(9)), true],
  ["distinct opaque references", r(9), r(8), false],
  ["fully applied reference", app(app(r(0), r(9)), r(8)), r(9), true],
  ["extra argument after unfolding", app(app(app(r(0), r(9)), r(8)), r(7)), app(r(9), r(7)), true],
  ["eta", lam(app(v(1), v(0))), v(0), true],
  ["eta reverse", v(0), lam(app(v(1), v(0))), true],
  ["eta under binder", lam(lam(app(v(1), v(0)))), lam(v(0)), true],
  ["eta completes definition", lam(app(app(r(0), r(9)), v(0))), app(r(0), r(9)), true],
  ["eta mismatch", lam(app(v(1), v(0))), v(1), false],
  ["nested binder capture", lam(lam(v(1))), lam(lam(v(0))), false],
  ["shared let", sharingCases[0][1], app(r(9), r(9)), true],
  ["shared beta", sharingCases[1][1], app(r(9), r(9)), true],
];

function spine(t: Term): [Term, number] {
  let arity = 0;
  while (t[0] === "App") {
    t = t[1];
    arity += 1;
  }
  return [t, arity];
}

function toHigher(t: Term, env: Bend.HTerm[] = []): Bend.HTerm {
  switch (t[0]) {
    // Bend reserves -1 and -2 for cells; lower IDs keep free variables disjoint from binders.
    case "Var": return env[t[1]] ?? Bend.Var("free", -3 - (t[1] - env.length));
    case "Lam": return Bend.Lam("x", 0, (x: Bend.HTerm) => toHigher(t[1], [x, ...env]));
    case "App": return Bend.App(toHigher(t[1], env), toHigher(t[2], env));
    case "Let": return Bend.Let(["x"], [0], [toHigher(t[1], env)],
      (xs: Bend.HTerm[]) => toHigher(t[2], [xs[0], ...env]));
    case "Ref": return Bend.Ref("r" + t[1]);
    case "Ann": return Bend.Ann(toHigher(t[1], env), toHigher(t[2], env));
  }
}

function reify(t: Bend.LTerm, depth = 0): Term {
  switch (t.$) {
    case "Var":
      if (t.i < 0) assert.ok(t.i <= -3, "unforced oracle cell");
      return v(t.i < 0 ? depth - (t.i + 3) : depth - 1 - t.i);
    case "Lam": return lam(reify(t.f, depth + 1));
    case "App": return app(reify(t.f, depth), reify(t.x, depth));
    case "Let": {
      assert.equal(t.v.length, 1);
      return let_(reify(t.v[0], depth), reify(t.f, depth + 1));
    }
    case "Ref": return r(Number(t.k.slice(1)));
    case "Ann": return ["Ann", reify(t.x, depth), reify(t.T, depth)];
    default: throw new Error("oracle produced out-of-scope term: " + t.$);
  }
}

function bend(t: Term): string {
  switch (t[0]) {
    case "Var": return `Core.TVar{${t[1]}n}`;
    case "Lam": return `Core.TLam{${bend(t[1])}}`;
    case "App": return `Core.TApp{${bend(t[1])}, ${bend(t[2])}}`;
    case "Let": return `Core.TLet{${bend(t[1])}, ${bend(t[2])}}`;
    case "Ref": return `Core.TRef{${t[1]}n}`;
    case "Ann": return `Core.TAnn{${bend(t[1])}, ${bend(t[2])}}`;
  }
}

function runBend(): unknown[] {
  const results = [...cases, ...sharingCases].map(([, t]) =>
    `Core.json_result(Core.run(256n, book, ${bend(t)}))`);
  results.push(`Core.json_result(Core.run(16n, book, Core.TRef{2n}))`);
  results.push(...eqCases.map(([, a, b]) =>
    `Core.json_eq_result(Core.compare(256n, book, ${bend(a)}, ${bend(b)}))`));
  results.push(`Core.json_eq_result(Core.compare(64n, book, Core.TRef{2n}, Core.TRef{2n}))`);
  results.push(`Core.json_eq_result(Core.compare(0n, book, Core.TVar{0n}, Core.TVar{0n}))`);
  const source = [
    "import Base",
    "import ../main.bend as Core",
    "",
    "def main() -> IO(Unit):",
    `  +book = {[${defs.map(d =>
      `Core.Def{${d.name}n, ${d.arity}n, ${bend(d.body)}}`).join(", ")}] : List<&2, Core.Def>}`,
    `  IO.print("[" ++ ${results.join(' ++ "," ++ ')} ++ "]")`,
    "",
  ].join("\n");
  const dir = fs.mkdtempSync(path.join(ROOT, ".parity-"));
  const file = path.join(dir, "main.bend");
  try {
    fs.writeFileSync(file, source);
    const proc = spawnSync(process.execPath, [CLI, file], {
      cwd: ROOT, encoding: "utf8", maxBuffer: 8 * 1024 * 1024,
    });
    if (proc.error) throw proc.error;
    if (proc.status !== 0) throw new Error(proc.stderr || proc.stdout);
    return JSON.parse(proc.stdout.trim());
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

let deeplyBound: Term = v(0);
for (let i = 0; i < 1001; i++) deeplyBound = lam(deeplyBound);
assert.deepEqual(reify(Bend.term_lower(toHigher(deeplyBound))), deeplyBound);

const book = Bend.book_nil();
for (const d of defs) {
  book.tlds["r" + d.name] = { $: "Def", n: d.arity, T: Bend.Qnt(), v: toHigher(d.body) };
}

const observed = runBend();
const reductions = cases.length + sharingCases.length;
assert.equal(observed.length, reductions + 1 + eqCases.length + 2);
for (const [i, [name, t]] of cases.entries()) {
  assert.notDeepEqual(observed[i], ["Exhausted"], `${name} exhausted fuel`);
  const expected = reify(Bend.term_lower(Bend.term_wnf(book, toHigher(t))));
  assert.deepEqual(observed[i], expected, `mismatch: ${name}`);
}
for (const [i, [name, t]] of sharingCases.entries()) {
  const actual = observed[cases.length + i] as Term;
  assert.notDeepEqual(actual, ["Exhausted"], `${name} exhausted fuel`);
  const expected = reify(Bend.term_lower(Bend.term_wnf(book, toHigher(t))));
  assert.deepEqual(spine(actual), spine(expected), `wrong head/spine: ${name}`);
  assert.ok(Bend.term_compare("EQ", book, toHigher(actual), toHigher(expected)),
    `not convertible: ${name}`);
}
assert.deepEqual(observed[reductions], ["Exhausted"], "divergent term must exhaust fuel");
for (const [i, [name, a, b, expected]] of eqCases.entries()) {
  const oracle = Bend.term_compare("EQ", book, toHigher(a), toHigher(b));
  assert.equal(oracle, expected, `wrong oracle fixture: ${name}`);
  assert.equal(observed[reductions + 1 + i], oracle ? "Equal" : "Different", `mismatch: ${name}`);
}
assert.equal(observed.at(-2), "Exhausted", "cyclic comparison must exhaust fuel");
assert.equal(observed.at(-1), "Exhausted", "zero-fuel comparison must exhaust fuel");
console.log(`${cases.length} structural + ${sharingCases.length} sharing + ${eqCases.length} equality cases; fuel exhaustion checked`);
