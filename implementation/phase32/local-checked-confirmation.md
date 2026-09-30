# Checked local-output confirmation

Actual checked03 output runs the complete edit-distance pair3.76× faster than
the installed Phase31 checked07 output and the independent array fold1.98×
faster. In this same window it remains3.78× and8.13× slower than pinned
TypeScript output respectively. These are the two complete local program
points; the original four-pair program and compiler request costs are separate
integration measurements.

| Compiler output | One256×256 pair ms | Fold4096 ms |
|---|---:|---:|
|Phase31 checked07|18.534792|0.650530|
|Checked01: scoped statement bindings|8.879800|0.527575|
|Checked02: add typed array-read tuple fusion|6.540376|0.407620|
|Checked03: add private representation changes|4.925421|0.329142|
|Pinned TypeScript|1.302093|0.040465|

Each incremental comparison has disjoint full sample ranges on both points.
Statement bindings remove52.09% of pair time and18.90% of fold time. Tuple fusion
then removes26.35% and22.74%. The final checked03 change removes24.69% and19.25%.
These are adjacent measured comparisons within one window, not percentages
applied to a different historical baseline.

The last step needs the [explicit representation scope](../../design/phase32/vector-ablation-scope.md).
The pair contains Dp state records and no Tuple constructor sites; its02→03
comparison isolates the new private Dp layout within this implementation.
The fold has no ordinary records; its03 gain accompanies removing three private
canonical Sigma constructor-dispatch sites while keeping their array layout.
Do not attribute the fold gain to eliminating ordinary record shells. General
generated-code/JIT consequences remain possible for either comparison.

## Controlled protocol and practical limits

The frozen `local-checked-plan-03/confirm.json` runs five fresh processes per
role/point, in rotating serial CPU3 order. Every process uses Node24.18.0,
a4MiB stack and1024MiB V8 old-space allowance. Each warms for at least100 calls
**and** three seconds before a roughly300ms timed interval. Each invocation
checks the complete exported scalar result. Module import, first call and
warmup are outside the reported warmed time; the first call is reported
separately. All50 timed processes completed, as did the separate checks and
calibrations. The harness took210.632seconds; outer supervised acquisition took
211.62seconds and peaked at approximately146MiB summed process-tree RSS.

| Output | Pair full range ms | Pair half drift | Fold full range ms | Fold half drift |
|---|---:|---:|---:|---:|
|07|17.266910–18.839951|+0.003% to+5.358%|0.642898–0.654689|−0.919% to+0.146%|
|01|8.400308–9.174923|−5.934% to+4.459%|0.522741–0.533219|−0.635% to−0.115%|
|02|6.505981–7.259359|−1.355% to+2.891%|0.401659–0.437253|−0.967% to+2.620%|
|03|4.885708–5.432317|−1.829% to+1.439%|0.323288–0.393899|−27.072% to+2.123%|
|TypeScript|1.233368–1.372888|−10.604% to+0.930%|0.039502–0.043972|−4.728% to+1.853%|

The checked03 fold has one large downward half drift, and the TypeScript pair
also retains a downward drift. The longer warmup does not establish converged
throughput. All samples, including the0.393899ms fold sample, remain in the
medians/ranges; no outliers were discarded. Ranges are descriptive, not confidence
intervals. The raw short screen remains a distinct earlier window and is not
averaged into this confirmation.

First-call medians improve54.44→21.27ms for the pair and11.19→6.78ms for the fold
between07 and03. The TypeScript first calls are17.67ms and6.59ms. These exclude
import time and are not complete process latency. Peak child RSS across timed
roles is approximately69–95MiB; the [machine summary](local-checked-summary.json)
retains each process's RSS, first call, import cost, warm calls and half timings.

## Evidence and decision boundary

`local-timing-summary.py` audits every expected role/trial, all child stdout
values, module hashes, result checksums, warmup minima, CPU affinity and identical
Node flags. It recomputes medians/ranges from all samples and verifies the
maintained harness's summaries. Raw evidence remains in
`selfhost/build/phase32/local-checked-confirm-03/` and its frozen cohort/plan.
Its derivative tools, full state/alias/scope controls and prospective source
boundaries are retained separately; timing result checks do not replace them.

The local performance hypothesis passes its named two-point criterion. Final
production admission still requires original-program transfer, mixed generic
canaries, normal compilation cost, final-artifact conformance and release gates.
No H compiler throughput, broad application average or fixed-point claim follows
from this local confirmation.
