# Final source review

Additional static review of the selected source during the exclusive final
timing window. This is not another execution gate and adds no conformance count.
The first pass below reviews checked16. Checked17 keeps its complete Bend source
and adds only the independently measured runtime flag discussed at the end.

`tree.bend` preserves the distinction between a public Nat input and the
predecessor passed to its successor arm. Its entry bound is predecessor `< 32n`,
so the public fast path admits depths through32. The private evaluator restores
the public depth before traversal. Each left descent saves the original parent
aliases after evaluating the ordered next-argument temporaries; the right child
uses those saved aliases. A reused frame overwrites all saved arguments, its
phase and its previous left result before another visit. Combination admission
allows only the two child results, so an overwritten parent environment cannot
become an escaping capture. These properties agree with the narrower documented
grammar; this is not a general conversion of arbitrary recursion.

In `runtime/js/core.mjs`, `invokeExact` resolves the call property and environment
before installing its permission token, restores the previous token in `finally`,
and `enterExact` consumes permission before entering the callback. The apparently
unused local read of `code.call` is intentional observable scheduling, not dead
source to remove casually. Fresh-vector ownership is restricted to the emitter's
non-tail calls; matcher fields, public calls and reusable tail messages still
copy. Constructor-arm cleanup leaves the ordinary delayed `matcher1` contract
and private callback registration in place.

The documentation review found two stale references to the removed arm module
and one instruction to keep its retired runtime bridge synchronized. These are
corrected in the backend README and compiler guide. Historical Phase27 evidence
remains linked, with its result identified as belonging to the earlier runtime.

No further source optimization follows from this review. In particular, removing
the invocation reads, broadening child-result captures, or treating all argument
vectors as owned would require new semantic controls and new checked artifacts.

## Selected17 monotone flag

Under the existing standard-intrinsics contract, false implies the private
WeakSet has received no successful registration and is empty. Its native `has`
would therefore return false without a public observation. The flag is read
after `f.code`, so registration during that getter is seen. Once true, the
original registered predicate and permission path execute unchanged. The flag
assignment follows the native `add` without an intervening reentrant operation;
it never resets, even if all registered callbacks later become unreachable.

The complete-module AST audit checks the private registry's bindings and uses.
The three production edits reproduce the measured runtime bytes exactly, and
fresh actual17 emissions reproduce the four measured program modules. The
independent22 transition cases specifically include late registration, getters,
reentry, errors, callable identity and foreign-module callbacks. This reasoning
and finite evidence are scoped to the existing intrinsics contract; they do
not promise equivalence for a replaced `WeakSet.prototype.has` hook.
