# Generated-program performance and the fast development loop

Use the [compiler guide](BEND-IN-BEND.md) for normal compilation and the
[Phase36 report index](../implementation/phase36/README.md) for exact results,
artifact identities, failed experiments and current promotion status. The target
remains upstream `018751270e800bc222a93dad7f257083ee53a5f7`. The comparison is
between JavaScript emitted from the same Bend source by the two compilers.
Compiler checking cost is a separate measurement.

## What to run during optimization

The maintained [program execution loop](../selfhost/tools/performance/programs/README.md)
provides portable compiled references and four wall budgets: **20 seconds** for
five local cases, **60 seconds** for eight core cases, **300 seconds** for fourteen
broad cases, and **600 seconds** for all fifteen points including raytrace.
Use `--set` or `--cases` to select coverage independently of the budget. Prepare a
checked compiler candidate once, then reuse its modules for execution comparisons.
These are maximum budgets; incomplete coverage is retained and exits nonzero.
The [Phase33 report](../implementation/phase33/README.md) records validation of
the tooling. Its protocol starts a new timing series; historical Phase32 medians
retain their original warmup, process and validation boundaries.

The [diagnostics guide](../selfhost/tools/performance/programs/DIAGNOSTICS.md)
adds separate CPU and allocation profiles plus AST comparisons of those exact
generated modules. It produces raw V8 profiles, source-attributed hot frames,
normalized tokens and a side-by-side HTML view. Profiled durations never become
speed ratios; syntax sites are distinguished from dynamically sampled costs.

## What the backend optimizes

The JavaScript backend retains ordinary function descriptors, partial calls,
constructor matching and a trampoline as its general path. Supported native
arithmetic becomes JavaScript expressions. Constant native shifts avoid a
repeated BigInt comparison/conversion while retaining operand evaluation and
large-shift behavior. Fresh non-tail argument vectors can transfer ownership to
the runtime instead of being copied immediately.

A bounded analysis finds closed scalar regions: native scalar inputs, proved
primitive operations, acyclic scalar helpers, and supported Nat countdowns.
It emits lexical JavaScript functions and direct private calls. The private
names encode source codepoints injectively; case and punctuation stay distinct.
Using lexical calls instead of a dictionary of functions was a major measured
improvement on the selected helper.

Ordinary private helpers emit their tail Let chains as statement blocks. All
parallel RHSs execute before any new source binder is introduced, and an inner
block holds immutable aliases. The emitter reuses the loop's existing scope
machinery. Expression-position Lets and general public callbacks keep their
existing emission; the broader statement experiment did not establish an
additional useful gain.

The same analysis supports three entry shapes:

- A native Nat countdown, with private local slots and a proved predecessor
  self-tail call. Nested proved countdown helpers share its analysis budget.
- A complete ordinary scalar lambda telescope whose helper graph contains a
  proved countdown. This profitability restriction avoids guarding every small
  arithmetic function.
- A native Nat tree with exactly two pure recursive children on its predecessor
  and a scalar combination. A private explicit DFS stack preserves left-child,
  right-child and combination order. The fast path admits public depth at most
  32; other depths retain ordinary compilation and execution. Frames are reused
  by depth within the invocation, with every saved scalar slot and phase reset
  before reuse. Storage grows with tree depth rather than the number of visits.

A terminal flat record can leave a countdown region when its fields contain
only admitted values. The backend retains the existing delayed construction and
field closures. It does not introduce a second public record or array format.
Private tree combinations initially see only their two child results; parent
captures and more general recursion are refused by this rule.

Phase31 extends the same analysis to **closed local data**. Public roots retain
scalar inputs/results and the existing inert terminal-record exception. Inside
the region, helpers may pass canonical `Array<U32>`, nonrecursive records and
specialized canonical Sigma tuples. A shared 256-step type budget, cycle checks
and complete constructor telescopes bound admission. Native allocation/read/write
calls require the actual canonical definitions and exact saturation. Arrays
must originate inside the region; foreign containers, callbacks and function
fields are refused.

Three further rules remove administration inside that boundary. Private helper
returns finish their fields at the demand point already required by their
callers. Consequently, private calls need no additional trampoline force.
Matches read the proved layout directly: tuple indices or an ordinary record's
field vector. Reads still snapshot every field in order before the arm executes.
Public constructors, array storage and the generic fallback keep their existing
representations. This is selective specialization and demand analysis; it does
not require a new ownership system or a second intermediate representation.

Read [the demand proof](../design/phase31/fully-demanded-private-results.md) and
[field-layout proof](../design/phase31/direct-private-field-reads.md) before
extending these rules. Eager writes in arbitrary returned fields are unsafe;
the admitted closed graph supplies the narrower invariant used here.

Phase32 removes more work within that same boundary. Return-position unpacking
uses scoped field bindings. A typed bridge fuses a canonical array read with
its immediate private pair consumer, preserving argument order and the read
even if its result is unused. Nonterminal private records use their ordered
field vectors directly; canonical Sigma construction also bypasses constructor
dispatch. Public flat scalar records stay boxed, including aliases and nested
occurrences. Both constructor and unpack emission use one normalized layout
predicate. The [ablation report](../implementation/phase32/local-representation.md)
separates the three increments, correctness controls, generated size and source
cost. No new general escape analysis, runtime representation or public ABI is
introduced.

Phase35 removes selected private vector allocations as well. It inlines only
proved vector-producing helpers and carries the final vector parameter of a
private countdown in separate locals. Fresh next-field values are complete
before any current slot changes; escaping uses reconstruct the ordinary value.
A private predecessor used solely as the next countdown argument can use an
exact Number counter, while public Nat remains BigInt. Canonical private
`Array.get`/`Array.set` calls also omit their erased type-argument wrappers;
`Array.new` keeps its evaluation-order wrapper. Broad helper inlining was
measured and rejected: several workloads became substantially slower. The
[private-state report](../implementation/phase35/private-state.md) separates
these increments and their alias, ordering and counter controls.

The same guarded boundary now includes F32 expressions, finite Nat decision
chains and countdowns whose final argument is a complete Bool match. Decision
leaves remain computed expressions. The final Bool worker preserves the
original public prefix and matcher stages, including reusable partial values;
each fast invocation copies its captured prefix into fresh loop locals.

The new `jpure.bend` analysis can certify a whole closed first-order graph
without requiring every helper to have a direct implementation. A certified
residual call keeps ordinary saturated dispatch and argument order, under the
enclosing region's dependency guard. Thus inactive traversal branches can be
direct while active leaves retain complex generic work. This proof checks all
reachable bodies and canonical scalar or monomorphic tagged-data types;
effects, arrays, foreign or dynamic calls and function-valued interfaces are
refused. Merely failing direct lowering is never evidence of purity.

For a narrower recursive-data grammar, `fold.bend` emits an explicit postorder
stack over existing tagged values. Complete U32 folds visit each recursive child
once in source order and retain the scalar combination. Their input must be
fully materialized within the proved graph; public external trees remain on the
generic path. Read the [direct-region design](../design/phase35/direct-regions.md),
[fold design](../design/phase35/private-sums.md) and
[implementation report](../implementation/phase35/direct-regions.md) before
extending either proof. These are emitter rules, not a new public data format.

Phase36 adds the corresponding private **producer**: a leading Nat countdown
with two independent recursive children reuses the existing tree frames. Left
child, right child and combination remain ordered; parent scalars survive in
the frame and shared children retain their identities. A whole-graph purity
proof is required. Within that context, existing finite Nat and Bool selectors
can consume trailing arguments directly. Constructors retain ordinary tagged
storage; direct fields are restricted to inert or primitive expressions so
general delayed calls do not become eager. See the
[producer report](../implementation/phase36/private-producers.md).

## Why entry and fallback matter

Before entering a private region, generated code checks primitive input
representations and the live owner/helper descriptors. The guard covers binding
identity, code, arity, environment, bound arguments and relevant prototype hooks.
The runtime grants permission only for a genuine exact invocation; it consumes
permission before an argument getter can reenter. Raw, hooked or oversaturated
calls and failed guards retain the original generic callback.

The admitted region cannot call unknown foreign code or inspect externally
supplied records/arrays. That closed boundary permits one guard around many
operations. The public global table and partial descriptors remain usable.
Standard host intrinsics are part of the runtime contract; the finite tests do
not establish equivalence under arbitrary replacement of JavaScript builtins.

Phase35 adds a captured host-intrinsic guard for F32, residual and fold regions.
It runs before F32 input validation or private execution, covering numeric
intrinsics, array protocols and Object/Array prototype own-key lists. The last
check rejects added inherited numeric getters/setters that could run code during
ordinary allocation. Dependencies remain live and guarded even when their calls
stay generic. The supported mutation controls assume standard intrinsics at
module initialization; integer-only regions without residual calls or folds
retain their earlier guard cost.

Phase36 amortizes these checks during eligible scalar-input tree entries. After
normal entry checks, a proof of the **entire original root graph** allows covered
nested calls to reuse a private dependency dictionary. The outermost proof stays
active through nested scopes and `finally` restores the previous value. Error
construction temporarily suspends proof because a replaced host Error function
can reenter. Native-array graphs are refused. Proving only one residual helper
pure was an unsafe earlier attempt and is retained as a counterexample. Exact
invocation, prototype and `.call` reflection checks remain: a separate experiment
did not justify removing more work. The
[guard report](../implementation/phase36/guard-report.md) states the boundaries.

`localGuard` also checks Array-prototype marker assumptions, including for
graphs with no Array-native calls: canonical Sigma uses a JavaScript array.
Native Array descriptors are captured at registration and checked with the other
helper dependencies. The independent negative control demonstrates why checking
only explicit array operations is insufficient. Runtime fragment edits must be
followed by `node src/runtime/js/build.mjs` from `selfhost/`; generated programs
embed the assembled `src/runtime.mjs` file.

Before any private worker has registered, a monotone runtime flag skips the
empty WeakSet lookup in ordinary calls. The code getter runs before reading the
flag, so a getter that registers a worker still receives the normal registered
checks. After the first registration, the complete exact-entry path remains.
The historical Phase30 experiment improves RLE and a complete generic row by about5–6%;
it does not remove generic descriptor, matching or record-construction costs.

Phase31 extends eligibility, so previously generic-only modules can now register
workers. Their remaining generic calls pay the existing registry lookup. The
controlled [registration diagnostic](../implementation/phase31/generic-registration-diagnostic.md)
explains the measured roughly5% generic-row regression; the scalar zero-work
entry separately pays about0.18µs for stronger prototype checks. Both costs are
explicitly disclosed in the [admission amendment](../design/phase31/admission-tradeoff.md),
rather than classified as no-regression passes.

The analysis is deliberately bounded: at most 32 helpers/graph definitions,
direct-helper dependency depth 16, one shared 32,768-unit region budget and
128 expression levels, with additional source, type and binding limits.
Unsupported direct cycles are rejected; the separate residual purity proof
accepts a recursive backedge only after validating its owner's complete body.
Failed analysis uses the ordinary emitter. Internal plan terms belong only to
emission; they are not fed back into checking or evaluation. See
[region.bend](../selfhost/src/back/js/region.bend),
[worker.bend](../selfhost/src/back/js/worker.bend), and
[tree.bend](../selfhost/src/back/js/tree.bend), plus the bounded
[purity](../selfhost/src/back/js/jpure.bend) and
[fold](../selfhost/src/back/js/fold.bend) analyses.

## Phase36 checked-output measurements

The selected checked03 output completes all fifteen unchanged points in 401.551
seconds. This comparison uses **Phase35 checked09 as the incremental baseline**,
alongside pinned TypeScript. The maintained suite's default portable baseline is
still Phase32; pass the explicit Phase36 `baseline02/manifest.json` to reproduce
these incremental ratios. See the [phase tools guide](../selfhost/tools/performance/phase36/README.md).

| Program | Phase35 ms | Phase36 ms | TypeScript ms | Gain vs Phase35 | Phase36 / TS |
| --- | ---: | ---: | ---: | ---: | ---: |
| Local pair | 3.7791 | 3.7997 | 1.2433 | 0.995× | 3.056× |
| Local fold | 0.13945 | 0.13915 | 0.039786 | 1.002× | 3.498× |
| Edit distance | 15.1448 | 15.1086 | 4.9828 | 1.002× | 3.032× |
| Symbolic regression | 15.5817 | 4.2650 | 1.1124 | **3.653×** | **3.834×** |
| Raytrace | 1,859.5891 | 801.8934 | 34.1617 | **2.319×** | **23.473×** |
| Tree bitonic | 23.0723 | 22.6844 | 0.28138 | 1.017× | 80.618× |
| Lexer | 170.429 | 172.054 | 1.92499 | 0.991× | 89.379× |

Only the two emphasized gains have disjoint observed ranges; the other thirteen
points overlap. The full run's 3.190% map/set slowdown prompted a separate
same-protocol follow-up: 0.523% faster, also overlapping. Both observations stay
in the [execution report](../implementation/phase36/execution-findings.md),
alongside the [complete table](../implementation/phase36/execution-table.md).
All fifteen candidates remain slower than TypeScript output, and these fixed
inputs do not define average application speed. Several samples show drift;
the protocol does not establish steady-state convergence.

The scoped proof removes repeated guard work in ray; direct private production
and selectors remove generic construction work in symreg. Thirteen complete
program suffixes remain byte-identical after each verified runtime prefix;
the common runtime grows by 1,005 bytes. Compiler Bend source grows by 124 lines
(0.687%) to 18,174 lines in 69 modules, with no new types or laws. The
[compiler-cost report](../implementation/phase36/compiler-cost.md) measures
normal checked requests separately, and the
[profiles](../implementation/phase36/profile-findings.md) cover both wins plus
lexer and tree sorting. The [admission record](../implementation/phase36/performance-admission.md)
keeps costs and semantic scope explicit.

## Historical Phase35 checked-output measurements

The checked09 full confirmation completed all fifteen maintained points in
518.34 seconds, using serial fresh Node 24.18.0 processes on CPU3 and fresh
same-run Phase32 and pinned TypeScript references. The fourteen shorter points
have five rotated rounds; raytrace has three. Warmup is at least 1 second,
with three calls for the shorter points and one for raytrace; the timed target
is 300 ms. Values below are median milliseconds per call from
`combined-full-confirm-01`, not prototype output or compiler-throughput results.

| Program | Phase32 reference | Checked09 | TypeScript | Reference / checked09 | Checked09 / TypeScript |
| --- | ---: | ---: | ---: | ---: | ---: |
| Local array pair | 5.046 | 3.810 | 1.246 | 1.324× | 3.058× |
| Local array fold | 0.3302 | 0.1399 | 0.0400 | 2.360× | 3.497× |
| Edit distance | 20.700 | 16.201 | 4.972 | 1.278× | 3.259× |
| Symbolic regression | 106.609 | 15.529 | 1.108 | 6.865× | 14.021× |
| Raytrace | 10,291.414 | 1,879.845 | 34.315 | 5.475× | 54.781× |
| Mandelbrot | 0.2094 | 0.2088 | 0.0457 | 1.003× | 4.574× |
| Tree bitonic | 25.344 | 25.393 | 0.3018 | 0.998× | 84.142× |
| Lexer | 176.709 | 172.003 | 1.929 | 1.027× | 89.150× |

The main gains come from removing repeated representation and dispatch work
inside substantial guarded regions. They do not transfer uniformly: the lexer,
tree bitonic and several generic library cases remain far behind TypeScript.
The full run's complete generic row was 9.52% slower (0.457966 → 0.501585 ms).
A separately retained five-round follow-up, `generic-row-confirm-01`, measured
0.453832 → 0.455299 ms, a 0.32% slowdown with overlapping ranges, using
600 ms warmup and a 250 ms timed target. It did not reproduce the first
regression; neither result is discarded or treated as a universal no-regression
guarantee. Short library programs also show material within-run drift.

The [Phase35 report](../implementation/phase35/README.md) retains every point,
artifact identity, controls, profiles and release status. These measurements
describe a checked candidate and do not by themselves establish installation,
broad conformance or a production workload average. Earlier Phase32 reports
remain historical measurements under their original protocols.

## Keep three iteration loops separate

1. **Test the mechanism on saved JavaScript.** Keep the checked original and
   pinned TypeScript output immutable. Derive a separately named variant with
   one change, validate complete results and relevant observable boundaries,
   then compare those bytes. This needs no compiler rebuild. A manually edited
   program is an experiment, never the compiler's measured output. Include both
   a scalar fixture and a complete-state generic row for runtime edits: Phase30's
   first broad matrix exposed a common generic slowdown despite its scalar win.
2. **Implement a surviving rule in Bend.** Build a fresh checked attempt, emit
   the small fixture with that compiler, run independent numerical and interface
   controls, and measure its actual output. Phase30 checked builds plus 36
   focused gates took roughly 35–40 seconds; one original-library emission took
   about five seconds. These acquisition durations are not compiler benchmarks.
3. **Integrate once the candidate is stable.** Run selected upstream execution,
   the small library corpus, real compiler components, the original algorithms
   and the HVM application. Run the expensive original-program timing here,
   then verify the installed release and relocated CLI.

Build and emission use the maintained workflow, from the repository root:

```sh
node --stack-size=4096 --max-old-space-size=4096 \
  selfhost/tools/development/workflow.mjs run BUILD_CONFIG.json NEW_ATTEMPT
node --stack-size=4096 --max-old-space-size=1024 \
  selfhost/tools/performance/phase26/emit.mjs NEW_ATTEMPT \
  selfhost/tools/performance/phase30/fixture-scalar-region.bend NEW_OUTPUT.mjs
```

The config names the selfhost project and pinned upstream checkout, uses the
`equality` profile with `strictExact: true`, and chooses a CPU outside the timing
slot. Read the [development workflow](PHASE5_DEVELOPMENT.md) for configuration,
lineage and release installation. Use a new output directory for every attempt.
The pinned compiler builds a genuine checked parent; ordinary compilation with
the resulting Bend compiler has no TypeScript fallback.

## Measure the workload you intend to improve

The maintained program execution loop and the
[historical comparison harness](../selfhost/tools/performance/phase29/compare.py)
use frozen configs, exact per-call results, fresh Node processes and rotating
serial CPU3 order. Stop other compilation, execution, profiling and compression
during a clean comparison. Record Node version, stack/heap bounds and input hashes.

The following is the historical Phase29–32 protocol, retained to interpret those
reports. Current budgeted runs record their exact settings in each frozen plan;
the Phase35 confirmation settings are stated above.

| Historical protocol | Samples per side | Warmup minimum | Timed target |
| --- | ---: | --- | ---: |
| Screen | 3 | 8 calls and 100 ms | 150 ms |
| Confirmation | 5 | 100 calls and 3 s | 300 ms |
| Original-program transfer | 5 | 3 calls and 1 s | 300 ms |

Warmup floors do not prove convergence. Keep first-call costs and both timed
halves. Phase30 retained cases where short-window rankings reversed, as well as
large gains whose whole-program paths still improved during the measurement.
A separate longer-warmup experiment has its own frozen protocol and receipts;
it never replaces an inconvenient earlier result.

Do not send a multi-second original program through the 100-call confirmation
floor. Use a small real component—one edit-distance row, one complete histogram
chunk or a small tree—with the same generated mechanism and a complete oracle.
Use the original program later to test whether the benefit transfers. Separate
instrumented event counts and profiles from speed measurements; fewer generic
calls do not imply the same proportional speedup.

For a shared runtime change, retain both a scalar improvement case and a generic
record/array case in this short loop. The complete-state edit-distance row is
useful for the latter. Phase30's integration matrix caught a common generic-path
regression even after the scalar benchmarks improved sharply; a scalar-only
screen cannot establish that an application/runtime change is broadly cheap.

## What remains expensive

Private field vectors outside the proved countdown-state grammar still allocate.
Array reads outside the immediate-consumer shape still construct tuples. The
Phase35 scalar replacement preserves complete state and aliases for its admitted
shape; widening that shape needs a separate proof and measurement.
Externally supplied data, higher-order calls and unsupported recursion still
retain generic dispatch. A floating-point helper can be too small to pay for a
guard: Phase30's acyclic F32 entry experiment regressed both hit and miss paths.
Extending coverage requires proving ownership/aliasing and delayed-field demand,
not merely recognizing an array or deleting a runtime call.

Results for a selected helper or algorithm are not a production average. Keep
absolute times and TypeScript ratios for every original program, compiler
throughput separately, and native/device execution outside the demonstrated JS
scope. The reports retain rejected alternatives so subsequent work can start
from evidence rather than repeat the same probes.

Compiler throughput has separate constraints. The historical Phase32 private checker
projection experiment improves selected helpers, but public getters and mutable
API callbacks prevent applying that shortcut generally. Complete-world semantic
checkpoints preserve the tested results but cost too much to retain. Scoped
memoization did not pass its declared speed criteria. Even reusing a repeated
stop-list query breaks a concrete default-API mutation case. Read the
[experiment reports](../implementation/phase32/README.md) before introducing a
cache or changing this ownership boundary.
