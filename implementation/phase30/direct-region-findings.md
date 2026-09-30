# Guarded direct-call experiments inside an existing loop

Agent-generated Phase30 investigation. This report is updated as evidence arrives;
prospective plans and raw attempts remain immutable. No compiler source changes
are made by these experiments.

## Scope and identities

The four-way experiment compares pinned upstream, installed Phase29 output,
a per-call guarded leading-lambda prototype, and a closed scalar-region prototype.
All retain the same original Mandelbrot source algorithm and `bench(0,0)` input.
The clean module identities are:

| Variant | SHA256 | Bytes |
| --- | --- | ---: |
| Upstream | `037f070e948ab7701364b7413c624bca4327db0bc6171ac4523b906d2ae9e222` | 15,442 |
| Phase29 | `11977282d5c364224eb3ac540fe3885345531d5819a68e5facfc72b03a836033` | 82,540 |
| Per-call guarded lambda02 | `6c7f3235cdda916521f57c3dd9507661a78ba0c72adfb470ad2fabb9ee15fd34` | 85,013 |
| Guarded region01 | `16e0ce13bbdceab199eb4204829b375bc77a253a7e34e15c1221bbfb62fa9e23` | 86,594 |

Derivations, plans, controls and frozen four-way screen/confirmation configurations
are under `selfhost/build/phase30/inspection-lambda-02` and
`selfhost/build/phase30/inspection-region-01`. The inspector and derivation tools
are maintained in `selfhost/tools/performance/phase30/inspect-*`.

The per-call version changes only `mit`'s three `asr8` and two `sel` applications.
Each invocation still performs live `get(G,name)`, then exact argument evaluation,
then a guarded direct positional body call or the original fallback. It leaves
`b2u`, nested calls, arithmetic, loop and BigInt representation unchanged.

The region version checks the entire scalar helper closure once after the original
seven indexed callback-argument reads. On a successful entry, a private copy of
the original loop calls direct `asr8`, `sel`, `sel.go` and `b2u` helpers. All
primitive arithmetic, immutable iteration aliases, next-state temporaries and
BigInt countdown behavior remain. Every rejected entry runs the old loop. Public
G descriptors and export adapters remain in place.

This guard assumes standard host intrinsics and primitive/Object/Array prototype
behavior. In particular, arbitrary injected primitive `request`/`bounce`/`build`
getters or modified administrative Array methods are outside the experiment's
contract. Ordinary G/descriptor mutation, code.call hooks and object-valued scalar
arguments are explicitly controlled. The prototype is not a general arbitrary-host
optimization or proof of backend correctness.

## Retained callable-object counterexample

The initial per-call lambda01 passed 103 scoped controls. Self-review and independent
review both identified a missing boundary: the runtime invokes `f.code.call`, so
adding an own `.call` method/getter to the unchanged code function changes behavior.
An extracted private body skips that property access despite identical descriptor
fields. Three prospective controls then failed on lambda01:

- own code.call method;
- own code.call getter;
- changed code-function prototype providing call.

The original successful receipt and the later failing
`inspection-lambda-01/callable-counterexample.json` are both retained. No clean
timing of lambda01 was performed. Lambda02 checks absence of an own code.call,
ordinary code-function prototype and unchanged inherited intrinsic call before
admitting the direct path. Its 106 controls all pass.

## Scoped correctness observations

Region01 passes the same 106 observations: 75 grid points, three additional
boundary/depth points including 50,000 iterations, original benchmark sizes0/1/2,
four partial-call observations and 21 mutation/error transcripts. These are
observations involving multiple emitters, not 106 new upstream conformance tests.
The repeated-zero case has independent expected result 50,000; size2 retains the
original known checksum 887240761. Other pure points compare both checked emitters.

A separate region boundary runner passes 55 exact observations:

- G getter, code getter/wrapper, Proxy replacement and own code.call mutation for
  each of all four reachable helpers;
- coercing/throwing host objects, Symbol, NaN, Infinity, negative/fractional/out-of-
  range Number and negative zero in three scalar positions;
- callback frames with indexed getters/Proxy traps, including slot-read mutations
  of b2u code and asr8.call;
- rejected non-BigInt callback counter inputs.

The seven indexed callback reads occur once in the original order before any new
admission checks. Guarding the captured scalar values, instead of rereading the
argument vector, is what preserves the accessor-frame transcript.

Independent review adds37 passing observations on boxed Number values,
Symbol.toPrimitive (including G/code mutation), throwing coercion, Proxy scalar
objects and a long-loop/saved-partial witness. A separately preserved excluded
Boolean.prototype.request hook produces the same value but a different trace,
confirming the importance of the standard-prototype contract. These observations
are retained under `selfhost/build/phase30/review-region-inputs-01`.

## Dynamic mechanism counts, without timing

Counts come from separate instrumented modules, reset after import, over ten
original `bench(0,0)` invocations. Every invocation returns2747870681. This small
input performs64 histogram pixels and64 recolor pixels, each with seven `mit`
iterations. The instrumented counts confirm 1,280 successful region entries and
44,800 selected per-call helper invocations. They are named runtime-site counts,
not a complete heap-allocation census.

| Named operation | Phase29 | Per-call lambda02 | Region01 |
| --- | ---: | ---: | ---: |
| Generic application | 256,100 | 211,300 | 52,580 |
| Generic `call` | 177,980 | 133,180 | 43,580 |
| Function descriptors | 101,160 | 101,160 | 32,040 |
| Bound descriptors | 26,240 | 26,240 | 26,240 |
| Jumps | 78,120 | 78,120 | 9,000 |
| Projection | 28,170 | 28,170 | 3,850 |
| Copied argument slots | 528,830 | 448,190 | 190,910 |
| Metadata guard attempts | 0 | 44,800 | 5,120 |

Region01 removes79.5% of observed generic applications,68.3% of function descriptor
creations,88.5% of jumps and63.9% of copied argument slots in this workload. The
unchanged bound-descriptor count is useful negative evidence: entry and outer
call chains still contain substantial partial-application machinery.

The region's5,120 metadata guard attempts are four checked helper descriptors per
entry; they are not counts of private helper calls. The latter are26,880asr8,
44,800sel,44,800sel.go and17,920b2u invocations. Their bodies execute no generic
application, but these counts alone cannot establish a speedup.

## Clean timing

The prospectively frozen four-way comparison ran serially on CPU3 with the
maintained Phase29 harness and paused competing acquisitions. Raw reports are
`inspection-region-screen-01/report.json` and
`inspection-region-confirm-01/report.json`. Adjacent launcher receipts measure
the complete command wall time. Every timed invocation checks its result.

| Variant | Short screen median ms | Longer-warm median ms | Longer-warm sample range ms |
| --- | ---: | ---: | ---: |
| Upstream | 0.012317 | 0.011741 | 0.011725–0.011750 |
| Phase29 | 6.141519 | 5.121350 | 5.097118–5.312902 |
| Per-call lambda02 | 10.068542 | 7.876658 | 7.823871–7.966891 |
| Region01 | 2.346550 | 1.911814 | 1.896611–1.960276 |

The region improves2.62× in the short screen and **2.68×** with longer warmup.
The per-call guarded version regresses64.0% in the short screen and **53.8%** with
longer warmup. Preserve both the positive and negative results. The region is
still **162.83×** upstream on this specific small Mandelbrot input; this is not
TypeScript parity, compiler throughput or a production-average speed claim.

Short screen timed halves show substantial drift: baseline second-half/first-half
ratios0.800–0.805 and upstream0.878–0.892. The longer-warm window has all ratios
within4.2% of1; baseline is0.991–1.011, per-call0.987–1.020, region0.958–1.003.
Five samples and stable halves do not prove universal steady-state convergence.

The full screen takes8.382seconds end to end (7.559seconds inside the comparer).
The longer confirmation takes84.926seconds (84.110seconds internal). Long-window
first-call medians are24.943ms baseline,31.400ms per-call and17.216ms region;
imports remain about20ms for the three selfhost-derived modules versus1.1ms for
upstream. Peak RSS ranges overlap between selfhost variants; no material memory
improvement is claimed from those process maxima.

These prototypes do not isolate guard frequency alone. The per-call version
removes five selected leading-lambda applications per iteration; the region
removes seven calls plus the complete nested scalar helper/matcher chain. What
the experiment establishes is that the closed-region strategy wins on this
fixture while the narrow per-call strategy loses. It does not quantify separate
shares for reflection, call elimination, Boolean matcher removal or V8 inlining.

Proceed with a bounded general scalar-region compiler rule and a second source
with the same admission grammar. Reuse the existing primitive emitter and Nat
loop machinery; keep unknown shapes and mutated public descriptors on the old
path. The [native reuse audit](native-ir-reuse-audit.md) explains why the existing
C-oriented segment representation is not a shortcut for this step.
