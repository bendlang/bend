# Phase32: cheaper private values, bounded experiments

[Design](../../design/phase32/representation-and-reuse.md). Baseline: Phase31
checked07 at `5f3015d`. Target: upstream `0187512`, after Bend 2.0.34.

Candidate03 combines statement unpacking, typed immediate-read bridges and
private field vectors. It adds 57 Bend lines (0.335%), six functions, two private
plan tags, and no datatype or module. The runtime and driver are unchanged.
**Checked03 is installed and verified; all declared integration and 42 ordinary/relocated CLI checks pass.** See the [release record](release-03.md),
[gate closure](final-conformance/gates.md) and [installation receipt](release-installation.json).

## Measured results

| Same-source generated program | Previous, ms | Candidate, ms | Improvement | Candidate / TypeScript |
| --- | ---: | ---: | ---: | ---: |
| Original four-pair edit distance | 72.266 | 20.398 | 3.54× | 4.09× |
| Complete single pair | 18.535 | 4.925 | 3.76× | 3.78× |
| Independent array fold | 0.651 | 0.329 | 1.98× | 8.13× |

The original edit-distance gap falls from 14.49× to 4.09× TypeScript in the same
window. Original Mandelbrot and RLE emit exactly the previous JavaScript bytes;
their timing ranges overlap. All three mixed/scalar regression canaries also
overlap. These selected workloads do not define average generated-program speed.

Compiler throughput does not improve generally. Mandelbrot compilation adds
36.75 ms (1.91%, disjoint ranges); edit-distance compilation changes by −0.45%
with overlap. The candidate's request-only TypeScript gaps remain about 5.56×
and 4.90× respectively. Import, first-call, warmup drift and process costs stay
separate. One candidate fold sample still improves 27% between its measured halves;
the reports retain that drift rather than claiming steady state.

Read the [checked local ablations](local-representation.md),
[audited local confirmation](local-checked-confirmation.md),
[original-program and compiler measurements](final-measurements/measurements.md),
and [source/concept/generated-size accounting](local-complexity.md).
The [selection decision](../../design/phase32/admission.md) explicitly accepts
the small compilation, source-size and generated-size costs, with the required release validation now complete.

## Findings from all four investigations

- **Local representation:** all three checked increments improve both selected
  fixtures with disjoint adjacent ranges. The change preserves ordered native
  events and public behavior. The last increment includes direct canonical
  Sigma construction; fold has no ordinary record-shell change.
- **Structured checker:** private projection experiments improve selected H17
  helpers 1.44–1.76×, but executable getter/mutation witnesses block applying the
  shortcut to the public API. [Results and boundary](checker-private-fields.md).
- **Semantic reuse:** dependency-complete checkpoints preserve 22 tested
  observations and skip substantial work, but comparison and retention cost too
  much in normal library requests. No production cache was added.
  [Results and coverage limits](reuse-counts.md).
- **Compact analysis:** repeated queries exist, but global wrappers and scoped
  4k/16k memo tables fail their prospective performance criteria. A new compiler
  IR is not justified by these experiments. [Results](compact-counts.md).

A further [stop-list reuse probe](compact-stop-reuse.md) finds an attractive
duplicate API query. Its proposed default-API ownership check fails a concrete
mutation witness, so it remains an experiment. A private source-only worker
boundary is a future hypothesis, not an installed feature.

## Correctness, memory and preservation

The candidate passes its 36 focused checked-build tests and six added control
groups: complete pair state and 328,966 native events, fold oracles, actual read
ordering, nested scope, public boxed records/aliases, and compiled layout
predicates. [Independent review](review-vector03.md) and
[exact gate identities](review-local-gates.json) record the scope. Fresh 3,026 + 196 frontend observations match the pinned
TypeScript references exactly. The backend preserves 69 passes / 8 N/A / 4 shared
failures through an explicit 60 + 21 native-context retry; original permission
failures remain recorded. All inherited corpus/component/HVM and 42 installed/
relocated CLI checks pass. Counts overlap and are not a unique test total.

All resumed compiler builds, acquisitions and benchmarks run serially under
explicit heaps, process-tree RSS limits, deadlines and a 2 GiB free-memory floor.
Checked builds take about 40 seconds with one worker and a 1 GiB heap setting.
Independent [supervisor controls](supervisor-controls.md) verify memory/deadline
termination and child cleanup, including the polling overshoot limitation.
Current resource counters do not establish the previous interruption's cause.

The verified [evidence capsule](evidence/README.md) preserves 20,807 raw files,
including failed and superseded attempts, exact consumed tools and measurements. The 103 unrelated starting files remain protected. The [installation receipt](release-installation.json) binds the installed API
and all 42 CLI checks. The [final protection audit](protected-files-final.json) and
[independent release review](independent-release-review.md) close preservation
and release scope. No new self-emitted H fixed point, GPU or independent
proof-kernel conformance is claimed.
