# Reuse the existing declaration index for template count only

Status: source investigation, not implemented or measured. This is a possible
fallback if the two declaration guards and empty-constructor-child change do
not recover the rejected contextual candidate's cost. It adds no new index,
cache, state field or traversal.

The fresh contextual profile attributes0.984 percentage points of exclusive
`f_find` samples to `f_context_call_input`; string comparisons, declaration-name
projection and loop overhead are additional shared costs. The function already
has the current `FParseScope.index`, but obtains only `dx` (template count) by
linearly searching `prior`. Replace just that projection with
`dx(index_find(index, nm(head), index_hash(nm(head), 2166136261), 32))`, inside the
existing Ref-only branch. Expected gain is a small few percent of whole-request
time, not a measured result.

Do not replace all `f_find` calls. Initial scope construction uses
`index_build(List.reverse(prior))`, so the index selects the last initial
declaration while `f_find` selects the first. Incremental contextual declarations
prepend the same header and insert it into the index, but this does not prove
initial full-definition equivalence. Missing results also differ: `f_find`
returns a named `Missing`, while the index returns an empty-name `Absent`.
The call consumer observes only `dx`, and both misses have zero.

The narrower invariant to verify is equality of template-count projection for
all names reachable at this call boundary. Accepted imported law fills preserve
`dx(old)` explicitly in `f_graph_fill`; duplicate non-fill declarations stop
graph completion. New local headers are prepended and indexed together. Type
headers have zero template count. Prove the relevant producer cases from source
and probe law/fill chains, missing calls, alias resolution, local shadowing,
self calls and template-argument errors. Retain an adversarial private prior
with different duplicate counts to demonstrate why a blanket index rewrite is
invalid and why the production invariant is essential.

The family and marked-name consumers additionally observe datatype kind,
arity and type shape; they are deliberately outside this proposal. A law fill
may carry a different raw parameter count on an invalid program, so projected
shape equivalence there needs separate investigation.

If tried: freeze a new source from the selected candidate, change only the one
call-count expression, build a genuine checked B1 and guarded derivative, then
run independent targeted controls and maintained36. A private instrumented
comparison may audit both count projections on real parser calls, but is not
a checked artifact or a substitute for ordinary probes. Measure the unchanged
frozen compiler workload in an exclusive window before broad integration.
Reject any changed public result or unproved producer case. Report raw private
counterexamples separately from the supported immutable production invariant.
