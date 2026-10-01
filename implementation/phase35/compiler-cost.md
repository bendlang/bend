# Checked compiler cost and its release tradeoff

The selected compiler makes these normal checked-library requests slower. Pair's
median increase is small with overlapping samples; Mandelbrot, symreg and ray
have disjoint slower ranges. The generated-program gains therefore come with a
real compilation cost. This phase does not improve compiler throughput.

Root completed all **36/36** measurements in **250.623 seconds**: four unchanged
sources × baseline/candidate/TypeScript × three fresh processes. Every emitted
module matched an independently checked expected module byte for byte. The
[derived receipt](compiler-cost-data.json) contains all medians, ranges, raw
samples, output identities and the raw report hash. The read-only
[extractor](compiler-cost-extract.py) verifies and reproduces these calculations.

## Complete normal checked requests

Times are milliseconds. Parentheses contain observed minimum–maximum across
three rotated samples, not confidence intervals.

| Source | Baseline request | Checked09 request | TypeScript request | Candidate change |
|---|---:|---:|---:|---:|
| Local pair | 1,669.819 (1,617.855–1,721.945) | 1,681.841 (1,669.065–1,704.072) | 311.867 (309.878–311.892) | +0.72%; overlap |
| Mandelbrot | 1,709.781 (1,707.827–1,720.134) | 1,849.441 (1,837.048–1,855.329) | 341.413 (339.203–345.191) | +8.17%; disjoint |
| Symreg | 1,531.111 (1,522.639–1,537.152) | 1,991.764 (1,966.559–2,034.365) | 299.518 (298.890–304.379) | +30.09%; disjoint |
| Ray tracing | 1,992.469 (1,793.833–2,274.656) | 2,677.918 (2,657.957–2,884.912) | 433.017 (429.390–440.687) | +34.40%; disjoint |

Candidate request medians are **5.39×, 5.42×, 6.65× and 6.18×** TypeScript for
these four source files. These are compiler-request ratios; the generated
program ratios are separate in [profile findings](profile-findings.md).

The unchanged Phase30 worker calls the ordinary checked library path: Bend
`inspect(source, {mode:'library'})`, including lazy API loading and the normal
validated Base cache; TypeScript `book_load`, `book_valid`, then `js_lib`. It
checks that the source closure contains only the requested file and Base. It
does not time emission alone or bypass type checking. This is a fresh process
using the established valid Base cache, not a cache-miss Base rebuild experiment.

## Import, process and memory boundaries

Each cell below is the median for **baseline / candidate / TypeScript**. The
full receipt retains every spread/sample for these boundaries as well.

| Source | Host import ms | Import + request ms | Supervised process ms | Peak process-tree RSS MiB |
|---|---:|---:|---:|---:|
| Local pair | 3.715 / 12.787 / 218.901 | 1,673.580 / 1,694.629 / 530.768 | 5,895.834 / 6,059.492 / 4,631.487 | 508.719 / 490.164 / 487.973 |
| Mandelbrot | 3.702 / 13.105 / 218.569 | 1,713.584 / 1,862.485 / 560.873 | 6,019.709 / 6,227.221 / 4,630.937 | 508.668 / 490.816 / 490.863 |
| Symreg | 3.734 / 13.117 / 221.969 | 1,535.304 / 2,004.641 / 521.486 | 5,798.026 / 6,372.204 / 4,610.869 | 506.184 / 490.441 / 483.172 |
| Ray tracing | 3.839 / 14.021 / 224.458 | 1,996.230 / 2,690.864 / 657.719 | 6,500.546 / 7,917.639 / 4,976.108 | 509.590 / 495.668 / 506.367 |

Host import alone is not a complete compiler startup comparison: the Bend driver
loads its API lazily during the timed request. Conversely, TypeScript loads its
compiler modules during host import. The measured import-plus-request boundary
includes both. Its candidate medians are 3.19×–4.09× TypeScript here.

Supervised process time additionally includes input hashing, checked-attempt and
cache verification before and after the request, output writing/verification and
process startup. The measured verifier preflight alone has medians around
1.51–1.69 seconds. Process time is the reproducibility harness cost, not a claim
about an ordinary user CLI invocation. Peak RSS likewise includes the verifier
and hashing work; it is not just optimizer memory. Candidate process-tree median
RSS is lower than baseline in all four cases, despite slower requests.

All processes used Node v24.18.0 on CPU3, a 4 MiB stack, a 1 GiB Node heap,
180-second child deadlines, a 2 GiB process-tree ceiling and a 2 GiB host-memory
floor. Timing jobs were serial and used the existing shared execution lock.

## Variability and emitted size

Three rotations cannot establish a precise population effect. The first-to-last
request changes show why the ranges must remain visible:

| Source | Baseline drift | Candidate drift | TypeScript drift |
|---|---:|---:|---:|
| Local pair | +3.12% | +1.32% | +0.01% |
| Mandelbrot | −0.72% | +0.32% | −1.09% |
| Symreg | +0.95% | −3.33% | −1.80% |
| Ray tracing | **+26.80%** | −0.75% | +2.63% |

Ray's baseline samples were 1,793.833, 1,992.469 and 2,274.656 ms. All remain
below the candidate's fastest sample, but the +34.40% median estimate should not
be treated as a stable high-precision ratio. Pair's overlapping ranges support
neither a confident regression nor a claim that compile time is unchanged.

| Source | Baseline module bytes | Candidate bytes | TypeScript bytes | Candidate growth |
|---|---:|---:|---:|---:|
| Local pair | 99,649 | 122,542 | 12,457 | +22.97% |
| Mandelbrot | 110,517 | 114,174 | 15,442 | +3.31% |
| Symreg | 83,895 | 102,304 | 12,815 | +21.94% |
| Ray tracing | 101,349 | 129,177 | 28,974 | +27.46% |

These are complete normal-library outputs, including runtime/public fallbacks.
They differ from the AST program-section sizes in the profile report. Private
workers and guards add output code even when dynamic allocation decreases.

## Why fresh baseline acquisition was necessary

The frozen performance reference used the same Phase32 API but an installed
`selfhost/dist/base.bend`. Normal checked attempts use
`selfhost/.bootstrap/upstream-phase23/bend2/base.bend`. Their Base contents both
hash to `c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661`,
but their directories appear in emitted foreign-binding paths.

Independent byte comparison confirms exactly **45 directory occurrences per
module** account for every difference in all four baseline outputs, adding
1,305 bytes each. No other source/code difference remains. This comparison is
offline cause analysis; **the timed worker does no normalization**. Root
explicitly selected the fresh checked baseline bundle at
`compiler-cost-baseline-preparation09/manifest.json` so each normal request had
an exact expected output. The historical performance corpus remains unchanged.

The fresh baseline still uses API
`8be506d811f627fe6346a5eaba07050c36db70e2704608adcfd781b85a3a7f92`;
the candidate uses checked09 API
`467bc7dec2751a94cb677c5eb2da22a8fb69ee3522c6e164cb2bfcc147a78d82`.
API, runtime, Base, driver, validated cache, upstream source and emitted-output
identities are bound by `compiler-cost-plan09/config.json`. The worker's hash
is unchanged from Phase30:
`f0dea569bdb02df60ed1156b0cead389e197291f1c3a3c6775102c7a03790f42`.
The new planner/runner changes bindings, CPU/resource supervision and role names;
it does not weaken the worker's checked-result or exact-byte assertions.

## Independent admission assessment

Accept these costs as a documented tradeoff for the selected generated-program
improvements, subject to final correctness/release closure. This matches the
[prospective admission rule](../../design/phase35/prospective-admission.md), which
requires explicit review of slower compilation rather than declaring any such
change automatically acceptable. This is not negligible overhead, and the phase
must not claim uniformly faster edit–compile–run iteration.

For the exact fixed benchmark inputs, arithmetic on the separate clean medians
illustrates the tradeoff. Symreg adds 460.653 ms per checked request and saves
91.080 ms per warmed complete call; six such calls cover that request difference.
Ray adds 685.450 ms but saves 8,411.569 ms per warmed complete call; one covers it.
Pair adds 12.022 ms and saves 1.236 ms, giving roughly ten calls, but its compile
effect has overlapping ranges. These are illustrative amortization calculations,
not measured end-to-end totals: they omit initial execution/import behavior and
cannot predict other program sizes or inputs. Mandelbrot has no established
runtime gain here to offset its additional 139.660 ms request cost.

The next work should avoid extending planner search indiscriminately. Instrument
admission/proof visits and cache repeated closed-graph facts before adding more
rules; investigate whether the candidate's unused private helper bodies can be
pruned. The measured runtime targets remain the generic symreg producer and
repeated ray entry guards. Each follow-up should keep this normal checked cost
gate, because faster generated code alone does not guarantee a faster validation
loop. Final release closure is documented in the [independent release assessment](release-assessment.md);
this cost receipt by itself does not authorize a release.
