// The types rules see.

import type { Ann, Book, Ctx, HTerm, LTerm, Name, Span } from "../../../bend2/bend.ts";
import type { Bend } from "./instrument.ts";

export type { Ann, Book, Ctx, HTerm, LTerm, Name, Span };

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
export type Source = { path: string; ns?: string; text: string; root: boolean; base: boolean; file: SourceFile };

// One result of the checker: `tm` checked (or inferred) against `ty` at
// depth `dep`, in `ctx`, inside def `def`. `bok` is the book it was
// checked in (a template body has its own). `spn` is in the file on disk;
// `raw` is the span bend.ts gave.
export type Fact = {
  tm: LTerm;
  ty: HTerm;
  bok: Book;
  ctx: Ctx;
  dep: number;
  def: Name;
  raw?: Span;
  readonly spn?: Span;
};

export type RuleContext = {
  Bend: Bend;
  book: Book;
  sources: Source[];
  root: Source;
  facts?: Map<LTerm, Fact>; // only for a rule with needsTypes
  prior: readonly Diag[];   // what earlier rules found
  span(s: Span | undefined): Span | undefined; // a bend.ts span, mapped to the file on disk
  walk(tm: LTerm): Generator<LTerm>;
  binder(fact: Fact, v: LTerm): Ann | null;
  show(fact: Fact, ty: HTerm): string;
  same(fact: Fact, a: HTerm, b: HTerm): boolean;
  diag(init: DiagInit): Diag;
};

export type LintRule = {
  id: string; // namespace/name
  needsTypes?: boolean;
  run(cx: RuleContext, signal: AbortSignal): Diag[] | Promise<Diag[]>;
};

export type LintResult = {
  ok: boolean;
  diags: Diag[];
  sources: Source[];
  book: Book;
  facts?: Map<LTerm, Fact>;
};
