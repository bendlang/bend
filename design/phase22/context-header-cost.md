# Guard declaration alias scans

Prospective source11 is a one-helper ablation from frozen source10. The final
bundle cost screen regressed 32.8%, so source10 is not promoted. No correctness
expectation or oracle changes are allowed.

`f_def_context_header` forms `alias != name && declared(alias, prior) &&
declared(name, prior)` with eager Bend boolean operators. Once the contextual
parser grows its actual prior book for every declaration, both recursive
membership scans execute even for an unchanged spelling. The condition is false
for that case regardless of either membership result.

Put those two membership calls behind the existing `f_choose` conditional on
`alias != name`. Preserve their order and both calls when an alias really changes
the spelling. This is a header-only evaluation/allocation correction, with no
index invariant change, new helper, changed alias order, or whole-term traversal.
Private poisoned prior-book probes may observe reduced demand on the unchanged
spelling path; valid source names and actual declaration books are the production
contract. Do not claim arbitrary stateful JavaScript getter equivalence.

Freeze exact source delta, build genuinely checked, run maintained36, the original
broader196 and saved alias/header checkpoints. Profile evidence and an exclusive
same-source process/request screen determine whether the correction recovers the
regression. Any materializer optimization is a separate candidate; do not fold
higher/lower traversals or change eager/deferred error ordering for speed.
