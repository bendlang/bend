// Runs rules over a checked book. Rules run one at a time, in order. A
// finding with severity error stops the run; a rule that throws is a bug
// in the rule, so the error goes to the caller.

import { Bend } from "./core.ts";
import { selfCheck } from "./instrument.ts";
import { coreDiag, loadBook, type Loaded } from "./load.ts";
import { walk } from "./walk.ts";
import type { Diag, LintResult, LintRule, RuleContext, Source } from "./types.ts";

export function validRule(rule: unknown): rule is LintRule {
  if (rule === null || typeof rule !== "object") return false;
  const r = rule as LintRule;
  return typeof r.id === "string" && /^[^/\s]+\/[^/\s]+$/.test(r.id)
    && typeof r.run === "function"
    && (r.needsTypes === undefined || typeof r.needsTypes === "boolean");
}

export async function lint(file: string, rules: LintRule[], opts: { signal?: AbortSignal } = {}): Promise<LintResult> {
  const signal = opts.signal ?? new AbortController().signal;
  for (const rule of rules) {
    if (!validRule(rule)) {
      throw new TypeError("bend-lint: invalid rule (needs an id like ns/name and a run function)");
    }
  }
  const capture = rules.some((r) => r.needsTypes === true);
  if (capture) {
    selfCheck(Bend);
  }
  const ld = await loadBook(file, capture, signal);
  const done = (ok: boolean, diags: Diag[]): LintResult =>
    ({ ok, diags, sources: ld.sources, book: ld.book, facts: ld.facts });
  if (ld.failed) {
    return done(false, [coreDiag(ld.failure, ld.spans)]);
  }
  const root = ld.sources.find((s) => s.root)!;
  const diags: Diag[] = [];
  for (const rule of rules) {
    signal.throwIfAborted();
    const out = await rule.run(context(rule, ld, root, diags), signal);
    signal.throwIfAborted();
    if (!Array.isArray(out)) {
      throw new TypeError("bend-lint: rule " + rule.id + " must return an array of diagnostics");
    }
    for (const d of out) {
      const diag = settle(d, rule.id, ld);
      diags.push(diag);
      if (diag.severity === "error") {
        return done(false, diags);
      }
    }
  }
  return done(true, diags);
}

// The code is the rule's id; every span is in the file on disk.
function settle(d: Diag, id: string, ld: Loaded): Diag {
  return {
    ...d,
    code: id,
    severity: d.severity ?? "warning",
    spn: ld.spans.map(d.spn),
    fixes: (d.fixes ?? []).map((f) => ({
      ...f,
      edits: f.edits.map((e) => ({ ...e, spn: ld.spans.map(e.spn)! })),
    })),
  };
}

function context(rule: LintRule, ld: Loaded, root: Source, prior: Diag[]): RuleContext {
  return {
    Bend,
    book: ld.book,
    sources: ld.sources,
    root,
    facts: rule.needsTypes === true ? ld.facts : undefined,
    prior,
    span: (s) => ld.spans.map(s),
    walk,
    binder: (fact, v) => v.$ === "Var" ? Bend.pmap_get(fact.ctx, v.i) : null,
    show: (fact, ty) => Bend.term_show(Bend.term_lower(ty, fact.dep)),
    same: (fact, a, b) => Bend.term_compare("EQ", fact.bok, a, b, fact.dep),
    diag: (init) => ({
      code: rule.id,
      severity: init.severity ?? "warning",
      message: init.message,
      spn: init.spn,
      def: init.def ?? init.fact?.def,
      ctx: init.fact?.ctx,
      bok: init.fact?.bok ?? ld.book,
      obs: init.obs,
      note: init.note,
      fixes: init.fixes ?? [],
    }),
  };
}
