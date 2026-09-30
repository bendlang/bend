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

No production cache or speed improvement is claimed. A surviving result would
still require an independently reviewed private entry, exact function/export
guards, immutability and arbitrary public mutable/getter/proxy/reentrancy
behavior. This prototype does not establish that boundary.
