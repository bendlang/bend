# Independent review of ordinary roots and the tree experiment

This is a static review by the analysis agent, separate from implementation and
owner-executed controls. No compiler invocation, program execution or timing was
performed for this review. Both scopes below are favorable within their stated
stable host-intrinsic contract; neither finding is a general backend-conformance
claim.

## Checked attempt11 ordinary roots

Reviewed the maintained diff and immutable attempt11 source:

| File | SHA-256 |
| --- | --- |
| `region.bend` | `4000bef184f9ee6fe73ad1119ce4190e4f2b187a404a6b35b49756d2bbf5433e` |
| `worker.bend` | `43f435c853dc0bca7b7ca1bda3cb54c3751937692d8b5163883bd4d447619c2a` |
| `emit.bend` | `f1a258f5fd6db0819ba2562df45aa8012b05dcca19b7f16a6cb352f39c2f816d` |

The actual original Mandelbrot output is
`selfhost/build/phase30/ordinary-region-11/candidate.mjs`, SHA-256
`87a451969d5c2a6f073f41fc8f5dda58cde08a381cc200b51d69a62597b47b8c`.

The root gate requires an ordinary, template-free, bounded complete native-scalar
lambda telescope and scalar result. Distinct unlabelled binders and existing deep
closure refusal remain. The existing analysis starts with the root active,
preserving cycle exclusion and the same helper/depth/work budgets. There is no
second analysis state or unbounded recursive helper admission.

The profitability gate accepts only a successfully admitted helper whose retained
body is a Nat matcher. Ordinary Boolean helper matches are lowered to private
expressions, so their presence does not accidentally satisfy this gate. An
unreachable loop in the book likewise does not qualify the root.

Actual `pix` and `rpix` output retains the original ordered argument-slot reads,
then checks exact entry, scalar values and the entire owner/helper closure.
Full Nat parameters use the inclusive native maximum; successor predecessor
slots retain the strict bound. Private nested `mit` still handles unprojected
zero before subtraction. The root itself is snapshot-captured by the existing
global emitter. Rejected/raw/overapplied/mutated cases retain the original generic
expression using already-read slots. No blocker found.

The separate reviewer's synthetic admission/refusal suite in
`review-ordinary-root-admission-11b` is complementary execution evidence, not an
execution performed by this review.

## Disposable scalar binary-tree output

Reviewed `prototype-tree-region-derive.py`, the prospective
[tree design](../../design/phase30/pure-scalar-tree-region.md), and control framing.
The experiment is based on checked attempt10; it is separate from the attempt11
ordinary-root change above.

The private evaluator preserves depth-first left-before-right order. It evaluates
left arguments into temporaries, saves immutable parent aliases, and visits the
left child. Only after that child completes does it restore parent aliases and
evaluate right arguments. It combines the two child values only after the right
child completes. The derivation refuses a combining expression that captures a
parent parameter, and refuses child arguments referring to the new parallel
result binders. Slot updates follow all corresponding argument temporaries.

There is no recursive call from the private tree function. Explicit frames
contain parent scalar slots, stage and completed left result. The validated
predecessor bound `<32n` reconstructs public depth at most32 and bounds live
continuation storage; it does not authorize executing a huge tree in tests.
The separate post-guard sentinel controls are appropriately used for that
boundary. Nested `mit` remains the existing private iterative loop.

The unchanged external Zero arm, registered exact successor entry, original slot
reads, complete nine-descriptor guard and original fallback preserve the stated
public scheduling boundary. The intermediate public-leaf variant retains the
original forcing point and the same closure proof; it is not an optimization for
arbitrary effectful public leaves.

The new private Array stack relies on the documented standard host-intrinsic
scope. Arbitrary inherited numeric Array prototype setters could observe its
new storage operations and are not covered by that contract. Relevant supported
public descriptor/matching prototype hooks remain subject to the existing
guard and fallback. No additional blocker found within the declared scope.

## Maintained attempt12 tree emitter and shared Nat header

Independently read `tree.bend` and the attempt11-to-attempt12 `worker.bend`
refactor. The factoring preserves the old countdown predicate: the shared
`j_nat_scalar_shape` performs the same header, telescope, bounds and binder
checks, and `j_nat_loop_shape` still requires the original captured-predecessor
self-tail shape. A binary tree cannot accidentally become a countdown worker.

The tree gate requires exactly two non-erased parallel bindings. Each right
side is a saturated owner call whose first argument is the captured predecessor;
binding identities differ from one another and every parent parameter. The
existing scalar signature excludes record state/results. Both child expressions
use the old parent environment. The combination receives only the two scalar
results, so it cannot accidentally read stale parent slots after an unwind.

The owner remains active while the existing region analyzer checks child
arguments and helper bodies. Self calls are permitted only at each explicitly
recognized child spine; argument analysis clears that permission. Nested owner
calls, indirect owner reentry, unknown calls and incomplete helper cycles thus
refuse. Zero, left, right and combine carry the same helper accumulator and
fuel, rather than independently resetting resource limits.

Emission follows the reviewed prototype: compute all left arguments, retain
immutable parent aliases, enter the left child, then restore those aliases for
right-argument computation only after left completion. All child argument
temporaries precede slot assignments. The combine occurs only after right
completion, then the frame is popped. A labeled iterative visit loop and explicit
frames replace host recursion; nested countdown helpers keep their own loop.
The shared lambda-body emitter's old use remains `return` with tail emission;
the tree Zero use assigns the complete scalar value with non-tail emission.

The public matcher, external Zero arm, fresh exact-entry callback, ordered slot
reads, predecessor bound, full descriptor closure and generic fallback retain
the prior proof boundary. No static blocker was found under the declared host
intrinsic scope. The independent actual-emission mathematical, ordered-boundary
and admission/refusal controls remain required execution evidence; this review
does not substitute for them. The extra admission traversal's compiler cost is
left to the separate final ordinary-compiler measurement.
