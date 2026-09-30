# Phase29 independent semantic review

Reviewer: `phase29_review`, separate from the primitive implementation owner.
This file distinguishes reviewed invariants, synthetic controls and checked
source execution. It is not a proof of complete compiler conformance.

Final candidate: genuine checked attempt-04, derived API
`10510efda268bac1f31cc8fed87a9315e8f9edfa15aad6b90b0d96756c217b11`;
unchanged runtime
`40823818afd57a6c37e055272dc332f461955a7cd225f67d66194f0d43ec823f`.
The maintained workflow's 36 strict focused cases passed with zero exact
differences. That gate is separate from the emitted-program controls below.

Attempt-03 (`578cfec83729…`) is superseded. Larger symbolic-regression and
ray-tracing programs exposed a recognizer stack overflow after its selected
gates passed. The explicit refusal fix passes fresh checked controls and both
original programs in attempt-04; see the integration finding below.

## Primitive identity and arithmetic

The new emitter rule is local to a fully saturated reference spine. It does not
replace the runtime primitive descriptor or increase public arity. The reviewed
guard requires the exact allowlisted name, native `Def`, no templates or foreign
body, the declared and supplied arity, a complete nonerased scalar telescope and
the appropriate native datatype/constructor owners. Every scalar domain/result
must have no parameters or removed constructors. Partial applications, unknown
functions, higher-order calls and unsupported operations retain generic emission.

The 54-operation manifest in `controls-operations.json` was specified separately
from the implementation. Review checked the **final** runtime registrations in
`selfhost/src/runtime/js/base.mjs`; earlier registrations are sometimes superseded.
Particularly relevant boundaries are:

| Operation | Required behavior |
| --- | --- |
| U32 add/sub/bit operations | Unsigned 32-bit result |
| U32 multiplication | `Math.imul`, then unsigned coercion |
| U32 division by zero | Zero |
| U32 remainder by zero | Dividend |
| U32 shifts by Nat | Zero when count is at least 32; no JavaScript modulo-32 count |
| U32/Nat conversions | BigInt Nat representation retained; low 32 bits on narrowing |
| F32 arithmetic/math | Binary32 rounding at the existing operation boundary |
| F32 division/remainder | IEEE Infinity/NaN and signed-zero behavior |

Conditional/repeated operands in division, remainder and variable shifts are
bound to private IIFE parameters. Both source arguments are evaluated once,
left to right, before the conditional. Other binary templates use each operand
once in JavaScript evaluation order. All primitive arguments are emitted in
nontail mode, so their existing forcing boundary remains. A primitive result is
a scalar and needs no new tail message.

Nat arithmetic remains unchanged, including the 48-bit checked bound. F32 pow
and F32-to-U32 were intentionally excluded from this first rule. No claim is
made about coercion of invalid raw JavaScript objects passed as native scalars,
replacement of built-in JavaScript intrinsics, or host mutation of the compiler's
private primitive registry. Controls use valid scalar representations.

## Completed controls

The first synthetic run against checked attempt-01, API `bf578858`, passed
1,129 recognizer checks and 25 emitted runtime observations. Its report is
`selfhost/build/phase29/controls-guards-01/report.json`; the exact consumed tool
and append-only diagnostic export are retained alongside it.

The recognizer matrix covers every operation, missing/extra arguments, arity,
native flags, definition kinds, templates, foreign and annotated foreign bodies,
each erased/wrong/parameterized/refined argument, malformed results, missing or
non-native owners/constructors and unsupported names. Synthetic books test the
guard, not whether the frontend would admit those books.

Eight actual emitted saturated sites cover arithmetic, zero division/remainder,
large shifts and F32 operations. Host argument producers record left/right
evaluation, throw distinct sentinels, and demonstrate that conditional results
do not suppress either argument. The public partially applied U32.add retains
arity 2, null environment, owned bound arguments and its original bound vector
after saturation. Every selected site contains the new primitive marker.

Checked-source acquisition also passed. The same `controls-primitives.bend`
source was checked and emitted independently by upstream, Phase27 and Phase29.
All 56,205 scalar/ABI observations agreed with the independent mathematical
oracles, including unsigned high bits and wrapping, zero divisors, Nat shifts
above 31, maximum Nat narrowing, F32 signed zero, subnormals, infinities and NaN.
Every one of the 54 primitive wrappers actually selected the new emitter rule;
the shape audit is retained separately as `controls-checked-shapes-01.json`.
Partial addition and shifting, a higher-order call, and 50,000 tail iterations
also passed. Raw evidence is in `controls-checked-01/`, including the exact
checked emission receipts and original module bytes. This selected coverage
does not renew the broader frontend, native or device conformance inventory.

## Private workers and later call grouping

Changing the public arity of a matcher is unsafe. A first application can
evaluate or fail while selecting its arm, before a later argument expression is
demanded. Existing backend `apply-order` and `matched-apply-order` controls make
this observable with distinct invalid Unicode scalar values. A worker may only
cross that boundary with a separate demand argument and retained partial ABI.

A narrower possible alternative is to group extra arguments that are already
bound lexical variables or validated scalar constants. Such reads add no
observable evaluation before the intermediate match. The existing runtime
`apply` forces intermediate stages during overapplication, so public descriptors
could remain unchanged. References, constructors, lets, arbitrary applications
and decoding/checking expressions must initially fall back. This is a reviewed
proposal, not an implemented optimization in this phase.

The implemented worker instead preserves the original public Nat matcher and
selected-arm partial descriptor. Its private loop begins only after the
successor callback has received all its arguments. It recognizes an exact
native Zero/Succ countdown with flat scalar parameters, explicit live arm
lambdas and a self-tail call on the captured predecessor. It rejects changed
counters, non-tail recursion, other alternatives, native function overrides,
unknown constructors, erased parameters, duplicate parameter IDs, malformed
parallel binding groups and predecessor shadowing. Arity, tree-size and existing
deep-closure boundaries remain bounded.

At each loop entry, private mutable state is copied into fresh lexical constants.
Closures capture that iteration's values. Each next argument is evaluated once,
left to right, into a fresh temporary before any state is updated. Parallel let
right-hand sides retain their outer scope and erased right-hand sides are not
evaluated. The only moved match is discrimination of the known native predecessor
with literal residual lambdas, which cannot execute a branch body before the
remaining arguments arrive.

Review caught and corrected signature aliases, predecessor-ID reuse and malformed
parallel binding groups before the final checked build. Failed attempt-02 is
retained: Bend rejected a match after a local binding in the compiler helper.
Attempt-03 moves type normalization behind a helper boundary, with the same
intended emission semantics.

Earlier attempt-03 passed a fresh primitive run: 1,129 guard checks, 25 emitted
order/partial observations and 56,205 scalar/ABI observations. It also passed
3,759 checked worker scalar observations against both upstream and Phase27 plus
14 baseline-equal descriptor, callback, error-order and escaped-closure
transcripts. The synthetic worker suite passed 36 guard cases and two executable
erased/parallel-let witnesses. Counts overlap in purpose and are not a new broad
conformance denominator.

The 25 runtime rows are observations in one ordered-control suite, not 25
independent conformance cases. Likewise each mathematical scalar point is run
against three emitted modules; the reported execution counts do not imply that
every execution tests a distinct language feature. The attempt-03 raw boundaries are
`controls-guards-02/report.json`,
`controls-primitive-final-01/comparison/report.json`,
`controls-worker-guards-01/report.json` and
`controls-worker-checked-01/comparison/report.json` under the Phase29 capsule.

Eight checked functions actually selected the worker: countdown, swapping,
parallel local values, Nat and F32 carried values, escaping closures, a delayed
Zero-arm callback and observable left/right transitions. The checked Bool-carried
case retained the conservative fallback because its elaborated arm shape differs;
it is a semantic regression control, not evidence that this worker lowered that
case. Non-tail and changed-counter functions also retained fallback. Both the
selected and fallback shapes are recorded in `controls-worker-shape-01.json`.
The runtime checks include 0/1/many iterations, 50,000 tail iterations, unchanged
public partial arity/bound vectors, no premature branch execution, fresh captured
values and distinct left/right exceptions.

## Integration finding: eager Boolean guards

The original combined candidate failed checked symbolic-regression and ray-tracing emission with
`Maximum call stack size exceeded`. Generated compiler inspection showed that
Bend's Boolean `&&` calls evaluate both arguments. An unsupported nested Nat
matcher has zero leading successor lambdas, but the eager guard still evaluated
`total - 1`, wrapping zero to 4,294,967,295, and descended through a recursive
lambda predicate. Earlier selected tests did not include this rejected shape.

The implementation owner and this reviewer independently identified the unsafe
descent. The replacement uses explicit `kc` branches before arity subtraction
and recursive predicate calls, and caps leading-lambda counting at 33. It changes
recognizer demand, preserving supported worker emission. Primitive telescope
predicates received the same explicit structural fencing. The fix has been
reviewed and passes fresh checked execution. The original failing attempt,
stack diagnostic and selected successes remain evidence of their actual scopes.

New controls retain a minimal checked nested-Nat source and a derived synthetic
suite with zero, one and excessive successor-lambda prefixes. The new synthetic
suite reproduces the stack overflow on attempt-03 after its first 15 guard
observations, then passes on attempt-04. This old-candidate failure is deliberately
retained as `controls-worker-frontier-old-03/`, including the diagnostic API and
exact derived tool. The original frozen guard tool was not edited.

Fresh final controls under `controls-final-04/` pass 56,205 primitive scalar/ABI
executions, 1,129 primitive guards and 25 ordered observations; 3,759 worker scalar
executions and 14 ABI/effect transcripts; 40 worker guards and two executable let
witnesses; and 144 checked nested-Nat outputs across upstream, Phase27 and the
new candidate. The nested cases all retain generic fallback. Both previously
failing original programs, and all ten original library workloads, now check,
compile and return their full expected result (`transfer-04/report.json`).

The two existing checked control modules and all eight previously emitted
original program modules are byte-identical between attempts 03 and 04. This
confirms that the refusal fix leaves those already-supported emissions unchanged;
the independent hash comparison is `controls-emission-equivalence-03-04.json`.
No semantic blocker remains within the reviewed checked/native-scalar scope.
Performance and release promotion remain separate decisions in the phase report.
