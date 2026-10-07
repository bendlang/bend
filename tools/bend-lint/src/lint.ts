#!/usr/bin/env bun
// bend-lint checks a Bend file with bend's checker, then runs rules over
// its source and the checker's results. Rules are TS modules, or Bend files
// built on ./lint.bend. It loads bend2 through ./patch.ts; anything there
// it cannot follow stops it with a DriftError. As a CLI, it exits 0 when
// ok, 1 when it found an error, 2 on bad usage or a tool failure.

import * as url from "node:url";
import * as util from "node:util";

import type * as BendModule from "bend2/bend.ts";
import type * as CompModule from "bend2/comp.ts";
import type { Ann, Book, Ctx, Err, HTerm, LTerm, Name, Quant, Span, Uses } from "bend2/bend.ts";
import { DriftError, MARK, bendDir, fs, patch, path } from "./patch.ts";
import type { Hooked } from "./patch.ts";

// Types
// =====

export type Bend = typeof BendModule;
export type Severity = "error" | "warning" | "information" | "hint";
// safe keeps behavior; suggested may change it; dangerous may break code.
export type Applicability = "safe" | "suggested" | "dangerous";
export type Edit = { spn: Span; text: string };
export type Fix = { title: string; applicability: Applicability; edits: Edit[] };

export type Diag = {
  code: string;
  severity: Severity;
  message: string;
  spn?: Span;
  def?: Name;
  ctx?: Ctx;
  bok?: Book;
  fixes: Fix[];
  core?: unknown; // bend's own failure, when the check failed
};

export type DiagInit = {
  message: string;
  severity?: Severity;
  spn?: Span;
  fact?: Fact;
  def?: Name;
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

// The checker's facts a rule gets. A fact must match each list given; an
// absent or empty list matches all. In defs, a template's instances
// (generic~0) count as the template.
export type FactFilter = {
  scope?: "file" | "program"; // file (the default): the linted file; program: its imports too, never Base
  kinds?: string[];           // the term's kind, annotations stripped: Var, Ref, App, ...
  defs?: Name[];              // the def whose body holds the term
  names?: Name[];             // the name a Var or Ref points to
};

export type RuleContext = {
  Bend: Bend;
  book: Book;
  sources: Source[];
  root: Source;
  options: Options;         // the rule's defaults, with the config's values
  facts?: Map<LTerm, Fact>; // only for a rule with facts, and only those it asked for
  prior: readonly Diag[];   // what earlier rules found
  span: Mapper; // a bend.ts span, in the file on disk
  walk(tm: LTerm): Generator<LTerm>;
  binder(fact: Fact, v: LTerm): Ann | null;
  show(fact: Fact, ty: HTerm): string;
  same(fact: Fact, a: HTerm, b: HTerm): boolean;
  normal(fact: Fact, ty: HTerm): HTerm;
  uses(fact: Fact): Array<{ name: Name; quantity: Quant }>;
  diag(init: DiagInit): Diag;
};

// A rule option's value. A default's type is its option's type.
export type OptionValue = number | boolean | string;
export type Options = Record<string, OptionValue>;

// bend-lint.json: per rule id, "off", or a severity and option values.
export type Config = { rules?: Record<string, "off" | ({ severity?: Severity } & Options)> };

export type LintOptions = { signal?: AbortSignal; config?: Config };

export type LintRule = {
  id: string; // namespace/name; the code of its findings
  facts?: true | FactFilter; // the checker's facts it needs; true: all of the linted file's
  options?: Options; // defaults; without them (a Bend rule), any option is passed as given
  run(cx: RuleContext, signal: AbortSignal): Diag[] | Promise<Diag[]>;
};

export type LintResult = { ok: boolean; diags: Diag[]; sources: Source[]; book: Book; facts?: Map<LTerm, Fact> };

// An LSP position: 0-based line and character, in UTF-16 units.
export type Position = { line: number; character: number };

// A span as lint.bend has it: a file's path and two code-point offsets.
type Spot = { path: string; beg: number; end: number };

// What a Bend rule reports, as lint.js reads it.
type Reported = {
  severity: Severity;
  message: string;
  span?: Spot;
  fixes: Array<{ title: string; applicability: Applicability; edits: Array<{ span: Spot; text: string }> }>;
};

// What lint.js asks of bend-lint while a Bend rule runs. Facts and types
// cross as indexes into the run's tables.
type Channel = {
  input(): { sources: Array<{ path: string; text: string; root: boolean }>; options: Options };
  next(): number | undefined;
  report(diags: Reported[]): void;
  view(fact: number): { owner: Name; inst: boolean; kind: string; name: string; quantity: Quant["$"]; span?: Spot; inner?: Spot };
  type(fact: number): number;
  binder(fact: number): number | undefined;
  same(fact: number, a: number, b: number): boolean;
  show(fact: number, t: number): string;
  normal(fact: number, t: number): number;
  uses(fact: number): Array<{ name: Name; quantity: Quant["$"] }>;
  text(span: Spot): string;
};

// comp.ts as patch.ts exports it.
type Comp = typeof CompModule & { RUNTIME_MAIN: string; js_sat(k: Name): string };

type Mapper = { (s: Span): Span; (s: Span | undefined): Span | undefined };
type Checked = { book: Book; sources: Source[]; span: Mapper; facts?: Map<LTerm, Fact>; failure?: Diag };

// Constants
// =========

const RULE_ID = /^[^/\s]+\/[^/\s]+$/;
const SCOPES = ["file", "program"];
const CONFIG = "bend-lint.json";
const LINE = /[^\n]*\n|[^\n]+$/g;
const STACK = "the machine stack overflowed (a deep recursion, or a literal too large to expand)";
const SAMPLE = "type N is Data:\n  Z{}\n\ndef id(x: N) -> N:\n  x\n";
const HEAD: Record<Severity, string> = { error: "Error", warning: "Warning", information: "Information", hint: "Hint" };

const shared = globalThis as typeof globalThis & { BEND_LINT?: Channel };

// Checked base.bend books, by the text of base.bend: Base is checked once
// per process, and again only if base.bend changes.
const BASES = new Map<string, Promise<Book>>();

// Line starts per file object (see starts).
const STARTS = new WeakMap<object, number[]>();

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
  "fix-suggested": { type: "boolean" },
  "fix-dangerously": { type: "boolean" },
  json: { type: "boolean" },
  config: { type: "string" },
  bend: { type: "string" },
  help: { type: "boolean", short: "h" },
} as const;

const USAGE = [
  "usage: bun tools/bend-lint/src/lint.ts <file.bend> [--rules <rules.ts|rule.bend>]... [--config <bend-lint.json>] [--fix | --fix-suggested | --fix-dangerously] [--json] [--bend <dir>]",
].join("\n");

// The fix levels each flag applies; the widest flag given wins.
const FIXES: ReadonlyArray<readonly ["fix" | "fix-suggested" | "fix-dangerously", Applicability[]]> = [
  ["fix-dangerously", ["safe", "suggested", "dangerous"]],
  ["fix-suggested", ["safe", "suggested"]],
  ["fix", ["safe"]],
];

// Functions
// =========

// Every sub-term, parents first, with an explicit stack: linear in the
// size of the term, at any depth.
export function* walk(tm: LTerm): Generator<LTerm> {
  const stack = [tm];
  for (let t = stack.pop(); t !== undefined; t = stack.pop()) {
    const children = (CHILDREN as Record<string, ((tm: LTerm) => LTerm[]) | undefined>)[t.$];
    if (children === undefined) {
      throw new DriftError("unknown term kind " + t.$ + "; update CHILDREN in tools/bend-lint/src/lint.ts");
    }
    yield t;
    stack.push(...children(t).reverse());
  }
}

// Where each line of a file starts, computed once per file object.
function starts(file: Span["file"]): number[] {
  const known = STARTS.get(file);
  if (known !== undefined) {
    return known;
  }
  const out = [0, ...[...file.str.matchAll(/\n/g)].map((m) => m.index! + 1)];
  STARTS.set(file, out);
  return out;
}

// The index of the line that holds `off`, given each line's start.
function line(starts: number[], off: number): number {
  let [lo, hi] = [0, starts.length - 1];
  while (lo < hi) {
    const mid = (lo + hi + 1) >> 1;
    [lo, hi] = starts[mid] <= off ? [mid, hi] : [lo, mid - 1];
  }
  return lo;
}

// bend.ts parses a copy of each file with its import lines blanked, so a
// span moves to the file on disk by line and column. The copy's namespace,
// folder and lines pick the file; a copy that matches no file, or two, is
// a DriftError.
export function mapper(sources: Source[]): Mapper {
  const own = new Set<unknown>(sources.map((s) => s.file));
  const memo = new WeakMap<object, { file: SourceFile; from: number[]; to: number[] }>();
  function map(s: Span): Span;
  function map(s: Span | undefined): Span | undefined;
  function map(s: Span | undefined): Span | undefined {
    if (s === undefined || own.has(s.file)) {
      return s;
    }
    const f = s.file as Span["file"] & { dir?: string };
    if (!memo.has(f)) {
      const lines = f.str.split("\n");
      const found = sources.filter((src) => {
        const theirs = src.text.split("\n");
        return f.ns === src.ns
          && (f.dir === undefined || f.dir === src.path.slice(0, src.path.lastIndexOf("/") + 1))
          && lines.length === theirs.length
          && lines.every((l, i) => l === theirs[i] || l.trim() === "" && /^\s*import(\s|$)/.test(theirs[i]));
      });
      if (found.length !== 1) {
        throw new DriftError("cannot map a bend.ts span to a file on disk (" + found.length
          + " candidates); bend.ts may mask imports another way now");
      }
      Object.assign(found[0].file.al, f.al);
      memo.set(f, { file: found[0].file, from: starts(f), to: starts(found[0].file) });
    }
    const { file, from, to } = memo.get(f)!;
    const at = (off: number): number => {
      const i = line(from, off);
      return to[i] + off - from[i];
    };
    return { file, beg: at(s.beg), end: at(s.end) };
  }
  return map;
}

function isErr(e: unknown): e is Err {
  return typeof e === "object" && e !== null && (e as { $?: unknown }).$ === "Err";
}

// Loads and checks a book as bend2/main.ts book_read does; it does not give
// main.ts's verdict on @unsafe and foreign code. A file with a line exactly
// `import Base` starts from a copy of the checked Base, as `bend --checkup`
// does. A fact is kept as the checker gives it only if a filter wants it;
// with scope file, only if it is from the linted file's folder and
// namespace. After the check, only facts whose span maps to the linted file
// (or, with scope program, to any file but Base) stay.
async function check(file: string, filters: FactFilter[], signal: AbortSignal): Promise<Checked> {
  signal.throwIfAborted();
  const book: Hooked = Bend.book_nil();
  const seen = new Map<string, string | null>();
  const found: Array<Omit<Fact, "inst">> = [];
  const real = fs.existsSync(file) ? fs.realpathSync(file) : "";
  const home = real.slice(0, real.lastIndexOf("/") + 1);
  const far = filters.filter((f) => f.scope === "program");
  const program = far.length > 0;
  book.see = filters.length > 0
    ? (bok, tm, ty, ctx, dep, def, spn, qt, us) => {
      const at = spn?.file as { dir?: string; ns?: string } | undefined;
      const near = at?.dir === home && at.ns === "" ? filters : far;
      if (near.some((f) => open(f) || matches(f, shape(tm).kind, def, shape(tm).name))) {
        found.push({ tm, ty, bok, ctx, dep, def, spn, qt, us });
      }
    }
    : undefined;
  const seeded = real !== "" && /^import Base$/m.test(fs.readFileSync(real, "utf8"));
  const key = fs.readFileSync(Bend.BASE_BEND, "utf8");
  if (seeded && !BASES.has(key)) {
    const base = Bend.book_nil();
    BASES.set(key, Bend.book_load(base, Bend.BASE_BEND, "", new Map()).then(() => (Bend.book_valid(base), base)));
  }
  const caught = await Promise.resolve(seeded ? BASES.get(key) : undefined).then(async (base) => {
    if (base !== undefined) {
      Object.assign(book.tlds, Object.fromEntries(Object.entries(base.tlds).map(([k, tld]) => [k, { ...tld }])));
      Object.assign(book.ctrs, base.ctrs);
      Object.assign(book.tmps, Object.fromEntries(Object.entries(base.tmps).map(([k, m]) => [k, new Map(m)])));
      book.order.push(...base.order);
      seen.set(Bend.BASE_BEND, "");
    }
    await Bend.book_load(book, file, "", seen);
    const laws = path.join(path.dirname(file), "LAWS.bend");
    if (path.basename(file) === "PROOF.bend" && fs.existsSync(laws) && !seen.has(fs.realpathSync(laws))) {
      throw "PROOF.bend must import ./LAWS.bend";
    }
    Bend.book_valid(book, base?.order.length ?? 0);
    if (book.hols > 0) {
      throw book.hols + " TODO" + (book.hols === 1 ? "" : "s") + " found.\nThe code is incomplete, and not a valid proof yet.";
    }
  }).then(() => undefined, (e: unknown) => ({ e }));
  signal.throwIfAborted();
  const root = [...seen.keys()].find((real) => real !== Bend.BASE_BEND || !seeded);
  const sources = [...seen.keys()].filter((real) => fs.existsSync(real)).map((real): Source => {
    const text = fs.readFileSync(real, "utf8");
    const ns = seen.get(real) ?? "";
    return { path: real, ns, text, root: real === root, base: real === Bend.BASE_BEND, file: { str: text, ns, al: {}, path: real } };
  });
  const span = mapper(sources);
  if (caught === undefined) {
    const insts = new Set(Object.values(book.tmps).flatMap((m) => [...m.values()]));
    const own = new Set<unknown>(sources.filter((s) => program ? !s.base : s.root).map((s) => s.file));
    const facts = found.flatMap((f): Array<[LTerm, Fact]> => {
      const spn = span(f.spn);
      return spn !== undefined && own.has(spn.file) ? [[f.tm, { ...f, inst: insts.has(f.def), spn }]] : [];
    });
    return { book, sources, span, facts: filters.length > 0 ? new Map(facts) : undefined };
  }
  const err = isErr(caught.e) ? caught.e : undefined;
  const message = err !== undefined ? Bend.expr_show(err.bok, err.exp) : caught.e instanceof RangeError ? STACK : String(caught.e);
  // A file bend did not finish loading may not map; the failure still reports.
  let spn: Span | undefined;
  try {
    spn = span(err?.spn);
  } catch {
    spn = undefined;
  }
  return { book, sources, span, failure: { code: "bend/check", severity: "error", message, spn, def: err?.def, fixes: [], core: caught.e } };
}

// A term's kind, annotations stripped, and the name a Var or Ref points to.
function shape(tm: LTerm): { kind: string; name: Name } {
  const t = Bend.term_strip(tm);
  return { kind: t.$, name: t.$ === "Var" || t.$ === "Ref" ? t.k : "" };
}

// Whether a filter matches every fact in its scope.
function open(f: FactFilter): boolean {
  return [f.kinds, f.defs, f.names].every((xs) => xs === undefined || xs.length === 0);
}

// Whether a fact passes a filter, its scope aside.
function matches(f: FactFilter, kind: string, def: Name, name: Name): boolean {
  const all = (xs: string[] | undefined, x: string): boolean => xs === undefined || xs.length === 0 || xs.includes(x);
  return all(f.kinds, kind) && (all(f.defs, def) || all(f.defs, def.replace(/~\d+$/, ""))) && all(f.names, name);
}

export function readConfig(file: string): Config {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (e) {
    throw new Error(file + ": " + (e instanceof Error ? e.message : String(e)));
  }
}

// The bend-lint.json in the file's folder, or the nearest one above it.
export function findConfig(file: string): Config {
  for (let dir = path.dirname(path.resolve(file)); ; dir = path.dirname(dir)) {
    if (fs.existsSync(path.join(dir, CONFIG))) {
      return readConfig(path.join(dir, CONFIG));
    }
    if (path.dirname(dir) === dir) {
      return {};
    }
  }
}

// What the config says for a rule: off, a severity, and its options (the
// defaults, with the given values, which must be known and of their type).
function settings(rule: LintRule, config: Config): { off: boolean; severity?: Severity; options: Options } {
  const given = config.rules?.[rule.id];
  const where = CONFIG + ": " + rule.id;
  if (given === undefined || given === "off") {
    return { off: given === "off", options: { ...rule.options } };
  }
  if (typeof given !== "object" || given === null) {
    throw new Error(where + " must be \"off\" or an object");
  }
  const { severity, ...options } = given;
  if (severity !== undefined && !Object.hasOwn(HEAD, severity)) {
    throw new Error(where + ": severity must be one of " + Object.keys(HEAD).join(", "));
  }
  for (const [key, value] of Object.entries(options)) {
    const want = rule.options === undefined ? typeof value : typeof rule.options[key];
    if (rule.options !== undefined && !Object.hasOwn(rule.options, key)) {
      throw new Error(where + " has no option " + key);
    }
    if (typeof value !== want || !["number", "boolean", "string"].includes(want)) {
      throw new Error(where + ": " + key + " must be a " + (rule.options === undefined ? "number, boolean or string" : want));
    }
  }
  return { off: false, severity, options: { ...rule.options, ...options } };
}

// Rules run in order; the config may turn one off, set its severity, and
// give its options. A finding with severity error stops the run. A rule
// that throws, and an abort, reach the caller.
export async function lint(file: string, rules: LintRule[],
  { signal = new AbortController().signal, config = findConfig(file) }: LintOptions = {}): Promise<LintResult> {
  const names = (xs: unknown): boolean => xs === undefined || Array.isArray(xs) && xs.every((x) => typeof x === "string");
  const bad = rules.findIndex((r) => !RULE_ID.test(String(r?.id)) || typeof r?.run !== "function"
    || !(r.facts === undefined || r.facts === true || typeof r.facts === "object" && r.facts !== null
      && (r.facts.scope === undefined || SCOPES.includes(r.facts.scope)) && names(r.facts.kinds) && names(r.facts.defs) && names(r.facts.names)));
  if (bad >= 0) {
    throw new TypeError("invalid rule at " + bad + " (" + JSON.stringify(rules[bad]?.id)
      + "): it needs an id like ns/name, a run function, and facts, if given, true or a FactFilter");
  }
  const plans = rules.map((rule) => ({ rule, ...settings(rule, config), want: rule.facts === true ? {} : rule.facts }))
    .filter((p) => !p.off);
  const { book, sources, span, facts, failure } = await check(file, plans.flatMap((p) => p.want === undefined ? [] : [p.want]), signal);
  if (failure !== undefined) {
    return { ok: false, diags: [failure], sources, book };
  }
  const root = sources.find((s) => s.root)!;
  let diags: Diag[] = [];
  for (const { rule, severity, options, want } of plans) {
    signal.throwIfAborted();
    const out = await rule.run({
      Bend, book, sources, root, span, walk, options,
      // A filter that matches all, with the scope every kept fact has, gets the map as is.
      facts: want === undefined || facts === undefined ? undefined
        : open(want) && (want.scope === "program" || !plans.some((p) => p.want?.scope === "program")) ? facts
          : new Map([...facts].filter(([tm, f]) => (want.scope === "program" || f.spn?.file === root.file)
            && matches(want, shape(tm).kind, f.def, shape(tm).name))),
      prior: diags,
      binder: (fact, v) => v.$ === "Var" ? Bend.pmap_get(fact.ctx, v.i) : null,
      show: (fact, ty) => Bend.term_show(Bend.term_lower(ty, fact.dep)),
      same: (fact, a, b) => Bend.term_compare("EQ", fact.bok, a, b, fact.dep),
      normal: (fact, ty) => Bend.term_snf(fact.bok, ty),
      uses: (fact) => Bend.pmap_to_array(fact.us).flatMap(([v, quantity]) =>
        quantity.$ === "None" ? [] : [{ name: Bend.pmap_get(fact.ctx, v)?.k ?? "", quantity }]),
      diag: (d) => ({
        code: rule.id, severity: d.severity ?? "warning", message: d.message, spn: d.spn,
        def: d.def ?? d.fact?.def, ctx: d.fact?.ctx, bok: d.fact?.bok ?? book, fixes: d.fixes ?? [],
      }),
    }, signal);
    signal.throwIfAborted();
    if (!Array.isArray(out)) {
      throw new TypeError("rule " + rule.id + " must return an array of diagnostics");
    }
    const settled = out.map((d): Diag => ({
      ...d, code: rule.id, severity: severity ?? d.severity, spn: span(d.spn),
      fixes: d.fixes.map((f) => ({ ...f, edits: f.edits.map((e) => ({ ...e, spn: span(e.spn) })) })),
    }));
    const broken = settled.flatMap((d) => d.fixes).find((f) => f.edits.some(({ spn }, i) =>
      spn.beg < 0 || spn.beg > spn.end || spn.end > spn.file.str.length || f.edits.some((o, j) => j !== i && clash(f.edits[i], o))));
    if (broken !== undefined) {
      throw new TypeError("rule " + rule.id + ": fix \"" + broken.title + "\" has an edit out of bounds, or two that clash");
    }
    const stop = settled.findIndex((d) => d.severity === "error");
    diags = [...diags, ...(stop < 0 ? settled : settled.slice(0, stop + 1))];
    if (stop >= 0) {
      return { ok: false, diags, sources, book, facts };
    }
  }
  return { ok: true, diags, sources, book, facts };
}

// Whether two edits to one file cannot both apply: their ranges overlap,
// or they insert at the same point.
function clash(a: Edit, b: Edit): boolean {
  return a.spn.file === b.spn.file && (a.spn.beg < b.spn.end && b.spn.beg < a.spn.end
    || a.spn.beg === b.spn.beg && a.spn.end === b.spn.end);
}

// `text` with edits applied; their spans are offsets into `text`, and they
// do not clash.
function apply(text: string, edits: Edit[]): string {
  return [...edits].sort((a, b) => b.spn.beg - a.spn.beg || b.spn.end - a.spn.end)
    .reduce((s, { spn, text: t }) => s.slice(0, spn.beg) + t + s.slice(spn.end), text);
}

// The text of `file` with the fixes of the given levels applied, in order.
// An edit equal to one already taken is merged; a fix with an edit that
// clashes with one already taken is skipped and counted.
export function applyFixes(file: SourceFile, diags: Diag[], levels: Applicability[] = ["safe"]): { text: string; skipped: number } {
  const kept: Edit[] = [];
  let skipped = 0;
  for (const fix of diags.flatMap((d) => d.fixes).filter((f) => levels.includes(f.applicability))) {
    const fresh = fix.edits.filter((e) => e.spn.file === file
      && !kept.some((k) => k.spn.beg === e.spn.beg && k.spn.end === e.spn.end && k.text === e.text));
    if (fresh.some((e) => kept.some((k) => clash(k, e)))) {
      skipped += 1;
    } else {
      kept.push(...fresh);
    }
  }
  return { text: apply(file.str, kept), skipped };
}

// bend's own error layout; the head names the severity and the code, and
// each fix follows as a unified diff of the lines it touches.
export function render(d: Diag): string {
  const err = isErr(d.core) ? d.core : Bend.Err(d.bok ?? Bend.book_nil(), d.ctx ?? Bend.ctx_nil(), d.message, undefined, d.spn, d.def);
  const fixes = d.fixes.map((fix) => "\n\nFix: " + fix.title + " [" + fix.applicability + "]"
    + [...new Set(fix.edits.map((e) => e.spn.file))].map((file) => {
      const mine = fix.edits.filter((e) => e.spn.file === file);
      const ls = starts(file);
      const first = line(ls, Math.min(...mine.map((e) => e.spn.beg)));
      const from = ls[first];
      const to = ls[line(ls, Math.max(...mine.map((e) => e.spn.end))) + 1] ?? file.str.length;
      const old = file.str.slice(from, to);
      const gone = old.match(LINE) ?? [];
      const came = apply(old, mine.map((e) => ({ ...e, spn: { ...e.spn, beg: e.spn.beg - from, end: e.spn.end - from } }))).match(LINE) ?? [];
      const name = (file as SourceFile).path;
      const range = (n: number): string => (n === 0 ? first : first + 1) + "," + n;
      const show = (xs: string[], sign: string): string[] => xs.map((l) =>
        sign + l.replace(/\r?\n$/, "") + (l.endsWith("\n") ? "" : "\n\\ No newline at end of file"));
      return "\n--- " + name + "\n+++ " + name + "\n@@ -" + range(gone.length) + " +" + range(came.length) + " @@\n"
        + [...show(gone, "-"), ...show(came, "+")].join("\n");
    }).join(""));
  return Bend.err_show(err).replace(/^Error:/, HEAD[d.severity] + " [" + d.code + "]:") + fixes.join("");
}

// The LSP range of a span in a file on disk.
export function position(spn: Span): { start: Position; end: Position } {
  const ss = starts(spn.file);
  const at = (off: number): Position => {
    const i = line(ss, off);
    return { line: i, character: off - ss[i] };
  };
  return { start: at(spn.beg), end: at(spn.end) };
}

// A rule written in Bend: a file built on ./lint.bend (see there). It is
// checked and compiled once, as comp.ts io_run does; each run calls its
// main with bend's own IO runtime, while lint.js reaches bend-lint through
// globalThis.BEND_LINT. Offsets cross as code points.
export async function bendRule(file: string): Promise<LintRule> {
  const { book, failure } = await check(file, [], new AbortController().signal);
  if (failure !== undefined) {
    throw new Error(file + " does not check:\n" + render(failure));
  }
  const value = (k: Name): LTerm | undefined => {
    const tld = book.tlds[k];
    return tld?.$ === "Def" && tld.n === 0 && tld.v !== null ? Bend.term_lower(Bend.term_snf(book, tld.v)) : undefined;
  };
  const shown = value("id");
  const id = shown === undefined ? undefined : Bend.term_show(shown).match(/^"([^"\\]*)"$/)?.[1];
  // facts(), checked: NoFacts{} gives null, Want{...} a filter; else undefined.
  const args = (t: LTerm | undefined, ctr: string): LTerm[] | undefined =>
    t?.$ === "Ctr" && (t.k === ctr || t.k.endsWith(":" + ctr)) ? t.x : undefined;
  const texts = (t: LTerm | undefined): string[] | undefined => {
    const out: string[] = [];
    for (let at = t; ; at = args(at, "Con")?.[1]) {
      const [head] = args(at, "Con") ?? [];
      if (args(at, "Nil") !== undefined) {
        return out;
      }
      if (head?.$ !== "Lit" || typeof head.v !== "string") {
        return undefined;
      }
      out.push(head.v);
    }
  };
  const asked = value("facts");
  const [scope, kinds, defs, names] = args(asked, "Want") ?? [];
  const want = args(asked, "NoFacts") !== undefined ? null : {
    scope: args(scope, "File") !== undefined ? "file" as const : args(scope, "Program") !== undefined ? "program" as const : undefined,
    kinds: texts(kinds), defs: texts(defs), names: texts(names),
  };
  if (id === undefined || Comp.io_type(book) === null
    || want !== null && [want.scope, want.kinds, want.defs, want.names].includes(undefined)) {
    throw new Error(file + " must define id() -> String, facts() -> Lint.Want and main() -> IO(Unit)");
  }
  const main = new Function("require", Comp.js_lib(book) + "\n" + Comp.RUNTIME_MAIN
    + "\nreturn (args) => { cli_args = args; return io_run(" + Comp.js_sat("main") + "); };")(import.meta.require) as (args: string[]) => number;
  return {
    id,
    ...(want === null ? {} : { facts: want as FactFilter }),
    run: (cx) => {
      // Built once per text: the character at each UTF-16 offset (points),
      // and the UTF-16 offset of each character (units); both end at the end.
      const tables = new Map<string, { points: number[]; units: number[] }>();
      const table = (text: string): { points: number[]; units: number[] } => {
        const known = tables.get(text);
        if (known !== undefined) {
          return known;
        }
        const points: number[] = [];
        const units: number[] = [];
        for (const ch of text) {
          units.push(points.length);
          points.push(...Array<number>(ch.length).fill(units.length - 1));
        }
        units.push(points.length);
        points.push(units.length - 1);
        tables.set(text, { points, units });
        return { points, units };
      };
      const spot = (spn: Span | undefined): Spot | undefined => {
        const t = spn && table(spn.file.str);
        return spn && t && { path: (spn.file as SourceFile).path, beg: t.points[spn.beg], end: t.points[spn.end] };
      };
      const span = (s: Spot): Span => {
        const src = cx.sources.find((x) => x.path === s.path);
        if (src === undefined) {
          throw new Error("rule " + id + " reported a span in " + s.path + ", which is not in the book");
        }
        const { units } = table(src.text);
        const at = (n: number): number => units[Math.min(n, units.length - 1)];
        return { file: src.file, beg: at(s.beg), end: at(s.end) };
      };
      const facts = [...cx.facts?.values() ?? []];
      let given = 0; // facts handed to the rule so far
      const terms: HTerm[] = [];
      const pick = <T>(xs: T[], i: number, what: string): T => {
        if (xs[i] === undefined) {
          throw new Error("rule " + id + " asked about " + what + " " + i + ", which it was not given");
        }
        return xs[i];
      };
      const keep = (t: HTerm): number => terms.push(t) - 1;
      const found: Reported[][] = [];
      shared.BEND_LINT = {
        input: () => {
          const odd = Object.entries(cx.options).find(([, v]) => typeof v === "number" && !(Number.isInteger(v) && v >= 0 && v <= 0xffffffff));
          if (odd !== undefined) {
            throw new Error("rule " + id + ": option " + odd[0] + " must be a whole number from 0 to 4294967295 (a U32)");
          }
          return { sources: cx.sources.map((s) => ({ path: s.path, text: s.text, root: s.root })), options: cx.options };
        },
        next: () => given < facts.length ? given++ : undefined,
        report: (diags) => void found.push(diags),
        view: (i) => {
          const f = pick(facts, i, "fact");
          const t = Bend.term_strip(f.tm);
          return { owner: f.def, inst: f.inst, ...shape(f.tm), quantity: f.qt.$, span: spot(f.spn), inner: spot(cx.span(t.s)) };
        },
        type: (i) => keep(pick(facts, i, "fact").ty),
        binder: (i) => {
          const f = pick(facts, i, "fact");
          const ann = cx.binder(f, Bend.term_strip(f.tm));
          return ann === null ? undefined : keep(ann.T);
        },
        same: (i, a, b) => cx.same(pick(facts, i, "fact"), pick(terms, a, "term"), pick(terms, b, "term")),
        show: (i, t) => cx.show(pick(facts, i, "fact"), pick(terms, t, "term")),
        normal: (i, t) => keep(cx.normal(pick(facts, i, "fact"), pick(terms, t, "term"))),
        uses: (i) => cx.uses(pick(facts, i, "fact")).map((u) => ({ name: u.name, quantity: u.quantity.$ })),
        text: (s) => {
          const spn = span(s);
          return spn.file.str.slice(spn.beg, spn.end);
        },
      };
      let code: number;
      try {
        code = main([file]);
      } finally {
        shared.BEND_LINT = undefined;
      }
      if (code !== 0 || found.length !== 1) {
        throw new Error("rule " + id + " exited with " + code + " after " + found.length + " reports; it must report once");
      }
      return found[0].map((d) => cx.diag({
        message: d.message, severity: d.severity, spn: d.span && span(d.span),
        fixes: d.fixes.map((f) => ({ ...f, edits: f.edits.map((e) => ({ spn: span(e.span), text: e.text })) })),
      }));
    },
  };
}

// Finds bend2 (see bendDir), patches bend.ts and comp.ts as Bun loads
// them, then checks what the wrappers record for `x` in a tiny program.
async function instrument(given: string | undefined): Promise<{ Bend: Bend; Comp: Comp; BEND2: string }> {
  const dir = bendDir(given);
  // Bun.plugin is process-wide: match this checkout's two files by full path.
  const patched = new Map(["bend.ts", "comp.ts"].map((f) => [path.join(dir, f), patch(f, fs.readFileSync(path.join(dir, f), "utf8"))]));
  const exact = dir.replace(/[.*+?^${}()|[\]\\]/g, "\\$&").replaceAll("/", "[\\\\/]");
  const filter = new RegExp("^" + exact + "[\\\\/](bend|comp)\\.ts$", process.platform === "win32" ? "i" : "");
  Bun.plugin({
    name: "bend-lint",
    setup: (build) => {
      build.onLoad({ filter }, (args) => {
        const contents = patched.get(fs.realpathSync(args.path));
        if (contents === undefined) {
          throw new DriftError("bend-lint matched " + args.path + " but did not patch it");
        }
        return { contents, loader: "ts" };
      });
    },
  });
  const [B, C]: [Bend & { [MARK]?: number }, Comp & { [MARK]?: number }] = await Promise.all([
    import(url.pathToFileURL(path.join(dir, "bend.ts")).href),
    import(url.pathToFileURL(path.join(dir, "comp.ts")).href),
  ]);
  if (B[MARK] !== 1 || C[MARK] !== 1) {
    throw new DriftError("bend2 was loaded before bend-lint could patch it; import bend-lint first");
  }
  const sample: Hooked = B.book_nil();
  const seen: Fact[] = [];
  sample.see = (bok, tm, ty, ctx, dep, def, spn, qt, us) => void seen.push({ tm, ty, bok, ctx, dep, def, spn, qt, us, inst: false });
  B.parse_book(sample, "/", SAMPLE, "", {});
  B.book_valid(sample);
  const xs = seen.filter((f) => f.def === "id" && B.term_strip(f.tm).$ === "Var");
  const kind = (f: Fact, t: HTerm) => (B.term_wnf(f.bok, t) as { k?: string }).k;
  const tagged = (x: unknown, tags: string[]) => tags.includes((x as { $?: string } | null)?.$ ?? "");
  const wrong = xs.length < 2 ? ["facts (one from each wrapper)"] : xs.flatMap((x) => {
    if (typeof x.dep !== "number" || !tagged(x.ctx, ["Emp", "Bin"]) || !tagged(x.us, ["Emp", "Bin"]) || !tagged(x.qt, ["None", "Lone", "Many"])) {
      return ["kinds of values"];
    }
    const v = B.term_strip(x.tm) as Extract<LTerm, { $: "Var" }>;
    const bound = B.pmap_get(x.ctx, v.i);
    return ([
      ["type", kind(x, x.ty) === "N"],
      ["depth", x.dep === 1],
      ["scope", bound?.k === "x" && kind(x, bound.T) === "N"],
      ["quantity", x.qt.$ === "Lone"],
      ["uses", B.pmap_get(x.us, v.i)?.$ === "Lone"],
      ["span", x.spn !== undefined && x.spn.file.str.slice(x.spn.beg, x.spn.end) === "x"],
    ] as const).flatMap(([what, ok]) => ok ? [] : [what]);
  });
  if (wrong.length > 0) {
    throw new DriftError("self-check failed: the patched bend.ts recorded the wrong " + [...new Set(wrong)].join(", ")
      + " for `x` in `def id(x: N) -> N: x`; update tools/bend-lint/src/patch.ts");
  }
  return { Bend: B, Comp: C, BEND2: dir };
}

async function cli(argv: string[]): Promise<number> {
  const { values, positionals } = util.parseArgs({ args: argv, options: OPTIONS, allowPositionals: true });
  if (values.help) {
    console.log(USAGE);
    return 0;
  }
  if (positionals.length !== 1) {
    throw new Error("give one .bend file\n" + USAGE);
  }
  const modules = await Promise.all((values.rules ?? []).map(async (file): Promise<LintRule[]> => {
    if (file.endsWith(".bend")) {
      return [await bendRule(file)];
    }
    const { rules } = await import(url.pathToFileURL(path.resolve(file)).href);
    if (!Array.isArray(rules)) {
      throw new Error(file + " must export `rules`, an array of rules");
    }
    return rules;
  }));
  const res = await lint(positionals[0], modules.flat(), { config: values.config === undefined ? undefined : readConfig(values.config) });
  const root = res.sources.find((s) => s.root);
  const levels = FIXES.find(([flag]) => values[flag])?.[1];
  const fixed = levels !== undefined && res.ok && root !== undefined ? applyFixes(root.file, res.diags, levels) : undefined;
  const where = (spn: Span) => ({ path: (spn.file as SourceFile).path, range: position(spn) });
  console.log(values.json
    ? JSON.stringify({
      ok: res.ok,
      findings: res.diags.map((d) => ({
        code: d.code, severity: d.severity, message: d.message, def: d.def, ...(d.spn && where(d.spn)),
        fixes: d.fixes.map((f) => ({ ...f, edits: f.edits.map((e) => ({ ...where(e.spn), text: e.text })) })),
      })),
    }, null, 2)
    : [...res.diags.map(render), res.ok ? "bend-lint: " + res.diags.length + " finding(s)" : "bend-lint: FAIL"].join("\n\n"));
  if (root !== undefined && fixed !== undefined && fixed.text !== root.text) {
    fs.writeFileSync(root.path, fixed.text);
    console.error("bend-lint: fixed " + root.path);
  }
  if (fixed !== undefined && fixed.skipped > 0) {
    console.error("bend-lint: skipped " + fixed.skipped + " fix(es) that clash with earlier ones; run the fix again to apply them");
  }
  return res.ok ? 0 : 1;
}

function fail(e: unknown): never {
  console.error("bend-lint: " + (e instanceof Error ? e.message : String(e)));
  process.exit(2);
}

// Side effects
// ============

// The CLI's --bend is read here, before bend loads; a library uses $BEND_DIR.
const given = import.meta.main ? util.parseArgs({ args: process.argv.slice(2), options: OPTIONS, allowPositionals: true, strict: false }).values.bend : undefined;

export const { Bend, Comp, BEND2 }: { Bend: Bend; Comp: Comp; BEND2: string } =
  await instrument(typeof given === "string" ? given : undefined).catch((e: unknown) => import.meta.main ? fail(e) : Promise.reject(e));

if (import.meta.main) {
  process.exit(await cli(process.argv.slice(2)).catch(fail));
}
