# Materialize free parser variables using the existing freshener

Prospective correction after Stage3's first direct gate, pending root review.
`context-body-source-02` passes checked B1/36, prior names46/state27 and raw194.
Its body gate is healthy38/40: both failures are computed-pattern observations
with an outer variable, printed as `x^1`/`x^2` instead of `x`. Parser order,
fresh allocation, lexical stack, cursor and source range agree in both cases.
The frozen failed report is `context-body-probe-01/controls/report.json`.

Pinned `term_higher(t,null)` converts a nonnegative Var absent from its local
HOAS environment to its value fallback, or `Ref(writtenName)` when no fallback
exists. It does not preserve that free Var for the printer. The contextual
compiler already uses its existing freshener and consumes FName's canonical
Ref fallback; that traversal currently leaves an ordinary unmapped Var alone.

Seed that same traversal with explicit maps from each currently open parser
binder ID to `Ref(writtenName)`. Extend `f_rename_var` only so an explicit Ref
mapping returns that Ref with the occurrence's source span. Existing Var maps
retain their exact old renaming behavior. Inner Lam/All/Let binding maps are
prepended by the existing traversal and therefore shadow these outer seeds.
There is no new term traversal, implicit name lookup, ID sign trick, whole-body
scope pass, or printer-only spelling workaround. Normal raw calls still pass
only the existing Var mappings.

Before the correction, freeze direct comparison controls for free occurrences,
FName canonical fallback, lambda-local versus outer variables, same-written-name
inner shadowing, All domain versus codomain, Let value versus bound body, use-site
source spans, dotted outer names, and the old Var-map contract. Compare contextual
materialization against pinned `term_lower(term_higher(t),0)` and old Var-map
controls against the predecessor. The direct artifact may append exports of
compiled helpers but must preserve the production API prefix and have its own
hash. Re-run the unchanged body40, names46, state27 and public/raw194 afterward.

Expected correction is8–12 Bend lines plus independent controls. Review actual
delta and any mapping/inner-scope counterexample before promoting the local
checkpoint experiment to the next body owner.
