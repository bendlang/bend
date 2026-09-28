# P8-003 — current full-source checking cost

Status: closed with controlled observations. Date: 2026-09-28.
The recipe below was authored before measurements; the result follows it.

Question: how long does the updated compiler take to validate its own complete
assembled source compared with the new pinned TypeScript compiler?

Use the final genuine checked development attempt, its exact assembled source,
the canonical b2111cf Base, frozen host/runtime and Node 24.18.0. Run four fresh
processes in TypeScript/Bend/Bend/TypeScript order on one pinned CPU, with no
other intentional compiler workloads during the measured window. Use a 4 MiB
Node stack, 4 GiB heap and 600-second deadline per process. Preserve requests,
results, logs, identities and failures. Verify consumed bytes before and after.

This measures parse, ordinary type checking, specialization and declaration
trust reporting, **not emission or full self-reproduction**. Upstream starts with
a fresh book and checks Base; Bend uses its separately validated disk Base cache,
as normal development does. Both start in fresh processes. Report request time
and process wall separately; do not call this an isolated checker benchmark or
compare it directly with the historical 6.03× full-compilation ratio.

Both must accept the source's types, find no holes and return the expected trust
refusal for this unsafe compiler source. Compare their unsafe-definition sets
as an additional observation; preserve any difference instead of changing the
oracle. Failed validation invalidates a speed comparison. Two samples each on
one machine provide a descriptive ratio, not a confidence interval.

Use one untimed preflight before the exclusive window if needed to establish
that the workload completes within resource limits. It remains separate evidence.
The retained unchanged-source emitter comparison from P8-001 answers a different
question and cannot substitute for these current-source observations.


## Result and decision

All four fresh-process observations pass their type/trust and identity gates.
Mean process wall is2.804s for TypeScript and 205.260s for Bend:73.20×. Mean
request is1.805s versus 204.200s:113.11×. Maximum RSS is411.9MiB versus 1605.6MiB.
The two opposite-order samples are stable, but no confidence interval is claimed.

Decision: this is a measured remaining checking deficit, not a speedup. Preserve
short upstream-checked/focused iterations (one integration attempt26.94s), and
investigate checker cost separately. A concurrent export-wrapper profile locates
most time in the authoritative checker; it is not a controlled timing sample.
The old guarded equality transform needs fresh adaptation to the new generated
String.cmp-based body. Compact literals remain a correctness/performance follow-up.
No new optimization or self-hosting proof is promoted by this experiment.

[Report and raw-result summary](../../implementation/phase8/checking-cost.md).
Exact requests, worker, logs, provenance and outputs are retained through the
[migration evidence index](../../implementation/phase8/migration-evidence/README.md).
