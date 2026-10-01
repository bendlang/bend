# Eliminate private loop-state vectors

The Phase34 profiles place 65.40% of full-pair sampled allocation at `cell.f4`.
The hot row loop calls a chain of private helpers ending in a fresh four-field
vector for every cell. The independent fold similarly returns a two-field vector
for each iteration. Those values are consumed only by the next loop iteration
and the loop's terminal continuation in these fixtures.

## Falsifiable first experiment

Freeze the Phase33 baseline and edit only emitted private helper copies. Compare
three variants in the maintained suite: unchanged, helper-chain inlining retaining
one fresh state vector per iteration, and the same inlined loop with state fields
in local slots. This separates inlining from aggregate elimination. Keep Nat as
BigInt, all U32 rounding, the original native array primitive and the exact read /
write order. Preserve public definitions, closed-region guards and generic fallback.
The prototype is explicitly a manually written emitted-output ablation, not an
implemented general compiler rule or a proof of general correctness.

Use the complete pair and fold first, then original edit distance and full state /
logical native event controls. Every comparison uses fresh same-window measurements;
historical ratios are context. Root runs every job serially with existing resource
supervision. No compiler or benchmark runs in this agent.

## General compiler target

Do not add benchmark-name dispatch. Extend the already proved private first-order
region: bounded inlining exposes a complete record producer/consumer chain, then
scalar replacement tracks each field of an unescaped local record in its own SSA
slot. Loop-carried aggregate phis become one phi per field; terminal uses reify a
vector where needed. Parallel assignments snapshot all fields before rebinding.
Private read bridges must still read at the producer point, even if unused.

The existing region admission proves value representation and lack of foreign
callbacks, but it does not itself prove that every record has a unique alias.
Therefore reusing and mutating one backing record vector is not an acceptable
shortcut. Scalar replacement retains distinct field environments for aliases.
Reject unfamiliar use forms, escaping values, public terminal records, live
getters and any field evaluation whose order cannot be preserved. Retain exact
initial-zero and loop-to-zero behavior and the existing result boxing boundary.

First implement only the shape that survives the ablation. Bounded private
statement inlining may be independently useful, but generated-source growth and
compile-time cost need their own admission checks. A more general SSA backend is
not justified solely to handle this one opportunity.

## Measured refinement

The unrestricted first checked inliner passes semantic controls but regresses pair,
long scalar and Mandelbrot. Keep it as rejected evidence. Restrict inlining to
private-vector results before testing scalar loop state: an optimizer should expose
one proven aggregate-elimination opportunity, not copy every scalar helper. The
second stage scalarizes only the last vector argument of an admitted private Nat
loop, leaves initial zero unchanged and boxes its result before the old zero arm.

A separate alias fixture carries the old state through an earlier parameter while
swapping and updating the final state. This must distinguish scalar replacement
from unsafe reuse of a mutable shared output buffer. Validate all tuple fields via
an independent BigInt oracle, U32 wrap cases, deep countdown and public mutation
fallbacks, in addition to the full pair/fold storage schedules.

## Private countdown representation

After vector scalarization, allocation profiles still concentrate almost all hot
work in row/fold loops. Test one orthogonal hypothesis before changing more array
code: an unobservable countdown still pays BigInt decrement and comparison each
iteration. Native Nat values are bounded below 2^48, so a Number represents every
admitted value and predecessor exactly.

The compiler rule is intentionally narrower than general Nat unboxing. A nested
private vector loop must already have a valid exact self-tail transfer, and its
predecessor must occur exactly once throughout the complete successor plan, as
that first self-tail argument. Scan annotations, copied helper bodies, closures
and ordinary children; reject an ordinary arithmetic conversion, a stored field,
a second use or an indirect alias. This lets the counter become Number without
changing a source value's representation. Keep the initial zero branch, public
Nat ABI, generic fallback and zero-arm arguments unchanged. Nonvector loops
retain their previous representation in this phase.

Capture the Number intrinsic once at runtime module initialization. A fresh call
to the live global Number would introduce an observable callback that the old
countdown did not have. The counter conversion uses that private capture; existing
array-index conversions stay at their original positions and use the existing
runtime behavior. This assumes the repository's standard host intrinsics at
module initialization, and preserves replacements after import.

Validate this with the existing full pair/fold storage schedules, alias/nested
state controls, dedicated source fixtures for admitted/rejected counter uses,
and complete public calls under Number replacement, getter and throwing hooks.
Extract actual emitted initializer/decrement/stop expressions to test a bounded
number of transitions near 2^32 and 2^48; never execute a near-maximum full loop.
The saved-output ablation and final checked compiler need separate receipts and
timings. A successful mechanism screen does not certify the source rule.
