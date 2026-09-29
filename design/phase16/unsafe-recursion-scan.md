# Avoid recursion scanning when it cannot affect the checker

Prospective bounded cost correction after the populated-range profile.
`self_pending` combines `not unsafe` and `contains_self(body)` with Bool.and.
The generated function evaluates both arguments before Bool.and, even when the
definition is unsafe. The returned pending count is nevertheless always zero
for those definitions. A profile physically attributes 124 norm_join samples
(127,938 weighted microseconds) to self_pending on the instrumented candidate;
trampoline frames prevent treating that as the full scan cost or promised gain.

First instrument only the private contains_self binding in a copied checked API
and record calls/results for safe/unsafe and self/non-self bodies. No production
API is modified. Then replace the strict conjunction with the existing lazy kc
branch: test unsafe first, return zero immediately, and scan only safe bodies.
This preserves all meaningful results, source ranges and definition identities.
No extra data type, helper or pass is needed.

Validate the operation-count control before/after, the maintained 36 cases and
safe/unsafe recursion witnesses. Existing safe scans must keep their exact call
counts/results. The root integration gate and a matched-source timing comparison
remain required before any performance claim. Parent is frozen source-span
integration04; preserve its known strict conformance differences and all failures.
