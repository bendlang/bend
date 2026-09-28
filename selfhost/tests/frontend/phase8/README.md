# Phase 8 frontend controls

These focused controls compare the actual compiler with upstream revision
`b2111cf43244e65f76ddc278ee695e669f720cbf` in parse and check lanes.
`cases.json` records intended classification; paired upstream execution remains
a required gate. The files initially contain no inline oracle so expected exact
diagnostics are taken from the immutable reference rather than copied from an
older release. Retain any discovered invalid expectation in the run evidence
before correcting a fixture or selection.

Coverage: unsafe suffix/decorator/header punctuation, dotted names, duplicate
constructor fields, typed versus untyped pattern lets, array separators and
whitespace, selected-error preservation and quoted-token physical newlines.
Exact diagnostic parity is separate from acceptance/phase agreement. In
particular case arity ranges and new name/field ranges need current source
provenance and are not claimed by these parser guards alone.

Known follow-up boundary: a typed `x()` binder behaves differently when `x`
is already lexically bound; current raw parsing has no lexical environment.
The narrow typed-let guard rejects call syntax and does not claim to repair
that preexisting empty-call scope gap.

The first reference-only assumption gate is retained in
`build/phase8/frontend-reference-01`: three intended positive array fixtures
incorrectly used a second Array type parameter. The corrected fixtures use
`Array<U32>`; depth belongs to the constructor operation, not the type.
