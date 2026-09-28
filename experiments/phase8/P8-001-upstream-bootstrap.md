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

Correctness: closed with 33 actual bootstrap/ABI controls and authentic checked B1
builds. Public BigInt and named-field contracts remain; the internal emitter's
Nat representation did not justify a new host conversion layer. New Base required
semantic migration, documented separately in P8-002. The whole book is checked
before selected emission; holes and invalid exports are rejected.

Measurement: the unchanged-source CPU0 ABBA/BAAB comparison records1.52× faster
old-Base parsing and 1.45× faster checking of 60 tiny declarations, using the
upper-middle of four samples. This is neither a full-source nor a TypeScript
comparison. Failed fixture/setup attempts are retained.

Decision: promote the new pinned bootstrap route and genuine checked B1 release;
keep historical equality-derived provenance for the old artifact. See the
[implementation report](../../implementation/phase8/upstream_and_conformance.md)
and [evidence index](../../implementation/phase8/migration-evidence/README.md).
