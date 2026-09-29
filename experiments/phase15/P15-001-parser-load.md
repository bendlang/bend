# P15-001: parser and import validation order

Prospective plan. The [phase design](../../design/phase15/parser_conformance_and_speed.md)
owns baseline/integration/preservation policy. Hypothesis: the10fixture/20observation
phase differences are caused by missing early binder validation and import syntax
checks occurring after host path resolution. Correct these boundaries without
changing valid imports, accepted types, proof trust or unrelated error selection.

First inspect pinned code and reproduce exact baseline observations. Freeze small
boundary/precedence witnesses before candidate runs. Keep source-only fixes where
possible; any host delta is reviewed explicitly. Genuine checked B1,26focused
cases and exact/phase-scoped controls precede integration. Report every strict
difference; a changed phase alone is not exact conformance. Owner: behavior agent,
isolated behavior-* work, CPU2 after exclusive profiling. Root merges/promotes.
