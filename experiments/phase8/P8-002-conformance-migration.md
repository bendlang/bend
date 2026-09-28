# P8-002: migrate language rules and improve conformance without duplicate paths

Started 2026-09-28. Owners: root checker/loader, frontend agent assigned modules.
Design: [upstream migration](../../design/phase8/upstream_and_conformance.md).

Hypothesis: current upstream semantics and selected retained Phase6 repairs can
be implemented while keeping Phase7's authoritative failures and shared graph
operations. New target fixture results must be measured, not inherited from old
artifact reports. Upfront declarations do not permit arbitrary safe recursion.

Falsifiers: positive acceptance regressions, changed first-error selection,
unsafe/safe visibility confusion, stale namespace or prefix cache acceptance.
Separate phase/classification, selected rule and exact presentation results.

Correctness: the installed checked release retains the best S4 simplifications
and fixes the seven invalid acceptances found in the new corpus. Focused gates
cover 192 parse/check observations, 18 exact semantic executions, 35 import/JS
executions, 44 final foreign-runtime executions and 13 native/scanner controls;
sets overlap. All 19 maintained component groups ran; the source-diagnostic group
retains six real caret differences, while the other 18 groups pass.

Decision: promote bounded semantic/runtime improvements, retaining literal,
imported-law and diagnostic gaps explicitly. No full conformance or source-line
reduction milestone is claimed. Final full-corpus metrics and current checking
cost are recorded in the [implementation report](../../implementation/phase8/upstream_and_conformance.md).
All failed candidates, runtime regressions and setup-invalid attempts remain in
the [evidence index](../../implementation/phase8/migration-evidence/README.md).
