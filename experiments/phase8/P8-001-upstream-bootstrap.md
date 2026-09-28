# P8-001: current upstream builds the compiler with preserved public behavior

Started 2026-09-28. Owner: bootstrap agent; root integrates and measures.
Design: [upstream migration](../../design/phase8/upstream_and_conformance.md).
Baseline `69947fc`, old pin `6018e28`; new pin `b2111cf`.

Hypothesis: the new upstream emitter can build the unchanged Bend compiler with
small bootstrap-API adapters, preserving the host's public data contract while
reducing generated compiler execution cost. Selected exports retain the complete
checked book. Hole rejection remains mandatory.

First falsifiers: changed export eligibility, hidden missing law, host data
mutation, primitive/closure mismatch or a checked source rejection. Freeze and
compare actual generated artifacts before assigning any upstream speed claim.

Correctness: not yet run. Measurement: not run. Decision: investigate.
Evidence: new immutable attempts under `selfhost/build/phase8/`, preserved in the
eventual implementation report. Installed old release remains the control.
