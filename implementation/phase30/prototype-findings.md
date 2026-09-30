# Edit-distance private-call experiment

Agent-generated investigation, Phase30. This experiment uses the exact checked
Phase29 edit-distance output and the pinned upstream output already acquired in
Phase28. Disposable JavaScript variants are mechanism probes, not compiler
versions. Neither the installed compiler nor the original archived output changes.

## Prospective comparison

The source is `selfhost/tools/performance/phase28/corpus/editdist.bend`, SHA256
`f9cc44d93829d8ea48148c26b8ed7e2c1785611ad0c19a3770f86227a3142e6f`.
The Phase29 output hash is
`b8ef74706cdc0fc6c9205046b34b4a686ca501cee847ea43a2fcd830a0383ac3`;
the TypeScript output hash is
`33721b7770aa4e367896cf1b842cc8ec309dced3a2608e25c5709217474eabc6`.
The acquisition records retain exact tools, files, identities and rewrites.

One cell traverses five functions (`cell`, `cell.f1` through `cell.f4`). Each has a
leading function descriptor followed by a record/tuple matcher and another
field-consuming descriptor. Upstream directly invokes five JavaScript functions.
Our ablation changes only this call plumbing. It retains `project`, the projected
field-vector copy, array get/set helpers, arithmetic, `umin`, `b2u`, `build`, record
representation and the outer `row` trampoline. Public descriptors remain present.

Each private entry follows the original matcher and apply demand sequence:
project; read projected length; either produce the empty-field residual function,
or slice the fields and follow exact saturation/partial/oversaturation branches.
The usual complete-field path invokes a top-level body helper directly. Its
cold fallback uses the already-projected vector and never repeats projection.
Attempt02 keeps the original generated arm body on cold paths; the first attempt
incorrectly called the optimized downstream chain before an oversaturation length
read. The reviewer identified this observable-order counterexample, so attempt01
is retained only as an ordinary-field fixture result and is not confirmed.
Each transition is acyclic, so this prototype does not add an unbounded recursive
call chain.

The first variant assumes immutable compiler-created global descriptors. A second
variant reads the current `G` target before evaluating later arguments and checks
its identity against the original descriptor; replacements follow the original
call path. This distinguishes private-call benefit from replacement-guard cost.
Identity alone does not protect in-place mutation of a captured descriptor's
internals; neither prototype establishes that stronger production contract.

The fixture invokes the unchanged source `row` export with deterministic fresh
arrays, then returns the complete serialized four-array state. Python computes
an independent recurrence and complete expected arrays. Sizes0,1,2,7,16,32,64 and
seeds0,1,17,4294967295 exercise empty/single/multiple cells and unsigned wrap in
fixture construction. The timed point is size32,seed17. State allocation and
serialization are included for every variant, so the result describes the complete
small row fixture rather than an isolated cell instruction cost.

Freeze `prototype-guard-02/screen.json` and `confirm.json` before measurement.
Reuse the maintained Phase29 comparison protocols: serial rotated fresh CPU3
processes, Node24.18.0,4MiB stack,1GiB heap, sanitized environment, complete exact
output checks inside every invocation. Screen:3samples,8calls and100ms warmup,
150ms target. Confirmation:5samples,100calls and3000ms warmup,300ms target.
First call/import are separate; retain per-half drift. No runtime instrumentation
is used in those modules. Measurement starts only after the lead grants the CPU
window and independent semantic review completes.

## Correctness and mechanism counts

The initial unguarded/old/upstream comparison passes84 complete-array observations
(28points×3variants). The guarded variant passes the same28points. Corrected attempt02 passes112
observations (all28points×fourvariants), and its new counters are identical. These are
scoped fixture checks, not a general proof of private-call soundness.

Untimed counters over ten size32 rows give:

| Named site | Old | Private | Guarded private |
| --- | ---: | ---: | ---: |
| Function descriptors | 5,800 | 2,600 | 2,600 |
| Bound descriptors | 950 | 950 | 950 |
| Generic apply | 10,930 | 6,130 | 6,130 |
| Tail-jump objects | 5,160 | 2,280 | 2,280 |
| Generic call | 5,770 | 3,850 | 3,850 |
| Projection | 2,590 | 2,590 | 2,590 |
| Scheduled build | 330 | 330 | 330 |
| Array.get / Array.set | 1,280 / 320 | 1,280 / 320 | 1,280 / 320 |
| Copied slots, apply plus retained private projection | 26,330 | 16,730 | 16,730 |

`prototype-counters-01` initially counted only generic apply's copied slots.
The subsequent02/03attempts explicitly count the3,840private projection slots as
well. The old tool snapshot and all raw outputs remain. These are named-site
counts, not total heap allocation or evidence of execution speed. Bound
allocations do not fall because the unchanged row trampoline still creates them.

## Evidence

All paths are below `selfhost/build/phase30/`:

- `prototype-01`: exact acquisition,28oracle points, three emitted/wrapped modules,
  rewrites,84complete checks; original check-tool snapshot.
- `prototype-guard-01`: guarded variant, three byte-identical comparison copies,
  guard rewrites, frozen timing configurations,28additional complete checks.
- `prototype-counters-01`,02,03: separate instrumented variants and their named-site
  counts. Original counter-tool revisions remain in the first two attempts.

## Retained first screen

The original three-variant attempt01 screen completes in6.327s end to end:
old0.731226ms, private0.308615ms, upstream0.024499ms per complete fixture.
The apparent2.37× gain is not a stable warmed estimate: every old sample's second
half takes3.16–3.20× its first-half cost, while private ratios are0.73–0.74.
The reviewer found the cold-path ordering issue immediately after that screen;
confirmation stopped, attempt02 repaired the path, and the raw01result remains.
No broad semantic or compiler-promotion claim follows from attempt01.

Additional evidence: `prototype-02`, `prototype-guard-02`,
`prototype-counters-04` (corrected modules and independent complete-state checks),
`prototype-screen-01` and its adjacent end-to-end launcher receipt.
The independent reviewer executes the changing copied-vector length witness:
attempt01 fails because `b2u`/`Array.get` effects move before the final length read.
Both repaired02 variants pass33ordered/public-descriptor observations each;
these include custom projections, copy and field access, error ordering and
partial/oversaturation behavior. The separate live `G.cell` replacement witness
differs on unguarded02 and matches on guarded02, as their scopes predict.
Receipts: `review-prototype-01`, `review-prototype-02`,
`review-prototype-guard-02`. In-place captured descriptor mutation is still outside
these prototype contracts.

The corrected four-variant short screen completes in8.532s end to end. Medians:
old0.726531ms, private0.304955ms (2.382×), guarded0.660924ms (1.099×),
upstream0.024406ms. These remain lifecycle-sensitive: old second/first half ratios
3.06–3.37, guarded3.50–3.58, private0.69–0.74, upstream1.03–1.05. Keep them as the
specified short-window results, not a steady-state guard-overhead estimate.
The pre-frozen longer-warm confirmation completes in84.577s against exactly the
same bytes:

| Variant | Median ms | Five-sample range ms | Old / variant | First-call median ms |
| --- | ---: | ---: | ---: | ---: |
| Phase29 output | 0.281841 | 0.279317–0.313869 | 1.000 | 5.929 |
| Private, immutable globals | 0.204392 | 0.202468–0.205480 | 1.379 | 4.895 |
| Private, replacement guards | 0.218941 | 0.217820–0.223517 | 1.287 | 5.206 |
| Pinned TypeScript output | 0.023347 | 0.022968–0.024021 | 12.072 | 0.857 |

All private/guarded within-sample half ratios are within1.1% of1. One old sample
still drifts23.8%; the others are within6.6%. Ranges separate, but five samples are
not confidence intervals or proof of final JIT convergence. The identity guards
cost about7.1% relative to unguarded private entry in this window. Preserve the
very different short-window result; the short window overstates the unguarded
benefit and the guard cost.

Peak RSS ranges overlap substantially: old72,600–76,908KiB,
private72,432–74,372KiB, guarded72,592–74,764KiB; upstream62,408–64,636KiB.
No material memory reduction is established by these process peaks.

The long-warm result supports a measurable1.29× gain from guarded private entry
for this row fixture. It does not justify claiming a2.38× steady-state gain,
whole-program improvement, or the same TypeScript ratio for a complete edit
matrix: host fixture construction and complete-state serialization occupy a
larger fraction of the TypeScript measurement. The remaining array operations,
record construction, comparisons and outer loop are intentionally unchanged.
A general implementation should cover additional hot boundaries before its code
complexity is justified; this prototype does not settle that engineering choice.

## Exact-arm ablation and remaining application counts

The next separate ablation changes only five `matcher1(name,()=>fn(k,body))`
prefixes to the existing `matcher1p(name,k,k,makeBody)` helper. Every call site
and arm body remains byte-for-byte unchanged. It is rooted in the
[prospective exact-arm design](../../design/phase30/exact-constructor-arms.md).
This is a15-byte generated-output change, not a new runtime mechanism.
`exact-arm-01` retains the derived module,28complete-row oracle checks and frozen
four-variant screen/confirmation configurations (old/exact/private02/upstream).
Independent `review-exact-arm-01` controls pass33ordered/public-boundary
observations. The separate four-variant short screen takes8.081s: old0.711241ms,
exact0.685813ms (1.037×), private0.305720ms, upstream0.0246313ms. Old/exact
second halves take3.08–3.30×/3.16–3.24× first halves; preserve that lifecycle window.

Longer-warm confirmation takes84.379s: old0.280140ms (range0.278924–0.282389),
exact0.273785ms (0.273124–0.274829), private0.205234ms, upstream0.0231341ms.
The exact-arm gain is1.023×; ranges separate and all half ratios are within5.9%
of1. Thus the narrower existing-helper extension offers a small measurable gain
on this row while retaining ordinary call behavior. The application and descriptor
reductions below must not be read as proportional speedups. No combined exact-arm
plus private-call or compiler-wide transfer measurement is implied.
Receipts: `exact-arm-screen-01`, `exact-arm-confirm-01`, their adjacent launcher
records and `review-exact-arm-01`.

Ten rows produce4,200descriptors,9,330generic applications and3,560jumps, compared
with5,800/10,930/5,160originally. Calls, projection, construction and array operations
are unchanged. Copied slots also remain unchanged once both sites are counted:
old26,330apply +320prebind =26,650; exact22,490apply +4,160prebind =26,650.
`exact-arm-counters-01` initially included only the earlier named counters;
`exact-arm-counters-02` adds the prebinding helper's retained copies. The original
tool snapshot and both attempts remain. This matters: the helper removes an
application boundary, not the required field snapshot.

A further untimed instrumented run inherits a global-origin label when a runtime
function descriptor is created. It counts generic applications by that label,
then verifies that their sum matches the earlier total. These are mechanism
counts, not time shares or a CPU profile. `prototype-named-counters-01` records:

| Remaining origin after private cell calls | Applications / ten rows | Share of remaining applications |
| --- | ---: | ---: |
| `umin.go`, `umin`, `b2u` | 2,900 | 47.3% |
| `row` | 1,630 | 26.6% |
| `Array.get`, `Array.set` | 1,600 | 26.1% |
| Total | 6,130 | 100% |

The original five cell helpers account for another4,800applications. Exact-arm
prebinding removes1,600of those; private entry removes all4,800. The long-warm
1.29× gain with guards therefore leaves concrete, distinct work: Boolean/minimum
helper matching, the outer row trampoline and native array helper calls. It does
not establish which remaining group costs most time.

## A conservative closed-region proposal

The natural larger boundary is the original checked `pair(seed:U32)->U32`:
it creates the input arrays and dynamic-programming state itself, executes the
rows and returns a scalar checksum. Its complete reachable graph contains no
foreign callbacks, IO, externally supplied records or externally supplied array
handles in the intended region. A small scalar-input row wrapper can exercise
the same boundary cheaply before the full256×256program is timed.

A future rule could guard and enter a private region once, instead of checking
mutable callees for every cell transition. That region can use direct functions,
local-slot loops and internally owned records while retaining the ordinary public
entry and its fallback. This is a proposal, not an implemented admission proof.
The minimum contract would be:

1. Keep the public descriptor and original application boundary. Enter only after
   the original prefix has consumed its arguments, with primitive scalar values
   validated as the expected runtime types. Partial applications, foreign objects
   and unknown scalar representations keep the original path.
2. Statically close the reachable checked graph. Admit identified scalar
   operations, native array creation/get/set, ordinary constructors/matches,
   local bindings and proven tail transfers. Reject IO/foreign bodies, higher-order
   calls, unknown globals, escaped input containers, reflection and unsupported
   representation conversions. No name-based workload allowlist.
3. Prove every inspected record/tuple/array is created inside the region or comes
   from an admitted primitive operating on such a value. Preserve ownership,
   mutation order and parallel-let evaluation. This removes foreign getter and
   custom-field-vector paths by provenance, rather than making them incorrect.
4. Before entering, check the exact current descriptors for the closed dependency
   set, including code, arity, environment and bound-argument state. Reading
   ordinary property descriptors can reject accessor replacements without running
   them early. Preserve the original target capture and argument-demand order.
   Any unknown replacement or mutation falls back at the original boundary.
5. Once inside, the admitted graph must have no way to run arbitrary external
   code, so it cannot mutate those descriptors midway through execution. This is
   what allows an entry guard to replace per-cell guards. Fresh arrays alone do
   not establish this; purity and closed callee provenance are also required.
6. State the trusted runtime/builtin contract. Skipping generic apply also skips
   array-copy machinery; arbitrary mutation of host builtin prototypes is another
   observable boundary. A fast path needs an appropriate stable-builtin guard or
   an explicit existing host-runtime invariant, not an unstated assumption.
7. Preserve existing representations first: BigInt Nat, current array wrappers,
   construction/forcing rules and saturated scalar arithmetic. Change storage or
   primitive access in separate ablations. Preserve bounded stack behavior with
   loops; reject unsupported non-tail or mutual recursion initially.

The cheapest next demonstration is a disposable closed scalar-input wrapper with
four independent steps: comparator/Boolean calls, row loop, array helper calls,
then their combination. Keep full-array oracles on the small wrapper, effects and
replacement counterexamples at public boundaries, and the original checked
`pair` scalar output as a transfer control. A clean small result should precede
any compiler-wide region analysis or new intermediate representation. There is
no justified speedup estimate for that larger proposal yet.

## Separate diagnostic CPU profile

After the clean comparison window, the prospectively frozen
`prototype-profile-plan.json` drives one V8 sampling run of immutable private02
on CPU6. It performs5,000complete-oracle warmup calls before starting profiling,
then20,000profiled complete-oracle calls with a1,000microsecond sampling interval.
All observations pass. The6.378s launcher interval is diagnostic acquisition cost,
not a comparative runtime measurement. The raw `.cpuprofile`, exact tool/module/
Node/config identities,3,775samples and launch receipt are in `prototype-profile-01`.

Aggregating sampled **self** frames gives:

| Frame | Samples | Share of observed samples |
| --- | ---: | ---: |
| `apply` | 1,072 | 28.4% |
| `force` | 328 | 8.7% |
| `call` | 243 | 6.4% |
| Fixture construction/serialization | 389 | 10.3% |
| Generated `row` callback | 258 | 6.8% |
| `project` | 147 | 3.9% |
| `get` | 104 | 2.8% |
| Garbage collector | 100 | 2.6% |

The generic apply/force/call frames alone account for43.5%of this diagnostic's
samples after the five cell helper chains have already been removed. This supports
focusing on the remaining call/trampoline boundaries. It does not assign those
samples precisely among comparator, row and array operations, and does not make
the application-count percentages into timing shares.

Garbage collection is not the dominant sampled frame. Allocation work also occurs
inside `apply` and generated callbacks, so this observation does not show that
allocations are cheap or irrelevant. Similarly, `force` combines constructor
scheduling and trampoline work; this profile does not separate them. One sampled
run is for prioritization, not a stable universal profile or a speedup promise.
