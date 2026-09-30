# Phase27: remove redundant application at constructor arms

## Objective and frozen baseline

Reduce generated JavaScript dispatch without changing when source arguments or
selected branches execute. Phase26 removed native word construction but left
thousands of generic applications and partial records in traversal kernels.
Test the bounded proposal from its call-lowering analysis before adopting a new
calling convention or full compiler rewrite.

Baseline commit0f51c00cd040fb661d4544dc47530f2ba6cb3985, installed API4c67ac04,
checked parent818f68ca, upstream018751270e800bc222a93dad7f257083ee53a5f7. Exact
identities and103 protected paths are in implementation/phase27/start-state.json.
Preserve the prior usable release and all failed attempts. User authorization
includes implementation, documentation and pushes; **no new PR comments**.

## 1. Fuse the selected partial arm

Start only with a single remaining constructor, a literal non-lifted lambda arm,
all constructor fields live, and positive field count smaller than the arm's
leading lambda count. Reuse annotation/type-telescope and lambda-code helpers.
Keep the outer matcher arity1 and the returned partial record's original arity,
environment, code closure and copied bound fields. Keep project and its ownership
semantics. Reject erased, eta-short, lifted and unknown shapes.

The old path creates an arm function, jumps to it with projected fields, copies
the fields and creates another partial function. The candidate emits that final
partial descriptor directly, removing the first function record, bounce and
apply entry. Later argument applications and selected branch bodies remain delayed.
This does not raise public function arity or reorder source argument evaluation.

Preserve the original projected-vector length read and generic fallback when its
length differs from the expected count. After one slice, preserve apply's three
exact saturation/partial/overapplication branches: a custom slice can return a
different vector. Reapplying a prebound descriptor with empty arguments would add
observable concat/copy operations, so it is not a valid general fallback.

No runtime edit or new IR is planned. If the small rule is not measurably useful,
retain the rejected experiment rather than accumulating inactive compiler paths.
Any broader exact-saturation/inlining extension gets a separate hypothesis and
uncombined measurement before promotion.

## 2. Correctness and transfer

Build one immutable genuine checked B1 plus the maintained guarded derivative;
run36 standard focused observations. Run actual emitted-library controls against
the old and candidate API: partial/higher-order/overapplication behavior, descriptor
arity/env/bound, captures, field and later-argument order, mutation/getter ownership,
unselected effects/errors, erased/eta-short/lifted fallbacks, abnormal field vectors
and custom slice behavior. An independent reviewer challenges the transformation.

Re-emit the23-source Phase25 corpus and verify all127 independent scalar points.
Its preserved reference receipts establish source/oracle identity; runtime timing
uses Phase26 candidate emissions as the **before** output. Recheck a bounded
upstream JS selection around constructor/closure/erasure/word patterns. Extract
at least one actual compiler helper affected by this rule if present, keeping its
body bytes and dependencies identified; use an independent complete-output oracle.
If no such helper qualifies, state the transfer limitation explicitly.

## 3. Mechanism and timing

Use the existing Phase26 three-output measurement harness unchanged. Freeze exact
checked output identities, inputs and expected outputs first. CPU3/Node24.18.0,
stack4096KiB/heap1024MiB, at least100ms/eight calls warmup, side-specific150ms
calibration capped at1M calls, five fresh processes per output, rotating serial
order. Stop other agents' execution during clean timing. Retain all samples.

Primary kernels: match-remaining-args, partial-application, term-substitution,
Boolean worker/choice, scalar arithmetic and the actual compiler component.
Use host-boundary and Phase26 numeric-table behavior as controls. Start with a
small screen; broaden only if effects, correctness or transfer warrant it.
Measure exact helper counts separately to test the predicted fn/apply/bounce
reduction. Static code growth and source complexity are separate measurements.

Reject correctness differences. Do not promote a rule whose timings regress
representative affected workloads without a clear, bounded explanation and a
successful correction. Tiny changes near observed spread are inconclusive,
regardless of attractive operation counts. Microkernel or component gains do not
establish whole-compiler/H speed. No new full self-reproduction is required.

## 4. Consolidate

Install only after scoped correctness, source review and measurement gates pass.
Verify lineage and an ordinary CLI smoke. Write implementation/phase27 report,
preserve raw evidence with byte-verified recovery, document support and remaining
gaps in the compiler guide, update README/ledger/steering, then commit and push to
selfhost/bootstrap. Leave the103 unrelated starting paths unchanged. A null result
is reported and checkpointed with the previous compiler still usable.
