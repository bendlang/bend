# P32-002: structured-checker

Status at creation: investigate; no measurement or promotion.

Hypothesis: Known calls in a trusted private checker helper can avoid repeated generic dispatch without changing evaluation.

Domain, proof obligations, ownership, falsification and integration gates are in
[the campaign design](../../design/phase32/representation-and-reuse.md).
The owner must freeze the exact derivative and measurement plan before timing.
Failures and neutral outcomes remain evidence; no gain is presumed.

Results will be linked from [the Phase32 report](../../implementation/phase32/README.md).

Completed without production promotion. Namespace-matched private projection
changes improve cached lookup 1.763×, uncached lookup 1.615× and infer_ref 1.438×.
Binding-only ranges overlap. Getter/mutation counterexamples prevent applying
these rules to the public ABI. H17 helper measurements are not a new compiler
release or whole-request gain. [Report](../../implementation/phase32/checker-private-fields.md).
