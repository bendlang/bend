# Repeated emitter queries without a new IR

Actual07 emission repeats many pure queries, while complete root/region plans
do not repeat by identity. The first compact experiment therefore memoizes
existing queries inside one emission request; no permanent IR or production
change is needed to test the opportunity.

| Query | Edit distance repeats / calls | Mandelbrot repeats / calls |
| --- | ---: | ---: |
| `wnf(book,type)` |9,044 /14,760|10,768 /19,066|
| Local type |971 /1,973|1,715 /3,646|
| Local signature |281 /366|262 /330|
| Nat shape |64 /129|70 /122|
| Capture eligibility |63 /127|69 /118|
| Arm type |74 /153|64 /132|
| Canonical Nat natives |16 /17|11 /12|

Keys include every argument, not just a type or function name. Identity misses
may include structurally equal new values; no attempt turns them into hits.
The [frozen diagnostic](../../design/phase32/compact-query-counts.md) passes11
complete observation/output comparisons. Its nested-inclusive durations are
instrumented and cannot attribute the historical6.90% ordinary compile
regression by themselves. Raw evidence is shared with
[the semantic investigation](reuse-counts.md).

The [memo prototype](../../design/phase32/compact-memo-prototype.md) uses a small
Map trie per selected query, clears all tables per emission export, and retains
the same resolved trampoline result. Full book/type/mode/arity keys remain.
It does not memoize the active-set/fuel local-check worker. All15 candidate
output/error/dependency comparisons pass, including original programs and
type/signature/import edits. Memoization also makes normalized results share
identity, reducing later primitive-type work; call counts are consequently not
the same as the original counter-only acquisition.

The first [clean screen](../../design/phase32/compact-clean-screen.md) completed
in34.54seconds and preserves every output, but **fails its speed admission**:

| Warm normal request | Original07 median ms | Global-wrapper memo ms | Change |
| --- | ---: | ---: | ---: |
| Small source |757.731|857.139|+13.12%|
| Mandelbrot |1023.999|1092.107|+6.65%|
| Edit distance |1010.175|1099.136|+8.81%|

There are only two screen observations per role/case; these are not release
throughput estimates. Raw plan/results are
`selfhost/build/phase32/compact-screen-plan-01/plan.json` and
`selfhost/build/phase32/compact-screen-results-01/report.json`. This version
replaces `wnf` with a diagnostic wrapper even during checking, when memoization
is inactive. The rejected implementation therefore has costs outside emission.

[The scoped successor](../../design/phase32/compact-emitter-scoped.md) starts
from pristine07 bytes and swaps eight query bindings only while the ordinary
emission export executes; `finally` restores them. It has no global hook and
retains at most4,096 cached results during one emission. Fifteen complete
request comparisons precede any timing. Serial workers have768MiB heaps.
`compact-scoped-plan-01` was never executed and is superseded by plan02: the
worker now reports no query statistics for rejected requests that do not enter
emission, rather than repeating the previous request's statistics.

Scoped correctness02 now passes all15 complete baseline/candidate observation,
dependency and output comparisons. The two serial workers take16.55and16.15s;
their process peak RSS is428,496and448,220KiB. Positive small requests use674
memo entries; both original programs reach the4,096-entry cap. Rejected requests
correctly report no emission query statistics. The request sequence is warming
and not a speed comparison. Evidence:
`selfhost/build/phase32/compact-scoped-correctness-02/report.json`.

The4k scoped screen completes in36.5s with all outputs equal, but **does not meet
the prospective performance threshold**:

| Warm normal request | Original07 median ms | Emission-scoped4k ms | Change |
| --- | ---: | ---: | ---: |
| Small source |854.169|839.971|−1.66%|
| Mandelbrot |1289.337|1329.345|+3.10%|
| Edit distance |1189.122|1049.701|−11.72%|

Every range overlaps. In particular the edit-distance baseline spans1036.8–
1341.4ms, while the candidate spans1042.3–1057.1ms. Its lower median is not a
demonstrated speedup. Both larger cases still saturate the4k table. Evidence:
`selfhost/build/phase32/compact-scoped-screen-02/report.json`; each role has two
fresh-process timed observations after its first triad of priming requests.

A final [16k-capacity ablation](../../design/phase32/compact-capacity.md) was
frozen before these timing results were read. Only the cap changes; its complete
candidate observation suite reuses the exact unmodified baseline oracle, then
a fresh four-process screen tests whether the earlier bound hid a useful gain.
This is not a repeated attempt to improve the same candidate's reported median.

The16k candidate preserves all15 observations; the unchanged baseline oracle is
explicitly reused, not freshly rerun. Its largest table has8,892 entries on
Mandelbrot and6,737 on edit distance, so this capacity is not saturated. Candidate
correctness peak RSS is475,864KiB. Its36.02s fresh screen gives:

| Warm normal request | Original07 median ms | Emission-scoped16k ms | Change |
| --- | ---: | ---: | ---: |
| Small source |860.788|905.226|+5.16%|
| Mandelbrot |1287.169|1259.040|−2.19%|
| Edit distance |1037.094|1002.690|−3.32%|

Only edit distance has disjoint ranges:1013.59–1060.60ms original against
1002.40–1002.98ms candidate. The small-source and Mandelbrot ranges overlap.
The frozen admission still **fails**: both larger cases needed at least3%
median improvement and the small-source regression had to stay within5%.
This closes the bounded query-memo campaign without promotion, a large new IR,
or further retiming. Evidence:
`selfhost/build/phase32/compact-cap-correctness-03/report.json` and
`selfhost/build/phase32/compact-cap-screen-03/report.json`.

The simpler follow-up found during this analysis—reusing the driver's existing
stop list—has a more promising private screen but a concrete public-boundary
counterexample. It is reported separately in [stop-set reuse](compact-stop-reuse.md).

No production cache or speed improvement is claimed. A surviving result would
still require an independently reviewed private entry, exact function/export
guards, immutability and arbitrary public mutable/getter/proxy/reentrancy
behavior. This prototype does not establish that boundary.
