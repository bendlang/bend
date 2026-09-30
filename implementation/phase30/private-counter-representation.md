# Keep the BigInt counter for now

The [prospective counter ablation](../../design/phase30/private-counter-representation.md)
changed only the private countdown representation in the small Mandelbrot helper
fixture. It preserved helper arithmetic, guards, public values and fallback.
Both prototypes remain diagnostic artifacts, with the frozen region's mutation
and entry assumptions; neither is a production semantic approval.

All 121 independent points passed for all four variants (484 observations),
including a 50,000-iteration point. Six raw-frame fallback comparisons, three
saved partial checks and 10,006 numeric conversion/decrement checks also passed.

| Variant | Short window, ms | Longer warmup, ms | Long sample range, ms |
| --- | ---: | ---: | ---: |
| Phase29 | 0.422301 | 0.394473 | 0.391842–0.398985 |
| Private region, BigInt counter | 0.032299 | 0.029666 | 0.028661–0.030651 |
| Same region, Number counter | 0.029563 | 0.028194 | 0.027676–0.028708 |
| Pinned TypeScript output | 0.001748 | 0.001713 | 0.001701–0.001765 |

The incremental Number change gives a 1.052× ratio of long-window medians.
Its range slightly overlaps BigInt's. Two BigInt samples drift by −6.35% and
+11.19% between timed halves; Number samples stay within 0.93%. This is weak
evidence for an additional representation rule. Defer it and seek larger,
simpler wins first. The large combined private-region gain at this point does
not measure the counter change, and this helper point is distinct from the
original Mandelbrot benchmark reported elsewhere.

First-call medians are 6.444 ms / 2.008 ms / 2.030 ms / 0.751 ms in table order.
The clean CPU3 screen costs 8.281 s end to end; confirmation costs 84.417 s.
Both rotate variants serially in fresh Node 24.18.0 processes; confirmation uses
five samples, at least 100 calls and 3 s warmup, and 300 ms timed targets.
Result checking occurs inside each call. Other acquisitions were paused.

Raw evidence: `selfhost/build/phase30/counter-01`, `counter-check-01`,
`counter-screen-01`, `counter-confirm-01` and their launcher receipts. Derivation,
tool/input identities and original modules are preserved with the campaign.
