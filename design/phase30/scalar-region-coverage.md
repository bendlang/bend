# Measure scalar-region reach before widening admission

Prospective bounded analysis, before additional compiler edits. Use the exact ten
Phase28 library programs: six original runtime algorithms and four mixed tests.
The complete HVM mini application has a different process-level benchmark scope
and is excluded from this ten-program table. Preserve original fixture identities;
do not silently substitute the annotated raytrace variants.

Acquire checked library output using the immutable corrected Phase30 attempt05,
without executing full workloads or collecting speed claims. Record actual
private-region and generic Nat-loop sites by source definition. Inspect checked
user-definition signatures and body shapes to distinguish existing admission
from plausible extensions. Static site counts are not runtime cost estimates.
Retain any parse/check/emission refusals, without counting them as missing fast
paths in successfully compiled programs.

Compare two next steps. First, admit native F32 scalar helpers while keeping the
existing primitive emitter, fround operations, NaN/infinity/signed-zero behavior,
entry guards and fallback. This should require only type/literal admission, but
may enable no real loop if Nat selectors, residual matches or record results
still block it. Second, enclose already-proven scalar Nat helpers and nested
countdown loops in a larger pure region, guarding their complete closure once
at the outer entry. This can amortize descriptor guards and remove nested public
matcher/application overhead, but needs explicit bounded Nat control-flow and
tail scheduling proofs. Recursive tree forks and arbitrary graph cycles remain
distinct problems; do not treat them as countdown loops.

Before implementation, identify concrete original call paths for each option,
the smallest fixture that preserves their work, required extra concepts and
counterexamples. Prefer the extension whose actual closure is both reachable and
small enough to validate cheaply. Candidate gains remain hypotheses until an
isolated generated-JavaScript ablation and boundary controls discriminate them.

The first acquisition retains the original raytrace wrapper's rejection: its
unannotated `+rr = 6n` cannot be inferred. Acquire the already documented Phase28
`raytrace-typed.bend` retry separately, using `U32.to_nat(6)` in the appended
wrapper while retaining the entire original algorithm prefix. This is the
previously measured raytrace fixture, not a newly optimized algorithm. Keep both
the refusal and the explicit corrected-wrapper identity in the coverage report.
