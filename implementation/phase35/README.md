# Phase35: faster generated programs through private representations

**Checked09 is installed and verified.** All 14 preinstall groups, 42 ordinary/
relocated CLI checks and the final 15-group postinstall audit pass; all 225
canonical files match. The [release record](release-09.md) and
[independent review](release-assessment.md) bind the completed gates and scope.

The unchanged maintained benchmark now measures **6.865× faster symbolic
regression, 5.475× faster ray tracing, 2.360× faster array fold, 1.324× faster
pair kernel, and 1.278× faster original edit distance** than the frozen Phase32
compiler, in the same run. All fifteen outputs agree. None of these final
workloads beats the pinned TypeScript compiler. This is a set of fixed algorithms,
mixed tests and diagnostics, not an estimate of average production performance.

[Design](../../design/phase35/profile-guided-regions.md) ·
[literature](../../design/phase35/literature.md) ·
[performance admission](performance-admission.md) ·
[compiler cost](compiler-cost.md) ·
[profiles and next targets](profile-findings.md) ·
[tools](../../selfhost/tools/performance/phase35/README.md) ·
[evidence preservation](evidence/README.md)

## Final generated-program measurements

`combined-full-confirm-01` completes **15/15 points in 518.338 seconds**. CPU3,
Node 24.18.0, serial fresh processes, balanced role order, 1,000 ms warmup and
300 ms measurement target. Fourteen points have five rotations; full raytrace
has three. Invocation, exact result validation and checksum work are included;
module import and first-call times are separate. TypeScript and baseline outputs
are the unchanged portable Phase34 reference, verified by content identity.
All candidate outputs were freshly checked and emitted by checked09.

| Fixed input | Phase32 ms | Phase35 ms | TypeScript ms | Phase35 speedup | Phase35 / TS |
|---|---:|---:|---:|---:|---:|
| Pair kernel | 5.046214 | 3.810242 | 1.245898 | 1.324× | 3.058× |
| Independent array fold | 0.330214 | 0.139925 | 0.040012 | 2.360× | 3.497× |
| Scalar zero | 0.005204 | 0.004780 | 0.00009368 | 1.089× | 51.030× |
| Scalar 8192 | 0.140930 | 0.140255 | 0.099790 | 1.005× | 1.406× |
| Complete generic row32 | 0.457966 | 0.501585 | 0.008288 | 0.913× | 60.520× |
| Mandelbrot | 0.209371 | 0.208803 | 0.045655 | 1.003× | 4.574× |
| Original edit distance | 20.700365 | 16.200974 | 4.971906 | 1.278× | 3.259× |
| Tree bitonic | 25.343514 | 25.393448 | 0.301794 | 0.998× | 84.142× |
| Lexer | 176.708906 | 172.003184 | 1.929372 | 1.027× | 89.150× |
| Symbolic regression | 106.608508 | 15.528781 | 1.107533 | 6.865× | 14.021× |
| Morning mixed test | 0.230013 | 0.229581 | 0.003686 | 1.002× | 62.280× |
| Evening mixed test | 0.180967 | 0.159571 | 0.003032 | 1.134× | 52.630× |
| RLE roundtrip | 0.046751 | 0.046650 | 0.000601 | 1.002× | 77.588× |
| Map/set operations | 1.630668 | 1.624502 | 0.022470 | 1.004× | 72.296× |
| Full raytrace | 10,291.413844 | 1,879.844851 | 34.315384 | 5.475× | 54.781× |

The five headline gains exceed 5% and have disjoint observed ranges. The smaller
or overlapping changes are not established improvements. In particular, the
full-run generic-row ratio of medians is 9.52% slower with overlapping bimodal
samples. The required separate five-rotation investigation takes 17.957 seconds:
0.453832 → 0.455299 ms, only **0.323% slower**, with overlapping ranges. Its
executed functions are unchanged after normalizing the unused foreign path.
This does not erase the initial observation or establish that a regression was
fixed. Both reports, all samples and warmup drift remain available.

See [full table](measurements/full.md), [generic-row recheck](measurements/generic-row-recheck.md)
and [identities/statistics](measurements/summary.json). The separate three-case
screen takes **22.961 seconds**, with pair/fold/symreg gains of 1.310×/2.570×/7.087×.
Its shorter warmup produces different absolute times; use its own denominators.

## What changed and why it works

The useful compiler-theory connection is **worker/wrapper plus scalar
replacement**: preserve public calls and data, prove a bounded private region,
then remove representation and dispatch work inside it. The literature study
used primary LLVM, MLton, GHC, Flambda2 and stream-fusion implementations/papers;
it informed the experiments but does not prove our local JavaScript ABI rules.
The previous Zig study informs the fast experiment loop, not a runtime speed claim.

1. **Selective vector producer inlining and scalar state.** Immediately consumed
   vector fields become local loop slots with ordered old-value temporaries.
   Temporary result arrays disappear; underlying array handles, aliases and
   writes remain. Broad scalar-helper inlining was rejected after large slowdowns.
2. **Private countdown and array access.** A nonescaping Nat predecessor with
   one self-tail use can use a captured Number conversion and an exact local
   counter. Zero is handled before conversion. Public Nat values remain intact;
   observed, stored or multiply used predecessors refuse the optimization.
   Private array get/set calls omit proved erased slots without changing live
   argument order; array creation retains its ordering wrapper.
3. **Larger direct regions.** Complete finite Nat decisions, F32 arithmetic and
   final Boolean recursive transfers compile into direct expressions, branches
   and loops. Public stages, rounded operations and delayed record fields remain.
4. **Independent purity proof.** `jpure.bend` checks a complete reachable helper
   graph before permitting a generic residual call inside the private region.
   Failure to lower a helper is never evidence that it is pure. Bounds cover
   graph size, nodes, depth, type work and shared analysis fuel. IO, function and
   native-array fields, foreign calls and unsupported dependent data refuse.
5. **Closed structural folds.** `fold.bend` recognizes a small complete U32-result
   structural fold over a closed sum, using an explicit postorder stack and
   preserving child demand order. It removes repeated curried tree elimination
   without replacing the tagged data or generic generator. Shared trees and deep
   chains retain their semantics; no fixed depth or JavaScript recursion is used.

The runtime captures relevant intrinsics, checks host descriptors and prototype
keys before entry, and preserves generic fallback. Numeric prototype additions,
Number hooks, delayed fields, callback effects and partial entry have explicit
controls. These controls assume the documented standard host at initialization
and cover the named post-import mutations; they are not a universal equivalence
proof for arbitrary modified JavaScript environments.

Details: [private state](private-state.md), [direct regions](direct-regions.md),
[branch review](branch-review.md), [sum review](sum-review.md),
[independent review](independent-review.md), and the production
[architecture](../../selfhost/docs/ARCHITECTURE.md).

## Profiles explain the gains and the remaining gaps

The separate final diagnostic run completes **24/24 CPU/allocation profiles in
149.020 seconds**, with peak supervised RSS 532,652,032 bytes. Timing above is
uninstrumented. CPU samples and sampled cumulative allocations have their own
warmup/interval limits and are not exact operation counts or retained heap size.

| Program | Phase32 sampled MiB/call | Phase35 sampled MiB/call | TS sampled MiB/call |
|---|---:|---:|---:|
| Pair | 7.619 | 0.105 | 4.045 |
| Fold | 0.604 | 0.036 | 0.253 |
| Symbolic regression | 153.451 | 18.205 | 0.434 |
| Raytrace | 15,062.026 | 1,593.800 | 8.134 |

Allocation falls by about 73× for pair, 17× for fold, 8.4× for symreg and 9.5×
for raytrace. Pair/fold allocate less than TypeScript in these samples but still
run slower. Allocation reduction alone is not sufficient.

The profiles suggest the next experiments in this order:

- **Amortize guards across a proved ray region.** Guard ancestry covers 47.24% of
  candidate CPU samples; descriptor/name inspection and scalar guards account
  for 57.64% of sampled allocation. Share a proof only across calls that cannot
  invalidate it; retain callback, reentry, exception and mutation boundaries.
- **Lower the private symreg producer.** Eval/size ancestry falls from 74.48% to
  9.41% of CPU samples, while generator ancestry rises to 64.33%. More consumer
  tuning misses the new dominant cost. Keep generation/demand order and aliases.
- **Carry private array/index facts farther.** Pair/fold now spend most sampled
  CPU in their actual private loops. Test bounds/backing-array facts on the small
  complete-state fixtures before original edit distance.
- **Remove demonstrably unused private helper declarations.** Several generated
  helpers have no direct call, but some identifiers remain guard dependencies.
  This is a size experiment, not proof that arbitrary declarations can be deleted.

These are hypotheses for the next phase, not implemented gains. The detailed
[profile report](profile-findings.md) links a reproducible read-only extraction
and separates self samples, ancestry unions, allocation attribution and syntax.

## Negative results and experiment history

| Attempt or experiment | Outcome |
|---|---|
| checked01 | Parser failure, preserved |
| checked02, broad scalar/vector inlining | Focus36 passes; pair 1.67× slower, long scalar 4.20× slower, Mandelbrot 2.09× slower; rejected |
| checked03, selective vectors and state | Focus36 passes; pair/fold/edit-distance screens improve |
| checked04, F32/finite Nat/final Bool | Focus36 passes; full raytrace only 1.091× faster, still 240.323× TS |
| checked05, private Number counter | Focus36 passes; included in later combined acquisitions |
| checked06, purity analyzer | Parser failure at let before immediate match, preserved |
| checked07, matcher helper repair | Focus36 passes; partial regions and direct arrays; all fifteen points emitted |
| checked08, structural folds | Focus36 passes |
| checked09, prototype-key guard/frame bounds | Selected; Focus36 passes, all fifteen points emitted and measured |
| Sum loop alone | Essentially no gain: 110.844 → 110.485 ms |
| Direct tagged-tree sum consumption, saved output | 109.263 → 20.223 ms, 5.40×; motivated actual compiler fold |
| Inactive-column diagnostic, saved output | About 125.5×; deliberately narrow, not full-ray speed |
| Partial column traversal, saved output | Full ray 9,152 → 5,826 ms, 1.571×; actual combined compiler now improves further |

The first sum guard used `===` on NaN and never entered its proposed private
path. Correct outputs established only fallback correctness. An independent
entry witness caught this; the corrected prototype uses captured `Object.is`.
Both producers and the failed witness remain preserved. Parser/fixture errors,
null experiments, regressing candidates and the sandbox EPERM acquisition failure
also remain; retries use new directories and retain original failures.

## Complexity, compiler cost and release gates

Compiler source grows from **17,071 to 18,050 physical Bend lines (+979, 5.73%)**,
14,580 to 15,436 nonblank lines, 1,884 to 2,008 definitions, 70 to 71 types and
66 to 68 modules. The 640 laws are unchanged. These counts exclude generated
images, runtime JavaScript and experimental tools. This phase improves generated
execution at a real source-complexity cost; it is not a simplification result.

Program-section bytes grow 46.5%/10.4%/57.3%/55.1% for pair/fold/symreg/ray;
whole modules grow 24.6%/7.8%/23.9%/29.1%. The public bodies remain alongside
private workers and guards. Exact counts are in [profile evidence](profile-evidence-summary.json).

The selected checked build plus 36 focused checks takes **42.506 seconds** and
peaks at **1,129,676,800 process-tree bytes**. That is one bounded development
acquisition, not a controlled compiler-throughput result. The separate [normal compiler-cost comparison](compiler-cost.md) records
+0.72% request time for pair (overlap), +8.17% for Mandelbrot, +30.09% for symreg
and +34.40% for raytrace (disjoint ranges on the latter three). All 36 outputs
match independently checked bytes. These costs and source/output growth are
[explicitly accepted](performance-admission.md) for the runtime gains. The
[release record](release-09.md) closes final semantics, installation and CLI. Checked09 is a maintained checked B1 derivative, not a newly
self-emitted fixed point. The upstream pin remains `018751270e800bc222a93dad7f257083ee53a5f7`.

The final plan keeps exact historical frontend/backend assertions, requires all
15 new owner groups to reach the selected API through their hashed provenance,
and independently verifies canonical source equality. Main/shared failures and
backend N/A outcomes stay failures/N/A. No full backend, GPU, independent
proof-kernel, stage-two-speed or universal performance claim follows.

## Reproduce the fast loop

Use the [maintained benchmark guide](../../selfhost/tools/performance/programs/README.md)
and [diagnostics](../../selfhost/tools/performance/programs/DIAGNOSTICS.md). Prepare
a candidate once after a checked compiler build, then use the unchanged portable
baseline and TypeScript outputs. `--budget 20/60/300/600` sets a ceiling;
`--set` and `--cases` independently choose coverage. A budget never requests padding.
The three-case `local-pair,local-fold,symreg` 60-second screen took 22.961 seconds;
full ray remains an integration check. Run profiles separately from timing.

Only one heavy job runs at a time: one worker, CPU3, explicit ≤1 GiB Node heaps,
a shared execution lock, process-tree RSS/deadline limits and a 2 GiB free-memory
floor. Root coordinates execution while agents research, review and write code.
The [phase tools map](../../selfhost/tools/performance/phase35/README.md) distinguishes
actual compiler gates from saved-output experiments. Preserve every failed run.
The [evidence capsule](evidence/README.md) records preservation of the complete
Phase35 raw tree in bounded volumes with member-by-member reopening after all
writers close. The 103 unrelated starting files are protected separately.
