# Final generated-program execution

The unchanged fifteen-point comparison completes with every expected result in
**401.551 seconds**, across **219 fresh timing processes**. Against the immediately
previous Phase35 release, symbolic regression is **3.653× faster** and ray tracing
is **2.319× faster**. Their observed baseline/candidate ranges are disjoint. The
other thirteen points have overlapping ranges and establish no decisive change.

| Point | Phase35 median ms | Phase36 median ms | TypeScript median ms | Gain | Phase36 / TS |
| --- | ---: | ---: | ---: | ---: | ---: |
| Symbolic regression | 15.581745 | 4.265036 | 1.112363 | 3.653× | 3.834× |
| Ray tracing | 1,859.589096 | 801.893428 | 34.161730 | 2.319× | 23.473× |
| Tree bitonic | 23.0723 | 22.6844 | 0.281382 | 1.017×, overlap | 80.618× |
| Lexer | 170.429 | 172.054 | 1.92499 | 0.991×, overlap | 89.379× |

The [complete table](execution-table.md) and [bound summary](final-results.json) retain
all fifteen points, ranges and samples. Every candidate remains slower than its
same-run TypeScript counterpart. These fixed inputs include local controls,
original examples and test-derived programs; their ratios do not define average
application performance. Historical gains with different baselines are not
multiplied into a current speed claim.

## Clean protocol and variation

`selfhost/build/phase36/full-confirm03/report.json` is the authoritative full run.
It consumes the verified Phase35 `baseline02` bundle and actual checked03 `full03`
bundle through the unchanged maintained worker. All roles use CPU3, Node24.18.0,
a 1 GiB heap and 1.5 GiB process-tree RSS bound. Execution is serial and separate
from compilation, profiles and all other heavy work. There are five rotated
rounds per short point and three for the original full ray point. Warmup is at
least 1,000 ms; the timed target is 300 ms. This protocol does not establish
steady-state convergence, and observed ranges are not confidence intervals.

Symbolic regression ranges are 15.438628–15.676255 ms for Phase35 and
4.209430–4.286012 ms for Phase36. Ray ranges are 1,855.940374–1,898.320694 ms and
790.979915–896.051606 ms respectively. The high candidate ray sample is retained.
TypeScript symreg has an initial 1.992398 ms sample and four 1.105584–1.113915 ms
samples; it is retained in the five-sample median rather than filtered away.
Several generic points also show within-block drift. No overlapping improvement
is promoted as another established win.

## Map/set follow-up

The full run shows a **3.190%** higher map/set median, 1.590926→1.641680 ms, with
overlapping ranges. Both roles have a high band around 2.1 ms. This apparent cost
was investigated despite overlap, using exactly the same five-round 600-second
preset and original point in `map-set-confirm03`. The focused run completes in
24.058 seconds and records 1.611653→1.603229 ms, a **0.523% decrease**, again with
overlap. Baseline range is 1.573757–1.751567 ms; candidate is 1.567033–1.694302 ms.

Both runs remain evidence. No source change was made between them, so this is
neither a regression fix nor a confirmed speedup. The original full-run table
keeps its original map/set median.

The [exact suffix comparison](static-prefix-comparison.json) verifies each frozen
runtime prefix, then compares every remaining emitted byte. Thirteen program
suffixes, including map/set, are identical; only symreg and ray differ. All
modules embed the 1,005-byte larger runtime. This localizes source changes but
does not prove zero runtime or JavaScript-engine layout cost.

## Mechanism and scope

The [producer ablation](private-producers.md) separates generator lowering from
finite selector lowering. Actual checked output reproduces the complete gain;
additional complete-tree and mutation controls establish transfer and live
optimized execution. The [guard ablation](guard-report.md) isolates scope reuse
on saved ray output and the actual checked compiler passes the separate reentry
and refusal controls. Neither timing depends on retained diagnostic counters.

The next [profiles](profile-findings.md) use these exact modules but independent
instrumented processes. They include lexer and tree sorting as well as both wins.
Normal [compiler requests](compiler-cost.md), generated size and source growth
remain separate from the execution ratios above.
