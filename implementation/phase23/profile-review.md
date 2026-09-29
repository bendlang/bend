# Phase23 profile6 independent review

Read-only review of `selfhost/tools/development/equality.mjs` at SHA256
`4260f1d04020326b3e8896cb44851c84ea2b2f6b950744ed22538cff9a7911c5`
found no blocking issue. The reviewer inspected the emitted functions in
`bootstrap-build-02/api.mjs`, the upstream Base diff, transformation/provenance
checks, and `profile-controls-01/report.json`; the review did not rerun its tests.

The new emitted dependency path is `String.eq` → `Cmp.is_eq` / `String.order`,
then `String.order` → `Pair.snd` / `String.cmp`. The remaining comparison closure
uses `Char.cmp`, `String.cmp.fin`, `String.cmp.rec` and runtime `cmp_new`.
All these function bodies are guarded. The new `String.order` and `Pair.snd`
bindings also enter the existing shadow/rebinding checks. The complete runtime
prefix remains hash-guarded. It is byte-identical to the earlier library runtime;
that fact does not assert that all upstream IO/runtime source is unchanged.

Automatic selection now uses both runtime identity and the `String.eq` function
body hash. This separates new Base from the old emitter even though their
runtime prefixes agree. With the old equality body it continues to select
version5; with the new body it selects6. An explicit version still must satisfy
all dependency/body guards. The subsequent token/shape checks reject malformed
or duplicate declarations; the preliminary regex does not bypass those checks.
The supported public export shape, bootstrap revision/source/recipe lineage and
final output replay remain checked.

Version6 uses the existing version5 choice and restricted tail-choice transforms.
Their runtime guard still agrees with this exact emitted prefix. They introduce
no new rewrite policy in this update. The primitive string fast path remains
limited to two JavaScript primitive strings; other values take the original
function. For ordinary unmodified built-ins, equality of code-point sequences
is equality of UTF16 strings, including isolated surrogate code units.

The retained report records151,084 primitive pairs, nine refusal cases, matching
fallback observations and byte-identical replay of versions1–5. It includes
mutated `String.eq`, `String.order`, `Pair.snd`, `Cmp.is_eq`, `String.cmp`, an
unknown runtime, mismatched profiles and a shadowed dependency. These are scoped
controls, not arbitrary reflective/proxy/monkeypatched-host equivalence.

Checked bootstrap API: `selfhost/build/phase23/bootstrap-build-02/api.mjs`, SHA256
`dbf2ce5ff6ce5b47342cb6438423b17d378d8d6b67dd6eb9f1f335fe5b329a6a`.

Profile control report: `selfhost/build/phase23/profile-controls-01/report.json`, SHA256
`bb0b6a419d35ad8a8af340e26fff3a115395cea5d68116e8e3f59e9d40a2451a`.

At this review boundary the combined full compiler's focused36 and new30
frontend observations have passed according to the lead's reports. Historical
request-order/stack controls, full new-pin conformance, controlled performance
and installed/relocated release gates remain separate integration work. This
review neither marks them complete nor establishes universal transformation
soundness.
