# P16 lexical binding before alias resolution

Design: design/phase16/alias_lexical_bindings.md.
Baseline witness: current module-names-build-01; candidate source parent is
wave6-source-01/project, combining reviewed renderer/import/declaration work.
Own only alias-binding-* artifacts; CPU3 correctness only, one job at a time.
First freeze a valid `keep(M.double: Nat) -> Nat: M.double` fixture using the
existing mod.bend. Confirm pinned TypeScript accepts and baseline rejects.

Candidate uses one transient alias-reference alternative consumed by existing
f_scope. No extra full lexical walk. Preserve the imported ambiguity error and
numeric origins. Strict direct, applied, nested, sibling, pattern, family and
template controls must compare actual reference/candidate vectors; all failed
attempts remain. Root owns final full-corpus/performance/history/promotion.
