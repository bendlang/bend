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

Correctness: not yet run. Measurement: not run. Decision: investigate.
Preserve each candidate and its failures before combined validation/promotion.
