# Phase35 performance admission

The checked09 compiler improves five complete generated programs with disjoint
observed timing ranges: pair **1.324×**, fold **2.360×**, edit distance **1.278×**,
symbolic regression **6.865×**, and ray tracing **5.475×** versus the same-run
Phase32 baseline. All 15 maintained points complete with their expected results.
The other points do not establish a decisive change. An apparent generic-row
regression was investigated and did not reproduce in a focused confirmation.

The checked09 compiler is **admitted and installed**.
Normal checked requests expose real compiler costs: Mandelbrot increases **8.17%**,
symreg **30.09%** and ray **34.40%**, with disjoint observed request ranges; pair
increases 0.72% with overlap. Root accepts these compile-time costs and the source/
output growth for the five strong generated-program gains. The recorded
[root admission decision](admission-decision.json) was followed by successful
installation, release verification, **42 ordinary/relocated CLI checks** and a
complete **15/15 postinstall audit**. All **225 canonical files** still match
checked09. The complete evidence capsule and its independent reopening pass;
commit and push remain pending at this cutoff.
No production-workload average, stage-two compiler speed or self-hosting fixed
point is established by these measurements.

## Candidate, evidence and decision rules

The candidate is the equality-derived checked B1 in
`selfhost/build/phase35/checked09`, API SHA256
`467bc7dec2751a94cb677c5eb2da22a8fb69ee3522c6e164cb2bfcc147a78d82`.
The reference is Phase32 checked03, API
`8be506d811f627fe6346a5eaba07050c36db70e2704608adcfd781b85a3a7f92`.
TypeScript is pinned to `018751270e800bc222a93dad7f257083ee53a5f7`; all roles share
the maintained source/input identities and canonical Base
`c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661`.

The [campaign design](../../design/phase35/profile-guided-regions.md) asks for at
least 5% improvement with disjoint observed ranges, and investigation of disjoint
regressions over 3%. The [final admission policy](../../design/phase35/prospective-admission.md)
also requires complete expected answers, actual optimization witnesses, final-API
semantic gates, output/source size and separate normal compiler cost. Range
separation is an empirical screen, not a statistical confidence interval.

The [extracted data](performance-admission-data.json) retain exact input report
hashes, all 15 role medians, ranges, raw samples, first-call/import measurements,
within-block drift, classification and static counts. Original evidence is:

- `combined-full-01`: fresh checked candidate preparation for all 15 points.
- `combined-screen-01`: earlier three-point screen; retained separately.
- `combined-full-confirm-01`: all 15 execution points, 518.338 seconds.
- `generic-row-confirm-01`: five-rotation investigation, 17.957 seconds.
- `combined-profiles-01`: 24 CPU/allocation profiles, 149.020 seconds, plus parsed
  syntax and generated-code comparisons.
- `compiler-cost-run09`: 36 normal checked-library requests, all complete/pass,
  250.623 seconds; separate from execution timing.

Every execution/profile job is serial on CPU3, Node 24.18.0, 4 MiB stack, 1 GiB
heap, 1.5 GiB process-tree RSS ceiling and 2 GiB available-memory floor. Timing
does not overlap compilation, acquisition or profiling. The full confirmation
uses five fresh rotated rounds, three warmup calls and at least 1,000 ms warmup,
50 ms calibration and 300 ms timed target. Ray uses three rounds and one complete
warmup call, still subject to the warmup-time floor; each measured full ray call
already exceeds its timed target. No input was reduced to meet the budget.

## Complete maintained execution results

Medians are milliseconds per complete validated call. `Baseline/candidate` above
one means faster; `Candidate/TS` above one means slower than TypeScript. The row
with the observed generic-row regression is deliberately retained unchanged.

| Point | Baseline ms | Candidate ms | TS ms | Baseline/candidate | Candidate/TS |
| --- | ---: | ---: | ---: | ---: | ---: |
| local-pair | 5.046214 | 3.810242 | 1.245898 | **1.324×** | 3.058× |
| local-fold | .330214 | .139925 | .040012 | **2.360×** | 3.497× |
| scalar-region-0 | .005204 | .004780 | .0000937 | 1.089× | 51.030× |
| scalar-region-8192 | .140930 | .140255 | .099790 | 1.005× | 1.406× |
| complete-generic-row32 | .457966 | .501585 | .008288 | **.913×** | 60.520× |
| mandelbrot | .209371 | .208803 | .045655 | 1.003× | 4.574× |
| editdist | 20.700365 | 16.200974 | 4.971906 | **1.278×** | 3.259× |
| tree-bitonic | 25.343514 | 25.393448 | .301794 | .998× | 84.142× |
| lexer | 176.708906 | 172.003185 | 1.929372 | 1.027× | 89.150× |
| symreg | 106.608508 | 15.528781 | 1.107533 | **6.865×** | 14.021× |
| test-morning-program | .230013 | .229581 | .003686 | 1.002× | 62.280× |
| test-evening-program | .180967 | .159571 | .003032 | 1.134× | 52.630× |
| test-rle-roundtrip | .046751 | .046650 | .000601 | 1.002× | 77.588× |
| test-map-set-ops | 1.630668 | 1.624502 | .022470 | 1.004× | 72.296× |
| raytrace | 10291.413844 | 1879.844851 | 34.315384 | **5.475×** | 54.781× |

The five emphasized improvements satisfy both the size and range preference.
Their baseline/candidate ranges, in the same units, are:

| Point | Baseline range | Candidate range |
| --- | ---: | ---: |
| local-pair | 4.907082–5.507771 | 3.776858–4.079386 |
| local-fold | .327716–.364421 | .139039–.145817 |
| editdist | 19.759173–22.196313 | 14.928001–16.259691 |
| symreg | 105.010896–114.482947 | 15.369453–16.394344 |
| raytrace | 10280.215208–10667.956462 | 1853.408856–1925.109364 |

The scalar-zero and evening-program median improvements have overlapping ranges
and are not counted as established wins. Other controls mostly remain near their
baseline median. Map/set has a candidate high sample of 2.109205 ms, above its
baseline range of 1.587057–1.645043 ms; its candidate median is 1.624502 ms. This
outlier remains in the data rather than being filtered away. Tree-bitonic's
0.197% median slowdown also has widely overlapping ranges. There is no disjoint
median regression over 3% in this run.

These 15 fixed points include small mechanism controls, original examples and
test-derived programs. They offer broader transfer coverage than the pair/fold
microbenchmarks, but do not sample an application population. Averaging their
ratios would depend on arbitrary case/input weights; no universal speed ratio is
reported. The zero-work point mostly exposes boundary overhead, while recursive
generic workloads still expose much larger TypeScript gaps. All 15 candidates
remain slower than their same-run TypeScript counterparts.

## Generic-row regression investigation

The full run's ratio of medians suggests about **9.5% more time**, so it was
investigated despite overlapping ranges. The five baseline samples are
`.494837, .499354, .454488, .455775, .457966`; candidate samples are
`.503366, .501585, .503745, .460601, .460034` ms. Both occupy a high and low band,
with their median landing in different bands. Per-rotation ratios have median
approximately 1.011; this is diagnostic information, not a replacement for the
predeclared ratio-of-medians protocol.

Static output comparison found `row.probe`, generic `row`, its emitted callees
and the observation wrapper unchanged. Changed program definitions are the unused
private `pair`/`batch` bodies. Remaining differences are runtime initialization,
`F32.to_u32` capture and unused foreign-path bindings; no new private-region guard
is invoked on this generic-row path. Increased module size can still affect host
compilation/layout, so this observation alone cannot rule out a cost.

The focused five-rotation `generic-row-confirm-01` gives baseline **.453832 ms**
(.450830–.473224), candidate **.455299 ms** (.452969–.461402), TypeScript
**.008466 ms**. Candidate is **0.323% slower**, with overlapping ranges; the
larger slowdown was not reproduced. Retain both runs and accept no source fix on
this evidence. The follow-up still leaves the generic-row program about **53.78×**
slower than TypeScript, so it is a future throughput target rather than a solved
performance gap.

## Mechanisms and diagnostic evidence

The [private-state experiment](../../experiments/phase35/P35-001-private-state.md)
rejects broad helper copying: checked02 passed semantics while pair, scalar and
Mandelbrot regressed sharply. The retained source rule copies only private vector
producers, carries loop fields in locals, uses exact nonescaping Number counters,
and removes native get/set closure wrappers without reordering arguments.

The [direct-region experiment](../../experiments/phase35/P35-002-direct-regions.md)
adds finite native decisions and complete internal scalar paths while retaining
public stages and guarded generic residual calls. The
[fold experiment](../../experiments/phase35/P35-003-private-folds.md) consumes
proved local tagged trees with bounded host-stack usage. Earlier saved-output
gains are mechanism evidence, not extra factors to multiply into the final gains.

The [profile report](profile-findings.md) supplies details and limitations:

| Program | Sampled allocation baseline → candidate, MiB/call | Remaining diagnostic hotspot |
| --- | ---: | --- |
| Pair | 7.619 → .105 | Private row 70.91% CPU self weight, dp 20.00%, arraydata 6.39% |
| Fold | .604 → .036 | Private fold loop 71.40%, surrounding bench 18.76% CPU self weight |
| Symreg | 153.451 → 18.205 | 64.33% CPU sample ancestry in gen/gen.leaf/node; eval/esize down to 9.41% |
| Ray | 15062.026 → 1593.800 | 47.24% CPU sample ancestry in host/scalar/local entry guards |

These are V8 sampled cumulative allocation estimates including reclaimed objects,
not exact allocated bytes, retained heap, simultaneous RSS or throughput ratios.
Ray's candidate allocation-profile process peaks near 86.8 MiB RSS despite its
large cumulative allocation. Profiles ran separately: four programs × three
roles × CPU/allocation, 24/24 complete, 1,000 µs CPU sampling, 32 KiB allocation
sampling except 256 KiB for ray, 400 ms warmup and 1.5-second target. Ray has one
full call per profile, so its percentages are not repeated estimates.

Pair/fold now sample less allocation than TypeScript yet remain about 3–3.5×
slower in clean timing. Allocation removal worked; remaining loop operations,
backing-array validation and numeric representation deserve separate tests.
Symreg points to producer dispatch; ray points to repeated internal entry guards.
Removing public guards is not an admissible optimization. Larger proved internal
regions may amortize them while retaining public mutation fallback.

## Complexity and emitted-code cost

[Complexity counts](complexity.json) use the selected compiler-module inventory:

| Metric | Phase32 baseline | Checked09 | Change |
| --- | ---: | ---: | ---: |
| Bend compiler modules | 66 | 68 | +2 |
| Physical lines | 17071 | 18050 | +979, 5.7% |
| Nonblank lines | 14580 | 15436 | +856, 5.9% |
| Definitions | 1884 | 2008 | +124, 6.6% |
| Laws | 640 | 640 | 0 |
| Types | 70 | 71 | +1 |

This phase is **not a source simplification**. Those counts cover selected Bend
compiler modules, not runtime JavaScript, controls, experiments or documentation.
Line counts do not measure proof complexity. New concepts include bounded vector
inlining and destination slots, a counter nonescape predicate, finite decision
lowering, guarded floating/conditional regions, a shared typed purity graph and
structural-fold plans. They reuse the existing checked core/private-region model;
there is no new general SSA or alternate public ABI. Their maintenance cost still
needs to be weighed against the measured execution gains.

Parsed generated-program sections exclude shared runtime and export wrappers:

| Program | Baseline bytes | Candidate bytes | Change | TS bytes |
| --- | ---: | ---: | ---: | ---: |
| Pair | 44189 | 64730 | +46.5% | 6025 |
| Fold | 22250 | 24557 | +10.4% | 1033 |
| Symreg | 28030 | 44087 | +57.3% | 6728 |
| Ray | 46205 | 71681 | +55.1% | 21214 |

Whole modules grow 24.6%, 7.8%, 23.9% and 29.1%, respectively. Public fallbacks
remain while private bodies are added. Therefore static function/array sites can
increase while dynamic allocation falls. Pair retains 26 private declarations
with no direct calls under their names, totaling 21,160 bytes; fold retains five,
1,783 bytes. This is a reachability-audit opportunity, not yet a deletion proof:
lexical references, bridge partners and guard dependencies must remain correct.

## Normal checked compiler cost

The complete [compiler-cost comparison](compiler-cost.md) uses the unchanged
maintained checked-library worker: four sources × TypeScript/baseline/candidate
× three fresh rotated processes, **36/36 complete and passing**. Bend requests
use each checked compiler's validated Base cache and normal `inspect(...,
mode: library)` pipeline. TypeScript performs its normal source load, validity
check and library emission. Every resulting module matches an independently
acquired checked output byte for byte. These are full requests, not emission-only
timings or a reused frontend intermediate representation.

| Source | Baseline request ms | Candidate request ms | TS request ms | Candidate change | Candidate/TS |
| --- | ---: | ---: | ---: | ---: | ---: |
| Pair | 1669.819 | 1681.841 | 311.867 | +0.72% | 5.393× |
| Mandelbrot | 1709.781 | 1849.441 | 341.413 | **+8.17%** | 5.417× |
| Symreg | 1531.111 | 1991.764 | 299.518 | **+30.09%** | 6.650× |
| Ray | 1992.469 | 2677.918 | 433.017 | **+34.40%** | 6.184× |

Pair request ranges overlap (baseline 1617.855–1721.945 ms; candidate
1669.065–1704.072 ms). The other increases are disjoint: Mandelbrot
1707.827–1720.134 versus 1837.048–1855.329 ms; symreg 1522.639–1537.152 versus
1966.559–2034.365 ms; ray 1793.833–2274.656 versus 2657.957–2884.912 ms. This
cost is not negligible. Mandelbrot gets no established generated-execution gain
while its compilation pays for broader analysis; it is the clearest cost-control
target for a later narrow eligibility or planning-cache experiment.

Ray's baseline requests drift from 1793.833 to 2274.656 ms across three samples
(26.8% increase); its candidate range remains disjoint. The 34.40% figure is the
recorded ratio of medians, not a high-precision portable overhead estimate.

Cold host import is separate: baseline Bend medians are 3.70–3.84 ms, candidate
12.79–14.02 ms, and TypeScript 218.57–224.46 ms. Bend's lazy compiler API loading
and normal cache handling remain inside the request boundary. Thus request-only
and import-plus-request ratios answer different questions; neither should be
silently substituted for the other.

| Source | Baseline full process s | Candidate full process s | Baseline median peak RSS MiB | Candidate median peak RSS MiB |
| --- | ---: | ---: | ---: | ---: |
| Pair | 5.896 | 6.059 | 508.7 | 490.2 |
| Mandelbrot | 6.020 | 6.227 | 508.7 | 490.8 |
| Symreg | 5.798 | 6.372 | 506.2 | 490.4 |
| Ray | 6.501 | 7.918 | 509.6 | 495.7 |

Full-process times include fresh-process startup, strict attempt/cache/input
verification, compilation and output checks; they are supervised experiment
latency, not pure compiler throughput. RSS is the supervisor's process-tree
measurement, not V8 heap allocation. All jobs retained CPU3, 1 GiB Node heap,
2 GiB process-tree ceiling and 2 GiB available-memory floor. Ray's wider process
spread remains in the raw evidence. Lower peak RSS does not negate added latency.

The cost comparison prepares fresh baseline outputs against its actual upstream
Base location, preserving exact byte checks. The portable execution reference
was acquired from an installed Base location, so its whole-module byte counts
also include different absolute foreign binding paths. Keep those byte scopes
separate; the static program-section growth above is from the paired profile
modules. No expected output was normalized to make compiler-cost checks pass.

## Admission and release closure

Root accepts the performance tradeoff: five substantial transfers with disjoint
ranges, complete answers on all
15 points and no reproduced generated-program regression, in exchange for the
measured compile latency and source/output growth. This does not classify the
compile regressions as wins, or establish a faster stage-two compiler. Runtime
and compilation are separate objectives, with both results retained.

| Gate | Status at this report cutoff |
| --- | --- |
| Fresh checked09 preparation and 15-point execution | Complete |
| Focused generic-row regression investigation | Complete; large slowdown not reproduced |
| Final CPU/allocation profiles and static comparisons | Complete; diagnostic scope only |
| Source/output complexity accounting | Complete; growth accepted only as an explicit tradeoff |
| Exact final-API preinstall semantic/provenance closure | Complete: 14/14 groups, 225 canonical files; `final-audit09-preinstall-v2` |
| Normal checked compiler requests: pair/Mandelbrot and symreg/ray | Complete, 36/36; +8.17%/+30.09%/+34.40% disjoint request costs accepted explicitly |
| Installation, installed verification and 42 CLI checks | Complete; installed API is exactly checked09 |
| Postinstall provenance audit | Complete: 15/15 groups, 225 canonical files; `final-audit09-postinstall` |
| Durable evidence capsule and independent reopening | Complete: 24,717 files, two volumes, 52,475,156 compressed bytes |
| Final commit and push | Pending root consolidation |

The roughly 42.5-second checked09 build is a bounded acquisition observation,
separate from the completed rotated request comparison. Preinstall and
postinstall correctness/provenance are closed, including the installed CLI
checks. Known historical shared failures and the stated backend/GPU/proof-kernel
limits remain; this scoped release does not turn them into passes. The completed
[capsule](evidence/manifest.json) and [capture receipt](evidence/capture.json)
retain all closed Phase35 raw files, including failures. Root retains
responsibility for the final commit and push.
