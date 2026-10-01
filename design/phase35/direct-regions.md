# Finite Nat decisions inside direct regions

The Phase34 profiles assign roughly 30% of raytrace sampled allocation to four
finite Nat-to-F32 selectors. Their output contains eight nested native matchers
per selector. Each successive `Succ` creates descriptors, argument vectors and
trampoline messages; upstream reduces the same decisions to constant selection.
This experiment isolates control-flow lowering from constant folding and changes
to F32 arithmetic.

The first compiler extension admits an ordered, complete `Zero`/`Succ` chain
inside an already guarded private helper. It does not create a public selector
fast path or relax the region's entry/dependency checks. Admission requires the
matched Nat be the helper's last live argument and the chain contain at most 64
successor decisions. Native identity and all existing type, recursion, depth and
fuel restrictions still apply. Each selected result goes through the existing
`j_region_expr` analysis, so calls such as `fl` remain part of the complete guarded
dependency graph.

At depth `d`, earlier nonzero decisions establish `n >= d`. `JNatCase` emits
`n === d ? zero : successor`; the terminal lambda's original binder is represented
by `JEnvNat` and `JNatRest`, retaining its unique binder identity and type while
emitting `n - d`. Only the selected expression executes. A used remainder is
supported; an incomplete or reordered match is rejected. This is an equality
chain, not table precomputation: F32 leaf computation, rounding and demand remain
unchanged. It can later be folded into tables only under a separate constant-leaf
proof. The proof is a small form of pattern-match compilation; see the related
[compiler literature](literature.md).

A saved-output raytrace ablation separately measures the cost of the existing
matcher chain. It replaces only the five selector expressions, retaining exact
leaf source slices and live calls to `fl`. The guarded variant requires exact
runtime entry and the existing scalar prototype guard, then selects by a BigInt
switch. Its fallback reproduces the original outer matcher body. The unprotected
variant is only an upper-bound mechanism screen and is never a promotable
compiler result. One shared wrapper observes every selector through public calls;
the unchanged full raytrace entry remains available for transfer confirmation.

The independent selector oracle covers 0 through 9, 65,536 and maximum Nat, every
F32 result, live helper replacement/errors, malformed host inputs, manual callback
entry, callback `.call` overrides and primitive/Object marker hooks. A checked
source fixture additionally uses two selector argument positions and repeats the
terminal remainder. Root will run both source/compiler controls and the standard
unprofiled suite serially with process/RSS/deadline supervision.

This extension alone cannot admit raytrace's enclosing loops: the existing
private scalar proof excludes F32, and the Nat tail-loop recognizer does not
preserve self-tail transfers through residual Boolean matches. Those are separate
root-owned changes, measured individually where possible and integrated only
after their own boundary controls. The objective is one substantial guard around
complete work, rather than repeated guarded leaf entry.

## Preserve public stages while looping through a final Boolean

The larger follow-up targets countdowns whose last parameter is a Boolean match.
A source function such as `nearest.t` is publicly a Nat matcher, then a scalar
prefix descriptor, then an arity-one Boolean descriptor. Replacing it with one
saturated descriptor would change partial demand and error ordering. Instead,
retain the outer Nat matcher, original Zero arm, exact scalar-prefix arity and
binder reads. Replace only the final Boolean descriptor with an exact-entry
callback. It destructures that argument once at the original stage and copies the
immutable captured prefix into fresh mutable loop slots on every invocation.
Saved partial closures can therefore be reused without carrying the prior call's
loop state.

The recognizer requires both Boolean arms to end, through only permitted lets,
in a saturated self-tail call on the captured predecessor. Both zero branches
and all successor expressions still pass the region expression/dependency proof.
`JLoopSlot` is the current Boolean slot; the existing `JIf` statement emitter
selects the next-state computation. `JBranchZero` tells the terminal transfer to
bind all next-state arguments before selecting the original zero branch. Every
next argument is evaluated in source order before any loop slot changes.

Floating admission is a separate patch. F32 remains native and every operation
retains its existing `Math.fround` behavior. Because JavaScript Math methods are
mutable, new floating regions check captured global/intrinsic descriptors before
performing even the canonical-input `Math.fround` check. The guard also verifies
the array iteration/copy protocols whose generic calls the region would skip.
Changed getters, methods or descriptor dependencies select the original callback
body. Standard host intrinsics at module initialization are the stated boundary;
the guard protects subsequent mutations. Regions without any F32 syntax or
private F32 dependency keep their existing guard cost.

The separate saved-output branch ablation retains generic intersection and
selector calls, so it isolates the structural self-tail transfer. The compiler
extension additionally includes already-proven private helpers, making its
performance a distinct measurement. Final Boolean metadata, saved partial calls,
manual/forged callback entry, excess arguments, input iterator hooks, helper
mutation, Math mutation, F32 special values and a deep countdown are required
controls before a compiler result can be promoted.

## Later discriminator: inert comparison fields in terminal records

`nearest` additionally returns `Hit{U32.is_eq(index, 9), distance, index}`. The
current flat-record predicate admits only variables, literals and nullary Bool
constructors, so it rejects this result even after branch-loop admission. A
separate proposed patch admits only exact native `U32.is_*`/`F32.is_*` comparisons
whose operands are those existing inert forms. `j_primitive_call` verifies native
identity, saturation and the full scalar telescope; ordinary region argument
analysis still verifies each operand's type and provenance.

Those operations emit JavaScript primitive comparisons or `=== 0`. They call no
Math method or mutable helper, perform no constructor allocation or conversion,
and cannot invoke boxed-value coercion: the closed typed region establishes
primitive operands. This permits the comparison to remain at the original field
position and demand point. The ordinary boxed public constructor and field order
stay unchanged; fields containing helpers, arithmetic or nested computations
remain rejected. The proposal must be measured separately after branch-loop
validation, with complete Hit observations and deferred/public boundary controls.
# Partial regions after full-program transfer

The next region need not lower its entire reachable graph. A small loop can
contain an expensive residual generic call while still remove its own repeated
dispatch. The ray program's `colf` is the specific discriminator: a depth-14
balanced traversal per row computes a cheap scalar leaf predicate, returning zero
at inactive leaves and calling `pixel` only at active ones. Its source algorithm,
child evaluation order and U32 wrapping points stay unchanged.

The first experiment changes only complete fn5/fn6 callback entries beneath the
original public Nat matcher. One conservative host/dependency guard protects a
private balanced traversal for depths 0..24. Active pixel calls use their original
generic saturated convention. This tests whether eliminating dispatch on inactive
work matters more than making an already expensive active helper slightly faster.

Promotion requires two distinct bounded analyses. Existing region planning proves
the direct portion; a separate whole-graph purity analysis proves that a residual
call cannot run a callback that changes descriptors or host state before the next
direct operation. A failed lowering proof is never evidence of purity. The proposed
residual `JGeneric` node must carry planned arguments, the original checked result
type and every dependency required by the purity proof. Its emitter invokes the
original generic call at the original demand point.

The shared purity grammar admits canonical scalar primitives, monomorphic
non-native tagged ADTs whose fields recursively satisfy that grammar, complete
first-order calls and recursive references within the already checked graph. The
colf residual entry remains scalar-input/scalar-result initially; the recursive
tagged-type proof is shared with the separate sum-consumer experiment. It
must reject foreign/native calls outside an explicit pure allowlist, effects,
function-valued arguments/results, dynamic calls, arrays, unknown constructors,
erased/dependent runtime arguments and unbounded proof work. It must visit every
match arm and every field thunk, even though only a selected arm runs, because all
branches need the same no-callback guarantee. Cycles require an active set plus
completed cache; an active backedge may terminate graph discovery only after its
signature and syntactic body obligations are recorded.

`JPure` keeps a definition list, remaining fuel and a validity bit independently
of `JRegionBuild`. Each definition first validates its complete typed body into a
fresh list of direct callees. Only then is that definition reserved in the graph
state and its callees visited. Reserving after structural validation permits
recursive SCCs without allowing an unexamined branch to hide behind a backedge.
The type proof independently visits all constructors, sharing fuel across sibling
fields; an active recursive owner terminates only that field reference. Limits are
32 definitions, 32 constructors or fields, 128 expression levels, 8,192 source
nodes per definition, 512 type visits and the enclosing region's residual fuel.
Ordinary arguments are live and first-order; parameterized/dependent ADTs and
function-valued fields are deliberately outside this initial grammar.

The host guard must reject mutated/accessor Math and numeric operations before
canonical input validation and reject forcing/array protocol hooks before the
dependency guard itself can invoke those protocols. Full source dependencies and
residual runtime native descriptors must enter the enclosing guard. Root scalar
arguments and locally built records establish the provenance needed to rule out
getters, proxies and boxed coercion. A generic residual result is usable privately
only when the checked graph establishes its canonical result representation.

Experiment controls must prove actual fast entry, including an active residual
call. A host guard which always refuses can pass every semantic comparison and
still measure no optimization. Admission is therefore recorded separately from
the independent numerical oracle and public fallback matrix.
