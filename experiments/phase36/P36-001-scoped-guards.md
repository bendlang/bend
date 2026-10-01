# P36-001 — reuse a complete proof inside one closed private tree

Status: **accepted in installed checked03**. Final unchanged-ray gain is 2.319×
versus Phase35; all focused, broad integration and release gates pass. See the
[release](../../implementation/phase36/release-03.md). The 2.358× saved-output
result below remains separate historical mechanism evidence.

Hypothesis: repeated guards in Phase35 ray tracing can reuse a covering proof
within a synchronous scalar-input private region, retaining every public guard
and all exact-entry, mutation, reentry and delayed-demand behavior. The final
Phase35 profile assigns 47.24% CPU ancestry to those guards.

[Design](../../design/phase36/guard-scoped-proof.md).
[Owner report](../../implementation/phase36/guard-report.md).

Initial artifact: `selfhost/tools/performance/phase36/guard-derive.mjs` creates
saved-output variants from the exact Phase35 checked09 ray module. Root alone
runs resource-bounded controls and timing. No source compiler promotion follows
from this experiment alone. Stop on any semantic event mismatch or missing
admission witness; preserve every failed attempt.

The first scope control correctly rejected an inactive nearest.t hook witness.
V2 reaches a center pixel and passes 57 colf oracle rows, 200 existing boundaries
and 10 scope observations. Five balanced clean rounds measure 1868.350→792.226ms
on original ray tracing; pinned TS remains 34.212ms. See the linked owner report
and `guard-mechanism-summary.json` for exact frozen reports/hashes.

Independent review rejected two incomplete proof admissions before promotion:
mutable Error construction during native Nat constructor overflow, and direct
array callbacks coexisting with an independently pure residual. Production v3
suspends proof during Error construction and requires complete original-root
JPure. Real checked-source error/reentry and mixed-array refusal controls are
mandatory. Saved-output speed does not establish those production conditions.

Actual checked03 API 93e55ad7… passes colf 57/200, scope 10, Succ/Error 16/4 and mixed
array-refusal 16/4. The refusal witness keeps its existing private tree but does
not grant proof; native callbacks and mutation/reentry observations agree with
baseline. See [actual receipt hashes](../../implementation/phase36/guard-actual-summary.json).
Original array fixture parser failure is retained beside its named-parameter
successor. The later P36-004 reflection micro-optimization is rejected for a null
speed result and adds no production change.
