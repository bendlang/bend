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
The capsule also covers declaration visibility without premature family sugar,
lexically scoped prefix `+`, and decreasing versus nondecreasing nested
constructor reconstruction. `cases.json` currently selects 134 observations.

`semantic-cases.json` selects another 26 observations for the current upstream
bare-definition eta rule, forward live datatype references, and final impossible
match fallbacks, including controls which must remain rejected. These are a
separate capsule so their pre-fix evidence remains attributable.
`semantic-execution-cases.json` selects eight interpreter/JS output observations
to check that those accepted programs also survive annotation and execution.
`soundness-execution-cases.json` extends that capsule to 18 observations with
pure do headers and chronological template-instantiation outputs.
`soundness-cases.json` selects 32 observations for typed/padded do headers,
chronological template instances, and the first angle type argument. Positive
controls cover earlier template bodies, an unused erased future argument, an
unsafe template, ordinary calls, parenthesized compounds and numeric comparisons.

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

Supplementary binding gate: `lhs-component.mjs` checks the complete frozen Bend
compiler with the pinned stage0 helper, then exports the existing `mat_lhs` and
`kapply` workers. `lhs-binding-audit.mjs` runs seven capture and freshness
controls against those actual exports. This is a checked component, not a B1
self-host artifact, and is not a performance comparison. It binds the assembled
source, individual module hashes, helper, upstream sources and worker artifact.

The first semantic fixture assumption gate (`frontend-reference-05`) incorrectly
expected duplicate surface `case` rows to reach the repeated-case checker: the
upstream flattener removes the redundant row. That attempt is retained. The
corrected control uses an explicit first-class repeated matcher, which reaches
the intended checker branch.
