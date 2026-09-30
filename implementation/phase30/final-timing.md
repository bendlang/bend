# Final checked-14 controlled performance comparison

Status: all 13 prospectively frozen jobs completed successfully in 1,631.07
seconds (27 minutes 11 seconds), including every exact-output check. Checked-14
release remains on hold because the complete matrix exposed generic-path
regressions. Successful execution is not a performance acceptance decision.

The selected image is checked attempt 14, compared in the same serial window
with pinned upstream TypeScript and installed Phase29. The ten original programs
use unchanged source files, arguments and expected outputs from the retained
transfer plan. Each case checks its complete expected result, then measures five
fresh-process samples in rotating variant order on CPU3. The transfer protocol
uses three warmup calls, at least one second of warmup, 100 ms calibration and a
300 ms measurement target. It does not use the 100-call microbenchmark floor.
For slow original programs, one timed call can exceed the target; such samples
do not support a within-sample half-drift statistic.

Compiler checking, checked-library generation and helper scaling are separate
measurements. They do not contribute to a pooled generated-program speed claim.
Compiler request, import and process boundaries are reported separately by their
maintained tools. No other campaign CPU work runs during this batch.

The frozen orchestration is
`selfhost/build/phase30/final-timing-batch-plan-14/plan.json`; its launcher binds
752 input identities and runs the 13 approved jobs serially. The progress receipt
is `selfhost/build/phase30/final-timing-batch-14/report.json`. Each child retains its
own process receipts, configurations, stdout, stderr and report. Original-case
outer timeouts are the already frozen 1,200 seconds. No automatic retries,
additional warmups or adaptive protocol changes are part of this batch.

## Original programs

All ten original points pass their expected outputs. Times below are median
milliseconds per call; the percentage is checked14 time relative to Phase29.
Negative percentages mean less time. These are individual retained inputs,
without a pooled average.

| Original point | TypeScript ms | Phase29 ms | Checked14 ms | Time change | Checked14 / TS |
| --- | ---: | ---: | ---: | ---: | ---: |
| mandelbrot | 0.045687 | 21.473750 | 0.220591 | −98.97% | 4.83× |
| editdist | 4.929327 | 2029.574745 | 2435.480768 | +20.00% | 494.08× |
| tree-bitonic | 0.280755 | 26.097304 | 31.865055 | +22.10% | 113.50× |
| lexer | 1.912481 | 175.073926 | 210.847468 | +20.43% | 110.25× |
| symreg | 1.104209 | 106.228782 | 133.377933 | +25.56% | 120.79× |
| test-morning-program | 0.003684 | 0.224574 | 0.297414 | +32.43% | 80.72× |
| test-evening-program | 0.003146 | 0.303579 | 0.181654 | −40.16% | 57.74× |
| test-rle-roundtrip | 0.000595 | 0.044962 | 0.075053 | +66.92% | 126.15× |
| test-map-set-ops | 0.022082 | 2.224784 | 2.046543 | −8.01% | 92.68× |
| raytrace | 34.146446 | 10527.867179 | 13027.829828 | +23.75% | 381.53× |

The broad generic-path regression is visible in edit-distance, lexer and
ray tracing, with separated sample ranges. Symreg also regresses, although one
candidate sample remains a warmup outlier. This is sufficient to hold release
and investigate common runtime dispatch before promoting checked14.

Several short transfer cases are substantially unsettled. Phase29 tree-bitonic
halves improve by 17.6–20.1%; morning-program baseline improves 14.4–21.8% while
candidate halves worsen 18.2–25.4%; evening-program baseline worsens 191–215%;
map/set baseline worsens 39–42%. Candidate RLE halves improve 2.9–17.9%. Their
table percentages remain recorded transfer observations, not settled-throughput
claims. Edit-distance and ray tracing use one timed call per sample and therefore
have no meaningful within-sample half statistic.

Every full range, sample and half statistic is retained under
`final-transfer-plan-14/<case>-timing/report.json`, with compact ranges/drift in
the batch receipt. The original ray-tracing case alone took 756.3 seconds; its
cost was retained rather than reducing repetitions after seeing results.

## Compiler costs

The ordinary compiler check passes all nine observations on the same frozen
compiler source. Its median request times are TypeScript 2490.386 ms, Phase29
9813.938 ms and checked14 10186.944 ms: checked14 takes 3.80% more request time
than Phase29 and 4.09× TypeScript time. Corresponding process medians are
3617.723, 11005.747 and 11349.472 ms, a 3.12% increase versus Phase29. These
boundaries include the normal validated Base/cache behavior specified by the
existing tool, not an isolated compiler algorithm.

The retained tool additionally reports request means of 2492.568, 9826.327 and
10128.126 ms. Maximum observed RSS is 477408, 760104 and 676880 KiB respectively.
Means and medians are deliberately kept distinct. Raw data is
`final-integration-plan-14/compiler-cost/report.json`.

The checked-library matrix passes all 18 output-hash checks (two original
sources, three variants, three samples). Median costs below are milliseconds;
the request includes the normal checked-library operation, while explicit host
import is outside that request. Bend's lazy API load remains within the request.

| Source / boundary | TypeScript | Phase29 | Checked14 |
| --- | ---: | ---: | ---: |
| Mandelbrot request | 337.381 | 1656.833 | 1770.292 |
| Mandelbrot import + request | 604.985 | 1672.066 | 1785.549 |
| Mandelbrot full process | 4835.295 | 6068.343 | 6297.985 |
| Edit-distance request | 310.341 | 1538.760 | 1571.944 |
| Edit-distance import + request | 578.634 | 1552.704 | 1587.313 |
| Edit-distance full process | 4813.153 | 5944.310 | 6081.531 |

Checked14 request medians are 6.85% and 2.16% higher than Phase29 respectively.
The full process includes substantial input attestation, persistence and output
capture; it must not be relabeled request time. Raw ranges, import-only costs,
RSS, exact generated bytes and each supervised child are retained in
`library-cost-14/report.json`.

## Scalar helper scaling

All four scalar-helper points pass. This is the same helper source and seed
524800, with the retained five-sample confirmation protocol and its three-second
minimum warmup. Times are milliseconds per call.

| Iterations | TypeScript | Phase29 | Checked14 | Phase29 / checked14 | Checked14 / TS |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 0.000096972 | 0.001683511 | 0.004503616 | 0.37× | 46.44× |
| 128 | 0.001703555 | 0.390070374 | 0.006983992 | 55.85× | 4.10× |
| 1024 | 0.012891072 | 3.247765913 | 0.022101931 | 146.95× | 1.71× |
| 8192 | 0.099130400 | 25.393195250 | 0.133129180 | 190.74× | 1.34× |

The zero-work case exposes fixed entry/guard cost: checked14 takes 2.68× Phase29
time. With substantial work inside one admitted region, the same fixed cost is
amortized and the gap to TypeScript narrows. This is evidence for the private
scalar region mechanism, not a claim that general programs run 190× faster.
The original-program matrix above shows why coverage and generic fallback cost
must be measured separately.

Candidate sample ranges are 0.004486–0.004523, 0.006967–0.007138,
0.021979–0.022228 and 0.132338–0.134213 ms respectively. Candidate half drift
ranges are +0.60…+2.71%, −0.80…+2.61%, −1.40…−0.18% and +0.15…+3.03%.
Full samples and all comparison ranges are in
`scalar-scaling-confirm-14/report.json`.

## Interpretation

The final batch measures selected original inputs, not every Bend program. The
stronger 15-second-warmup Mandelbrot comparison and its incremental private-Let
result remain separately documented in `private-let-compiler.md`; the shorter
transfer samples here are not a replacement for that settled-throughput check.

The release hold leads to a new, separately frozen diagnostic design,
`design/phase30/generic-runtime-row-diagnosis.md`. It compares identical complete
edit-distance rows and isolates runtime dispatch changes while preserving the
corrected public contracts. No measurements in this completed batch are retried
or rewritten to accommodate that follow-up.
