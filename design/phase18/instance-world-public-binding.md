# Phase18 stable payload: source05 parser refusal

The genuine source05 build refused before API generation: pinned parsing rejects
matching `payload` after the preceding local error projection used that binder.
The failed build and source remain unchanged. This is an implementation setup
failure, not a changed result from the candidate compiler.

Source06 keeps the explicit error binding and projects the term through one small
`sp_payload_term(KChecked) -> KTerm` helper. Each helper matches its own parameter;
the public diagnostic reads book/payload/error first, then term. No semantic
checker operation, record field, host wrapper or renderer changes. The exact
saved 18-control public oracle stays unchanged. Repeated reads of an immutable
error field may be coalesced; no equivalence to arbitrary stateful JavaScript
getters is claimed, as approved by root.
