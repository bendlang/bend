# P16-002B: preserve metadata with one child rebuild

Prospective follow-up to P16-002, before helper edits/build. The numeric metadata
ablation passed its first controlled cost gate: +1.01% process and +1.07% request
time on the frozen same-source matrix, with +8.93% peak RSS. Two samples per
image do not establish zero cost. Root authorizes one independent simplification
before source instrumentation.

Hypothesis: `k_with_children(parent, kids)`, using one KTerm pattern, can replace
15 duplicated eight-field record rebuild sites and 105 projector calls while
preserving every semantic and origin field. Only exact unchanged-head/removed/
span rebuilds qualify; changed names, IDs, quantities, removed lists or explicit
metadata replacement stay explicit. For well-typed immutable KTerms each
projection is total and side-effect-free; the child expression is still evaluated
once before construction. No recursive walk is introduced.

Prepare from the frozen zero-metadata source, not the live tree. Keep the first
ablation untouched. Preserve the maintained v5 helper/runtime and parser semantics.
The next host version also rejects an explicitly present unknown span ABI, as
requested in root's review; this is separately identified, not silently inserted
into the earlier consumed image.

Require genuine checked B1,36 focused cases unchanged, direct parent metadata and
all six semantic fields preserved, empty/nonempty children, exactly one evaluated
child argument, existing substitution/equality controls, unchanged old results
and helper bytes. Count source/site/projector changes. Any performance comparison
needs its own exclusive root-coordinated window and identical source. Report
the helper result separately from actual source-provenance work.
