# Final generated-program profiles and next opportunities

The new compiler removes most state-container allocation and much generic call
work. The next bottlenecks differ by workload: repeated entry guards dominate
ray tracing, generic tree production dominates symbolic regression, and the
already direct array loops dominate pair/fold. Continuing to optimize the old
eval/size or temporary-state paths would miss most remaining work.

This analysis reads root's completed `combined-profiles-01`: **24/24 profiles**,
four unchanged programs × baseline/candidate/TypeScript × CPU/allocation, in
149.020 seconds. The candidate is checked09 API
`467bc7dec2751a94cb677c5eb2da22a8fb69ee3522c6e164cb2bfcc147a78d82`;
upstream is pinned to `018751270e800bc222a93dad7f257083ee53a5f7`.
The [summary](profile-evidence-summary.json) retains input hashes, static metrics,
profile samples, warnings and the separate clean timing evidence.
[profile-extract.py](profile-extract.py) reproduces it by reading artifacts only.

## Clean timing and sampled allocation

Speed numbers below come from the separate completed 600-second-budget
`combined-full-confirm-01`, which finished all 15 selected points in 518.338
seconds. They do not divide profiler loop times. These four are the diagnostic
subset, not the complete representative corpus.

| Program | Baseline ms | Candidate ms | TypeScript ms | Baseline/candidate | Candidate/TS |
|---|---:|---:|---:|---:|---:|
| Local pair | 5.046 | 3.810 | 1.246 | 1.32× | 3.06× |
| Local fold | 0.330 | 0.140 | 0.040 | 2.36× | 3.50× |
| Symreg | 106.609 | 15.529 | 1.108 | 6.87× | 14.02× |
| Ray tracing | 10,291.414 | 1,879.845 | 34.315 | 5.47× | 54.78× |

Allocation numbers are V8 **sampled cumulative allocated-byte estimates per
validated call**, including collected objects. They are not retained heap, RSS,
exact byte counts, allocation event counts or speed ratios.

| Program | Baseline MiB/call | Candidate MiB/call | TypeScript MiB/call | Estimated reduction |
|---|---:|---:|---:|---:|
| Local pair | 7.619 | 0.105 | 4.045 | 72.7× |
| Local fold | 0.604 | 0.036 | 0.253 | 16.7× |
| Symreg | 153.451 | 18.205 | 0.434 | 8.43× |
| Ray tracing | 15,062.026 | 1,593.800 | 8.134 | 9.45× |

Ray tracing's cumulative allocation estimate is large, but the candidate
allocation-profile process peaked at about 86.8 MiB RSS; the baseline peaked at
about 508.0 MiB. Reclaimed allocation must not be mistaken for simultaneous
memory demand. Pair/fold now allocate much less than TypeScript in these samples
while still taking roughly three times as long: further throughput work must
address their loop operations and representation, not infer speed from bytes.

All jobs were serial on CPU3, with 1 GiB Node heaps, a 1.5 GiB process-tree ceiling
and 2 GiB available-memory floor. CPU sampling used 1,000 µs intervals; allocation
sampling used 32 KiB except ray tracing's 256 KiB. The target was 1.5 seconds after
400 ms warmup. Ray tracing required only one complete call per profile because
each call exceeded the target. Its percentages are one diagnostic observation,
not repeated confidence intervals. V8 sample totals and call-tree allocation
estimates differ; the analyzer retains both and attributes sampled bytes only.
Three profiles retain one unattributed allocation sample each (35,136, 37,440
and 34,136 estimated bytes); none is silently assigned a convenient caller.

## What moved in the hot paths

**Pair/fold state removal worked.** Pair's baseline sampled allocation was mainly
`cell.f4` (65.09%) and `row` (33.15%). Candidate CPU self weight is instead 70.91%
in private `row`, 20.00% in `dp`, and 6.39% in `arraydata`; garbage collection
falls from 4.37% to 0.07%. In local fold, the former `fold.step` allocation share
was 82.96%; the candidate spends 71.40% CPU self weight in the direct `fold.loop`
and 18.76% in its surrounding bench body. Candidate GC is 1.04%, versus 6.20%
baseline. The remaining loop-owned sampled allocation does not establish which
object or numeric boxing operation caused it; that needs a discriminating test.

**Symreg's producer is now the main target.** Baseline CPU self samples are
dominated by `apply` (29.22%), `invokeExact` (13.77%), runtime matcher callbacks
(12.23%), `force` (6.81%) and `callOwned` (6.73%). After private folds, the explicit
eval worker is only 8.25% of candidate CPU self weight. Generic dispatch remains,
with `apply` 19.30%, `force` 9.03%, `invokeExact` 8.83% and `callOwned` 8.21%.

To distinguish their callers, the extractor walks each raw CPU sample's ancestry
and counts that sample at most once for a group, even through recursive frames:

| Symreg ancestry group | Baseline sample weight | Candidate | TypeScript |
|---|---:|---:|---:|
| `gen`, `gen.leaf` or `node` | 10.32% | **64.33%** | 14.19% |
| `eval` or `esize` | 74.48% | **9.41%** | 77.14% |
| Host/scalar/local guards | 0.00% | 11.14% | 0.00% |

Groups are unions within each group and may overlap across groups. This is not a
sum of recursive inclusive-frame percentages. The result does not mean the
producer became slower; its share grew after consumer dispatch was removed.
Candidate sampled allocations also point to production: `gen` 23.70%, `node`
18.25%, and `gen.leaf` 9.13%, together **51.07%** of exclusive allocated-byte weight.
The existing tagged tree layout can remain while the producer's saturated calls
and constructor dispatch become private.

**Ray tracing now pays heavily for repeatedly proving the same entry conditions.**
Baseline CPU self weight in `apply` was 48.15%, followed by matcher callbacks
17.27%, `callOwned` 7.58%, `invokeExact` 5.50% and `force` 5.45%. Candidate self
weight instead includes `regionHostGuard` **26.43%**, `scalarGuard` **15.70%**, and
`localGuard` **3.58%**, totaling **45.71%**. A raw-sample ancestry union attributes
**47.24%** to those guards including their sampled callees. `apply` still takes
14.44%, and `enterExact` 4.94%; arithmetic `nearest` owns 4.88%.

Candidate ray allocation estimates place 38.07% in `getOwnPropertyDescriptor`,
9.87% in `getOwnPropertyNames`, and 9.70% in `scalarGuard`: **57.64%** combined
exclusive weight. The new conservative prototype-name guard is semantically
necessary for pure residual regions, but calling it repeatedly through already
proved internal transitions is now expensive. Removing public guards would
discard the mutation protections just tested. The opportunity is to share one
proved entry across a larger closed internal call chain.

## Static output grew; retain this cost explicitly

These are program-section bytes from the parsed AST boundary, excluding the
shared runtime prefix and library export wrapper. They include generic fallback
definitions, private copies and other program support. They are static syntax,
not executed work or a source-compiler line count.

| Program | Baseline program bytes | Candidate | Growth | TypeScript |
|---|---:|---:|---:|---:|
| Local pair | 44,189 | 64,730 | 46.5% | 6,025 |
| Local fold | 22,250 | 24,557 | 10.4% | 1,033 |
| Symreg | 28,030 | 44,087 | 57.3% | 6,728 |
| Ray tracing | 46,205 | 71,681 | 55.1% | 21,214 |

Whole-module growth is smaller (24.6%, 7.8%, 23.9%, 29.1%). Static array-literal
and generic helper counts do not necessarily shrink because public fallbacks
remain and private bodies are added. The dynamic allocation profiles establish
that hot paths avoided most of those constructions; syntax counts alone would
have reached the wrong conclusion about execution.

There is a concrete simplification candidate: 26 emitted private pair helper
declarations, totaling **21,160 bytes**, have names with no direct-call sites
anywhere in that module. Local fold has five such declarations totaling **1,783
bytes**. Their bodies survived bounded inlining. These counts are an opportunity
inventory, not a deletion proof: check lexical references/escapes and each private
region's reachable call graph first. Remove only unreachable emitted bodies,
while retaining their public dependency identities in the enclosing guard.

## Ranked next experiments

| Rank | Experiment | Evidence and cheapest discriminator | Main correctness/complexity boundary |
|---|---|---|---|
| 1 | Saturate the closed symreg producer graph | 64.33% of candidate CPU samples descend from `gen`/`node`/`gen.leaf`. In saved output, change only those producers; retain tagged trees, current consumers and original full benchmark. | Preserve constructor/child demand and sharing; production must handle depth safely and preserve public producer mutation fallback. Moderate extension of the existing purity/region proof. |
| 2 | Amortize guards across proved private ray calls | Guard ancestry is 47.24%; descriptor/name checking owns much allocation. A private clone or explicit internal entry proof can test one enclosing check while keeping every public wrapper. | Proof must cover every residual callee and host callback; reentry, exceptions and post-import mutation cannot inherit unauthorized entry. Avoid a global unchecked switch. Moderate-to-high proof work. |
| 3 | Carry backing-array facts through pair/fold loops | Direct loops now dominate, and pair `arraydata` alone has 6.39% self weight. A saved-output ablation hoists validated backing-array access and removes redundant Number conversion only for canonical U32 indices. | Aliases, native get/set identity, wraps/modulo, initial zero and array read/write order. Do not infer object kinds from sampled allocation owner names. Moderate proof/data-flow work. |
| 4 | Prune private helper bodies made unreachable by inlining | Pair has 21,160 bytes of declarations with no direct call under their names. Use a lexical reference/region-reachability audit, then emit only live bodies and compare exact controls. | Keep guard dependencies even when code bodies disappear; read-adapter partners and nested scopes must stay correct. Small bounded graph pass; code-size benefit measurable before timing. |

These rankings are evidence-based choices, not promised gains. As an illustrative
upper bound, deleting all work in a 64.33% CPU ancestry group with no replacement
cost gives about 2.8× overall; deleting 47.24% gives about 1.9×. Real producer and
guard implementations retain work, and JIT/GC interactions can change the profile.
The bounds explain why these are worthwhile experiments without predicting that
either will close the full TypeScript gap.

For each, keep the existing cheap mechanism point plus admission witness, then
run the relevant original program and the final mutation controls. Wider 300/600
second confirmation follows only a clear bounded screen win. The raw artifacts
include profiles, analyzer input, comparison HTML, normalized tokens, failed
attempts and the exact final checked source. The [preservation receipt](evidence/README.md)
records whether these ignored build files have been captured durably.
