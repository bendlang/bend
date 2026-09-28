# Phase11 scope-guard investigation

The [P11-005 plan](../../experiments/phase11/P11-005-scope-guard.md) survives its
bounded checked-candidate gates and is integrated in the final Phase11 candidate.

## Mechanism and scope

The offload guard in `f_scope_reference` was an eager conjunction/disjunction.
It scanned declarations even for ordinary bound variables, although only an
explicit offload marker can satisfy the predicate. Nested existing `f_choose`
branches now skip the scan when the marker is absent or a bound variable already
requires the same offload refusal. Marked type references and the later ordinary
ADT/name-resolution paths remain unchanged. This costs zero added physical lines,
helpers, types or cache concepts.

On four valid public source families with4/8/16/32 identity functions, actual
`f_find` entries fall96/248/744/2504→80/216/680/2376. Complete loaded books and
check observations remain identical. These are counts, not measured speedups.
All24 direct quantifier/bound/definition combinations also remain exactly equal.
Two private null-book controls intentionally stop raising TypeError: an ordinary
bound reference succeeds, and a known bound offload reference returns the existing
refusal without inspecting the irrelevant book. The equivalence domain is finite
well-formed compiler data, not arbitrary malformed/reflective JavaScript objects.

## Checked evidence and failures

`scope-guard-02` retains the source recipe and disposable operation screen.
`scope-guard-checked-01` is a genuine checked build with the unchanged equality
profile; all21 selected controls pass, with12 known exact upstream differences.
`scope-guard-controls-01` repeats the public/direct/count/boundary controls on that
actual checked image, exposing private bodies only for observation/counters.
The immutable source change is `src/front/families.bend`, SHA-256
`f569eac960ce89166117a67798e7eae874137776f21aed49d0c553017248ebda`.
The baseline preimage is
`d1934de5de876fdc71ccb72afd8f4ac55726432157cc183d60afcfce77596ea2`.

The first `scope-guard-01` screen incorrectly passed a raw parsed book straight
to the checker and failed before comparison (`cannot infer: annotation required`).
The corrected screen uses the complete public loader/elaborator. Its original
consumed harness bytes, failure and input remain preserved; no failed report is
overwritten. No source or timing conclusion is drawn from that setup failure.

Root independently reviewed and integrated this survivor. The final checked
artifact repeats these controls in `integrated-scope-01` and passes the fresh
frontend regression gate, with the separately explained long-string improvement.
The [combined report](known_work.md) owns the controlled comparison and promotion.
Its standalone whole-source speed contribution has
not been measured and must not be inferred from profile percentages.
