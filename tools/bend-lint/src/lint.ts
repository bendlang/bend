#!/usr/bin/env bun
// bend-lint checks a Bend file with bend's checker, then runs rules over
// its source and the checker's results. It loads bend2/bend.ts through
// ./patch.ts. Anything in bend.ts it cannot follow stops it with a
// DriftError. As a CLI, it exits 0 when ok, 1 when it found an error, 2
// on bad usage or a tool failure.

import * as url from "node:url";
import * as util from "node:util";

import type * as BendModule from "../../../bend2/bend.ts";
import type { Ann, Book, Ctx, Err, HTerm, LTerm, Name, Quant, Span, Uses } from "../../../bend2/bend.ts";
import { BEND_TS, DriftError, MARK, PIN_FILE, current, fs, patch, path, pinned } from "./patch.ts";

// Types
// =====

export type Bend = typeof BendModule;
export type Severity = "error" | "warning" | "information" | "hint";
// safe keeps behavior; suggested may change it; dangerous may break code.
export type Applicability = "safe" | "suggested" | "dangerous";
export type Edit = { spn: Span; text: string };
export type Fix = { title: string; applicability: Applicability; edits: Edit[] };
export type Position = { line: number; character: number };

export type Diag = {
  code: string;
  severity: Severity;
  message: string;
  spn?: Span;
  def?: Name;
  ctx?: Ctx;
  bok?: Book;
  obs?: string;
  note?: string;
  fixes: Fix[];
  core?: unknown; // bend's own failure, when the check failed
};

export type DiagInit = {
  message: string;
  severity?: Severity;
  spn?: Span;
  fact?: Fact;
  def?: Name;
  obs?: string;
  note?: string;
  fixes?: Fix[];
};

// A file of the book, as it is on disk.
export type SourceFile = { str: string; ns: string; al: Record<Name, Name>; path: string };
export type Source = { path: string; ns: string; text: string; root: boolean; base: boolean; file: SourceFile };

// `tm` checked (or inferred) as `ty` at depth `dep` in `ctx`, in def `def`,
// demanded `qt` times, using the variables in `us`. `bok` is the book it was
// checked in (a template body has its own). A template body is checked as
// written, then again for each instance (generic~0) at the same spans;
// `inst` marks the facts of an instance.
export type Fact = { tm: LTerm; ty: HTerm; bok: Book; ctx: Ctx; dep: number; def: Name; qt: Quant; us: Uses; inst: boolean; spn?: Span };

export type RuleContext = {
  Bend: Bend;
  book: Book;
  sources: Source[];
  root: Source;
  facts?: Map<LTerm, Fact>; // only for a rule with needsTypes
  prior: readonly Diag[];   // what earlier rules found
  span<S extends Span | undefined>(s: S): S; // a bend.ts span, in the file on disk
  walk(tm: LTerm): Generator<LTerm>;
  binder(fact: Fact, v: LTerm): Ann | null;
  show(fact: Fact, ty: HTerm): string;
  same(fact: Fact, a: HTerm, b: HTerm): boolean;
  diag(init: DiagInit): Diag;
};

export type LintRule = {
  id: string; // namespace/name; the code of its findings
  needsTypes?: boolean;
  run(cx: RuleContext, signal: AbortSignal): Diag[] | Promise<Diag[]>;
};

export type LintResult = { ok: boolean; diags: Diag[]; sources: Source[]; book: Book; facts?: Map<LTerm, Fact> };

type Hooked = Book & { see?: (bok: Book, tm: LTerm, ty: HTerm, ctx: Ctx, dep: number, def: Name, spn: Span | undefined, qt: Quant, us: Uses) => void };
type Mapper = <S extends Span | undefined>(s: S) => S;
type Checked = { book: Book; sources: Source[]; span: Mapper; facts?: Map<LTerm, Fact>; failure?: Diag };

// Constants
// =========

const RULE_ID = /^[^/\s]+\/[^/\s]+$/;
const LINE = /[^\n]*\n|[^\n]+$/g;
const STACK = "the machine stack overflowed (a deep recursion, or a literal too large to expand)";
const SAMPLE = "type N is Data:\n  Z{}\n\ndef id(x: N) -> N:\n  x\n";
const HEAD: Record<Severity, string> = { error: "Error", warning: "Warning", information: "Information", hint: "Hint" };

// Binders are explicit in checked terms, so Var.v cells are not followed.
// A new term kind is a type error here, and a DriftError when walked.
const CHILDREN: { [K in LTerm["$"]]: (tm: Extract<LTerm, { $: K }>) => LTerm[] } = {
  Let: (tm) => [...tm.v, tm.f],
  Lam: (tm) => [tm.f],
  Sub: (tm) => [tm.f],
  App: (tm) => [tm.f, tm.x],
  Ctr: (tm) => tm.x,
  ADT: (tm) => tm.x,
  Mat: (tm) => [tm.h, tm.m],
  Rwt: (tm) => [tm.e, tm.p, tm.f],
  Typ: (tm) => [tm.g],
  Min: (tm) => [tm.a, tm.b],
  All: (tm) => [tm.A, tm.B],
  Eql: (tm) => [tm.a, tm.b, tm.T],
  Ann: (tm) => [tm.x, tm.T],
  Var: () => [],
  Ref: () => [],
  Qnt: () => [],
  Qua: () => [],
  Lit: () => [],
  Efq: () => [],
  Rfl: () => [],
  Hol: () => [],
};

const OPTIONS = {
  rules: { type: "string", multiple: true },
  fix: { type: "boolean" },
  pin: { type: "boolean" },
  help: { type: "boolean", short: "h" },
} as const;

const USAGE = [
  "usage: bun tools/bend-lint/src/lint.ts <file.bend> [--rules <module>]... [--fix]",
  "       bun tools/bend-lint/src/lint.ts --pin   (pin the current bend2/bend.ts)",
].join("\n");

// Functions
// =========

export function* walk(tm: LTerm): Generator<LTerm> {
  const children = (CHILDREN as Record<string, ((tm: LTerm) => LTerm[]) | undefined>)[tm.$];
  if (children === undefined) {
    throw new DriftError("unknown term kind " + tm.$ + "; update CHILDREN in tools/bend-lint/src/lint.ts");
  }
  yield tm;
  for (const child of children(tm)) {
    yield* walk(child);
  }
}

function starts(text: string): number[] {
  return [0, ...[...text.matchAll(/\n/g)].map((m) => m.index! + 1)];
}

function line(starts: number[], off: number): number {
  let lo = 0;
  let hi = starts.length - 1;
  while (lo < hi) {
    const mid = (lo + hi + 1) >> 1;
    [lo, hi] = starts[mid] <= off ? [mid, hi] : [lo, mid - 1];
  }
  return lo;
}

// bend.ts parses a copy of each file with its import lines blanked, so a
// span moves to the file on disk by line and column. A copy that does not
// match its file is a DriftError.
export function mapper(sources: Source[]): Mapper {
  const own = new Set<unknown>(sources.map((s) => s.file));
  const memo = new WeakMap<object, { file: SourceFile; from: number[]; to: number[] }>();
  return <S extends Span | undefined>(s: S): S => {
    if (s === undefined || own.has(s.file)) {
      return s;
    }
    const f = s.file as Span["file"] & { dir?: string };
    if (!memo.has(f)) {
      const lines = f.str.split("\n");
      const found = sources.filter((src) => {
        const theirs = src.text.split("\n");
        return (f.dir === undefined || f.dir === src.path.slice(0, src.path.lastIndexOf("/") + 1))
          && lines.length === theirs.length
          && lines.every((l, i) => l === theirs[i] || l.trim() === "" && /^\s*import(\s|$)/.test(theirs[i]));
      });
      if (found.length !== 1) {
        throw new DriftError("cannot map a bend.ts span to a file on disk (" + found.length
          + " candidates); bend.ts may mask imports another way now");
      }
      Object.assign(found[0].file.al, f.al);
      memo.set(f, { file: found[0].file, from: starts(f.str), to: starts(found[0].text) });
    }
    const { file, from, to } = memo.get(f)!;
    const at = (off: number): number => {
      const i = line(from, off);
      return to[i] + off - from[i];
    };
    return { file, beg: at(s.beg), end: at(s.end) } as S;
  };
}

function isErr(e: unknown): e is Err {
  return typeof e === "object" && e !== null && (e as { $?: unknown }).$ === "Err";
}

// Loads and checks a book as bend2/main.ts book_read does.
async function check(file: string, capture: boolean, signal: AbortSignal): Promise<Checked> {
  signal.throwIfAborted();
  const book: Hooked = Bend.book_nil();
  const seen = new Map<string, string | null>();
  const found: Array<Omit<Fact, "inst">> = [];
  book.see = capture ? (bok, tm, ty, ctx, dep, def, spn, qt, us) => void found.push({ tm, ty, bok, ctx, dep, def, spn, qt, us }) : undefined;
  const caught = await Bend.book_load(book, file, "", seen).then(() => {
    const laws = path.join(path.dirname(file), "LAWS.bend");
    if (path.basename(file) === "PROOF.bend" && fs.existsSync(laws) && !seen.has(fs.realpathSync(laws))) {
      throw "PROOF.bend must import ./LAWS.bend";
    }
    Bend.book_valid(book, 0);
    if (book.hols > 0) {
      throw book.hols + " TODO" + (book.hols === 1 ? "" : "s") + " found.\nThe code is incomplete, and not a valid proof yet.";
    }
  }).then(() => undefined, (e: unknown) => ({ e }));
  signal.throwIfAborted();
  const root = seen.keys().next().value;
  const sources = [...seen.keys()].filter((real) => fs.existsSync(real)).map((real): Source => {
    const text = fs.readFileSync(real, "utf8");
    const ns = seen.get(real) ?? "";
    return { path: real, ns, text, root: real === root, base: real === Bend.BASE_BEND, file: { str: text, ns, al: {}, path: real } };
  });
  const span = mapper(sources);
  if (caught === undefined) {
    const insts = new Set(Object.values(book.tmps).flatMap((m) => [...m.values()]));
    return { book, sources, span, facts: capture ? new Map(found.map((f) => [f.tm, { ...f, inst: insts.has(f.def), spn: span(f.spn) }])) : undefined };
  }
  const err = isErr(caught.e) ? caught.e : undefined;
  const message = err !== undefined ? Bend.expr_show(err.bok, err.exp) : caught.e instanceof RangeError ? STACK : String(caught.e);
  return { book, sources, span, failure: { code: "bend/check", severity: "error", message, spn: span(err?.spn), def: err?.def, fixes: [], core: caught.e } };
}

// Rules run in order. A finding with severity error stops the run. A rule
// that throws, and an abort, reach the caller.
export async function lint(file: string, rules: LintRule[], signal = new AbortController().signal): Promise<LintResult> {
  if (current() !== pinned() && process.env.BEND_LINT_UNPINNED !== "1") {
    throw new DriftError("bend2/bend.ts is " + current() + ", but bend-lint is pinned to " + pinned() + ".\n"
      + "To bump: BEND_LINT_UNPINNED=1 bun test tools/bend-lint, then bun tools/bend-lint/src/lint.ts --pin");
  }
  const bad = rules.find((r) => !RULE_ID.test(String(r?.id)) || typeof r?.run !== "function");
  if (bad !== undefined) {
    throw new TypeError("invalid rule " + JSON.stringify(bad?.id) + ": it needs an id like ns/name and a run function");
  }
  const { book, sources, span, facts, failure } = await check(file, rules.some((r) => r.needsTypes === true), signal);
  if (failure !== undefined) {
    return { ok: false, diags: [failure], sources, book };
  }
  const root = sources.find((s) => s.root)!;
  let diags: Diag[] = [];
  for (const rule of rules) {
    signal.throwIfAborted();
    const out = await rule.run({
      Bend, book, sources, root, span, walk,
      facts: rule.needsTypes === true ? facts : undefined,
      prior: diags,
      binder: (fact, v) => v.$ === "Var" ? Bend.pmap_get(fact.ctx, v.i) : null,
      show: (fact, ty) => Bend.term_show(Bend.term_lower(ty, fact.dep)),
      same: (fact, a, b) => Bend.term_compare("EQ", fact.bok, a, b, fact.dep),
      diag: (d) => ({
        code: rule.id, severity: d.severity ?? "warning", message: d.message, spn: d.spn,
        def: d.def ?? d.fact?.def, ctx: d.fact?.ctx, bok: d.fact?.bok ?? book, obs: d.obs, note: d.note, fixes: d.fixes ?? [],
      }),
    }, signal);
    signal.throwIfAborted();
    if (!Array.isArray(out)) {
      throw new TypeError("rule " + rule.id + " must return an array of diagnostics");
    }
    const settled = out.map((d): Diag => ({
      ...d, code: rule.id, spn: span(d.spn),
      fixes: d.fixes.map((f) => ({ ...f, edits: f.edits.map((e) => ({ ...e, spn: span(e.spn) })) })),
    }));
    const stop = settled.findIndex((d) => d.severity === "error");
    diags = [...diags, ...(stop < 0 ? settled : settled.slice(0, stop + 1))];
    if (stop >= 0) {
      return { ok: false, diags, sources, book, facts };
    }
  }
  return { ok: true, diags, sources, book, facts };
}

// The text of `file` with the edits on it applied. Edits must not overlap.
function edit(file: Span["file"], edits: Edit[]): string {
  const mine = edits.filter((e) => e.spn.file === file).sort((a, b) => b.spn.beg - a.spn.beg);
  const sound = mine.every(({ spn }, i) => {
    const wall = i === 0 ? file.str.length + 1 : mine[i - 1].spn.beg;
    return spn.beg >= 0 && spn.beg <= spn.end && spn.end <= file.str.length && spn.beg < wall && spn.end <= wall;
  });
  if (!sound) {
    throw new Error("bend-lint: fixes are out of bounds or overlap");
  }
  return mine.reduce((s, { spn, text }) => s.slice(0, spn.beg) + text + s.slice(spn.end), file.str);
}

export function applyFixes(file: SourceFile, diags: Diag[], levels: Applicability[] = ["safe"]): string {
  return edit(file, diags.flatMap((d) => d.fixes).filter((f) => levels.includes(f.applicability)).flatMap((f) => f.edits));
}

function common(a: string[], b: string[]): number {
  const n = a.findIndex((x, i) => x !== b[i]);
  return Math.min(n < 0 ? a.length : n, b.length);
}

// bend's own error layout; the head names the severity and the code, and
// each fix follows as a unified diff.
export function render(d: Diag): string {
  const err = isErr(d.core) ? d.core : Bend.Err(d.bok ?? Bend.book_nil(), d.ctx ?? Bend.ctx_nil(), d.message, d.obs, d.spn, d.def, d.note);
  const fixes = d.fixes.map((fix) => "\n\nFix: " + fix.title + " [" + fix.applicability + "]"
    + [...new Set(fix.edits.map((e) => e.spn.file))].map((file) => {
      const old = file.str.match(LINE) ?? [];
      const now = edit(file, fix.edits).match(LINE) ?? [];
      const pre = common(old, now);
      const suf = common(old.slice(pre).reverse(), now.slice(pre).reverse());
      const gone = old.slice(pre, old.length - suf);
      const came = now.slice(pre, now.length - suf);
      const name = (file as SourceFile).path;
      const range = (n: number): string => (n === 0 ? pre : pre + 1) + "," + n;
      const show = (xs: string[], sign: string): string[] => xs.map((l) =>
        sign + l.replace(/\r?\n$/, "") + (l.endsWith("\n") ? "" : "\n\\ No newline at end of file"));
      return "\n--- " + name + "\n+++ " + name + "\n@@ -" + range(gone.length) + " +" + range(came.length) + " @@\n"
        + [...show(gone, "-"), ...show(came, "+")].join("\n");
    }).join(""));
  return Bend.err_show(err).replace(/^Error:/, HEAD[d.severity] + " [" + d.code + "]:") + fixes.join("");
}

// The LSP range of a span in a file on disk (0-based, UTF-16).
export function position(spn: Span): { start: Position; end: Position } {
  const ss = starts(spn.file.str);
  const at = (off: number): Position => {
    const i = line(ss, off);
    return { line: i, character: off - ss[i] };
  };
  return { start: at(spn.beg), end: at(spn.end) };
}

// Patches bend.ts as Bun loads it, then checks a tiny program: the type of
// `x` in `id` must be recorded as N.
async function instrument(): Promise<Bend> {
  const patched = patch(fs.readFileSync(BEND_TS, "utf8"));
  Bun.plugin({
    name: "bend-lint",
    setup: (build) => {
      build.onLoad({ filter: /[\\/]bend2[\\/]bend\.ts$/ }, () => ({ contents: patched, loader: "ts" }));
    },
  });
  const B: Bend & { [MARK]?: number } = await import(url.pathToFileURL(BEND_TS).href);
  if (B[MARK] !== 1) {
    throw new DriftError("bend2/bend.ts was loaded before bend-lint could patch it; import bend-lint first");
  }
  const sample: Hooked = B.book_nil();
  const seen: Array<{ bok: Book; tm: LTerm; ty: HTerm; def: Name }> = [];
  sample.see = (bok, tm, ty, _ctx, _dep, def) => void seen.push({ bok, tm, ty, def });
  B.parse_book(sample, "/", SAMPLE, "", {});
  B.book_valid(sample);
  const typed = seen.some((t) => t.def === "id" && B.term_strip(t.tm).$ === "Var"
    && (B.term_wnf(t.bok, t.ty) as { k?: string }).k === "N");
  if (!typed) {
    throw new DriftError("self-check failed: the patched bend.ts recorded no type for `id`; update tools/bend-lint/src/patch.ts");
  }
  return B;
}

async function cli(argv: string[]): Promise<number> {
  const { values, positionals } = util.parseArgs({ args: argv, options: OPTIONS, allowPositionals: true });
  if (values.help) {
    console.log(USAGE);
    return 0;
  }
  if (values.pin) {
    fs.writeFileSync(PIN_FILE, current() + "\n");
    console.log("bend-lint: pinned bend2/bend.ts " + pinned());
    return 0;
  }
  if (positionals.length !== 1) {
    throw new Error("give one .bend file\n" + USAGE);
  }
  const modules = await Promise.all((values.rules ?? []).map(async (file): Promise<LintRule[]> => {
    if (file.endsWith(".bend")) {
      throw new Error(file + ": rules written in Bend are not supported yet");
    }
    const { rules } = await import(url.pathToFileURL(path.resolve(file)).href);
    if (!Array.isArray(rules)) {
      throw new Error(file + " must export `rules`, an array of rules");
    }
    return rules;
  }));
  const res = await lint(positionals[0], modules.flat());
  const fixed = values.fix && res.ok
    ? res.sources.filter((s) => !s.base).map((s) => ({ s, text: applyFixes(s.file, res.diags) })).filter(({ s, text }) => text !== s.text)
    : [];
  for (const d of res.diags) {
    console.log(render(d) + "\n");
  }
  for (const { s, text } of fixed) {
    fs.writeFileSync(s.path, text);
    console.error("bend-lint: fixed " + s.path);
  }
  console.log(res.ok ? "bend-lint: " + res.diags.length + " finding(s)" : "bend-lint: FAIL");
  return res.ok ? 0 : 1;
}

function fail(e: unknown): never {
  console.error("bend-lint: " + (e instanceof Error ? e.message : String(e)));
  process.exit(2);
}

// Side effects
// ============

export const Bend: Bend = await instrument().catch((e: unknown) => import.meta.main ? fail(e) : Promise.reject(e));

if (import.meta.main) {
  process.exit(await cli(process.argv.slice(2)).catch(fail));
}
