# Phase21 R1 independent baseline

All 68 parse/check observations completed against pinned TypeScript and the installed Phase20 API40c8f7f3 on CPU2, with a 4GiB heap and 4MiB stack. The unchanged maintained paired harness retains complete diagnostics and actual checker/parse outcomes. No compiler source was edited.

The original 30-fixture cohort is frozen: 44/60 exact, 16 strict differences, no primitive differences. Six prospective acceptance assumptions disagree with the pin and remain failed in the raw reports: computed constructor RHS (four observations), typed callee (one), ungrouped callee (one). No fixture or oracle was corrected.

A separate two-fixture constructor-parameter cohort exposed four existing acceptance differences: pinned TypeScript rejects the grouped destructuring, while the parent accepts parse and check. It remains a regression boundary, not a positive conformance claim.

The original astral fixture used `//`, which is an earlier syntax error in Bend. A third frozen cohort uses a real `#` comment and a prior astral string, with four valid pinned pattern refusals and four parent range differences. This cohort was frozen after the root candidate build but before consuming it; the earlier cohorts preceded candidate preparation.

Candidate comparison must replay every original selection unchanged, retain every raw failure, keep the full pinned observation protocol identical, preserve all parent exact matches and preserve all candidate primitive axes. Diagnostic-only improvements may become newly exact. Root-owned structural controls check raw/lowered span identity; these controls exercise real loader/parser/checker behavior.

The machine-readable `group-range-controls-baseline.json` binds every fixture, selection, plan, tool and complete parent/reference report.
