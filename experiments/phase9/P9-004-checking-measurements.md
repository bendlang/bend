# P9-004 — current checking cost and residual profile

Date: 2026-09-28. Prospective record; outcomes belong in
`implementation/phase9/checker_speed.md`.

Question: which operations dominate the installed Phase8 checker, and how much
do independently validated Phase9 changes reduce the same full-source request?

First take a V8 CPU sampling profile of the immutable Phase8 release07 checking
its frozen complete source. Use CPU0, Node24.18.0, a 4MiB stack, 4GiB heap and a
600-second deadline. Other agents may develop on CPU1–3 during this profile.
Consequently its wall time is diagnostic only, excluded from performance ratios.
Preserve original profile, request/result, sampled node identities and command.
Sampling and native/GC frames can obscure attribution; do not infer exact
allocation counts or call counts from sample hits.

Small operation/size experiments belong to P9-001/P9-002/P9-003. Their timing
lanes must remain separate from instrumented counters. Use their results and the
baseline/residual profile to justify deeper work; do not run every candidate
through an unchanged several-minute full self-check.

The integration comparison follows the committed Phase9 design: same final
assembled source, new pinned TypeScript, preserved baseline API and integrated
candidate API; serial TS/baseline/candidate/candidate/baseline/TS, CPU0, no other
intentional compiler jobs, fresh processes with independently validated Bend
Base caches. Record peak RSS, request and process wall. All six type/trust and
input-identity gates must pass before calculating gains. Report every failed
preflight separately. If a final-source construct is unsupported by the baseline,
select an explicitly identical supported source for all lanes before timing and
record the changed workload rather than hiding the failure.

The output is a checking comparison, not emitted-program performance, full
compilation or a fresh self-hosted fixed point. No baseline claim is borrowed from
the historical 6.03x full-compilation comparison.
