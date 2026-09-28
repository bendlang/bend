# P14-001: imported-law semantics

Status: prospective, before reproduction or implementation.
Owner: imported-law workstream; root integrates. Scope and gates follow the
[Phase14 design](../../design/phase14/conformance_and_dispatch.md).

Hypothesis: the four imported-law trust fixtures share a frontend/import handling
mismatch that can be corrected without weakening trust or declaration chronology.
Read the exact import graphs and both implementations; reproduce baseline and
pinned TypeScript before editing. The first divergence, not the existing high-level
classification, determines the patch. Preserve every failed attempt.

Success requires all four cases to reach the intended proof-trust refusal,
maintained positive/negative acceptance, and explicit duplicate/fill/import-order
boundary controls. Do not equate type acceptance with independent proof validity.
Use isolated checked B1 snapshots and exact ordinary results. Broad integration
is conditional on scoped evidence. Report in
[imported-laws.md](../../implementation/phase14/imported-laws.md).
