# Independent review of the final16 frontend layout migration

The retained main frontend acquisition agrees on all3,026 probes under the
existing strict-path comparison policy and its explicit module-layout migration.
No compiler/fixture execution was repeated. The independent receipt is
`selfhost/build/phase30/review-frontend-layout-16-main/report.json`; all per-probe
rows remain in `per-probe.json`, and the complete maintained comparison is in
`comparison.json`.

The original gate at `frontend-renewal-plan-16/main/report.json` remains failed
and unchanged: its strict target-manifest identity check rejected the changed
module list after worker acquisition completed. Its candidate.json and worker
receipts remain the input evidence. Identical aggregate summaries alone were
not used to approve the comparison.

The reviewed descriptor is `frontend-layout-tools16/migration.json`. It binds
both exact manifest hashes and complete ordered module lists: the old60-module
manifest `ab196d008363b3bb403fe3c5b43fb5cf17605e614eb23e7f807408c05b358814`
and final65-module manifest
`954e4cfb54fc94a81e4a55bb264c121b0d860ebd201c1a743b4eff1a0042c63d`.
The only additions relative to that original Phase23 reference are
`src/back/js/{u32,primitive,region,worker,tree}.bend`; none of its modules were
removed or reordered. The intermediate arm.bend module is absent from both this
old reference and final16. Every non-module manifest field agrees exactly:
upstream018751270e800bc222a93dad7f257083ee53a5f7 and targetVersion2.0.34.

The independent tool calls the unchanged maintained
`phase22/frontend-layout-compare.mjs` with strictPaths=true and the explicit
descriptor, then independently checks all behavioral result fields and registered
metadata. It verifies finished reports, four healthy workers on each side,
zero changed inputs/artifacts, every input/artifact hash, exact fixture inventory,
fixture paths and oracles, and no missing/duplicate probes. Unknown result keys
fail closed. Diagnostic/output paths or strings are not rewritten; the existing
comparator's absent-field handling is unchanged. It also checks reference-side
registered metadata, beyond the inherited gate's candidate metadata check.

The analysis agent's adapted gate preserves the original all-fields/unknown-key
and metadata block verbatim. Its optional saved-acquisition branch admits only
the declared original manifest-mismatch failure with matching scope/count/API,
successful worker process completion, stable input/candidate identities, and the
final compiler/runtime/Base identities. Fresh broader acquisition still uses the
normal worker path. This is an explicit reviewed identity migration, not a blanket
manifest-hash bypass.

A tooling-only syntax preflight failure in the independent metadata-list
expression is retained at `review-frontend-layout-syntax-01`; it executed no
comparison or probes. Correcting the bracket allowed the3,026-row audit above.
The original shared four failed statuses remain failed in the raw data; exact
observational agreement does not turn them into passed language tests or prove
full checker equivalence. Broader196 and backend renewal are reported separately.
