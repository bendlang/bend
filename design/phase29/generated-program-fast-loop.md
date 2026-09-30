# Phase29: fast experiments for generated-program speed

## Objective and baseline

Improve JavaScript produced by the compiler written in Bend, keeping checked
source semantics, the public calling contract and upstream pin unchanged. The
user authorized design, implementation, reporting and pushes to the existing
fork branch. No new upstream PR comment is authorized. This is a bounded phase,
not a renewal of earlier multi-hour budgets or a promise to eliminate every gap.

Baseline is commit e7395eaddf3de4055ad013673ec3c489b80b3342: installed Phase27 API
5a89c775, runtime40823818, sourcef3097523, upstream018751270e800bc222a93dad7f257083ee53a5f7.
The103 unrelated paths are inventoried and must remain untouched. Exact API/runtime
bytes and release manifest are frozen before compiler edits. Pinned upstream and
human-written bend2/bend.ts are never edited.

Phase28's original ten-library measurement costs816.11s. Raytrace and edit distance
account for659.49s of child execution,80.81% of that wall time. Mandelbrot, lexer
and tree sorting account for59.68s with the same checks/calibration/five-sample
protocol. Long-warm results still drift in some cases. These observations support
a small diagnostic loop and selected integration gates, not a relaxed correctness
standard or selective reporting of favorable warmup windows.

## Hypotheses

1. Primitive arithmetic dispatched through generic call/get/descriptor machinery
   imposes avoidable cost and conceals arithmetic from the host optimizer.
   Inline only identified native saturated operations with preserved order,
   scalar behavior and a generic fallback. Predicted observation: fewer runtime
   calls plus lower uninstrumented execution cost.
2. Matched arguments fragment known saturated calls into several unary calls and
   temporary partial descriptors. A private saturated worker/direct tail loop
   can remove those boundaries while keeping the public descriptor unchanged.
   Predicted observation: fewer partials/copies/bounces plus faster execution.
3. Generic constructor construction/projection/forcing can remain a later cost.
   Inspect and measure before adding a third interacting compiler mechanism.
   Do not change Nat representation, global evaluation strategy or algorithm
   simultaneously with the first two hypotheses.

Counter reductions alone are not success. A prototype that changes results,
argument demand or permitted numeric behavior is a failed attempt. A correct
prototype with no material speed gain argues against prioritizing that change.

## Sequential stages

### 1. Diagnose without a compiler rewrite

Extract a small fixture from actual Mandelbrot helpers, preserving source
definitions and varying coordinates/inputs. Acquire checked baseline and pinned
TypeScript outputs. Freeze source/module hashes and multiple expected results.
Make separately named disposable generated-JS variants: unchanged, arithmetic
only, private worker only, combined. Keep BigInt Nat/scalar representations and
the algorithm fixed. These are mechanism experiments, not compiler releases.

Keep unsuccessful derivations, incorrect outputs and infeasible transformations.
Run a bounded CPU/allocation/counter diagnostic separately from clean timings if
needed to distinguish remaining generic work; instrumented times are not speed
claims. Count all moved allocations, not only one old helper's branch.

### 2. Establish a maintained fast comparison

Root owns clean execution. Use Node24.18.0, CPU3,4MiB stack,1GiB heap, sanitized
BEND_*/NODE_OPTIONS/NODE_PATH environment. Acquire/build on other CPUs separately;
pause all builds and generated-program executions for comparative timing.

The initial screen uses three fresh samples/output, rotating serial order, a
separate first call, at least8 further calls AND100ms warmup, calibrated150ms
timed target,1M repetition cap and60s per-child deadline. Check every complete
result. Calibration uses separate processes and doubles to50ms/65536 calls.
Record timed halves, actual durations, import, first call, RSS, commands, source,
compiler/runtime, tool and Node hashes. No failed-case survivor aggregates.
Target5–10s for one small paired hypothesis; measure the actual wall cost.

Confirmation for promising or warmup-sensitive cases uses five samples/output,
at least100 further calls AND3000ms warmup,300ms timed target and120s deadline.
Keep both windows; do not claim convergence from a floor or tight sample range.
Thresholds are fixed before runs; changes require a prospective amendment.

### 3. Implement supported general emitter rules

Implement primitive inlining in Bend only after its guard/evaluation boundaries
are reviewed; prototype and code preparation can proceed independently but no
promotion occurs before causal/timing evidence. Build a genuine checked B1 with
the maintained workflow and compatible runtime. Re-emit the fixture and ensure
the compiler itself produces the intended code shape. Private workers are a
separate ablation; implement only when a sound, bounded rule and a worthwhile
prototype justify it. Keep generic fallback for unknown/partial/higher-order cases.

Tests cover checked source outputs, native identity versus same-spelled user
definitions, saturation and partial application, erased arguments, argument order,
U32 wrapping/division/shift bounds, Nat behavior, constructor ownership and deep
tail behavior as applicable. Reuse existing arm/numeric/library controls instead
of pretending frontend-only checks exercise changed emission. Independent review
challenges semantics and measurements before promotion.

### 4. Verify transfer and integrate

Measure already-emitted old/new/TypeScript outputs together on original Mandelbrot,
lexer and tree sorting inputs using the Phase28 original protocol. Run a separately
recorded longer-warm comparison where needed. Also retain an actual compiler
component and unaffected controls to detect narrow overfitting/regressions.
Keep compiler-build, emission, runtime and whole-process costs separate.

Escalate a surviving candidate to the other Phase28 programs and applicable
existing backend/conformance gates once, rather than every edit. The expensive
raytrace/edit-distance screen is justified at that integration boundary. Changed
calling/representation semantics require broader gates than simple local arithmetic.
Do not claim a new self-hosted fixed point or full native/device coverage.

### 5. Report, preserve and publish

Report each hypothesis, isolated and combined effects, failures, absolute costs,
TypeScript ratios, actual fast-loop duration, checked compiler identities and
remaining gaps. Record canonical line/concept changes and simplify duplication
where possible. Promote only a checked candidate passing relevant controls with
measured benefit; otherwise retain the old installed release and explain why.

Archive raw attempts/emitted bytes/harnesses with independent recovery receipts;
explicitly link Phase27/28 immutable prerequisites. Update compiler documentation,
README, experiment ledger/steering/preservation. Verify all103 protected files,
commit scoped paths, push the existing branch and give the report link.
