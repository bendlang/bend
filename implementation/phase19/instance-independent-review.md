# Independent live-checker boundary review

No public-path blocker was found in the read-only review of source04/build03,
API `a15d150a920b89d9c0781372356424e559edabef3246ca281741069b0fe739b6`. The unchanged V2 boundary suite passes **104/104** on this
exact image at `selfhost/build/phase19/instance-boundary-candidate-03`.
The [machine record](instance-independent-review.json) binds the source, pinned
TypeScript, attempt, frozen harness/oracle and new result identities.

The reviewed recursion path checks closed template arguments before key/memo
lookup, rejects active cross-instance reuse, and checks decreasing runtime
arguments after removing consumed comptime applications. Erased references do
not mint; unsafe self recursion retains its exception. New mint depth agrees
with the pinned 64-level boundary. Generated owners force pending runtime arity,
so a self-reference discovered through specialization is still checked.

Public source events declare the current owner before checking it. This keeps
generic bodies in generic mode while their private opaque constants exist.
Success restores the original semantic book; failure retains the actual world.
Instances publish only after successful checking, and output accumulation places
nested dependencies before callers. Source bodies become visible only at their
last declaration/fill event. Source-only prefix inputs are replayed rather than
used to skip memo/output reconstruction.

One private-helper precondition should remain explicit: generic-mode detection
uses the current owner's declaration in the book. A fabricated call to internal
`check_definition_world` with an unpublished generic owner is outside that
invariant. The emitted public paths always declare owners; the independently
planned raw unpublished-owner freshness test is nongeneric and must not be
reported as support for every unpublished generic owner.

The 104 controls cover diagnostic/failure-world/sourcebook/prefix/materialized
output contracts and a runtime call/datatype-head inventory. They do not prove
full checked-term equivalence or backend execution. Backend gates, the full
frontend vector, and the owner's freshness/demand controls are separate. This
review launched only the requested frozen boundary rerun, made no compiler
changes and duplicated no owner recursion probes. All its processes are closed.
