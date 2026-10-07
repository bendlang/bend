import { afterAll, describe, expect, test } from "bun:test";
import { spawnSync } from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

import type { Book, LTerm, Span } from "bend2/bend.ts";
import { BEND2, Bend, Comp, applyFixes, bendRule, findConfig, lint, mapper, render, walk } from "../src/lint.ts";
import type { Diag, Edit, Fact, LintRule, RuleContext, Source, SourceFile } from "../src/lint.ts";
import { rules as trailing } from "../rules/trailing_whitespace.ts";
import { DriftError, bendDir, fetchBend, installedTag, latestTag, patch, relative, resolve, seeCheck, seeInfer } from "../src/patch.ts";

// Types
// =====

type Loose = Fact & { tm: { x?: { $: string; k?: string; i?: number } } };
type Token = { text: string; beg: number; end: number };
type Seen = { kind: string; def: string; name: string; path: string };

// Constants
// =========

const USERLAND = String.raw`type N is Data:
  Z{}
  S{p: N}

def Alias() -> Type:
  N

def id(x: Alias()) -> Alias():
  x

def generic(~T: Type, x: T) -> T:
  x

def proof(-x: N) -> {x == x : N}:
  {==}

def peel(x: N) -> N:
  match x:
    case Z{}:
      Z{}
    case S{p}:
      p

def main() -> N:
  a = id(S{Z{}})
  generic(~N,a)
`;

const ERASURE = String.raw`type N is Data:
  Z{}
  S{p: N}

def Alias() -> Type:
  N

def direct(x: N) -> N:
  copy : N = x
  copy

def alias(x: N) -> N:
  copy : Alias() = x
  copy

def generic(~T: Type, x: T) -> T:
  copy : T = x
  copy

def dependent(-x: N, p: {x == x : N}) -> {x == x : N}:
  copy : {x == x : N} = p
  copy

def required_lambda(x: N) -> N:
  f : N -> N = y => y
  f(x)

def required_constructor() -> N:
  value : N = Z{}
  value

def main() -> N:
  direct(alias(generic(~N, required_lambda(required_constructor()))))
`;

const FORMAT = String.raw`import Base

type Sample is Data:
  SampleValue{}

def choose(x: Sample,y: Sample) -> Sample:
  x

def text() -> String:
  "a,b=c # still text; escaped quote: \"x,y=z\""

def marker() -> Char:
  '='

def proof(-x: Sample) -> {x==x : Sample}:
  {==}

def main() -> Sample:
  a : Sample=SampleValue{} # preserve,this=comment
  b : Sample  =SampleValue{}
  f : Sample -> Sample=y=>y
  f(choose(a,b))
`;

// Tests in the bend checkout (bend2/../tests) whose first expected line
// says if the check passes.
const DRIFT = [
  "check/alpha_equivalence", "check/assert_plain_fill", "check/dependent_telescope", "check/beta_ann_body",
  "check/ctor_arity", "check/forward_reference", "check/hole_todo", "check/typed_let_mismatch",
  "import/base_prelude", "import/string_literal", "import/alias_shadow", "import/duplicate_name",
];

// Inside the repo, so a Bend rule here can import ../../../src/lint.bend;
// .tmp/ is ignored by git.
const TMP = fileURLToPath(new URL("./.tmp", import.meta.url));
const DIR = (fs.mkdirSync(TMP, { recursive: true }), fs.mkdtempSync(path.join(TMP, "run-")));
const CLI = fileURLToPath(new URL("../src/lint.ts", import.meta.url));
const LINE_LENGTH = fileURLToPath(new URL("../rules/line_length.bend", import.meta.url));

// A file for the rules in rules/: trailing spaces and tabs, CRLF, and
// lines of 100, 101 and 103 characters (the last two end in a \r).
const STYLE = "import Base\n\ndef main() -> U32:  \r\n  1\t\n#" + "x".repeat(99) + "\n#" + "y".repeat(100) + "\r\n#" + "z".repeat(102) + "\r\n";

// The comma-space rule, written in Bend: source text only.
const COMMA_BEND = String.raw`import Base
import ../../../src/lint.bend as Lint

def id() -> String:
  "style/comma-space"

def facts() -> Lint.Want:
  Lint.NoFacts{}

def is_word(+c: Char) -> Bool:
  Bool.or(Char.is_alpha(c), Bool.or(Char.is_digit(c), Char.is_eq(c, '_')))

def comma_before_word(+c: Char, rest: String) -> Bool:
  match rest:
    case SNil{}:
      False{}
    case SCon{n, t}:
      Bool.and(Char.is_eq(c, ','), is_word(n))

def keep(hit: Bool, +at: U32, tail: List<&2, U32>) -> List<&2, U32>:
  match hit:
    case True{}:
      U32.add(at, 1) <> tail
    case False{}:
      tail

# A tail call: bend runs it as a loop, so a long file does not overflow the
# stack.
def commas(s: String, +at: U32, acc: List<&2, U32>) -> List<&2, U32>:
  match s:
    case SNil{}:
      acc
    case SCon{+c, +rest}:
      commas(rest, U32.add(at, 1), keep(comma_before_word(c, rest), at, acc))

def diag_at(+span: Lint.Span) -> Lint.Diag:
  Lint.Diag{Lint.Warning{}, "Add a space after the comma.", Some{span}, [Lint.Fix{"Insert space", Lint.Safe{}, [Lint.Edit{span, " "}]}]}

def diag(path: String, +at: U32) -> Lint.Diag:
  diag_at(Lint.Span{path, at, at})

def diags(+path: String, ats: List<&2, U32>) -> List<&2, Lint.Diag>:
  match ats:
    case Nil{}:
      []
    case Con{+at, rest}:
      diag(path, at) <> diags(path, rest)

def choose(root: Bool, +path: String, text: String, others: List<&2, Lint.Diag>) -> List<&2, Lint.Diag>:
  match root:
    case True{}:
      diags(path, commas(text, 0, []))
    case False{}:
      others

def pick(s: Lint.Source, others: List<&2, Lint.Diag>) -> List<&2, Lint.Diag>:
  match s:
    case Lint.Source{+path, text, root}:
      choose(root, path, text, others)

def all(srcs: List<&2, Lint.Source>) -> List<&2, Lint.Diag>:
  match srcs:
    case Nil{}:
      []
    case Con{s, rest}:
      pick(s, all(rest))

def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
  match input:
    case Lint.Input{sources, options}:
      IO.pure(List<&2, Lint.Diag>, all(sources))

def main() -> IO(Unit):
  Lint.serve(run)
`;

// A typed rule written in Bend: for each Var in def id, its type and normal
// form, whether the checker finds it equal to its binder's, its text, how
// many times it is demanded, and what it uses.
const TYPES_BEND = String.raw`import Base
import ../../../src/lint.bend as Lint

def id() -> String:
  "test/types"

def facts() -> Lint.Want:
  Lint.Want{Lint.File{}, ["Var"], ["id"], []}

def verdict(same: Bool) -> String:
  match same:
    case True{}:
      " (same as its binder)"
    case False{}:
      " (unlike its binder)"

def compare(f: Lint.Fact, b: Maybe<&2, Lint.Term>, t: Lint.Term) -> IO(Bool):
  match b:
    case None{}:
      IO.pure(Bool, False{})
    case Some{x}:
      Lint.same(f, x, t)

def quantity(q: Lint.Quantity) -> String:
  match q:
    case Lint.Erased{}:
      "erased"
    case Lint.Once{}:
      "once"
    case Lint.Many{}:
      "many"

def use_text(u: Lint.Use) -> String:
  match u:
    case Lint.Use{name, q}:
      name ++ " " ++ quantity(q)

def first_use(us: List<&2, Lint.Use>) -> String:
  match us:
    case Nil{}:
      "nothing"
    case Con{u, rest}:
      use_text(u)

def text_of(inner: Maybe<&2, Lint.Span>) -> IO(String):
  match inner:
    case None{}:
      IO.pure(String, "")
    case Some{s}:
      Lint.text(s)

def describe(+f: Lint.Fact, name: String, q: Lint.Quantity, span: Maybe<&2, Lint.Span>, inner: Maybe<&2, Lint.Span>) -> IO(Maybe<&2, Lint.Diag>):
  do IO<Maybe<&2, Lint.Diag>>:
    t : Lint.Term <- Lint.type_of(f)
    shown : String <- Lint.show(f, t)
    t2 : Lint.Term <- Lint.type_of(f)
    n : Lint.Term <- Lint.normal(f, t2)
    nf : String <- Lint.show(f, n)
    u : Lint.Term <- Lint.type_of(f)
    b : Maybe<&2, Lint.Term> <- Lint.binder(f)
    same : Bool <- compare(f, b, u)
    here : String <- text_of(inner)
    us : List<&2, Lint.Use> <- Lint.uses(f)
    return Some{Lint.Diag{Lint.Hint{}, name ++ ": " ++ shown ++ " = " ++ nf ++ verdict(same) ++ ", text " ++ here ++ ", demanded " ++ quantity(q) ++ ", uses " ++ first_use(us), span, []}}

def wanted(hit: Bool, +f: Lint.Fact, name: String, q: Lint.Quantity, span: Maybe<&2, Lint.Span>, inner: Maybe<&2, Lint.Span>) -> IO(Maybe<&2, Lint.Diag>):
  match hit:
    case True{}:
      describe(f, name, q, span, inner)
    case False{}:
      IO.pure(Maybe<&2, Lint.Diag>, None{})

def fact_diag(+f: Lint.Fact, v: Lint.View) -> IO(Maybe<&2, Lint.Diag>):
  match v:
    case Lint.View{owner, inst, kind, name, q, span, inner}:
      wanted(Bool.and(String.eq(owner, "id"), Bool.and(String.eq(kind, "Var"), Bool.not(inst))), f, name, q, span, inner)

def prepend(m: Maybe<&2, Lint.Diag>, xs: List<&2, Lint.Diag>) -> List<&2, Lint.Diag>:
  match m:
    case None{}:
      xs
    case Some{d}:
      d <> xs

def step(found: List<&2, Lint.Diag>, +f: Lint.Fact) -> IO(List<&2, Lint.Diag>):
  do IO<List<&2, Lint.Diag>>:
    v : Lint.View <- Lint.view(f)
    here : Maybe<&2, Lint.Diag> <- fact_diag(f, v)
    return prepend(here, found)

def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
  Lint.fold_facts(~List<&2, Lint.Diag>, ~step, [])

def main() -> IO(Unit):
  Lint.serve(run)
`;

const commaSpace: LintRule = {
  id: "style/comma-space",
  run: (cx) => [...cx.root.text.matchAll(/,(?=\w)/g)].map((m) => {
    const spn = { file: cx.root.file, beg: m.index! + 1, end: m.index! + 1 };
    return cx.diag({
      message: "Add a space after the comma.", severity: "warning", spn,
      fixes: [{ title: "Insert space", applicability: "safe", edits: [{ spn, text: " " }] }],
    });
  }),
};

const identity: LintRule = {
  id: "example/identity",
  facts: true,
  run: async (cx, signal) => {
    await Promise.resolve();
    signal.throwIfAborted();
    const body = facts(cx, "id").find((f) => f.dep === 1 && f.tm.x?.$ === "Var")!;
    const ann = cx.Bend.pmap_get(body.ctx, body.tm.x!.i!)!;
    expect(ann.k).toBe("x");
    expect((cx.Bend.term_wnf(body.bok, body.ty) as { k?: string }).k).toBe("N");
    expect(cx.same(body, body.ty, ann.T)).toBe(true);
    return [cx.diag({ message: "This function returns its parameter.", severity: "information", spn: body.spn, fact: body })];
  },
};

const neverRun: LintRule = {
  id: "test/never-run",
  facts: true,
  run: () => { throw new Error("this rule must not run"); },
};

// x : T = v, where v is a variable that already has type T. Constructors
// and lambdas keep theirs: checking needs the expected type. Template
// instances repeat the facts of the def as written, so they are skipped.
const redundantAnnotation: LintRule = {
  id: "erasure/redundant-local-annotation",
  facts: true,
  run: (cx) => [...cx.facts!.values()].flatMap((fact): Diag[] => {
    const term = cx.Bend.term_strip(fact.tm);
    const value = cx.span(term.s);
    const v = cx.binder(fact, term);
    if (fact.inst || term.$ !== "Var" || fact.spn === undefined || value === undefined || v === null || !cx.same(fact, v.T, fact.ty)) {
      return [];
    }
    const prefix = fact.spn.file.str.slice(fact.spn.beg, value.beg);
    const name = prefix.match(/^([A-Za-z_][A-Za-z_0-9]*)\s*:/);
    if (fact.spn.file !== value.file || fact.spn.beg >= value.beg || prefix.includes("#") || name === null || !prefix.trimEnd().endsWith("=")) {
      return [];
    }
    const spn = { file: fact.spn.file, beg: fact.spn.beg + name[1].length, end: fact.spn.beg + prefix.lastIndexOf("=") };
    return [cx.diag({
      message: "Remove the redundant annotation: " + v.k + " already has type " + cx.show(fact, v.T) + ".",
      severity: "hint", spn, fact,
      fixes: [{ title: "Remove redundant local type annotation", applicability: "suggested", edits: [{ spn, text: " " }] }],
    })];
  }),
};

// One space after a comma and on each side of an assignment, in the file
// linted. Quoted literals, comments and compound operators stay whole.
const spacing: LintRule = {
  id: "format/spacing",
  run: (cx) => spacingEdits(cx.root.file).map((edit) => cx.diag({
    message: "Use one space after a comma and on each side of an assignment.",
    severity: "hint", spn: edit.spn,
    fixes: [{ title: "Normalize spacing", applicability: "safe", edits: [edit] }],
  })),
};

// A Bend rule that reports its options, read with defaults.
const OPTIONS_BEND = String.raw`import Base
import ../../../src/lint.bend as Lint

def id() -> String:
  "test/options"

def facts() -> Lint.Want:
  Lint.NoFacts{}

def summary(+opts: List<&2, Lint.Option>) -> String:
  U32.show(Lint.option_number(opts, "width", 2)) ++ " " ++ Bool.show(Lint.option_flag(opts, "wrap", False{})) ++ " " ++ Lint.option_text(opts, "name", "none")

def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
  match input:
    case Lint.Input{sources, +options}:
      IO.pure(List<&2, Lint.Diag>, [Lint.Diag{Lint.Hint{}, summary(options), None{}, []}])

def main() -> IO(Unit):
  Lint.serve(run)
`;

// A Bend rule that counts the facts it pulls, from the linted file and its
// imports: the Vars.
const COUNT_BEND = String.raw`import Base
import ../../../src/lint.bend as Lint

def id() -> String:
  "test/count"

def facts() -> Lint.Want:
  Lint.Want{Lint.Program{}, ["Var"], [], []}

def add(n: U32, +f: Lint.Fact) -> IO(U32):
  IO.pure(U32, U32.add(n, 1))

def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
  do IO<List<&2, Lint.Diag>>:
    n : U32 <- Lint.fold_facts(~U32, ~add, 0)
    return [Lint.Diag{Lint.Hint{}, U32.show(n), None{}, []}]

def main() -> IO(Unit):
  Lint.serve(run)
`;

// A rule that reports its options.
const echo: LintRule = {
  id: "test/echo",
  options: { tabWidth: 2, breakLines: false },
  run: (cx) => [cx.diag({ message: JSON.stringify(cx.options), severity: "hint" })],
};

// Functions
// =========

function source2(p: string, ns: string): Source {
  return { path: p, ns, text: "x\n", root: false, base: false, file: { str: "x\n", ns, al: {}, path: p } };
}

function fixture(name: string, text: string): string {
  const file = path.join(DIR, name);
  fs.writeFileSync(file, text);
  return file;
}

function facts(cx: Pick<RuleContext, "facts" | "book" | "walk">, name: string): Loose[] {
  const tld = cx.book.tlds[name];
  return tld.$ !== "Def" || tld.e === undefined ? []
    : [...cx.walk(tld.e)].map((tm) => cx.facts!.get(tm)).filter((f): f is Loose => f !== undefined);
}

function bodies(book: Book): Record<string, string> {
  return Object.fromEntries(book.order.flatMap((name) => {
    const tld = book.tlds[name];
    return tld.$ === "Def" && tld.e !== undefined && !tld.b ? [[name, Bend.term_show(tld.e)]] : [];
  }));
}

function root(sources: Source[]): Source {
  return sources.find((s) => s.root)!;
}

function tokens(source: string): Token[] {
  const pattern = /#[^\r\n]*|"(?:\\[\s\S]|[^"\\])*"|'(?:\\[\s\S]|[^'\\])*'|==|=>|!=|<=|>=|[^\s]/g;
  return [...source.matchAll(pattern)].map((m) => ({ text: m[0], beg: m.index!, end: m.index! + m[0].length }));
}

function spacingEdits(file: SourceFile): Edit[] {
  const stream = tokens(file.str);
  const gap = (left?: Token, right?: Token): Edit[] => {
    const between = left === undefined || right === undefined ? "#" : file.str.slice(left.end, right.beg);
    return right?.text.startsWith("#") || !/^[ \t]*$/.test(between) || between === " "
      ? [] : [{ spn: { file, beg: left!.end, end: right!.beg }, text: " " }];
  };
  return stream.flatMap((token, i) => [
    ...(token.text === "=" ? gap(stream[i - 1], token) : []),
    ...((token.text === "=" || token.text === ",") && !["}", ")", "]"].includes(stream[i + 1]?.text ?? "}")
      ? gap(token, stream[i + 1]) : []),
  ]);
}

// The facts a rule with this filter gets: kind, def, name and file.
async function seen(file: string, want: LintRule["facts"]): Promise<Seen[]> {
  let got: Fact[] = [];
  await lint(file, [{ id: "test/seen", facts: want, run: (cx) => (got = [...cx.facts!.values()], []) }]);
  return got.map((f) => {
    const t = Bend.term_strip(f.tm);
    return { kind: t.$, def: f.def, name: t.$ === "Var" || t.$ === "Ref" ? t.k : "", path: (f.spn!.file as SourceFile).path };
  });
}

// A GitHub that lists `tags` and serves this checkout's bend2 at any
// release; it records the URLs it is asked for.
function github(tags: string[]): { get: (url: string) => Promise<Response>; asked: string[] } {
  const asked: string[] = [];
  const get = async (url: string): Promise<Response> => {
    asked.push(url);
    const file = url.match(/^https:\/\/raw\.githubusercontent\.com\/bendlang\/bend\/v[\d.]+\/bend2\/(.+)$/)?.[1];
    return url.includes("/info/refs")
      ? new Response(["0000 HEAD\0caps", ...tags.flatMap((t) => ["0000 refs/tags/" + t, "0000 refs/tags/" + t + "^{}"]), "0000 refs/heads/main"].join("\n") + "\n")
      : file !== undefined && fs.existsSync(path.join(BEND2, file)) ? new Response(fs.readFileSync(path.join(BEND2, file), "utf8")) : new Response("", { status: 404 });
  };
  return { get, asked };
}

function run(...args: string[]) {
  return spawnSync(process.execPath, [CLI, ...args], { encoding: "utf8" });
}

function module(name: string, body: string): string {
  return fixture(name, "export const rules = " + body + ";\n");
}

// Tests
// =====

afterAll(() => fs.rmSync(DIR, { recursive: true, force: true }));

describe("patch", () => {
  const src = fs.readFileSync(path.join(BEND2, "bend.ts"), "utf8");
  const comp = fs.readFileSync(path.join(BEND2, "comp.ts"), "utf8");

  test("bend.ts: renames term_infer and term_check behind wrappers, and swaps fs and path", () => {
    const out = patch("bend.ts", src);
    expect(out).toContain("function unseen_term_infer(");
    expect(out).toContain("function unseen_term_check(");
    expect(out).toContain("export const term_infer = seeInfer(unseen_term_infer);");
    expect(out).toContain("export const term_check = seeCheck(unseen_term_check);");
    expect(out).not.toMatch(/^export function term_(infer|check)\(/m);
    expect(out).toMatch(/^import \{ fs \} from "file:.*patch\.ts";/m);
    expect(out).toMatch(/^import \{ path \} from "file:.*patch\.ts";/m);
  });

  test("comp.ts: exports RUNTIME_MAIN and js_sat", () => {
    expect(patch("comp.ts", comp)).toContain("export { RUNTIME_MAIN, js_sat };");
  });

  test("fails loudly when an edit or a needed name is missing or repeated", () => {
    expect(() => patch("bend.ts", src.replace("export function term_infer(", "export function term_infer2("))).toThrow(DriftError);
    expect(() => patch("bend.ts", src.replace('import * as fs from "node:fs";', 'import fs from "node:fs";'))).toThrow(/node:fs/);
    expect(() => patch("bend.ts", src + "\nexport function term_check(\n")).toThrow(/found 2 of "export function term_check\("/);
    expect(() => patch("comp.ts", comp.replace("function js_sat(", "function js_name("))).toThrow(/comp\.ts: found 0 of a declaration of js_sat/);
  });

  test("the loaded bend.ts and comp.ts are the patched ones", () => {
    expect((Bend as unknown as Record<string, unknown>).BEND_LINT_PATCH).toBe(1);
    expect((Comp as unknown as Record<string, unknown>).BEND_LINT_PATCH).toBe(1);
  });

  test("the wrappers pass every argument through, and need the expected arity", () => {
    const got: unknown[][] = [];
    const fake = ((...args: unknown[]) => (got.push(args), { tm: null, us: null })) as unknown as typeof Bend.term_check;
    Object.defineProperty(fake, "length", { value: 7 });
    (seeCheck(fake) as unknown as (...a: unknown[]) => unknown)({}, { def: "d" }, {}, 1, 2, 3, 4, "extra");
    expect(got).toEqual([[{}, { def: "d" }, {}, 1, 2, 3, 4, "extra"]]);
    Object.defineProperty(fake, "length", { value: 5 });
    expect(() => seeInfer(fake as unknown as typeof Bend.term_infer)).toThrow(/term_infer takes 5 parameters, not 6/);
  });

  test("bend2 is found from a checkout, its bend2 folder, or the repo; a wrong dir fails", async () => {
    const repo = path.dirname(BEND2);
    expect([await bendDir(repo), await bendDir(BEND2), await bendDir(undefined)]).toEqual([BEND2, BEND2, BEND2]);
    await expect(bendDir(DIR)).rejects.toThrow(/no bend2 at/);
  });

  test("paths: a drive letter is a root; POSIX paths are unchanged", () => {
    expect(resolve("C:/cwd", "C:/Users/m/", "./dep.bend")).toBe("C:/Users/m/dep.bend");
    expect(resolve("C:/cwd", "C:/Users/m/", "/shared/x.bend")).toBe("C:/shared/x.bend");
    expect(resolve("/home/x", "/a/b/", "../c.bend")).toBe("/a/c.bend");
    expect(resolve("/home/x", "y.bend")).toBe("/home/x/y.bend");
    expect(relative("C:/Users/m/", "C:/Users/m/sub/d.bend")).toBe("sub/d.bend");
    expect(relative("/a/b", "/a/c/d.bend")).toBe("../c/d.bend");
  });
});

describe("downloading bend", () => {
  const cache = () => fs.mkdtempSync(path.join(DIR, "cache-"));
  const offline = () => Promise.reject(new Error("offline"));

  test("the installed bend's version comes first; else the newest release, asked once a day", async () => {
    expect([installedTag(() => "bend 2.0.36\n"), installedTag(() => undefined), installedTag(() => "nope")]).toEqual(["v2.0.36", undefined, undefined]);
    const gh = github(["v2.0.9", "v2.0.36", "v2.0.10", "nightly"]);
    const at = cache();
    expect([await latestTag(at, gh.get), await latestTag(at, gh.get)]).toEqual(["v2.0.36", "v2.0.36"]);
    expect(gh.asked.length).toBe(1);
    fs.writeFileSync(path.join(at, "latest.json"), "{ damaged");
    expect(await latestTag(at, gh.get)).toBe("v2.0.36");
    expect(installedTag(() => "bend 2.0.36\nA newer bend is out.\n")).toBe("v2.0.36");
  });

  test("offline, the newest release in the cache is used", async () => {
    const at = cache();
    ["v2.0.3", "v2.0.12", "latest-ish"].forEach((d) => fs.mkdirSync(path.join(at, d)));
    expect(await latestTag(at, offline)).toBe("v2.0.12");
    await expect(latestTag(cache(), offline)).rejects.toThrow(/cannot list bend's releases \(offline\)/);
  });

  test("a release downloads once and whole, and bend-lint runs on it", async () => {
    const gh = github([]);
    const at = cache();
    const dir = await fetchBend("v2.0.36", at, gh.get);
    const effs = fs.readdirSync(path.join(BEND2, "effs"));
    expect(fs.readFileSync(path.join(dir, "bend.ts"), "utf8")).toBe(fs.readFileSync(path.join(BEND2, "bend.ts"), "utf8"));
    expect(fs.readdirSync(path.join(dir, "effs")).sort()).toEqual(effs.sort());
    expect(gh.asked.length).toBe(3 + effs.length);
    expect(await fetchBend("v2.0.36", at, gh.get)).toBe(dir);
    expect(gh.asked.length).toBe(3 + effs.length);
    expect(fs.readdirSync(path.join(at, "v2.0.36"))).toEqual(["bend2"]);
    const out = spawnSync(process.execPath, [CLI, fixture("downloaded.bend", USERLAND)], { encoding: "utf8", env: { ...process.env, BEND_DIR: dir } });
    expect([out.status, out.stderr]).toEqual([0, ""]);
    await expect(fetchBend("../x", at, gh.get)).rejects.toThrow(/not a bend release/);
  });

  test("bendDir downloads only when no bend is given or around it", async () => {
    const gh = github(["v2.0.35"]);
    const at = cache();
    const away = { get: gh.get, cache: at, repo: DIR };
    expect(await bendDir(undefined, { ...away, run: () => "bend 2.0.36\n" })).toBe(fs.realpathSync(path.join(at, "v2.0.36", "bend2")).replaceAll("\\", "/"));
    expect(await bendDir(undefined, { ...away, run: () => undefined })).toBe(fs.realpathSync(path.join(at, "v2.0.35", "bend2")).replaceAll("\\", "/"));
    await expect(bendDir(undefined, { get: offline, cache: at, repo: DIR, run: () => "bend 2.0.40\n" })).rejects.toThrow(/could not download bend v2\.0\.40 \(offline\)/);
    expect(await bendDir(undefined, { get: offline, cache: at, run: () => "bend 2.0.40\n" })).toBe(BEND2);
  });
});

describe("spans", () => {
  const source = (p: string, text: string): Source =>
    ({ path: p, ns: "", text, root: true, base: false, file: { str: text, ns: "", al: {}, path: p } });

  for (const eol of ["\n", "\r\n"]) {
    const text = ["import Base", "import ./a.bend as A", "", "def f() -> N:", "  x", ""].join(eol);
    const lines = text.split("\n");
    for (const [kind, masked] of [
      ["empty", lines.map((l) => l.startsWith("import") ? "" : l).join("\n")],
      ["spaces", lines.map((l) => l.startsWith("import") ? " ".repeat(l.length) : l).join("\n")],
    ]) {
      test("map past " + kind + " import lines (" + JSON.stringify(eol) + ")", () => {
        const src = source("/p/m.bend", text);
        const beg = masked.indexOf("x");
        const got = mapper([src])({ file: { str: masked, ns: "", dir: "/p/", al: { A: "a" } }, beg, end: beg + 1 } as Span);
        expect(got.file).toBe(src.file);
        expect(text.slice(got.beg, got.end)).toBe("x");
        expect(src.file.al.A).toBe("a");
      });
    }
  }

  test("a span on disk passes through; a copy that does not match fails", () => {
    const src = source("/p/m.bend", "import Base\ndef f() -> N:\n  x\n");
    const map = mapper([src]);
    const spn = { file: src.file, beg: 2, end: 3 };
    expect(map(spn)).toBe(spn);
    expect(() => map({ file: { str: "\ndef g() -> N:\n  x\n", ns: "", al: {} }, beg: 0, end: 0 })).toThrow(DriftError);
    expect(() => map({ file: { str: "def f() -> N:\n  x\n", ns: "", al: {} }, beg: 0, end: 0 })).toThrow(DriftError);
  });

  test("the directory picks between equal files", () => {
    const a = source("/a/m.bend", "import Base\nx\n");
    const b = source("/b/m.bend", "import Base\nx\n");
    const map = mapper([a, b]);
    expect(map({ file: { str: "\nx\n", ns: "", dir: "/b/", al: {} }, beg: 1, end: 2 } as Span).file).toBe(b.file);
  });
});

describe("lint", () => {
  const userland = fixture("userland.bend", USERLAND);

  test("source and typed rules report in order, with fixes on the file on disk", async () => {
    const res = await lint(userland, [commaSpace, identity]);
    expect(res.ok).toBe(true);
    expect(res.diags.map((d) => d.code)).toEqual([commaSpace.id, identity.id]);
    expect(res.diags[0].fixes[0].edits[0].spn.file.str).toBe(USERLAND);
    expect(render(res.diags[0])).toStartWith("Warning [style/comma-space]:");
    expect(render(res.diags[0])).toContain("generic(~N, a)");
    expect(render(res.diags[1])).toContain("Context:");
  });

  test("only rules with facts get facts", async () => {
    const look: LintRule = { id: "test/look", run: (cx) => { expect(cx.facts).toBeUndefined(); return []; } };
    expect((await lint(userland, [look, identity])).ok).toBe(true);
    expect((await lint(userland, [commaSpace])).facts).toBeUndefined();
  });

  test("facts cover templates, proofs, matches and fields", async () => {
    const probe: LintRule = {
      id: "test/probe",
      facts: true,
      run: (cx) => {
        const generic = facts(cx, "generic").find((f) => f.tm.x?.$ === "Var" && f.tm.x.k === "x")!;
        expect(generic.bok.tlds["generic~T"]).toBeDefined();
        expect(generic.inst).toBe(false);
        const inst = facts(cx, "generic~0").find((f) => f.tm.x?.$ === "Var" && f.tm.x.k === "x")!;
        expect(inst.inst).toBe(true);
        expect(inst.spn).toEqual(generic.spn);
        expect(["None", "Lone", "Many"]).toContain(generic.qt.$);
        expect(generic.us.$).toBeDefined();
        const proof = facts(cx, "proof").find((f) => f.tm.x?.$ === "Rfl")!;
        expect(proof.ty.$).toBe("Eql");
        expect(proof.dep).toBe(1);
        const peel = [...cx.walk((cx.book.tlds.peel as { e: LTerm }).e)];
        expect(peel.some((tm) => tm.$ === "Mat")).toBe(true);
        expect(peel.some((tm) => tm.$ === "Ann" && tm.x.$ === "Efq" && !cx.facts!.has(tm))).toBe(true);
        const field = facts(cx, "peel").find((f) => f.tm.x?.$ === "Var" && f.tm.x.k === "p")!;
        expect(cx.Bend.pmap_get(field.ctx, field.tm.x!.i!)!.k).toBe("p");
        return [];
      },
    };
    expect((await lint(userland, [probe])).ok).toBe(true);
  });

  test("walk reaches every kind in checked bodies; an unknown kind fails", async () => {
    const res = await lint(userland, []);
    const kinds = new Set(res.book.order.flatMap((name) => {
      const tld = res.book.tlds[name];
      return tld.$ === "Def" && tld.e !== undefined ? [...walk(tld.e)].map((tm) => tm.$) : [];
    }));
    for (const k of ["Mat", "Lam", "App", "Var", "Ctr"]) expect(kinds.has(k as LTerm["$"])).toBe(true);
    expect(() => walk({ $: "Nope" } as unknown as LTerm).next()).toThrow(DriftError);
  });

  test("a failed check is one bend/check error, and no rule runs", async () => {
    const parse = await lint(fixture("parse.bend", "type N is Data:\n  Z{}\ndef broken(\n"), [neverRun]);
    expect(parse.ok).toBe(false);
    expect(parse.diags.map((d) => d.code)).toEqual(["bend/check"]);
    expect(render(parse.diags[0])).toStartWith("Error [bend/check]:");
    expect((await lint(fixture("name.bend", "type N is Data:\n  Z{}\ndef broken() -> N:\n  missing\n"), [neverRun])).ok).toBe(false);
    const todo = await lint(fixture("todo.bend", "type N is Data:\n  Z{}\ndef broken() -> N:\n  ?TODO\n"), [neverRun]);
    expect(todo.diags[0].message).toContain("1 TODO found");
    expect((await lint(path.join(DIR, "missing.bend"), [neverRun])).ok).toBe(false);
  });

  test("an error finding stops later rules; the code is always the rule's id", async () => {
    const stamp: LintRule = { id: "test/stamp", run: (cx) => [{ ...cx.diag({ message: "stamped", severity: "hint" }), code: "other/code" }] };
    expect((await lint(userland, [stamp])).diags[0].code).toBe(stamp.id);
    const stop: LintRule = { id: "test/error", run: (cx) => [cx.diag({ message: "failed", severity: "error" })] };
    const res = await lint(userland, [stop, neverRun]);
    expect(res.ok).toBe(false);
    expect(res.diags.map((d) => d.code)).toEqual([stop.id]);
  });

  test("a bad rule, a rule that throws, and an abort reach the caller", async () => {
    await expect(lint(userland, [{ id: "bad", run: () => [] }])).rejects.toThrow(/invalid rule/);
    await expect(lint(userland, [undefined as unknown as LintRule])).rejects.toThrow(/invalid rule at 0/);
    const broken: LintRule = { id: "test/broken-fix", run: (cx) => {
      const spn = { file: cx.root.file, beg: 0, end: 4 };
      return [cx.diag({ message: "b", fixes: [{ title: "two", applicability: "safe", edits: [{ spn, text: "a" }, { spn, text: "b" }] }] })];
    } };
    await expect(lint(userland, [broken])).rejects.toThrow(/fix "two" has an edit out of bounds, or two that clash/);
    await expect(lint(userland, [{ id: "test/boom", run: async () => { throw new Error("rule failed"); } }])).rejects.toThrow("rule failed");
    const controller = new AbortController();
    const abort: LintRule = { id: "test/abort", run: async () => { controller.abort(); return []; } };
    await expect(lint(userland, [abort, neverRun], { signal: controller.signal })).rejects.toThrow();
    await expect(lint(userland, [], { signal: controller.signal })).rejects.toThrow();
  });

  test("spans after import lines point at the right text on disk", async () => {
    fixture("dep.bend", "type N is Data:\n  Z{}\ndef id(x: N) -> N:\n  x\n");
    const main = fixture("main.bend", "import ./dep.bend as D\n\ndef main() -> D.N:\n  D.id(D.Z{})\n");
    const look: LintRule = {
      id: "test/imports",
      facts: true,
      run: (cx) => {
        expect(cx.root.path).toEndWith("/main.bend");
        expect(cx.sources.find((s) => s.path.endsWith("/dep.bend"))!.ns).toBe("dep");
        const texts = [...cx.facts!.values()].filter((f) => f.def === "main" && f.spn !== undefined).map((f) => {
          expect(f.spn!.file).toBe(cx.root.file);
          return cx.root.text.slice(f.spn!.beg, f.spn!.end);
        });
        expect(texts.some((t) => t.startsWith("D.id") || t.startsWith("D.Z"))).toBe(true);
        return [];
      },
    };
    const res = await lint(main, [look]);
    expect(res.diags.map(render)).toEqual([]);
    expect(res.sources.length).toBe(2);
  });

  test("Base is reused, its facts are left out, and it stays out of files that do not import it", async () => {
    const withBase = fixture("with_base.bend", "import Base\n\ndef main() -> Nat:\n  1n\n");
    const probe: LintRule = {
      id: "test/base",
      facts: true,
      run: (cx) => {
        expect(cx.root.path).toEndWith("/with_base.bend");
        expect(cx.sources.some((s) => s.base)).toBe(true);
        expect([...cx.facts!.values()].some((f) => f.def === "main")).toBe(true);
        expect([...cx.facts!.values()].every((f) => cx.book.tlds[f.def]?.b !== true)).toBe(true);
        return [];
      },
    };
    const first = await lint(withBase, [probe]);
    const second = await lint(withBase, [probe]);
    expect([first.ok, second.ok]).toEqual([true, true]);
    expect(second.book.order).toEqual(first.book.order);
    expect((await lint(fixture("without_base.bend", "def main() -> Nat:\n  1n\n"), [])).ok).toBe(false);
  });

  test("lints in flight keep their own rules and facts", async () => {
    const gate = Promise.withResolvers<void>();
    const entered = Promise.withResolvers<void>();
    const paused: LintRule = {
      id: "test/paused",
      run: async (cx) => { expect(cx.facts).toBeUndefined(); entered.resolve(); await gate.promise; return []; },
    };
    const first = lint(userland, [paused]);
    await entered.promise;
    const second = await lint(userland, [identity]).finally(() => gate.resolve());
    expect(second.facts!.size).toBeGreaterThan(0);
    expect(second.diags.map((d) => d.code)).toEqual([identity.id]);
    expect((await first).diags).toEqual([]);
  });

  test("a rule may await I/O, and later rules see earlier findings", async () => {
    const server = Bun.serve({ port: 0, fetch: async (req) => new Response("advice for " + (await req.json()).type) });
    const remote: LintRule = {
      id: "test/api",
      facts: true,
      run: async (cx, signal) => {
        const fact = cx.facts!.get((cx.book.tlds.id as { e: LTerm }).e)!;
        const type = cx.Bend.term_wnf(fact.bok, fact.ty) as { A: typeof fact.ty };
        const arg = cx.Bend.term_wnf(fact.bok, type.A) as { k?: string };
        const res = await fetch(server.url, { method: "POST", body: JSON.stringify({ type: arg.k }), signal });
        return [cx.diag({ message: await res.text(), severity: "hint" })];
      },
    };
    const next: LintRule = { id: "test/after-api", run: (cx) => { expect(cx.prior[0].message).toBe("advice for N"); return []; } };
    const res = await lint(userland, [remote, next]).finally(() => server.stop(true));
    expect(res.ok).toBe(true);
  });
});

describe("options", () => {
  const userland = fixture("options_userland.bend", USERLAND);
  const messages = async (config?: object, file = userland) =>
    (await lint(file, [echo], { config })).diags.map((d) => [d.severity, d.message]);

  test("a rule gets its defaults, with the config's values", async () => {
    expect(await messages({})).toEqual([["hint", '{"tabWidth":2,"breakLines":false}']]);
    expect(await messages({ rules: { "test/echo": { tabWidth: 4 } } })).toEqual([["hint", '{"tabWidth":4,"breakLines":false}']]);
  });

  test("the config turns a rule off, or sets its severity", async () => {
    expect(await messages({ rules: { "test/echo": "off" } })).toEqual([]);
    expect(await messages({ rules: { "test/echo": { severity: "warning", breakLines: true } } }))
      .toEqual([["warning", '{"tabWidth":2,"breakLines":true}']]);
  });

  test("a wrong config fails loudly", async () => {
    await expect(messages({ rules: { "test/echo": { tabSize: 4 } } })).rejects.toThrow(/test\/echo has no option tabSize/);
    await expect(messages({ rules: { "test/echo": { tabWidth: "4" } } })).rejects.toThrow(/tabWidth must be a number/);
    await expect(messages({ rules: { "test/echo": { severity: "loud" } } })).rejects.toThrow(/severity must be one of/);
    await expect(messages({ rules: { "test/echo": 4 } })).rejects.toThrow(/must be "off" or an object/);
  });

  test("bend-lint.json is found in the file's folder or above it", async () => {
    const top = path.join(DIR, "project");
    fs.mkdirSync(path.join(top, "deep", "er"), { recursive: true });
    fs.writeFileSync(path.join(top, "bend-lint.json"), JSON.stringify({ rules: { "test/echo": { tabWidth: 8 } } }));
    const file = path.join(top, "deep", "er", "file.bend");
    fs.writeFileSync(file, USERLAND);
    expect(findConfig(file)).toEqual({ rules: { "test/echo": { tabWidth: 8 } } });
    expect(await messages(undefined, file)).toEqual([["hint", '{"tabWidth":8,"breakLines":false}']]);
    expect(await messages({}, file)).toEqual([["hint", '{"tabWidth":2,"breakLines":false}']]);
  });

  test("a Bend rule reads its options with defaults", async () => {
    const rule = await bendRule(fixture("options_rule.bend", OPTIONS_BEND));
    const said = async (config: object) => (await lint(userland, [rule], { config })).diags.map((d) => d.message);
    const [plain] = await said({});
    expect(plain).toMatch(/^2 \S+ none$/);
    const [given] = await said({ rules: { "test/options": { width: 4, wrap: true, name: "x" } } });
    expect(given).toMatch(/^4 \S+ x$/);
    expect(given.split(" ")[1]).not.toBe(plain.split(" ")[1]);
    await expect(said({ rules: { "test/options": { width: 1.5 } } })).rejects.toThrow(/whole number/);
  });
});

describe("review fixes", () => {
  test("facts come only from the linted file: none from Base, with or without seeding", async () => {
    for (const [name, head] of [["base_comment.bend", "import Base # comment"], ["base_plain.bend", "import Base"]]) {
      const file = fixture(name, head + "\n\ntype P is Data:\n  P{n: Nat}\n\ndef main() -> Nat:\n  1n\n");
      const where: LintRule = {
        id: "test/where",
        facts: true,
        run: (cx) => {
          const facts = [...cx.facts!.values()];
          expect(facts.length).toBeGreaterThan(0);
          expect(facts.every((f) => f.spn?.file === cx.root.file)).toBe(true);
          return [];
        },
      };
      expect((await lint(file, [where])).ok).toBe(true);
    }
  });

  test("identical files map by namespace, not only by text", async () => {
    const dir = path.join(DIR, "twins");
    fs.mkdirSync(dir, { recursive: true });
    for (const f of ["a.bend", "b.bend"]) fs.writeFileSync(path.join(dir, f), "def one() -> Type:\n  Type\n");
    fs.writeFileSync(path.join(dir, "m.bend"), "import ./a.bend as A\nimport ./b.bend as B\n\ndef main() -> Type:\n  A.one()\n");
    const all: LintRule = { id: "test/all", facts: true, run: (cx) => [...cx.facts!.values()].map((f) => cx.diag({ message: "f", spn: f.spn })) };
    const res = await lint(path.join(dir, "m.bend"), [all]);
    expect(res.ok).toBe(true);
    expect(res.diags.length).toBeGreaterThan(0);
    const a = source2("/p/a.bend", "a"), b = source2("/p/b.bend", "b");
    expect(mapper([a, b])({ file: { str: "x\n", ns: "b", dir: "/p/", al: {} }, beg: 0, end: 1 } as Span).file).toBe(b.file);
  });

  test("walk is linear in a long list (it took 408 ms at 2,000 elements)", async () => {
    const n = 2000;
    const file = fixture("long_list.bend", "import Base\n\ndef xs() -> List<&2, U32>:\n  [" + Array.from({ length: n }, (_, i) => i).join(", ") + "]\n");
    const res = await lint(file, []);
    expect(res.diags.map(render)).toEqual([]);
    const t = performance.now();
    const count = [...walk((res.book.tlds.xs as { e: LTerm }).e)].length;
    expect(count).toBeGreaterThan(n);
    expect(performance.now() - t).toBeLessThan(100);
  });

  test("clashing fixes are skipped, not fatal; equal ones merge", () => {
    const file: SourceFile = { str: "abcdef", ns: "", al: {}, path: "<fix>" };
    const fix = (beg: number, end: number, text: string): Diag => ({ code: "t/f", severity: "hint", message: "",
      fixes: [{ title: "f", applicability: "safe", edits: [{ spn: { file, beg, end }, text }] }] });
    expect(applyFixes(file, [fix(1, 1, " "), fix(1, 1, " "), fix(3, 5, "X"), fix(4, 6, "Y"), fix(1, 1, "-")]))
      .toEqual({ text: "a bcXf", skipped: 2 });
  });

  test("comp.ts that already exports js_sat still loads", () => {
    const comp = fs.readFileSync(path.join(BEND2, "comp.ts"), "utf8").replace("\nfunction js_sat(", "\nexport function js_sat(");
    const out = patch("comp.ts", comp);
    expect(out).toContain("export { RUNTIME_MAIN };");
    expect(() => new Bun.Transpiler({ loader: "ts" }).transformSync(out)).not.toThrow();
  });

  test("another checkout's bend.ts loads as its own code", () => {
    const other = path.join(DIR, "other");
    fs.cpSync(BEND2, path.join(other, "bend2"), { recursive: true });
    fs.appendFileSync(path.join(other, "bend2", "bend.ts"), "\nexport const OTHER_CHECKOUT = 1;\n");
    const script = fixture("other.ts", "import " + JSON.stringify(CLI) + ";\nconst o = await import(" + JSON.stringify(path.join(other, "bend2", "bend.ts")) + ");\n"
      + "console.log(JSON.stringify([o.OTHER_CHECKOUT, o.BEND_LINT_PATCH ?? null]));\n");
    const out = spawnSync(process.execPath, [script], { encoding: "utf8" });
    expect(JSON.parse(out.stdout.trim().split("\n").at(-1)!)).toEqual([1, null]);
  });
});

describe("rules", () => {
  test("erasure: four redundant annotations; the fix keeps every body", async () => {
    const file = fixture("erasure.bend", ERASURE);
    const res = await lint(file, [redundantAnnotation]);
    expect(res.diags.map((d) => d.def).sort()).toEqual(["alias", "dependent", "direct", "generic"]);
    const cleaned = applyFixes(root(res.sources).file, res.diags, ["suggested"]).text;
    expect(cleaned).toContain("f : N -> N = y => y");
    expect(cleaned).toContain("value : N = Z{}");
    const after = await lint(fixture("erasure_fixed.bend", cleaned), [redundantAnnotation]);
    expect(after.diags).toEqual([]);
    expect(bodies(after.book)).toEqual(bodies(res.book));
    for (const [annotation, binding] of [["f : N -> N =", "f ="], ["value : N =", "value ="]]) {
      const broken = await lint(fixture("erasure_broken.bend", cleaned.replace(annotation, binding)), []);
      expect(broken.diags.map((d) => d.code)).toEqual(["bend/check"]);
    }
    expect(fs.readFileSync(file, "utf8")).toBe(ERASURE);
  });

  test("format: strings, characters, comments, operators and CRLF stay whole", () => {
    const source = String.raw`a= "x,y=z#text\"still,string" # comment,a=b` + "\r\n"
      + String.raw`b= '='` + "\r\n" + "c= ','\r\nd= '#'\r\n" + String.raw`e= '\''` + "\r\n"
      + "f(a,\r\n  b)\r\nx==y\r\nx=>y\r\nx!=y\r\nx<=y\r\nx>=y\r\nf(a,)\r\n";
    const file: SourceFile = { str: source, ns: "", al: {}, path: "<lexical>" };
    const diags = spacingEdits(file).map((edit): Diag =>
      ({ code: spacing.id, severity: "hint", message: "", fixes: [{ title: "", applicability: "safe", edits: [edit] }] }));
    const formatted = applyFixes(file, diags).text;
    expect(formatted).toBe(source.replace(/^([abcde])=/gm, "$1 ="));
    expect(tokens(formatted).map((t) => t.text)).toEqual(tokens(source).map((t) => t.text));
    expect(applyFixes(file, [diags[0], diags[0]])).toEqual({ text: applyFixes(file, [diags[0]]).text, skipped: 0 });
  });

  test("format: one rule gives editor findings and formatter edits", async () => {
    const res = await lint(fixture("format.bend", FORMAT), [spacing]);
    expect(res.facts).toBeUndefined();
    expect(res.diags.length).toBe(8);
    const formatted = applyFixes(root(res.sources).file, res.diags).text;
    for (const line of ["def choose(x: Sample, y: Sample)", "a : Sample = SampleValue{} # preserve,this=comment",
      "b : Sample = SampleValue{}", "f : Sample -> Sample = y=>y", "f(choose(a, b))"]) {
      expect(formatted).toContain(line);
    }
    expect(tokens(formatted).map((t) => t.text)).toEqual(tokens(FORMAT).map((t) => t.text));
    const after = await lint(fixture("format_fixed.bend", formatted), [spacing]);
    expect(after.diags).toEqual([]);
    expect(bodies(after.book)).toEqual(bodies(res.book));
  });
});

describe("drift: the copy of book_read agrees with bend's own tests", () => {
  for (const name of DRIFT) {
    const file = path.join(BEND2, "..", "tests", name + ".bend");
    test.skipIf(!fs.existsSync(file))(name, async () => {
      const first = fs.readFileSync(file, "utf8").match(/^#\|(.*)$/m)![1].trim();
      expect((await lint(file, [])).ok).toBe(first !== "SOME PROOFS FAIL");
    });
  }
});

describe("rules written in Bend", () => {
  const userland = fixture("bend_userland.bend", USERLAND);

  test("a source rule finds the comma, with a fix on the file on disk", async () => {
    const rule = await bendRule(fixture("comma_rule.bend", COMMA_BEND));
    expect([rule.id, rule.facts]).toEqual(["style/comma-space", undefined]);
    const res = await lint(userland, [rule]);
    expect(res.diags.map((d) => [d.code, d.severity])).toEqual([["style/comma-space", "warning"]]);
    expect(render(res.diags[0])).toContain("generic(~N, a)");
    expect(applyFixes(root(res.sources).file, res.diags).text).toContain("generic(~N, a)");
  });

  test("a typed rule asks the checker through effects", async () => {
    const rule = await bendRule(fixture("types_rule.bend", TYPES_BEND));
    expect(rule.facts).toEqual({ scope: "file", kinds: ["Var"], defs: ["id"], names: [] });
    const res = await lint(userland, [rule, rule]);
    expect(res.diags.map((d) => d.message)).toEqual(Array(2).fill("x: Alias = N (same as its binder), text x, demanded once, uses x once"));
    expect(res.diags.every((d) => d.spn?.file === root(res.sources).file)).toBe(true);
  });
});

describe("fact filters", () => {
  const userland = fixture("filter_userland.bend", USERLAND);

  test("kinds, defs and names narrow the facts; an empty or absent list matches all", async () => {
    const all = await seen(userland, true);
    const only = async (want: LintRule["facts"], keep: (f: Seen) => boolean) => {
      const got = await seen(userland, want);
      expect(got.length).toBeGreaterThan(0);
      expect(got).toEqual(all.filter(keep));
    };
    await only({ kinds: ["Var"] }, (f) => f.kind === "Var");
    await only({ defs: ["generic"] }, (f) => f.def === "generic" || f.def.startsWith("generic~"));
    await only({ kinds: ["Ref"], names: ["id"] }, (f) => f.kind === "Ref" && f.name === "id");
    await only({ kinds: [], defs: [], names: [] }, () => true);
    expect(all.some((f) => f.def.startsWith("generic~"))).toBe(true);
  });

  test("each rule gets its own facts; bend-lint keeps only what some rule asked for", async () => {
    const got: Record<string, string[]> = {};
    const rule = (id: string, kinds: string[]): LintRule => ({ id, facts: { kinds }, run: (cx) => (got[id] = [...cx.facts!.values()].map((f) => Bend.term_strip(f.tm).$), []) });
    const res = await lint(userland, [rule("test/vars", ["Var"]), rule("test/refs", ["Ref"])]);
    expect(new Set(got["test/vars"])).toEqual(new Set(["Var"]));
    expect(new Set(got["test/refs"])).toEqual(new Set(["Ref"]));
    expect(res.facts!.size).toBe(got["test/vars"].length + got["test/refs"].length);
    expect(res.facts!.size).toBeLessThan((await lint(userland, [rule("test/all", [])])).facts!.size);
  });

  test("scope program adds the imports' facts, never Base's", async () => {
    const dir = path.join(DIR, "program");
    fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(path.join(dir, "dep.bend"), "import Base\n\ndef one(x: Nat) -> Nat:\n  x\n");
    for (const head of ["import Base", "import Base # comment"]) {
      const main = path.join(dir, "main.bend");
      fs.writeFileSync(main, head + "\nimport ./dep.bend as D\n\ndef main() -> Nat:\n  D.one(1n)\n");
      const where = async (scope: "file" | "program") => new Set((await seen(main, { scope })).map((f) => path.basename(f.path)));
      expect(await where("file")).toEqual(new Set(["main.bend"]));
      expect(await where("program")).toEqual(new Set(["main.bend", "dep.bend"]));
    }
  });

  test("a bad filter is an invalid rule", async () => {
    for (const facts of [{ scope: "all" }, { kinds: "Var" }, { names: [1] }, 3]) {
      await expect(lint(userland, [{ id: "test/bad", facts, run: () => [] } as unknown as LintRule])).rejects.toThrow(/invalid rule at 0/);
    }
  });

  test("a Bend rule pulls its facts one at a time, any number of them", async () => {
    const rule = await bendRule(fixture("count_rule.bend", COUNT_BEND));
    expect(rule.facts).toEqual({ scope: "program", kinds: ["Var"], defs: [], names: [] });
    const many = fixture("many_vars.bend", "import Base\n\n" + Array.from({ length: 5000 }, (_, i) => "def f" + i + "(x: U32) -> U32:\n  x\n").join("\n"));
    expect((await lint(many, [rule])).diags.map((d) => d.message)).toEqual(["5000"]);
  });
});

describe("the rules in rules/", () => {
  test("style/trailing-whitespace finds spaces and tabs, and its fix keeps the line breaks", async () => {
    const res = await lint(fixture("trailing.bend", STYLE), trailing);
    const found = res.diags.map((d) => d.spn!.file.str.slice(d.spn!.beg, d.spn!.end));
    expect([res.ok, found]).toEqual([true, ["  ", "\t"]]);
    expect(res.diags.every((d) => d.code === "style/trailing-whitespace" && d.fixes[0].applicability === "safe")).toBe(true);
    expect(applyFixes(root(res.sources).file, res.diags).text).toBe(STYLE.replace("U32:  \r\n", "U32:\r\n").replace("1\t", "1"));
  });

  test("style/line-length finds lines past max, without the \\r, and covers the overflow", async () => {
    const file = fixture("long.bend", STYLE);
    const res = await lint(file, [await bendRule(LINE_LENGTH)]);
    const over = (d: Diag) => d.spn!.file.str.slice(d.spn!.beg, d.spn!.end);
    expect(res.diags.map((d) => [d.code, d.severity, d.message, over(d)])).toEqual([
      ["style/line-length", "warning", "Keep the line to 100 characters; it has 101.", "y"],
      ["style/line-length", "warning", "Keep the line to 100 characters; it has 103.", "zzz"],
    ]);
    const narrow = await lint(file, [await bendRule(LINE_LENGTH)], { config: { rules: { "style/line-length": { max: 18 } } } });
    expect(narrow.diags.map(over)).toEqual(["  ", "x".repeat(82), "y".repeat(83), "z".repeat(85)]);
    const off = await lint(file, [await bendRule(LINE_LENGTH)], { config: { rules: { "style/line-length": "off" } } });
    expect(off.diags).toEqual([]);
  });
});

describe("cli", () => {
  const input = fixture("cli.bend", USERLAND);
  const first = module("first.js", `[{ id: "cli/first", facts: true, run(cx) {
    if (!cx.facts?.size || !cx.sources.length) throw new Error("missing metadata");
    return [cx.diag({ message: "First rule", severity: "warning" })];
  } }]`);
  const second = module("second.ts", `[{ id: "cli/second", run(cx) {
    if (cx.prior[0]?.code !== "cli/first") throw new Error("wrong rule order");
    return [cx.diag({ message: "Second rule", severity: "hint" })];
  } }]`);

  test("rules run in order and print bend's layout", () => {
    const out = run(input, "--rules", first, "--rules", second);
    expect(out.status).toBe(0);
    expect(out.stdout).toMatch(/Warning \[cli\/first\]:[\s\S]*Hint \[cli\/second\]:/);
  });

  test("an error finding, or a failed check, exits 1", () => {
    const blocking = module("error.js", `[{ id: "cli/error", run: (cx) => [cx.diag({ message: "Blocked", severity: "error" })] }]`);
    expect(run(input, "--rules", blocking)).toMatchObject({ status: 1, stdout: expect.stringContaining("Error [cli/error]:") });
    expect(run(fixture("cli_bad.bend", "def broken(\n"))).toMatchObject({ status: 1, stdout: expect.stringContaining("Error [bend/check]:") });
  });

  test("bad usage and bad modules exit 2", () => {
    expect(run().status).toBe(2);
    expect(run(input, "--rules").status).toBe(2);
    expect(run(input, "--nope").status).toBe(2);
    expect(run(input, "--rules", path.join(DIR, "missing.js")).status).toBe(2);
    expect(run(input, "--rules", module("object.js", "{}")).stderr).toMatch(/must export `rules`/);
    expect(run(input, "--rules", module("bad.js", `[{ id: "bad", run() { return []; } }]`)).stderr).toMatch(/invalid rule/);
    expect(run(input, "--rules", fixture("no_id.bend", "import Base\n\ndef main() -> IO(Unit):\n  IO.print(\"x\")\n")).stderr)
      .toMatch(/must define id\(\) -> String/);
    expect(run(input, "--rules", fixture("broken_rule.bend", "def broken(\n")).stderr).toMatch(/does not check/);
    expect(run(input, "--rules", fixture("no_facts.bend", COMMA_BEND.replace("def facts() -> Lint.Want:\n  Lint.NoFacts{}\n", ""))).stderr)
      .toMatch(/must define id\(\) -> String, facts\(\) -> Lint.Want/);
  });

  test("a rule written in Bend runs from the CLI", () => {
    const out = run(input, "--rules", fixture("cli_comma_rule.bend", COMMA_BEND));
    expect(out.status).toBe(0);
    expect(out.stdout).toContain("Warning [style/comma-space]:");
  });

  test("--json prints findings with LSP ranges, and nothing else", () => {
    const comma = module("json_comma.js", `[{ id: "style/comma-space", run: (cx) =>
      [...cx.root.text.matchAll(/,(?=\\w)/g)].map((m) => {
        const spn = { file: cx.root.file, beg: m.index + 1, end: m.index + 1 };
        return cx.diag({ message: "space", severity: "hint", spn,
          fixes: [{ title: "Insert space", applicability: "safe", edits: [{ spn, text: " " }] }] });
      }) }]`);
    const out = run(input, "--rules", comma, "--json");
    expect(out.status).toBe(0);
    const json = JSON.parse(out.stdout);
    const at = { line: 25, character: 13 };
    expect(json).toEqual({
      ok: true,
      findings: [{
        code: "style/comma-space", severity: "hint", message: "space", path: fs.realpathSync(input).replaceAll("\\", "/"),
        range: { start: at, end: at },
        fixes: [{ title: "Insert space", applicability: "safe", edits: [{ path: fs.realpathSync(input).replaceAll("\\", "/"), range: { start: at, end: at }, text: " " }] }],
      }],
    });
    expect(USERLAND.split("\n")[at.line].slice(0, at.character)).toBe("  generic(~N,");
    const bad = JSON.parse(run(fixture("json_bad.bend", "def broken(\n"), "--json").stdout);
    expect([bad.ok, bad.findings[0].code]).toEqual([false, "bend/check"]);
  });

  test("--bend and BEND_DIR choose the bend to load; a wrong one exits 2", () => {
    expect(run(input, "--bend", path.dirname(BEND2)).status).toBe(0);
    const env = spawnSync(process.execPath, [CLI, input], { encoding: "utf8", env: { ...process.env, BEND_DIR: BEND2 } });
    expect(env.status).toBe(0);
    expect(run(input, "--bend", DIR)).toMatchObject({ status: 2, stderr: expect.stringContaining("no bend2 at") });
  });

  test("--config gives the config", () => {
    const echoes = module("echo.js", `[{ id: "test/echo", options: { tabWidth: 2 }, run: (cx) => [cx.diag({ message: "w" + cx.options.tabWidth })] }]`);
    const config = fixture("cli_config.json", JSON.stringify({ rules: { "test/echo": { tabWidth: 6, severity: "hint" } } }));
    const out = run(input, "--rules", echoes, "--config", config, "--json");
    expect(JSON.parse(out.stdout).findings.map((f: { severity: string; message: string }) => [f.severity, f.message])).toEqual([["hint", "w6"]]);
  });

  test("--fix writes only the linted file, and prints findings when fixes clash", () => {
    const dir = path.join(DIR, "fixroot");
    fs.mkdirSync(dir, { recursive: true });
    const dep = path.join(dir, "dep.bend");
    fs.writeFileSync(dep, "def one() -> Type:\n  Type\n");
    const main = path.join(dir, "main.bend");
    fs.writeFileSync(main, "import ./dep.bend as D\n\ndef main() -> Type:\n  D.one()\n");
    const everywhere = module("everywhere.js", `[{ id: "test/everywhere", run: (cx) => cx.sources.filter((s) => !s.base).flatMap((s) => [0, 0, 1].map((n) => {
      const spn = { file: s.file, beg: n, end: n };
      return cx.diag({ message: "x", spn, fixes: [{ title: "x", applicability: "safe", edits: [{ spn, text: n === 0 ? "#" : "!" }] }] });
    })) }]`);
    const out = run(main, "--rules", everywhere, "--fix");
    expect(out.status).toBe(0);
    expect(out.stdout).toContain("Warning [test/everywhere]:");
    expect(fs.readFileSync(dep, "utf8")).toBe("def one() -> Type:\n  Type\n");
    expect(fs.readFileSync(main, "utf8").startsWith("#i!mport")).toBe(true);
    expect(out.stderr).not.toContain("skipped");
  });

  test("--fix-suggested and --fix-dangerously apply wider levels", () => {
    const levels = module("levels.js", `[{ id: "test/levels", run: (cx) => ["safe", "suggested", "dangerous"].map((applicability, n) => {
      const spn = { file: cx.root.file, beg: n, end: n };
      return cx.diag({ message: applicability, spn, fixes: [{ title: applicability, applicability, edits: [{ spn, text: String(n) }] }] });
    }) }]`);
    const fixed = (flag: string) => {
      const target = fixture("levels" + flag + ".bend", "#abc\n");
      expect(run(target, "--rules", levels, flag).status).toBe(0);
      return fs.readFileSync(target, "utf8");
    };
    expect(["--fix", "--fix-suggested", "--fix-dangerously"].map(fixed)).toEqual(["0#abc\n", "0#1abc\n", "0#1a2bc\n"]);
  });

  test("--fix applies safe fixes", () => {
    const target = fixture("fix.bend", USERLAND);
    const comma = module("comma.js", `[{ id: "style/comma-space", run: (cx) =>
      [...cx.root.text.matchAll(/,(?=\\w)/g)].map((m) => {
        const spn = { file: cx.root.file, beg: m.index + 1, end: m.index + 1 };
        return cx.diag({ message: "space", severity: "hint", spn,
          fixes: [{ title: "Insert space", applicability: "safe", edits: [{ spn, text: " " }] }] });
      }) }]`);
    expect(run(target, "--rules", comma, "--fix").status).toBe(0);
    expect(fs.readFileSync(target, "utf8")).toContain("generic(~N, a)");
  });
});
