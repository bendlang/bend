# Independent review of the bounded scalar tree proposal

This is a static review of `design/phase30/pure-scalar-tree-region.md` and the
actual emitted `rcol` shape. It is not an execution or performance result.

The proposed explicit depth-first continuation preserves the source order:
left recursive application, right recursive application using the parent
predecessor in its shift, then U32 addition. A stage per frame and immutable
parent aliases avoid native recursive stack growth and avoid precomputing the
right argument before the left result. The closed nine-descriptor proof is
required even for the intermediate variant that calls public `rpix` at leaves.
Those unchanged public calls are pure only while that proof remains valid.

The public depth bound 32 means the projected successor predecessor must be a
native BigInt in `[0,32)`. The original slot reads must precede validation, and
the existing exact-entry token must already have been consumed. A separate
post-guard sentinel should demonstrate predecessor 31 admitted and 32 declined
with an otherwise pristine closure. Coercible or boxed predecessors must take
the byte-preserved generic path. No exponential boundary computation is needed.

No static blocker was found in the prospective design. The derivation still
needs code-specific review, complete scalar oracles, saved-partial/raw/outer
oversaturation observations, and independent frame/visit counters. A recursive
JavaScript implementation or a flat sum would not satisfy this reviewed plan.

The subsequent static read of `prototype-tree-region-derive.py` also found no
blocker. Saved parent arguments retain the projected predecessor for the later
right-child shift; the tree evaluator receives unprojected `p+1` and tests zero
before decrementing. Nested `mit` retains the same zero-first entry. The public
leaf variant forces its original tail bounce at the leaf demand point. The
deriver asserts there is no private recursive tree call. Its acquisition and
execution controls had not run at this review point.

After acquisition, the owner reported 74 scalar oracle points, 130 ordered host
observations and eight depth sentinels in `prototype-tree-controls-01`, plus 30
instrumented stack comparisons in `prototype-tree-counts-01`. An independent
static read of those control implementations found the reference tree and pixel
formula separate from the generated expressions. The node/leaf/combine counts,
frame high-water and wrapped index trace test the actual traversal order. These
are the owner's execution receipts, not a second independent execution.

Before production consideration, broaden the recorded boundary coverage with
persistent primitive-prototype hooks, additional descriptor metadata changes and
outer copied-length mutation/throws at reads other than four. Those requests
reuse already maintained runtime contracts; they are coverage improvements, not
newly observed counterexamples or a reason to discard the current scoped output
experiment.

The later unbuilt `tree.bend` integration and shared `worker.bend` header/body
refactor were also reviewed statically before attempt12. No blocker was found.
The initial shape gates protect child access and recursive analysis, both child
arguments share the original parent environment and one analysis accumulator,
and the combination receives only the two scalar child bindings. A self call
inside an argument loses the special tail allowance and meets the active-owner
cycle check. The old countdown path still requires its original tail predicate
after the shared Nat header, while the tree adds a scalar-only result signature.

The emitter saves immutable parent aliases, evaluates right arguments after the
left result, and places its local declarations in scopes separate from generic
fallback. During unwind, constructing the child-only type context relies on the
explicit result annotations retained on both transformed child calls. The
independent admission witnesses must preserve and exercise that invariant rather
than treating arbitrary unannotated injected terms as a checked program.
