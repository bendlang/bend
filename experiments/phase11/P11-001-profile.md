# P11-001 — Profile the released compiler before choosing further work

Owner: root. Date:2026-09-28. Prospective diagnostic plan.
Baseline: Phase10 `integrated-01`, release `5f561c4`, upstream b2111cf.
Hypothesis: the remaining expensive source operations differ after Phase10;
its old baseline profile cannot rank this release's optimization opportunities.

Verify release integrity; run unchanged Phase9 profile-check.mjs with10ms samples
on CPU0 and a fresh `build/phase11/current-profile-01` directory. Input identities
and ordinary-type/expected-unsafe-trust result must hold. Summarize with the
existing streaming reader and Phase10 lexical-owner tool. Keep historical tool
schema names, complete raw data and failures. Do not interpret lexical ownership
as inclusive caller cost, GC as allocation counts, or instrumented wall as speed.

Reread relevant pinned TypeScript algorithms and emitted shapes after profiling.
Separate genuine representation/algorithm differences from incidental line counts.
Record findings in [the report](../../implementation/phase11/known_work.md).
No production mutation or optimization is authorized by this diagnostic itself;
subsequent source candidates require their own prospective hypothesis and gates.

## Final disposition

Final profile complete; see [combined report](../../implementation/phase11/known_work.md).
