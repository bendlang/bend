function verdict_translation_error() {
  const fs = require("node:fs");
  const os = require("node:os");
  const path = require("node:path");
  const child = require("node:child_process");
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bend-verdict-error-"));
  const source = `import Base

type T is Type:
  A{}
  B{}

def f(b: T) -> T:
  match b:
    case A{}: B{}
    case B{}: A{}

def P(c: T) -> Type:
  &z: T -> {f(c) == z : T} & {f(z) == c : T}

def p() -> P(A{}):
  (B{}, {==}, {==})
`;
  const bun = typeof Bun !== "undefined";
  const command = bun ? process.execPath : "bun";
  const prefix = bun && Bun.main.startsWith("/$bunfs/")
    ? [] : [path.resolve("bend2/main.ts")];
  const options = { encoding: "utf8", timeout: 3000,
    env: { ...process.env, BEND_ORIGIN: "http://127.0.0.1:9",
      BEND_NO_TELEMETRY: "1", BENDTT: path.join(dir, "unused-kernel") },
  };
  const run = (file, ...args) => child.spawnSync(command,
    [...prefix, path.join(dir, file), ...args], options);
  const rejects = (got, name) => got.status === 1 && got.stdout === ""
    && got.stderr.startsWith("Error: BendTT: while translating " + name + ": ")
    && /call stack|stack overflow/i.test(got.stderr)
    && !/SOME PROOFS FAIL|out of scope|Sorry - /.test(got.stderr);
  try {
    // #1984 passes source checking, then overflows during translation.
    fs.writeFileSync(path.join(dir, "root.bend"), source);
    const checked = run("root.bend", "--check-only");
    if (checked.status !== 0 || !checked.stdout.startsWith("ALL PROOFS CHECK")) return 1;
    if (!rejects(run("root.bend", "--verdict"), "p")) return 2;
    const out = path.join(dir, "proof.bendtt");
    const sentinel = "existing output\n";
    fs.writeFileSync(out, sentinel);
    if (!rejects(run("root.bend", "-o", out), "p")
      || fs.readFileSync(out, "utf8") !== sentinel) return 3;
    fs.writeFileSync(path.join(dir, "lib.bend"), source);
    fs.writeFileSync(path.join(dir, "imported.bend"), "import ./lib.bend as Lib\n");
    if (!rejects(run("imported.bend", "--verdict"), "lib.p")) return 4;
    // The same equations with an inline return type still export.
    fs.writeFileSync(path.join(dir, "inline.bend"), source.replace(
      "def p() -> P(A{}):",
      "def p() -> &z: T -> {f(A{}) == z : T} & {f(z) == A{} : T}:"));
    const good = run("inline.bend", "-o", out);
    if (good.status !== 0 || good.stderr !== ""
      || fs.readFileSync(out, "utf8") === sentinel) return 5;
    return 0;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Verdict.translation_error), verdict_translation_error);
