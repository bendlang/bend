# Phase35 independent static review

Reviewer: the literature/review agent, 2026-10-01. This is source inspection,
not executed validation or a proof of general compiler correctness. Only root
runs compiler acquisitions, semantic controls and performance jobs. Results
from those jobs belong in their own reports.

## Bounded private helper inlining

Reviewed proposed [private-state.patch](private-state.patch), SHA256
`4f08ff9fe7519fb9915335a61b380578d892b2fb35de39f05035eb033717741c`.
No blocking issue was found in the admitted private grammar.

- Original argument/result `Ann` wrappers survive the rewrite, so existing Let
  context construction can still recover types.
- Argument values are captured before the inner block introduces the callee's
  `$p` names. This avoids shadowing the caller's positional values during their
  own initializers. Existing parallel Let scopes and immutable aliases remain.
- `JInlineRead` evaluates prefix arguments before the erased type, array and
  index operands. It reads at the original producer point, even when the scalar
  field is unused, before entering the consumer body. Its field slots match the
  existing `$get` bridge: the array at `arity`, read value at `arity + 1`.
- The outer `JUnpack` remains visible to read-consumer recognition. The rewrite
  does not knowingly disable the existing bridge or alter its complete telescope.
- Public descriptors, entry guards and captured helper dependency identities
  remain unchanged. Only already admitted private plans are copied.
- The shared traversal budget covers copied bodies, but is **2,048 visits per
  helper**, with eight levels of call expansion, rather than 2,048 for the entire
  region. A failed helper rewrite keeps that complete original helper. Regions
  already limit the number of helpers.

This stage retains aggregate result allocation. Expression-position calls add
IIFEs; eliminating generic private call boundaries need not make those cases
faster. Actual checked-output pair/fold, full-state, demand-order, alias and
public mutation controls remain necessary, followed by clean timing.

The separate hand-written vector ablations were compared with exact Phase33
baseline output. Pair reads remain `b[i]`, `prev[i]`, `prev[U32.inc(i)]`,
`curr[i]`, followed by wrapped additions, the same numeric minimum and the write.
Initial-zero row still returns a fresh swapped vector; fold zero returns its
input state. Scalar mode preserves the underlying handles, rather than copying
array contents. The requested input-identity restriction was subsequently added
to `vector-prototype.mjs`, avoiding name-only replacement of an unrelated `row`.
Those explicit fixture ablations are not general compiler transformations.

## Private finite Nat decisions

Reviewed [direct-regions.patch](direct-regions.patch), SHA256
`4a02674778c3cc7a885d169dfdc4fe548fbbeab63c64a5bf6447c7b06bb2659b`.
No blocking issue was found under its existing closed canonical-Nat boundary.

`j_env` obtains types without inspecting the environment-node tag. The new
`JEnvNat` therefore retains the source binder's identity/type while recording
its positional slot and subtraction offset. At depth `d`, preceding failed
Zero branches establish `n >= d`. The residual binder can denote `n - d`
without introducing a negative Nat. Ternary emission executes one selected
leaf; normal region analysis retains leaf helper dependencies and demand.
Fuel/helper state flows through the inspected arms. The last-argument and
complete-pattern restrictions avoid leaving a partially applied private closure.

This is equality-chain lowering with unchanged leaf expressions. It is not
constant-table folding, F32 admission or branch-aware recursive-loop admission.
Requested controls include all explicit/default branches, default predecessor
used more than once, different argument positions, maximum valid Nat and public
descriptor/prototype mutation fallback. Unsupported, nonnative or incomplete
match shapes must remain rejected.

The saved-output public selector prototype is a mechanism screen. Its
source-sliced leaves preserve live `fl` calls, and the inlined generic fallback
avoids additional `.code`/`.call` observations. The reviewer initially raised a
callback-shape objection after inspecting the private `function(a, $entered)`.
Inspection of `exactCode(inner, true)` corrected that objection: the public
wrapper remains an arrow with length one, matching the original matcher callback.
That initial concern was incorrect, not a demonstrated counterexample. An
explicit public-shape control was requested to cover name, length and own keys.
The maintained private-region patch avoids changing the public selector at all.
The prototype controls create many fresh module instances, so they should retain
root's explicit memory supervision. Static inspection alone establishes no full
public-ABI equivalence claim.

## Rejected naive branch-loop wrapper

Root proposed extending Nat workers to a residual Boolean match by exposing one
public successor callback with the total argument count. Independent review and
root both identified the public-prefix problem before implementation:

1. `j_nat_loop_generic` consumes leading lambdas, then returns the residual
   matcher. Reusing it behind an eagerly saturated callback would leave the
   already supplied Boolean unapplied.
2. Changing the callback's arity can change partial-application descriptor shape
   and the staging of observable work. Applying the residual matcher later fixes
   the first issue alone, not necessarily the second.

Root deferred that naive architecture. A later design should preserve existing
public stages and place the fast path at the final Boolean arm, or prove a
larger private ordinary root. Required future controls include every saved
prefix, mutation between stages, oversaturation, raw callback entry and complete
argument-read traces, as well as F32 special values and deep loop execution.
No branch-control fixture is claimed as executed or complete by this review.


## Final vector state destinations

The second-stage `private-state-scalar.patch` was inspected separately. No
concrete blocking issue was found in the admitted private grammar. Initial-zero
execution returns before vector field reads. Nonzero loops snapshot immutable
field slots, and each next-state destination is completed before any current
slot changes. Escaping uses reify a fresh vector; terminal-zero entry reconstructs
the existing argument ABI. The scheme does not mutate one shared output record.

One maintainability concern remains: substitution uses ordinary `subst`, whose
`core_rebuild` may beta-reduce `App(Lam, ...)`. The currently admitted private
expression grammar appears to exclude that value shape, and frontend freshening
provides unique binder identities. A future grammar expansion should use a
plan-only variable replacement traversal or explicitly preserve this invariant.
Requested controls include nested vectors/loops and caller/callee binder scope.

## Floating host guard and final-Boolean compiler worker

Reviewed the sequential frozen patches recorded by `patch-order.json`:

- `float-regions.patch`, SHA256
  `7b80dd6ac2d2db5a17a92d61472bf0b668b24fc41f8457ecfce3c997fa3bd1c0`;
- `branch-loop.patch`, SHA256
  `fa5110dbd5439a2b6bc6fc2fb7a24ddfff4587fc75ca12eb61022849ed0cb026`.

An actual guard omission was found in the initial floating proposal: scanning
only literal `F32` names in raw source types/bodies does not establish that an
admitted type alias contains no floating input. An unused alias-of-F32 argument
can still trigger new `Math.fround` canonical-input checks. The corrected patch
normalizes each root/helper function telescope before deciding whether to emit
`regionHostGuard()`. This resolves the identified static hole; an actual compiled
alias fixture and mutated-Math control remain required.

No further blocking issue was found in the final-Boolean worker's admitted
grammar. The public outer Nat matcher and original zero branch remain. The
successor retains the leading `fn(total - 1)` stage, followed by a length-one
nonconstructible exact-entry arrow. Boolean destructuring occurs once before
metadata guards, and copying captured lexical values does not reread public
argument properties. Planned `JLoopSlot` positions agree with successor and zero
layouts. All next-argument RHS temporaries finish before mutable slots change;
`JBranchZero` installs those arguments before evaluating the zero plan. The
inline generic fallback demands only the original selected arm.

The numeric hook list matches the actual `j_primitive_known` floating admission
set; `pow` and `atan2` appear in the wider runtime but are not admitted by this
primitive planner. Standard host identities at module initialization remain an
explicit assumption. Actual checked compiler output, both Bool orders, alias
inputs, deep countdowns, every saved public prefix, mutation and hook observations
must pass before promotion. This report is still static inspection only.


## Deferred terminal-record comparisons

Reviewed `record-compare-fields.patch`, SHA256 `27e24112d16e6a98bcf099d6550d63ed4380e26d6fb819daf0683f6cccc836b4`.
No blocking issue was found. The new syntactic field predicate is not the whole
proof: `j_primitive_call` validates the native definition and telescope, then
`j_region_args` recursively checks the operands against canonical U32/F32 types
and their environment types. Boolean constructor atoms cannot silently become
numeric comparison operands merely because the syntactic predicate accepts them.

Admitted `is_*` forms compile to strict comparisons or `is_zero`. With canonical
numeric inputs they do not coerce objects, access G, call Math, allocate or invoke
callbacks, including for F32 NaN and signed zero. Existing deferred field thunks
and immutable captured aliases remain. This bounded extension therefore does
not require a post-return lifetime for mutable dependency proofs. The preceding
comment claiming fields contain no computation should be updated to describe
inert values and proved scalar comparisons. Actual complete-record, descriptor,
coercion and special-value controls remain required.


## Nonescaping private vector-loop counter

Reviewed `private-counter.patch`, SHA256
`088179b293d2f61b6ea008586ef035f81ad1968aebe286cd3caea3ef8949a011`. No blocking issue was found
under the existing canonical private Nat invariant. The original zero branch
runs before conversion. For a nonzero private vector loop, the predicate proves
that the predecessor occurs exactly once throughout all successor children,
including annotations and copied plans, and that this occurrence is the first
self-tail argument. Thus the changed Number counter is neither inspected by
source arithmetic nor stored or returned. The terminal-zero argument list omits
that counter. Values below 2^48 and their countdown steps are exactly
representable; a captured native Number avoids adding calls through a replaced
global conversion function. Requested tests include arithmetic/store/multiple-use
refusal, initial zero, nested loops, and transfer to the actual pair/fold output.
This is a static review, not a new performance claim.
