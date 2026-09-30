# Phase26: direct native U32 decisions

## Objective

Remove the measured representation overhead of scalar numeric patterns from the
Bend implementation of the JavaScript emitter. Phase25 established that every
native U32 match currently builds a 32-bit linked word, and selected decision
functions expand into hundreds of generic matchers. First test a small, strictly
guarded compiler change. Keep the ordinary checked bootstrap loop and existing
function ABI; do not start another full self-reproduction campaign.

Baseline: commit7199b391865f79acd38e67b44c4fdf21bfa721e9, upstream
018751270e800bc222a93dad7f257083ee53a5f7, installed API7b523bdf. Exact identities
and the103 protected pre-existing paths are in implementation/phase26/start-state.json.
The original Phase25 emissions provide frozen, checked before/TypeScript outputs.
Copy the installed API/runtime/Base/release metadata before source edits.

## 1. Conservative decision worker

Recognize a top-level native U32-to-U32 matcher with closed numeric terminal
results. Verify native type and constructor ownership, including Bool, Word.Nil
and Word.Con. Walk the elaborated ordered matcher tree, using unsigned bit tests
on the original scalar. Decode terminal literals with the existing literal
helpers. An ignored default binder may end at a closed literal; used binders,
captures, arbitrary effects/calls and residual structural word results use the
existing generic emitter. A failed recognition emits no partial replacement.

Recognize before deep closure lifting, so unused factories for the discarded
matcher tree are not emitted. Reuse fn(1,...) and normal global registration;
do not change application arity, partial application, exported descriptors,
forcing order or runtime code. Bound traversal and avoid repeated expansion of
ignored bits. No general decision-tree IR or runtime datatype is needed.

## 2. Correctness before timing

Build a genuine checked upstream B1 and the maintained guarded equality profile;
run the36 standard focused observations. Separately compile and execute paired
JS libraries covering dense/sparse tables, unsigned boundaries and neighboring
keys, nested captures, multiple columns, partial/higher-order application,
structural Word views, variable/default fallbacks, unselected divergent branches,
and user-defined U32 identity/refusal cases. Use independent expected outputs,
an exhaustive byte domain and fixed full-width pseudo-random inputs.

Rerun the23-source Phase25 emitted corpus and all127 independent scalar checks.
An independent reviewer challenges native identity, ordered/default semantics,
compile-time expansion and demand preservation. Any mismatch blocks promotion.
Keep failed source/build/measurement attempts with their original identities.

## 3. Measure the changed mechanism

Use unchanged Phase25 execution/calibration tools on newly emitted libraries.
Freeze inputs, API/runtime/Base/driver/tool hashes before acquisition. Compare
old output, candidate output and pinned TypeScript output on CPU3 serially,
Node24.18.0, stack4096, heap1024, with at least100ms/eight-call warmup and five
fresh processes per side. Side-specific calibration targets150ms, capped at1M
calls; compare time per call, retain all samples and exact output checks.

Start with dense and full-width numeric kernels, a boundary control and scalar
arithmetic unaffected control. Use independent allocation/operation diagnostics
to verify that word construction disappeared. Add a real extracted compiler
numeric helper if its result type fits the initial support envelope; label its
provenance and limitations. Report remaining generic loop/dispatch cost separately.
Microkernel speedups are neither whole-compiler speedups nor predictions of H.

## 4. Consolidate and choose the next step

Promote only if the scoped correctness gates pass, the intended mechanism is
removed and the implementation cost is reasonable. Install the checked derivative,
verify release lineage and preserve the prior release. Document source lines and
concepts added alongside measured gains and unsupported cases. Add usage and
reproduction instructions, update the compiler guide/README and experiment frontier,
write implementation/phase26/direct-u32-decisions.md, then commit and push.

Review match-boundary call lowering independently. Merely increasing call arity
can eagerly evaluate later arguments and change behavior. Defer that separate
optimization unless this experiment leaves enough evidence for a small, safe
next ablation; do not combine its attribution with numeric decisions.
