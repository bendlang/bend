# Checked16 renewed controlled comparison

Status: the actual-image small confirmation passes and retains both the generic
row recovery and scalar speedup. All 13 jobs in the renewed complete matrix
pass in 1557.58 seconds (25 minutes 58 seconds). The residual RLE regression,
compiler costs, and unstable warmup observations remain visible below. Both
separate long-warmup checks also pass their exact outputs; tree-bitonic retains
a small performance regression. This is not an installation or release claim.
Checked14's complete matrix and release hold remain documented in
`final-timing.md`; these are separate checked16 results.

The candidate integrates the confirmed generic constructor-field runtime repair
and removes unused prebinding source machinery. The original ten programs have
all been freshly compiled and their exact public outputs pass. The row and
scalar source/control provenance is documented in
`generic-runtime-row-diagnosis.md`, including the independent checked15→16
structural proof and complete-state/alias/effect observations.

`runtime-cleanup-timing-plan-16/confirm.json` freezes a five-way row32/scalar128
confirmation (Phase29, held14, repaired15, cleaned16, pinned TypeScript). The
pending15-only plan remains unexecuted; the combined comparison replaces its
execution without modifying that historical plan.

The complete final batch is frozen in
`selfhost/build/phase30/final-timing-batch-plan-16/plan.json`: 13 serial jobs and
751 input identities. Its exact retained launcher derivation lives in
`final-timing-launchers-16/derivation.json`. It executes the ten unchanged
original transfer points, ordinary compiler check, two-source checked-library
cost matrix, and four-point scaling confirmation. Per-case receipts and drift
remain separate. Original-case outer limits remain 1,200 seconds; no 100-call
microbenchmark floor is substituted for expensive original programs.

The scaling correctness precheck passes all 12 public source/variant points.
Only its acquisition affinity changes from CPU7 to CPU2 to avoid frontend workers;
the frozen derivative and exact edit record are in
`scalar-scaling-cpu2-check-16`. Measured scaling remains on CPU3 with the original
confirmation protocol.

## Actual-image row and scalar confirmation

`runtime-cleanup-confirm-16` completes in 209.80 seconds with every exact result
check passing. Median milliseconds per call:

| Point | Phase29 | Held14 | Repaired15 | Cleaned16 | TypeScript |
| --- | ---: | ---: | ---: | ---: | ---: |
| Complete row32 | 0.448173 | 0.601983 | 0.448121 | 0.444585 | 0.008421 |
| Scalar128 | 0.396410 | 0.006965 | 0.006972 | 0.006975 | 0.001703 |

Cleaned16's row range is 0.442894–0.458928 ms, compared with repaired15's
0.447231–0.451254 and Phase29's 0.444422–0.451538. The recovered generic speed
holds: cleaned16 takes 26.15% less time than held14, with disjoint ranges.
The 0.79% median difference against repaired15 is inside overlapping ranges and
does not establish a further speed gain from source cleanup. Row half drift is
−0.16…+2.31% for cleaned16 and −0.55…−0.02% for repaired15.

The scalar ranges of held14, repaired15 and cleaned16 all overlap. Cleaned16
takes 0.006955–0.007050 ms, retaining the scalar win: 56.83× Phase29 throughput
and 4.096× TypeScript time at 128 iterations. Its half drift is +0.68…+2.38%;
all scalar variants stay within 3.00% absolute half drift. These results support
preserving the repair while deleting unused machinery, not a new compounded
optimization claim.

The final original-program matrix, separate long-warmup comparison and release
gates remain required; this small confirmation alone is not a release verdict.

## Renewed original-program comparison

The immutable launcher journal is
`selfhost/build/phase30/final-timing-batch-16/report.json`; each row below links
through that journal to its own complete process outputs and report hashes.
These are medians from the unchanged transfer protocol, in milliseconds per
call. A positive time change means cleaned16 is slower than Phase29.

| Original point | TypeScript | Phase29 | Cleaned16 | Time change vs29 | Cleaned16 / TS |
| --- | ---: | ---: | ---: | ---: | ---: |
| Mandelbrot | 0.045452 | 21.416666 | 0.214181 | −99.00% | 4.71× |
| Edit distance | 4.957825 | 2034.066101 | 2026.226551 | −0.39% | 408.69× |
| Tree bitonic | 0.273253 | 26.047441 | 26.938268 | +3.42% | 98.58× |
| Lexer | 1.919549 | 176.054721 | 176.159110 | +0.06% | 91.77× |
| Symbolic regression | 1.106572 | 106.987871 | 109.779127 | +2.61% | 99.21× |
| Morning program | 0.003723 | 0.227457 | 0.222019 | −2.39% | 59.63× |
| Evening program | 0.003152 | 0.286586 | 0.271041 | −5.42% | 85.98× |
| RLE round trip | 0.000593 | 0.044767 | 0.049376 | +10.30% | 83.23× |
| Map/set operations | 0.023200 | 2.328559 | 2.110699 | −9.36% | 90.98× |
| Raytrace | 34.225803 | 10609.546586 | 10789.490798 | +1.70% | 315.24× |

Mandelbrot retains approximately 100× Phase29 throughput. Its candidate range
is 0.212438–0.214528 ms and candidate half drift is −1.30…+0.78%; the separate
long-warmup comparison remains scheduled. Edit distance's candidate range
2019.644–2040.377 ms overlaps Phase29's 2013.869–2047.052 ms. Lexer likewise
overlaps (175.159–178.379 versus 174.519–178.027 ms). The broad ~20% slowdown of
held14 is therefore absent on these two expensive generic points. Edit distance
uses single-call slow samples, so there is no meaningful within-sample half
drift statistic for its Bend variants.

Raytrace also recovers the large held14 regression: cleaned16's
10741.816–10931.432 ms range overlaps Phase29's 10477.826–11033.455 ms.
The +1.70% median difference does not establish a stable remaining regression.
Its Bend samples are likewise single calls. This original point consumes
695.07 seconds of outer measurement time, which reinforces the need for the
independent small-state loop used to isolate the common runtime problem.

RLE retains a smaller clear regression: candidate 0.048220–0.049927 ms versus
Phase29 0.044631–0.045172 ms, with candidate half drift −0.17…+1.40%. Symbolic
regression is 2.61% slower, with candidate 109.423–110.441 ms versus Phase29
106.325–107.402 ms and candidate drift −0.62…+0.38%. Neither result is hidden
by the successful runtime repair.

The remaining short-point medians need warmup qualifications. Tree bitonic
still improves within each Bend sample by roughly 17–21%; morning improves
by roughly 5–22%. Evening slows by 112–281% between sample halves, and map/set
by 35–70%. Their displayed median changes do not establish settled gains or
regressions. All exact result checks pass; no failed observation, discarded
sample, or changed timing protocol is involved.

## Compiler cost is a separate metric

The ordinary checked-compiler request passes on all three sides. Its three
request medians are 2484.872 ms for pinned TypeScript, 9859.740 ms for Phase29,
and 10240.078 ms for cleaned16. Cleaned16 is 3.86% slower than Phase29 and
4.12× TypeScript on this request. Corresponding whole-process medians are
3652.701, 11102.794, and 11425.316 ms; maximum observed RSS is 479844, 763068,
and 708748 KiB. Means are retained separately in the report, rather than
substituted for medians. This job consumes 93.20 seconds of outer time.

The two-source checked-library matrix also passes, using three retained
rotations. Request medians in milliseconds:

| Source | TypeScript | Phase29 | Cleaned16 | Time change vs29 |
| --- | ---: | ---: | ---: | ---: |
| Mandelbrot | 339.139 | 1648.566 | 1746.279 | +5.93% |
| Edit distance | 306.699 | 1546.262 | 1536.402 | −0.64% |

Mandelbrot's candidate request range 1734.250–1765.449 ms is disjoint from
Phase29's 1617.596–1668.092 ms. Additional analysis and emission have a
measurable compiler cost even though the generated scalar program is much
faster. Edit distance's candidate range 1534.505–1573.200 ms overlaps
Phase29's 1540.462–1554.752 ms. The candidate is 5.15× and 5.01× TypeScript
request time respectively. Whole-process medians are 4829/6109/6242 ms for
Mandelbrot and 4794/5962/6051 ms for edit distance, in TypeScript/29/16 order;
host import and driver work remain separate raw fields. The library-cost job
consumes 122.72 seconds. These compilation costs must not be described as
generated-program runtime ratios.

## Scalar work scaling

All twelve source/variant result checks and all timed samples pass. This final
batch job takes 251.18 seconds. Median milliseconds per call:

| Iterations | Phase29 | Cleaned16 | TypeScript | Phase29 / Cleaned16 | Cleaned16 / TS |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0 | 0.001674 | 0.004566 | 0.000097 | 0.37× | 46.94× |
| 128 | 0.395900 | 0.006972 | 0.001703 | 56.78× | 4.09× |
| 1024 | 3.303268 | 0.022229 | 0.012844 | 148.60× | 1.73× |
| 8192 | 25.648360 | 0.132922 | 0.099274 | 192.96× | 1.34× |

The larger points amortize the entry guard and expose the private loop's
throughput. The zero-work point instead pays a real fixed cost: cleaned16 is
2.73× Phase29 time. This table is a controlled scaling series for one scalar
helper, not a representative-program aggregate or a promise for array/record
programs.

At 128 iterations the candidate range is 0.006908–0.007036 ms. At 1024 it is
0.022111–0.023189 ms, and at 8192 it is 0.132257–0.138470 ms. Retained drift
exceptions include one +17.96% candidate zero-work sample, one −7.32% candidate
1024 sample, and one −4.18% candidate 8192 sample. The remaining candidate
8192 halves stay within 0.34% absolute drift. No sample is discarded; complete
ranges and each individual half remain in the batch and per-job reports.

## Separate settled Mandelbrot retention check

The prospectively frozen `runtime-cleanup-long-plan-16` uses the unchanged
15-second warmup, three alternating samples per side and one-second measured
target. `runtime-cleanup-long-confirm-16` passes every exact check in 193.69
seconds. Repaired15 takes 0.211216 ms (0.208245–0.211252), cleaned16 takes
0.209363 ms (0.209007–0.210544), and pinned TypeScript takes 0.045581 ms
(0.045580–0.045639).

Cleaned16 is 4.593× TypeScript time in this independent settled window. Its
three half drifts are −0.390%, −0.105% and −0.025%; repaired15 ranges from
−2.875% to +0.235% and TypeScript from −0.373% to +0.582%. The overlapping
15/16 ranges confirm preservation of the scalar benefit, without establishing
a further cleanup speedup. These samples remain separate from the original
transfer protocol.

## Separate tree-bitonic warmup diagnostic

`final-tree-bitonic-long-plan-16` was frozen after observing the original
17–21% negative half drift and before measuring this follow-up. It preserves
the original `bench(8, 0)` point, expected output 971629740, and exact three
modules. The unchanged long runner uses 15-second warmup, three alternating
samples per side and one-second targets. `final-tree-bitonic-long-confirm-16`
passes every exact result check in 194.74 seconds.

Phase29 takes 23.274130 ms (23.017739–23.508582), cleaned16 takes 24.240725 ms
(24.156210–24.748064), and pinned TypeScript takes 0.259341 ms
(0.258703–0.261329). Cleaned16 remains 4.15% slower than Phase29 with disjoint
ranges, and takes 93.47× TypeScript time. Candidate half drift is +0.287%,
+2.716%, and −0.029%; Phase29 is −6.965%, +4.899%, and +0.247%, while
TypeScript stays within 0.26% absolute drift.

Warmup reduced the original transition substantially, but did not remove the
small regression. Retain this outcome alongside RLE rather than relabeling the
transfer difference as entirely warmup. These samples do not replace the
original transfer receipt or authorize a repeated/tuned window. The renewed
performance release remains on hold pending the residual-dispatch investigation
and parent-owned native backend gates.
