# A bounded private region for a scalar binary tree

Prospective investigation after ordinary scalar-root confirmation. This is a
separate generated-JavaScript experiment; it does not authorize a production
tree-recursion backend or change any running timing configuration.

## Why the remaining boundary matters

The original Mandelbrot second pass calls
`rcol : Nat, U32, Nat, U32×8 → U32`. At zero it calls `rpix`; at successor it
computes two `rcol` children, both on the captured predecessor, then adds their
U32 results. All carried values and results are scalars. The first child starts
at the same pixel index; the second uses the existing U32 shift/add expression.
The complete closure is `rcol, rpix, pix, bkt, mit, asr8, sel, sel.go, b2u`.
Only `rcol` has binary recursion and only `mit` has the already proved Nat-tail
loop. There is no mutual recursion between helpers.

The ordinary-root experiment removes application machinery but still enters
one guard per pixel. Original `bench(2,0)` renders 256 second-pass leaves. A
closed region at `rcol` could replace these 256 inner guards with one nine-name
guard. With the separate terminal first-pass region, the structural opportunity
is four chunk guards plus one tree guard. This predicts guard count, not speed.

## Use an explicit private depth-first stack

Do not turn arbitrary source recursion into unbounded JavaScript recursion.
Even a finite public-depth guard needs care for a caller already near the host
stack limit. Prefer a private iterative depth-first evaluator for this exact
binary scalar shape. The stack stores private scalar continuation frames; it
is not part of the public ABI or the Bend value representation.

At a nonzero node, evaluate the original first-child arguments once and in
order, save the parent scalar aliases and a left-child continuation, then visit
the left child. After it returns, retain its scalar result, evaluate the original
second-child arguments in their original order, and visit the right child.
After that result returns, execute the original combining expression once and
resume the parent frame. At zero, evaluate the original leaf expression using
private proved helpers. No recursive host function call appears in this tree
evaluator; the nested `mit` remains its existing iterative BigInt loop.

Use an explicit stage per frame, original immutable scalar aliases, and a stack
index. Do not precompute the right child before the left result. Do not rewrite
the tree into a flat sum, rely on commutativity/associativity, change its index
arithmetic, or infer that distinct source calls are interchangeable. Preserve
the actual copied primitive expressions, including dynamic Nat-shift behavior.
No source array, record, string or constructor enters the region.

The initial generated experiment additionally caps the **public tree depth at
32**, with exact equality at that boundary, and otherwise uses the original
generic path. That is a conservative experimental admission limit, not a
different result or a new source restriction. It bounds private continuation
storage and includes the documented large render depth 24. It must not be used
as permission to run an exponentially large point during validation. Ordinary
controls use small depths. Separate diagnostic copies can replace each selected
fast/fallback body with a distinct sentinel after its real entry guards, proving
boundary selection without evaluating a huge tree. A mutated global alone is
not a depth-cap test: it independently invalidates the closure guard.

## Narrow proof and public entry

Before a later compiler implementation, establish all of the following from
the checked book, not from function or benchmark names:

- The ordinary nonnative/template-free owner has exactly native Nat Zero and
  Succ alternatives, with the expected scalar telescope and scalar result.
  Both arms have complete live lambda prefixes, distinct unlabelled binders,
  bounded source and no residual match demand.
- The zero body is closed scalar work under the existing region grammar.
- The successor body has exactly two statically visible saturated recursive
  calls, both with the same captured predecessor in first position. Their
  arguments and the final combination contain no additional owner reference,
  escaping closure, dynamic callee, effect or unproved helper.
- The original evaluation order is two child results followed by a scalar
  combination. Preserve annotations, parallel-let scope and immutable aliases.
  Refuse an owner reference in an argument, an indirect self call, a different
  counter, missing/extra arguments, a shadowed predecessor, mutual recursion
  or a helper-cycle that is not the separately proved `mit` self-tail edge.
- Reuse the existing scalar helper proof and its shared active-name/depth/fuel
  budgets. Do not recursively restart an analysis with fresh fuel or publish
  an incomplete helper in the cache.

Keep the original public matcher, partial arities, metadata, function kinds and
ordinary generic callback. The first experiment can optimize only the complete
Successor callback; leave the public Zero callback unchanged. Consume existing
`exactCode` permission before reading its slots, read every original slot once,
then check native scalar values, the bounded depth and the complete live closure.
All raw, hooked, malformed, over-saturated and failed-guard invocations execute
the original callback expression with those same slots. Preserve its deferred
result and public getter/effect order. The predecessor slot reconstructs the
public depth only after native BigInt validation; a raw coercible predecessor
must never enter the private evaluator.

The pure path has no host observer between guard and scalar return. An input
getter or environment getter can mutate a global before the guard; the guard
must then reject. Every current owner/helper descriptor is included and snapshot
captured as an ordinary compiled descriptor. In-place fields and code hooks
retain the existing guard semantics. Standard host intrinsics remain the scope.

## Frozen output experiment and coverage

Use a fresh checked whole-program emission of attempt10, the planned duplicate-
capture cleanup of the lexical plus terminal-region compiler, as the unchanged
control. Freeze its receipt and hashes before deriving output. If that checked
candidate is unavailable, stop acquisition and amend the prospective baseline;
do not substitute a moving source tree or an older emitted file silently.

Use three variants:

1. Unchanged checked output.
2. The same private explicit tree traversal, with its original public `rpix`
   call at each leaf. This isolates tree administrative work and keeps the
   per-leaf public helper/guard boundary.
3. The same traversal with the complete private scalar helper closure, including
   nested `mit`, and one guard at the outer exact entry.

The intermediate variant must retain the forcing point of the public leaf call.
Because a replaced public leaf may have effects, its owner/self/helper closure
must also be guarded before the private traversal is allowed; a mutated public
leaf forces the original generic fallback. It is an ablation within the same
closed admitted domain, not an effectful general-purpose tree worker.

Static coverage currently establishes one actual original-program owner:
`rcol`, its eight scalar helper dependencies, and both documented Mandelbrot
render sizes. Other binary scalar programs may fit, but none is claimed until
their checked shapes pass the same proof. Record-returning histogram `hfold`,
arbitrary Fibonacci, mutual recursion and record/array tree walkers are outside
this first concept. The production-analysis cost is materially higher than
adding an ordinary root: it adds one continuation shape and its refusal proof.
An explicit output prototype is still a small bounded test before accepting
that complexity in the compiler.

## Independent validation and measurement

Use an independent mathematical pixel/recolor oracle and a simple reference
recursive sum for small depths 0–6, with varied starting indices, zero/short
inner iterations and palettes containing U32 extremes. Compare the complete
scalar result, original `bench(0,0)` and `bench(2,0)`, and multiple repeated calls.
Add a deliberately unsafe host-recursive derivative only as a retained static
counterexample if needed; do not time an artifact that fails its scope.

Compare all ordered public/foreign observations used for the ordinary-root
experiment, plus raw predecessor coercion, a saved successor partial, mutation
before tree entry, source-order observations in generic fallback and an outer
copied-vector length getter/throw. Prove the depth cap selects fallback with the
separate post-guard sentinel diagnostic before attempting any large computation. Check there
is no call from the private tree function to itself or another host-recursive
tree helper. Instrument frame high-water, node/leaf visits, applies, partials,
jumps and guards separately; verify expected `2^d` leaves and `2^d−1` binary
combines for small depth.

Freeze small-tree and original-small timing points only after these gates and
independent review. Use the maintained exclusive CPU3 screen and long
confirmation protocols, preserving all failures, complete output, ranges and
drift. Keep this experiment separate from ordinary-root/F32 admission and exact-
call runtime changes. Decide on a compiler proposal only after the measured
benefit justifies the extra analysis and continuation concept.
