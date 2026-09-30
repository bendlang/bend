# Generated-program performance and the fast development loop

Use the [compiler guide](BEND-IN-BEND.md) for normal compilation and the
[Phase31 report index](../implementation/phase31/README.md) for exact results,
artifact identities, failed experiments and current promotion status. The target
remains upstream `018751270e800bc222a93dad7f257083ee53a5f7`. The comparison is
between JavaScript emitted from the same Bend source by the two compilers.
Compiler checking cost is a separate measurement.

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
The isolated experiment improves RLE and a complete generic row by about5–6%;
it does not remove generic descriptor, matching or record-construction costs.

Phase31 extends eligibility, so previously generic-only modules can now register
workers. Their remaining generic calls pay the existing registry lookup. The
controlled [registration diagnostic](../implementation/phase31/generic-registration-diagnostic.md)
explains the measured roughly5% generic-row regression; the scalar zero-work
entry separately pays about0.18µs for stronger prototype checks. Both costs are
explicitly disclosed in the [admission amendment](../design/phase31/admission-tradeoff.md),
rather than classified as no-regression passes.

The analysis is deliberately bounded: at most 32 completed helpers, dependency
depth 16, one shared 32,768-unit budget, bounded source/expressions/bindings, and
an active-name set that rejects unsupported cycles. Failed analysis uses the
ordinary emitter. The internal `JSlot`, `JCall`, `JIf`, `JNative` and `JUnpack`
terms belong to emission;
they are not fed back into checking or evaluation. See
[region.bend](../selfhost/src/back/js/region.bend),
[worker.bend](../selfhost/src/back/js/worker.bend), and
[tree.bend](../selfhost/src/back/js/tree.bend).

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

The [maintained comparison harness](../selfhost/tools/performance/phase29/compare.py)
uses frozen configs, exact per-call results, fresh Node processes and rotating
serial CPU3 order. Stop other compilation, execution, profiling and compression
during a clean comparison. Record Node version, stack/heap bounds and input hashes.

| Protocol | Samples per side | Warmup minimum | Timed target |
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

Closed local records and arrays now qualify, but their ordinary storage still
allocates tuples on native reads and record shells for loop state. Removing a
generic projection does not remove its producer's allocation. Possible next
experiments are return-position field bindings and worker/wrapper scalar
replacement, with full native-event and alias controls. Their gains are unmeasured.
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
