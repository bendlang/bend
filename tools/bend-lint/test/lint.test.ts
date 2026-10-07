import { afterAll, describe, expect, test } from "bun:test";
import { spawnSync } from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

import type { Book, LTerm, Span } from "../../../bend2/bend.ts";
import { BEND2, Bend, Comp, applyFixes, bendRule, lint, mapper, render, walk } from "../src/lint.ts";
import type { Diag, Edit, Fact, LintRule, RuleContext, Source, SourceFile } from "../src/lint.ts";
import { DriftError, bendDir, blob, current, patch, pinned, relative, resolve } from "../src/patch.ts";

// Types
// =====

type Loose = Fact & { tm: { x?: { $: string; k?: string; i?: number } } };
type Token = { text: string; beg: number; end: number };

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

// Repo tests whose first expected line says if the check passes.
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

// The comma-space rule, written in Bend: source text only.
const COMMA_BEND = String.raw`import Base
import ../../../src/lint.bend as Lint

def id() -> String:
  "style/comma-space"

def types() -> Bool:
  False{}

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

def commas(s: String, +at: U32) -> List<&2, U32>:
  match s:
    case SNil{}:
      []
    case SCon{+c, +rest}:
      keep(comma_before_word(c, rest), at, commas(rest, U32.add(at, 1)))

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
      diags(path, commas(text, 0))
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
    case Lint.Input{sources, facts}:
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

def types() -> Bool:
  True{}

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

def each(facts: List<&2, Lint.Fact>) -> IO(List<&2, Lint.Diag>):
  match facts:
    case Nil{}:
      IO.pure(List<&2, Lint.Diag>, [])
    case Con{+f, rest}:
      do IO<List<&2, Lint.Diag>>:
        v : Lint.View <- Lint.view(f)
        here : Maybe<&2, Lint.Diag> <- fact_diag(f, v)
        later : List<&2, Lint.Diag> <- each(rest)
        return prepend(here, later)

def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
  match input:
    case Lint.Input{sources, facts}:
      each(facts)

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
  needsTypes: true,
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
  needsTypes: true,
  run: () => { throw new Error("this rule must not run"); },
};

// x : T = v, where v is a variable that already has type T. Constructors
// and lambdas keep theirs: checking needs the expected type. Template
// instances repeat the facts of the def as written, so they are skipped.
const redundantAnnotation: LintRule = {
  id: "erasure/redundant-local-annotation",
  needsTypes: true,
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

// Functions
// =========

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

  test("bend.ts: wraps term_infer and term_check, and swaps fs and path", () => {
    const out = patch("bend.ts", src);
    expect(out.match(/^export function term_infer\(/gm)?.length).toBe(1);
    expect(out).toContain("function lint_infer(");
    expect(out).toContain("function lint_check(");
    expect(out).toMatch(/^import \{ fs \} from "file:.*patch\.ts";/m);
    expect(out).toMatch(/^import \{ path \} from "file:.*patch\.ts";/m);
  });

  test("comp.ts: exports RUNTIME_MAIN and js_sat", () => {
    const out = patch("comp.ts", comp);
    expect(out).toMatch(/^export const RUNTIME_MAIN: string = /m);
    expect(out).toMatch(/^export function js_sat\(/m);
  });

  test("fails loudly when an anchor changes or repeats", () => {
    expect(() => patch("bend.ts", src.replace("term_infer(book: Book,", "term_infer(bk: Book,"))).toThrow(DriftError);
    expect(() => patch("bend.ts", src.replace('import * as fs from "node:fs";', 'import fs from "node:fs";'))).toThrow(/node:fs import/);
    expect(() => patch("bend.ts", src + "\n" + src.match(/^export function term_check\(.*$/m)![0] + "\n")).toThrow(/found 2 of term_check/);
    expect(() => patch("comp.ts", comp.replace("function js_sat(", "function js_name("))).toThrow(/comp\.ts: found 0 of js_sat/);
  });

  test("the loaded bend.ts and comp.ts are the patched ones", () => {
    expect((Bend as unknown as Record<string, unknown>).BEND_LINT_PATCH).toBe(1);
    expect((Comp as unknown as Record<string, unknown>).BEND_LINT_PATCH).toBe(1);
  });

  test("the pin holds git blob hashes, and matches bend2", () => {
    expect(blob("a\r\nb\n")).toBe(blob("a\nb\n"));
    expect(blob("hello\n")).toBe("ce013625030ba8dba906f756967f9e9ca394464a");
    expect(pinned()).toMatch(/^bend\.ts [0-9a-f]{40}\ncomp\.ts [0-9a-f]{40}$/);
    if (process.env.BEND_LINT_UNPINNED !== "1") expect(current(BEND2)).toBe(pinned());
  });

  test("bend2 is found from a checkout, its bend2 folder, or the repo; a wrong dir fails", () => {
    const repo = path.dirname(BEND2);
    expect([bendDir(repo), bendDir(BEND2), bendDir(undefined)]).toEqual([BEND2, BEND2, BEND2]);
    expect(() => bendDir(DIR)).toThrow(/no bend2 at/);
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

  test("only rules with needsTypes get facts", async () => {
    const look: LintRule = { id: "test/look", run: (cx) => { expect(cx.facts).toBeUndefined(); return []; } };
    expect((await lint(userland, [look, identity])).ok).toBe(true);
    expect((await lint(userland, [commaSpace])).facts).toBeUndefined();
  });

  test("facts cover templates, proofs, matches and fields", async () => {
    const probe: LintRule = {
      id: "test/probe",
      needsTypes: true,
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
    await expect(lint(userland, [{ id: "test/boom", run: async () => { throw new Error("rule failed"); } }])).rejects.toThrow("rule failed");
    const controller = new AbortController();
    const abort: LintRule = { id: "test/abort", run: async () => { controller.abort(); return []; } };
    await expect(lint(userland, [abort, neverRun], controller.signal)).rejects.toThrow();
    await expect(lint(userland, [], controller.signal)).rejects.toThrow();
  });

  test("spans after import lines point at the right text on disk", async () => {
    fixture("dep.bend", "type N is Data:\n  Z{}\ndef id(x: N) -> N:\n  x\n");
    const main = fixture("main.bend", "import ./dep.bend as D\n\ndef main() -> D.N:\n  D.id(D.Z{})\n");
    const look: LintRule = {
      id: "test/imports",
      needsTypes: true,
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
      needsTypes: true,
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
      needsTypes: true,
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

describe("rules", () => {
  test("erasure: four redundant annotations; the fix keeps every body", async () => {
    const file = fixture("erasure.bend", ERASURE);
    const res = await lint(file, [redundantAnnotation]);
    expect(res.diags.map((d) => d.def).sort()).toEqual(["alias", "dependent", "direct", "generic"]);
    const cleaned = applyFixes(root(res.sources).file, res.diags, ["suggested"]);
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
    const formatted = applyFixes(file, diags);
    expect(formatted).toBe(source.replace(/^([abcde])=/gm, "$1 ="));
    expect(tokens(formatted).map((t) => t.text)).toEqual(tokens(source).map((t) => t.text));
    expect(() => applyFixes(file, [diags[0], diags[0]])).toThrow(/overlap/);
  });

  test("format: one rule gives editor findings and formatter edits", async () => {
    const res = await lint(fixture("format.bend", FORMAT), [spacing]);
    expect(res.facts).toBeUndefined();
    expect(res.diags.length).toBe(8);
    const formatted = applyFixes(root(res.sources).file, res.diags);
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

describe("drift: the copy of book_read agrees with the repo tests", () => {
  for (const name of DRIFT) {
    test(name, async () => {
      const file = fileURLToPath(new URL("../../../tests/" + name + ".bend", import.meta.url));
      const first = fs.readFileSync(file, "utf8").match(/^#\|(.*)$/m)![1].trim();
      expect((await lint(file, [])).ok).toBe(first !== "SOME PROOFS FAIL");
    });
  }
});

describe("rules written in Bend", () => {
  const userland = fixture("bend_userland.bend", USERLAND);

  test("a source rule finds the comma, with a fix on the file on disk", async () => {
    const rule = await bendRule(fixture("comma_rule.bend", COMMA_BEND));
    expect([rule.id, rule.needsTypes]).toEqual(["style/comma-space", false]);
    const res = await lint(userland, [rule]);
    expect(res.diags.map((d) => [d.code, d.severity])).toEqual([["style/comma-space", "warning"]]);
    expect(render(res.diags[0])).toContain("generic(~N, a)");
    expect(applyFixes(root(res.sources).file, res.diags)).toContain("generic(~N, a)");
  });

  test("a typed rule asks the checker through effects", async () => {
    const rule = await bendRule(fixture("types_rule.bend", TYPES_BEND));
    expect(rule.needsTypes).toBe(true);
    const res = await lint(userland, [rule, rule]);
    expect(res.diags.map((d) => d.message)).toEqual(Array(2).fill("x: Alias = N (same as its binder), text x, demanded once, uses x once"));
    expect(res.diags.every((d) => d.spn?.file === root(res.sources).file)).toBe(true);
  });
});

describe("cli", () => {
  const input = fixture("cli.bend", USERLAND);
  const first = module("first.js", `[{ id: "cli/first", needsTypes: true, run(cx) {
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
