import { afterAll, describe, expect, test } from "bun:test";
import { spawnSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

import type { Book, LTerm, Span } from "../../../bend2/bend.ts";
import { Bend, applyFixes, lint, mapper, render, walk } from "../src/lint.ts";
import type { Diag, Edit, Fact, LintRule, RuleContext, Source, SourceFile } from "../src/lint.ts";
import { BEND_TS, DriftError, blob, current, patch, pinned, relative, resolve } from "../src/patch.ts";

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

const DIR = fs.mkdtempSync(path.join(os.tmpdir(), "bend-lint-"));
const CLI = fileURLToPath(new URL("../src/lint.ts", import.meta.url));

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
// and lambdas keep theirs: checking needs the expected type. A template
// body is checked again per instance (generic~0), at the same span; the
// first finding at a span is from the def as written, so it is kept.
const redundantAnnotation: LintRule = {
  id: "erasure/redundant-local-annotation",
  needsTypes: true,
  run: (cx) => [...new Map([...cx.facts!.values()].flatMap((fact): Array<[string, Diag]> => {
    const term = cx.Bend.term_strip(fact.tm);
    const value = cx.span(term.s);
    const v = cx.binder(fact, term);
    if (term.$ !== "Var" || fact.spn === undefined || value === undefined || v === null || !cx.same(fact, v.T, fact.ty)) {
      return [];
    }
    const prefix = fact.spn.file.str.slice(fact.spn.beg, value.beg);
    const name = prefix.match(/^([A-Za-z_][A-Za-z_0-9]*)\s*:/);
    if (fact.spn.file !== value.file || fact.spn.beg >= value.beg || prefix.includes("#") || name === null || !prefix.trimEnd().endsWith("=")) {
      return [];
    }
    const spn = { file: fact.spn.file, beg: fact.spn.beg + name[1].length, end: fact.spn.beg + prefix.lastIndexOf("=") };
    return [[spn.beg + ":" + spn.end, cx.diag({
      message: "Remove the redundant annotation: " + v.k + " already has type " + cx.show(fact, v.T) + ".",
      severity: "hint", spn, fact,
      fixes: [{ title: "Remove redundant local type annotation", applicability: "suggested", edits: [{ spn, text: " " }] }],
    })]];
  }).reverse()).values()].reverse(),
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
  const src = fs.readFileSync(BEND_TS, "utf8");

  test("wraps term_infer and term_check, and swaps fs and path", () => {
    const out = patch(src);
    expect(out.match(/^export function term_infer\(/gm)?.length).toBe(1);
    expect(out).toContain("function lint_infer(");
    expect(out).toContain("function lint_check(");
    expect(out).toMatch(/^import \{ fs \} from "file:.*patch\.ts";/m);
    expect(out).toMatch(/^import \{ path \} from "file:.*patch\.ts";/m);
  });

  test("fails loudly when an anchor changes or repeats", () => {
    expect(() => patch(src.replace("term_infer(book: Book,", "term_infer(bk: Book,"))).toThrow(DriftError);
    expect(() => patch(src.replace('import * as fs from "node:fs";', 'import fs from "node:fs";'))).toThrow(/node:fs import/);
    expect(() => patch(src + "\n" + src.match(/^export function term_check\(.*$/m)![0] + "\n")).toThrow(/found 2 of term_check/);
  });

  test("the loaded bend.ts is the patched one", () => {
    expect((Bend as unknown as Record<string, unknown>).BEND_LINT_PATCH).toBe(1);
  });

  test("the pin is a git blob hash, and matches bend.ts", () => {
    expect(blob("a\r\nb\n")).toBe(blob("a\nb\n"));
    expect(blob("hello\n")).toBe("ce013625030ba8dba906f756967f9e9ca394464a");
    expect(pinned()).toMatch(/^[0-9a-f]{40}$/);
    if (process.env.BEND_LINT_UNPINNED !== "1") expect(current()).toBe(pinned());
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
    expect(run(input, "--rules", fixture("rule.bend", "")).stderr).toMatch(/not supported yet/);
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
