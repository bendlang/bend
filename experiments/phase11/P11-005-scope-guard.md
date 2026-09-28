# P11-005 — Do not look up a declaration for an inapplicable offload guard

Owner: root. Prospective plan,2026-09-28, before probes/candidate. Baseline is
Phase10 integrated01; current exclusive lexical f_find share is3.89%, not a
prediction of the possible speedup.

`f_scope_reference` handles marked references, offload markers, lexical binders,
datatypes and ordinary references. Its offload predicate uses eager && and ||:
`qt(t)==3 && (boundPresent || f_find(name, book).kind==ADT)`. It performs a
whole declaration-list lookup even for every ordinary bound variable. Pinned
TypeScript distinguishes lexical and named references using explicit branches;
this scan is not needed to determine a false offload predicate.

Hypothesis: use existing f_choose to evaluate the right predicate only for qt3,
and skip f_find when boundPresent already determines refusal. Preserve the rest
of scoping and all actual offload/marked/name-resolution behavior. No helper,
cache, representation, or physical-line growth is needed.

First instrument exact released f_find entries and compare a disposable generated
expression ablation on valid small public sources of growing binder/reference
counts. Preserve complete parse/load/check observations. Add direct boundary
controls for qt0/2/3, bound/absent, ADT/ordinary/missing, qualifiers and errors.
Raw malformed unused book/null/getter controls can expose intentional demand
changes; record these separately rather than claiming arbitrary host-object
parity. The equivalence domain is finite well-formed compiler data.

If work counts fall and public observations agree, prepare isolated source from
the frozen Phase10 snapshot, build genuinely checked B1 with existing equality
profile, and repeat exact public/selected controls before integration. No source
promotion based on patched/generated counter images. Preserve condition and
selected error order; reject on supported-source observation change. Node24.18.0,
4MiB stack,4GiB heap,CPU0 for bounded probes; counts are not timings. Root will
measure complete combined compiler serially. Outcome:
[scope guard report](../../implementation/phase11/scope_guard.md).

## Final disposition

Guard promoted with finite-data demand controls; see [scope report](../../implementation/phase11/scope_guard.md).
