# Prospective live-binding record-loop probe

Frozen before guarded output derivation. Extend only repaired disposable02 from
the [record-loop investigation](record-carrying-nat-loop.md). Production compiler
files remain untouched. Unlike the fixed-global probe, this variant must match
live recursive `G.row` replacement and in-place descriptor changes.

## Entry and iteration boundary

The public successor callback captures `get(G,self)` exactly where the old
recursive prefix did, before next argument expressions. It tests that captured
target against an ordinary original descriptor snapshot without invoking new
getters. It still evaluates the entire original first prefix and first cell.
Only a stable target and primitive BigInt predecessor may transfer by bounce to
the private worker; otherwise return the already computed original bounce.

On every private iteration, capture the next recursive target before next
arguments. If its identity or internals changed, evaluate the original curried
prefix using that captured target, then the remaining next argument expressions
once in their old order, then return its bounce. Do not restart the current body
or look up the target twice. The current callback was selected by the previous
prefix, so a mutation in the preceding cell affects the *next recursive call*,
not which already selected current callback executes. Stable nonterminal prefixes
may be omitted; terminal zero prefixes remain generic and precede the final cell.

Retain original first-step deferral on outer overapplication and raw code calls.
Non-BigInt raw predecessors fall back after the original prefix has coerced them
once. No new field projection, state copying, array access or closure hoisting is
introduced. Public matcher arities, partial descriptors and result representation
remain unchanged; private bounce identity is not a byte-level ABI promise.

## Conservative descriptor guard

Borrow the already independently challenged array guard shape: target identity,
ordinary Object.prototype, no own/inherited `io` or `typeName`, original data
descriptors for `arity`, `code`, `env` and `bound`, original empty bound array,
and unchanged function invocation lookup. Inspect data-property descriptors so
accessors trigger fallback without an extra accessor invocation. The captured
target remains the fallback target. Preserve the existing standard host-intrinsic
assumption; this does not establish arbitrary prototype tampering support.

This guard executes each iteration because the generic cell may run arbitrary
host code. The array-call experiment warns it may cost more than it saves.
Timing must measure it honestly; correctness does not justify an unmeasured
performance claim. A future compiler admission should separately allow closed
opaque carried types while proving removed parameter prefixes have no match or
effect demands. A residual zero match is safe only where its argument demand
is preserved; the row's final residual state match is not authorization to group
arguments across an earlier residual match.

## Evidence and gate

Derive guarded row-loop and private-cell-plus-guarded-row-loop alongside the
five02 comparison modules, with full identities and rewrites. The combined private
cell context retains its separate immutable cell-chain limitation. Check the same
28 complete states in all seven modules. Extend32/33 ordered controls to require
the former recursive replacement counterexample now matches, plus independent
controls for G getters/zero-arity initialization, mutation during cell and index
coercion, in-place code/arity/env/bound changes, descriptor accessors, and outer
copied-length mutation. Preserve prior unsafe witnesses separately.

Run only untimed CPU6 acquisitions after reviewer coordination. Counters remain
separate from timing. Independent review is required before any exclusive parent
timing grant. Freeze seven-way screen/confirmation configs; do not execute them
without that grant or modify controls after viewing speed results.
