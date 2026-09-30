# Integrate the measured scalar tree with the existing region proof

Conditional production design following the independently checked
[output experiment](pure-scalar-tree-region.md). The short screen is promising;
promotion requires its longer confirmation and fresh checked compiler output.
Do not specialize function names, benchmark constants or result checksums.

Factor the existing native Nat matcher/telescope admission into a shared scalar
Nat shape predicate. The existing countdown predicate additionally requires its
original predecessor tail call. A tree candidate additionally requires a scalar
result, and precisely two live parallel let bindings whose right sides are
saturated calls to the owner on the captured predecessor, followed by a scalar
combination. Both child binders must be distinct from all parameters and each
other. Refuse different predecessors, extra children, extra calls, labels,
erasure, record state/results, an escaping value, or an unknown helper.

Keep the existing `JRegion` result and `JRegionBuild` accumulator. Analyze the
zero arm first using `j_region_prefix`. Walk the successor lambda telescope into
the ordinary typed environment, then analyze both child argument vectors with
`j_region_args`, sequentially through the same accumulator. The owner stays in
the active-name set, so owner calls inside arguments, helper cycles or indirect
owner reentry fail. Analyze the combination with an environment containing only
the two scalar child results. This refuses parent captures and preserves the
parallel-let scope. Keep original binders, types and annotated terms. No new
KTerm tag, cache, runtime value or analysis-state field is required.

Emit a private iterative depth-first traversal using the prototype's proven
continuation shape: saved immutable parent scalar aliases, stage, and completed
left result. Compute left arguments before saving and entering that child;
compute right arguments only after the left child completes. Evaluate the
unchanged scalar combination only after both child results. Reuse the existing
primitive and JCall expression emitters. Neither the traversal nor a tree helper
may recurse through the host call stack. The nested countdown helper remains its
existing private loop. Do not flatten/reassociate the tree or its arithmetic.

The public definition retains its original matcher and zero arm. The selected
successor callback remains a fresh ordinary `exactCode` callback and reads all
slots once. Require genuine exact entry, the existing native scalar input
checks, predecessor `<32n` (public depth at most 32), and the complete owner plus
helper live-descriptor guard. Reconstruct full depth only after those checks.
Any failure runs the original generic callback with saved slots. Register the
owner once with `scalarCapture`, as for the existing Nat worker. Standard host
intrinsics remain the contract, including the private Array stack operations.

The implementation should live beside the existing region/worker emitters.
Share only proven common admission and ordinary lambda-body emission; avoid a
general recursion framework. Record its source/concept cost separately from
the simpler ordinary-root extension. If the strict two-child proof cannot fit
without unreviewed semantic expansion, retain the prototype and defer promotion.

Validation requires a fresh checked attempt and all focused gates; the retained
tree oracle, ordered public-interface controls and depth sentinels adapted to
actual compiler output; independently authored admission/refusal books; explicit
noncommutative combines and different left/right arguments; proof of left-before-
right evaluation in fallback; raw, copied-vector and descriptor mutation probes;
and bounded-depth diagnostics without exponential work. Add callback metadata,
primitive prototype observations and the independently requested copied-length
trigger positions before promotion. Preserve every failed attempt and harness
correction. Then measure actual emitted code against the prior checked version
and pinned TypeScript, and run broad integration once the combined image freezes.
