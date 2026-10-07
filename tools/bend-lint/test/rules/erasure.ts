// Finds local annotations the checker does not need: `x : T = v` where v
// is a variable that already has type T. Constructors and lambdas keep
// theirs, since checking needs the expected type.

import type { Diag, Edit, Fact, LintRule, RuleContext, Span } from "../../src/index.ts";

export const redundantAnnotation: LintRule = {
  id: "erasure/redundant-local-annotation",
  needsTypes: true,
  run(cx, signal) {
    const found = new Map<string, Diag>();
    for (const fact of cx.facts!.values()) {
      signal.throwIfAborted();
      const d = redundant(cx, fact);
      if (d === undefined) continue;
      const key = cx.sources.findIndex((s) => s.file === d.spn!.file) + ":" + d.spn!.beg + ":" + d.spn!.end;
      if (!found.has(key)) found.set(key, d);
    }
    return [...found.values()];
  },
};

function redundant(cx: RuleContext, fact: Fact): Diag | undefined {
  const term = cx.Bend.term_strip(fact.tm);
  const binding = fact.spn;
  const value = cx.span(term.s);
  if (term.$ !== "Var" || binding === undefined || value === undefined) return;
  const v = cx.binder(fact, term);
  if (v === null || !cx.same(fact, v.T, fact.ty)) return;
  const edit = annotationEdit(binding, value);
  if (edit === undefined) return;
  return cx.diag({
    message: "Remove the redundant annotation: " + v.k + " already has type " + cx.show(fact, v.T) + ".",
    severity: "hint",
    spn: edit.spn,
    fact,
    fixes: [{ title: "Remove redundant local type annotation", applicability: "suggested", edits: [edit] }],
  });
}

function annotationEdit(binding: Span, value: Span): Edit | undefined {
  if (binding.file !== value.file || binding.beg >= value.beg) return;
  const prefix = binding.file.str.slice(binding.beg, value.beg);
  if (prefix.includes("#")) return;
  const name = prefix.match(/^([A-Za-z_][A-Za-z_0-9]*)\s*:/);
  if (name === null || !prefix.trimEnd().endsWith("=")) return;
  const beg = binding.beg + name[1].length;
  const end = binding.beg + prefix.lastIndexOf("=");
  return { spn: { file: binding.file, beg, end }, text: " " };
}

export default [redundantAnnotation];
