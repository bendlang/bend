# Independent review of the closed local-array probe

The first three private variants pass an independent review of their exact
generated-code derivation and 27 additional paired host observations. This is
evidence for the frozen probe, not a general container-region compiler proof.
No compiler or maintained runtime was changed.

The reviewed tool is `prototype-owned-derive.py`; the retained output ladder is
`selfhost/build/phase30/prototype-owned-01`. The probe reads its two original
argument slots before checking exact entry, native U32 bounds and the complete
16-definition snapshot closure. Native Array descriptors are captured during
module initialization, before outside code can mutate them. Private code may
therefore use ordinary local records and handles without a guard at each cell.
All public row/cell definitions remain byte-identical to the checked baseline.

The strongest scheduling condition is the private root's `force(...)`: it
finishes all Dp field thunks and deferred Array.set bounces before returning the
record to outside code. The generic raw/overapplied path retains the original
deferred expression. The private row loop forces each completed cell before
advancing, copies parent aliases freshly and invokes the original zero-row arm
to preserve its row swap. Local storage is allowed to alias; no uniqueness or
immutability assumption is introduced.

The additional design is `closed-owned-row-independent-controls.md`. The tool
`review-owned-row-controls.mjs` produced the passing receipt
`review-owned-row-controls-01/report.json`. Its 27 observations, each compared
across baseline/private-cell/private-scalar/private-row, cover:

- Raw, forged and constructor callback results retained while Array.get,
  Array.set or cell is replaced, then forced. The changed helper is required to
  run, so the test checks actual delayed demand rather than a vacuous equality.
- Repeated forcing of a saved bounce, with a completed public row and later
  write-helper replacement between forces; all four current and saved arrays
  and their handle relationships agree.
- Public rows whose fields share one handle or backing store, indexed proxy
  storage, and a foreign array-property getter, across zero/one/two-row entries.
- Object.prototype request/bounce/build/code getter traces, complementing the
  owner's primitive-prototype cases.

The owner's separately executed 28 complete-state points, 16 alias scenarios,
257 boundaries and mechanism counts are not counted as independent reviewer
executions here. Stable host intrinsics, including ordinary private Array
allocation/indexing, remain explicit assumptions. The probe exposes a fully
forced Dp only for observation; production admission of arbitrary escaping
container results is not established by these controls.
