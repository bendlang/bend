# P8-003 — current full-source checking cost

Status: planned, before measurements. Date: 2026-09-28.

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
