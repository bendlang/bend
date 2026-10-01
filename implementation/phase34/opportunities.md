# Current generated-program results and the next experiments

The installed compiler remains Phase32 checked03. The new execution suite's
[complete Phase33 comparison](../phase33/measurements/600s.md) measures the same
fifteen points against pinned upstream TypeScript in one serial run. The baseline
API is `8be506d811f627fe6346a5eaba07050c36db70e2704608adcfd781b85a3a7f92`;
the upstream pin is `018751270e800bc222a93dad7f257083ee53a5f7`.

This note ranks opportunities from those clean timings, inspection of their exact
generated modules, and the new fast/full profiles. Profile attribution does not
assign a causal percentage of the performance gap to an individual mechanism.
No compiler optimization is implemented by this diagnostics phase.

## Current execution results

| Original program | Our output, ms/call | TypeScript output, ms/call | Ours / TypeScript |
|---|---:|---:|---:|
| Edit distance | 15.1477 | 4.95993 | 3.054× |
| Mandelbrot | 0.189116 | 0.0454744 | 4.159× |
| Tree bitonic sort | 19.564 | 0.274744 | 71.208× |
| Lexer | 153.067 | 1.67968 | 91.128× |
| Symbolic regression | 98.120 | 1.09838 | 89.332× |
| Morning mixed test | 0.199445 | 0.00323585 | 61.636× |
| Evening mixed test | 0.129762 | 0.00260348 | 49.842× |
| RLE roundtrip | 0.0372973 | 0.00056412 | 66.116× |
| Map/Set operations | 1.49250 | 0.0207468 | 71.939× |
| Ray tracing | 8933.94 | 34.2072 | 261.171× |

These are generated JavaScript execution times, not compilation times. They
include exact result validation and checksum work. Inputs are the catalog's
unchanged documented small benchmarks or original smoke tests. The raytrace
point still visits 1,048,576 column probes. It is a useful expensive confirmation,
not the recommended inner loop for changing its code generation.

Five diagnostic points explain why one overall slowdown number would obscure
the useful distinctions: the long scalar region is **1.403×** TypeScript,
complete private pair **3.061×**, local fold **5.937×**, complete generic row
**58.817×**, and zero-work scalar entry **56.226×**. The last ratio is only
0.003756 ms versus 0.0000668 ms per call: fixed guard and harness costs matter
much more there than in a long loop. Short warmups do not establish V8 steady
state. The corpus is not a statistical sample of production applications.

The broad three-role run used another acquisition of the same compiler, not an
optimized candidate. Its baseline/candidate ratios of 0.987–1.020 are noise
controls, not gains. Historical Phase28–32 medians use different protocols and
must not become denominators for the new suite.

## What the new fast profiles establish

`selfhost/build/program-diagnostics/fast-02` captures all **30/30** requested
profiles in **17.98 seconds**: five points, TypeScript/baseline/same-compiler
candidate, and separate CPU/allocation processes. It consumes the exact modules
from the successful Phase33 fast timing run. These profiles use a 200 ms target,
50 ms warmup plus at least one warm call, a 1 ms CPU interval and a 32 KiB allocation
sampling interval. They are short mechanism screens, not settled timing results.

| Point | TypeScript estimated allocation/call | Baseline estimated allocation/call | Main baseline allocation attribution |
|---|---:|---:|---|
| Complete private pair | 4.268 MB | 8.126 MB | `cell.f4` 64.93%; `row` 33.12% |
| Local fold | 0.263 MB | 0.699 MB | `fold.loop` 98.02% |
| Complete generic row | 0.00774 MB | 0.481 MB | `apply` 17.36%; `gen` 11.36%; `cell.f4` 8.02%; `project` 7.88% |

MB here means one million estimated allocated bytes. Each value divides the
profile's sampled allocation estimate by its own completed calls; the faster
program performs more calls in the same target window. These are neither retained
heap sizes nor exact allocation counts, and are not uninstrumented measurements.

The private pair's current `cell.f4$get` still returns a fresh four-field vector
after each cell update. Its surrounding `row` carries that vector through the
loop. The source performs 65,536 cells per complete pair. This combines a concrete
remaining allocation site with a matching sampled hotspot, making **scalar
replacement of the private loop-carried state** a sharply targeted experiment:
carry its fields in loop slots, or fuse the cell result into its immediate row
continuation, while preserving array write order, aliases and row swaps.
The independent fold has the same remaining shape: `fold.step$get` returns a
two-slot `[updatedArray, accumulator]` vector carried by `fold.loop`. This gives
a second source fixture for the same general rule. Its allocation can be
attributed to the loop after V8 inlines the helper; a profile owner is not an
exact source allocation site.

The pair CPU screen has 172 samples: `row` receives 26.18% of weighted self cost,
`cell.f4` 21.43%, `cell.f2` 15.73% and GC 22.40%. The generic row instead attributes
47.36% to `invokeExact` and 9.99% to `apply` in its 111-sample CPU screen. These
support different next experiments for already-private and generic code. They
do not establish that deleting a named frame would remove that fraction of time;
inlined work and inspector attribution can move between frames.

The long scalar point attributes 97.44% of its approximately 0.341 MB/call
allocation estimate to `mit`. Its current private loop contains a BigInt countdown
and no inner generic calls. A private numeric countdown is therefore a renewed
allocation hypothesis, but the historical small timing gain still constrains its
priority. Upstream has only **15 allocation samples** at this point, mostly harness
work. Do not advertise a large allocation ratio using that sampling floor.

The zero-work entry attributes much of its CPU and allocation to descriptor
guards, consistent with the visible fixed cost. This does not justify dropping
the guards: an already rejected tiny F32 guard experiment demonstrates the need
to amortize them across larger proven regions.

Interpretation limits remain visible. The short CPU windows attribute roughly
8–10% of sampled self cost to the inspector `post` boundary in several cases;
longer profiles are preferable for small changes. V8 allocation sample sums and
tree `selfSize` sums differ in these captures; the tool reports both and uses the
explicit `samples[].size` weights. Two candidate profiles contain one sample
whose tree node is absent; those bytes remain explicitly unattributed rather
than being discarded or assigned a guessed call path. The first `fast-01`
attempt stopped on that previously unsupported shape and remains preserved;
its incomplete acquisition is not merged into the successful `fast-02` result.

## Full-corpus profiles confirm the broad problem

`selfhost/build/program-diagnostics/full-01` completes all **60/60** profiles and
30 AST analyses in **244.88 seconds**, under its 300-second ceiling. This is
fifteen points with two roles and two separate profiler kinds. Its target is
1.5 seconds per profile after at least one warm call and 400 ms of warmup; CPU
sampling remains 1 ms and this acquisition uses 32 KiB allocation sampling.
The fixed raytrace invocation is longer than the target, so its CPU and allocation
profiles each contain one complete benchmark call. Their time is not a new
uninstrumented speed comparison.

The most useful finding is **the generic execution machinery is hot, while GC
alone is not the dominant sampled CPU cost**. In the baseline CPU profiles:

| Program | `apply` self weight | Runtime matcher callbacks | `invokeExact` | GC | CPU samples |
|---|---:|---:|---:|---:|---:|
| Raytrace | 49.81% | 17.59% | 5.48% | 2.26% | 8,382 |
| Lexer | 28.39% | 10.60% | 7.47% | 5.20% | 1,315 |
| Symreg | 33.25% | 13.44% | 10.95% | 4.31% | 1,305 |
| Tree bitonic | 24.72% | 8.94% | 9.16% | 5.19% | 1,314 |

Matcher callbacks here are the two exact runtime callback locations in `matcher`
and `matcher1`, not every anonymous function named `fn:argument1`. Percentages
are exclusive sampled weights within each individual CPU capture. Other hot
runtime work includes `force`, `callOwned` and `project`; the table is not an
exhaustive or causal decomposition. Removing allocations could reduce ordinary
execution work as well as GC, so the small GC fraction does not make allocation
elimination unimportant.

| Program | TypeScript estimated allocation/call | Baseline estimated allocation/call | Baseline allocation attribution |
|---|---:|---:|---|
| Raytrace | 8.438 MB | 15,823.757 MB | `apply` 24.76%; `colf` 9.34%; four sphere selectors 29.92% combined |
| Lexer | 3.931 MB | 219.638 MB | `apply` 13.93%; `step.at` 11.79%; `lex` 9.40% |
| Symreg | 0.456 MB | 160.824 MB | `eval` 52.90%; `apply` 17.07%; runtime matcher callbacks 16.59% |
| Tree bitonic | 1.367 MB | 33.907 MB | `warp` 25.54%; `warp_zip` 11.52%; `apply` 11.17% |
| Original edit distance | 16.954 MB | 32.183 MB | `cell.f4` 65.22%; `row` 33.17% |

These estimates divide each allocation capture's explicit sample weights by its
own completed calls. The raytrace allocation captures have 480,983 baseline and
10,805 TypeScript samples, so neither is a tiny sampling floor. Nevertheless the
numbers are estimates under allocation profiling, not exact bytes allocated by
uninstrumented code. In particular, 15.8 GB allocated over a call does **not** mean
15.8 GB resident at once. The fine raytrace acquisition itself reached about
1,221 MiB process-tree RSS while collecting/serializing its large profile. It is
retained as evidence. The maintained runner now uses a coarser, explicitly
reported **256 KiB allocation interval for both raytrace roles**. The separate
`raytrace-memory-01` control completes 2/2 profiles in 44.40 seconds; baseline peak
tree RSS falls to **541.6 MiB**. Its baseline capture has 60,178 samples and an
estimated 15,782.118 MB allocated for its one complete call. The TypeScript capture
has 1,347 samples across 44 calls, estimating 8.026 MB/call. These remain separate
from the fine-profile table above. The coarse capture retains the same leading
baseline attribution: `apply` 25.06%, and the four sphere selectors 29.68%
combined. This validates a lower-memory diagnostic configuration and broadly
consistent hotspots; it is not a generated-program speed improvement.

The TypeScript CPU profiles chiefly show algorithm functions: raytrace `colf`
46.17%, `nearest` 27.83% and `nearest.t` 12.38%; lexer `batch` 30.46%, `gen` 25.52%
and `step.at` 12.20%; symbolic regression `eval` 71.58%. Those are useful contrasts
to the generic runtime frames above, not percentages to subtract from another
profile. The raytrace point traverses many rejected column probes as well as
actual rays, so a direct `colf` traversal is a separate discriminator from
intersection and selector lowering.

The longer profiles also confirm the cheap private-state target: complete pair
allocation is approximately 8.002 MB/call baseline versus 4.227 MB/call TypeScript,
with 65.40% assigned to `cell.f4` and 32.88% to `row`. Fold is 0.628 MB versus
0.265 MB, with 82.97% assigned to `fold.step`. These longer-window percentages
remain separate from the earlier fast-window table. Their changing function
attribution illustrates why one short profile should not become a precise causal
claim about an individual source line.

The AST report independently records these current source-owned units:

| Program | Source-owned bytes, TS / baseline | Generic call/trampoline sites, TS / baseline | Projection/matcher sites, TS / baseline | Loops, TS / baseline |
|---|---:|---:|---:|---:|
| Raytrace | 19,443 / 27,518 | 0 / 279 | 0 / 133 | 3 / 0 |
| Lexer | 7,403 / 10,429 | 0 / 80 | 0 / 56 | 1 / 0 |
| Symreg | 6,685 / 8,769 | 0 / 89 | 0 / 37 | 2 / 0 |
| Tree bitonic | 4,981 / 6,570 | 0 / 57 | 0 / 31 | 0 / 0 |

These are disjoint top-level units mapped to names declared in the Bend fixture,
excluding runtime, Base/other support and export wrappers. The baseline retains
`main`, which upstream library output omits. Raytrace's five upstream table
declarations add 1,702 support bytes and 45 cells outside those function bodies;
the analyzer lists them separately. Source byte counts and syntax sites are not
dynamic counts or a compiler-complexity score. Relatively modest algorithm-body
size differences coexist with repeated expensive generic operations.

## Strongest remaining opportunities

### 1. Extend direct regions through complete match and argument chains

The largest deficits remain in programs whose central work still crosses the
generic calling, matching and construction machinery. Our current raytrace
`nearest` retains twelve successive `callOwned` applications on its recursive
transfer; `nearest.t` retains ten. Both end in a Boolean match after their leading
Nat match and scalar parameters. Upstream emits direct saturated functions with
`for (;;)` loops and local-slot updates. Our `trace` additionally crosses a
`Hit` record match. Primitive F32 arithmetic already uses direct expressions
with `Math.fround`; adding those operations again would not address this structure.

Current lexer `lex` similarly crosses SNil/SCon, Chr and Tuple matchers before
its recursive call. Upstream directly extracts the same string/state values
inside a loop. Our `step.at` constructs nested state/pair values through
`build` and function descriptors. Both compilers already use native JavaScript
strings. The proposed improvement is the work surrounding the strings.

The next discriminating experiments should isolate a complete `nearest.t` call
and a short `lex` run, using saved output and a private saturated-loop prototype.
First keep arithmetic, records and native storage unchanged. Count or profile
the generic operations separately, then compare uninstrumented modules. Require
complete Hit/state observations where applicable, F32 rounding/NaN/signed-zero
controls, Unicode and empty-string controls, and deep tail-recursion checks.

A surviving compiler rule must retain public partial-application and demand
order, including errors, descriptor mutation and deferred work. Reuse one guarded
closed region across substantial work; guarding every tiny helper has already
failed. The magnitude of a transferable improvement is unmeasured. The
**261×/91× gaps are available headroom, not promised gains**.

### 2. Collapse pure finite Nat decisions inside that region

Raytrace's current `sx`, `sy`, `sz`, `sr` and `skr` are another specific remaining
difference. Our modules retain up to eight nested Zero/Succ matcher levels.
Upstream emits a shared constant table and a selector of this shape:

```js
return TAB_0[Math.min(_i_0, 8)];
```

Four selectors are called for each tested sphere inside `nearest`/`nearest.t`.
The full raytrace allocation profile attributes 7.55%, 7.49%, 7.46% and 7.42%
respectively to `sy`, `sx`, `sr` and `sz`: **29.92% of sampled allocation self
weight combined**. This is now a measured allocation target, not just a source
pattern. It does not promise a 29.92% runtime improvement.
This gives a small experiment before a general loop change: compare the unchanged
selectors with a private table implementation, checking indices 0 through 9,
large valid Nat values, every default and the exact rounded F32 constants. Keep
the loop itself unchanged to separate effects. Do not move live calls to `fl`
across an observable public boundary without proving the captured dependency.
Any guard should be amortized across the enclosing work.

Table lowering is not a new discovery: Phase25 already recorded upstream tables
and Phase26 improved native U32 decisions. The fresh finding is that these
**Nat-to-F32 selectors remain generic in the current raytrace output**. Pinned
upstream `comp.ts` implements the relevant `mat_nats`, `emit_row` and `emit_tab`
analysis; its table rows are restricted to constants/pure intrinsic expressions.
Its shared table declarations must be counted as support when comparing code size.

### 3. Extend locality to tree and sum-type work

Current symbolic-regression `eval` matches Var/Lit/Add/Sub/Mul/Xor through generic
descriptors and repeatedly applies its known two-argument recursive function in
two stages. Tree sort's `bsort`, `warp`, `flow` and `scan` similarly move between
tree construction, matches and recursive forks. Upstream uses direct tag tests,
field reads and saturated calls.

The promising extension is a private traversal over locally produced trees,
followed by eliminating constructor/destructor pairs that cannot escape. Start
with one small expression evaluation or tree pass and compare complete trees or
independent outputs before broadening. Separate direct calls from representation
changes so the effect is attributable. Preserve evaluation order, aliasing,
public getters and bounded-stack behavior; arbitrary foreign records cannot
be treated as private fields. These boundaries make this a larger compiler
extension than the selector experiment.

### 4. Remove the remaining private loop-carried allocation

Pair/fold are much closer to TypeScript after Phase32's statement unpacking,
typed read bridges and private field vectors. The new allocation evidence above
targets the remaining per-cell state vector and loop costs. Use
`local-pair`/`local-fold` for a small scalar-replacement ablation, then confirm on
original edit distance and a second workload. This is a cheaper, more isolated
next implementation experiment than general recursive ADT lowering, even though
the generic programs have larger absolute deficits. Keep the wider region work
as the transfer objective. A sampled anonymous callback or `enterExact` frame is
not by itself evidence that the permission token is expensive: V8 inlining and
source attribution can place child work there.

## Approaches already tested that should not be repeated unchanged

- [Tiny guarded F32 roots](../phase30/f32-ordinary-root.md): `isect5` removed
  several generic operations but regressed **2.87× on a hit and 6.99× on a miss**.
  This rejects that guard boundary, not F32 lowering in a larger region.
- [Per-call/native guards and broad runtime tweaks](../phase30/decisions.md):
  repeated descriptor checks and per-call Array bypasses lost their intended
  gains. Existing guards protect executed mutation, getter and order witnesses.
- [Number-only private Nat countdowns](../phase30/decisions.md): the retained
  confirmation gave only **1.057×** on its narrow helper, with remaining warming.
  BigInt is a possible cost, not an established explanation for 70–260× gaps.
- [Helper hoisting and source-size reduction](../phase30/decisions.md): one
  experiment removed 7,849 generated bytes and reduced helper copies from 31 to 8,
  without a demonstrated execution gain. Runtime/Base bytes affect import cost
  and must not be mistaken for warmed algorithm instruction counts.
- [Generic registration](../phase31/generic-registration-diagnostic.md): unused
  exact-call registration causally explained a roughly 5.7% row regression in
  that window. It is worth preserving as a canary, but cannot explain the entire
  current generic-code deficit.

## Reproducible structural evidence

The exact source fixtures and both emitted variants are portable parts of the
[maintained suite](../../selfhost/tools/performance/programs/README.md). The
[reference manifest](../../selfhost/tools/performance/programs/baseline/manifest.json)
identifies members of `baseline/programs.tar.gz`; a normal run extracts the
selected modules. This inspection does not depend on an ignored historical
compiler build directory.

| Program / role | Canonical module SHA256 | Inspected Bend definitions |
|---|---|---|
| Raytrace / baseline | `3d1bc9a29878c1c079fdafcad3e6733037194323edc9a099efd940d811b3b367` | `nearest`, `nearest.t`, `trace`, `sx`, `sy`, `sz`, `sr`, `skr` |
| Raytrace / TypeScript | `87bd526f04705416db047a31eb4ccc186f1c90f5c911f57736a3216a7629ddd2` | Same source definitions |
| Lexer / baseline | `866fdf5adf04ba4730253fc48fdf01671a32a3e8fe56193afee4cfd5065c6e4f` | `lex`, `step.at`, `prng` |
| Lexer / TypeScript | `2d9378dfdcacc5904f4b2ac65fd90ba1dcc4a51d9c68b00f6042c42aaeadbbba` | Same source definitions |
| Symreg / baseline | `551e61d6ccbeca827650038d31d93dc5866f59a11283bff9bc6a6ca59e05d875` | `eval`, `run` |
| Symreg / TypeScript | `545d6112dbbb0cc66074407a0daf7076b148f9d311e7e9bbffff3376f8e00651` | Same source definitions |
| Tree bitonic / baseline | `87cc70fa5820a7af339ff6f7c75b0120e167ad0cfbda1a7ac4d143ec0c0ae807` | `bsort`, `scan`, `warp`, `flow` |
| Tree bitonic / TypeScript | `c24fff66dd20c4579b7912b42450f1574e4c0b7a84e5d8b2d3d1d1345ef2b159` | Same source definitions |

These structural differences are observed syntax. CPU sampling, allocation
sampling, exact event counts and clean execution timings answer different
questions. Only an isolated, correct ablation can establish that removing a
particular difference improves the program.
