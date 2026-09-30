# Final source review

Additional static review of the selected source during the exclusive final
timing window. This is not another execution gate and adds no conformance count.
The maintained source remains checked16.

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
