# Checked-source coverage for scalar tree results and refusal

The independent attempt12 tree books cover native Bool/Nat carried state but
return U32. Add one bounded source fixture compiled by pinned TypeScript and
the immutable attempt11/12 images, exercising the whole checked source pipeline.
This is a correctness gate, not a new optimization or performance experiment.

Positive cases return Bool and Nat with differing left/right state transitions
and a noncommutative combination. A third tree carries and returns native Nat,
including the full supported48-bit maximum. Its scalar Bool-choice helper
consumes both child results, preventing dead-binding simplification from making
an intended two-child admission witness ambiguous. The oracle is a separate recursive
JavaScript definition with explicit U32 wrapping and native scalar results.
Use depths0,1,2,3,5 and a short deterministic state set; never execute an
exponentially large boundary depth. Require actual12 tree markers on these
definitions and absence of that marker on actual11.

Execute source-valid negative neighbors: a combine capturing a parent parameter,
one child, three children, a changed predecessor, F32 state/result, a sequential
two-let tree outside the initial strict parallel-binding rule, native Base
Boolean helpers outside ordinary-source private capture, and a record
result. Assert each remains ordinary generated code, then compare its complete
result against the independent recurrence and both compilers. Observe the record
through an ordinary checked source projection wrapper to compare language
results without imposing the same JavaScript record representation on TypeScript.

Add a small actual11/12 public guard check for the new positive result shapes:
live owner code replacement and saved partial replacement preserve full event
order and scalar results. Existing independent tree host/entry/prototype/copy
controls remain the broader boundary gate; do not reproduce them all here.

Freeze source, oracle, emitters, upstream Base/compiler identities and each
attempt manifest before acquisition. Preserve checked emission receipts and
original source copies. Each child uses CPU7 and a120s deadline. A source
checking failure remains retained; fix it in a new attempt directory rather
than rewriting a failed receipt. No production compiler/runtime edit, no clean
timing, no new global frontend conformance percentage follows from this fixture.
