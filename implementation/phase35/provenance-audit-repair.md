# Historical reference provenance in the final audit

The first preinstall audit, `final-audit09-preinstall`, accepts 13 of 14 gate
groups and all 225 canonical-source identities. Its owner-provenance traversal
fails on `selfhost/src/runtime.mjs`. This is preserved as an audit failure;
neither the original audit producer nor its frozen input plan was edited.

The precise edge is:

```text
owner/ray/report.json
  → owner/ray-cohort/derive.json
  → selfhost/tools/performance/programs/baseline/manifest.json
  → roles.baseline.compiler.runtime
  → historical canonical selfhost/src/runtime.mjs, SHA256 4121f338…
```

The colf owner reaches the same reference manifest. Its declaration describes the
installed compiler when the reference was acquired. Current source correctly has
checked09 runtime SHA256 `af2a3ae8…`. The checked historical Phase32 attempt
records both the original runtime path/hash and its frozen snapshot with the
old hash. Treating the declaration as a live source dependency is incorrect; the
reference's own provenance explicitly says those absolute acquisition paths are
historical metadata. Read-only traversal of all owner reports found 74 JSON
documents and only this mismatched byte identity before installation.

The new producer is
`selfhost/tools/performance/phase35/final-gate-audit-v2.py`. It pins the original
Phase35 audit SHA256 `33f425d9…` and changes only the `owner_group` traversal plus
one reference-resolution helper. Every original semantic assertion function,
current-input verification, final API/attempt binding, installed API check and
canonical source check is retained. AST comparison confirms no other existing
function body changes.

The exception is restricted to the exact maintained reference document, SHA256
`e5f0af8a…`; it cannot accept an arbitrary mismatched old path. Before admitting
that document as preserved provenance, the successor checks:

- Exact catalog, archive, reference-freezer and maintained bundle-reader hashes.
  The unchanged reader checks all 15 catalog source/point records, both roles,
  every selected generated-module hash, safe archive members and size bounds.
- The archive's exact SHA256 `13df6cfe…`, external and archived provenance,
  consumed freezer/prepare producers and both archived preparation receipts.
  The old prepare producer is validated from the archive; its current pathname
  is not falsely required to retain old bytes.
- Exact historical Phase32 attempt manifest `9bf0c842…`, checked status, all
  frozen source bytes and recorded original/frozen hash agreement, original
  checked API, derived API, runtime, Base, bootstrap and derivation receipts,
  assembled source and pinned upstream sources.
- The reference's API/runtime/Base/driver hashes equal those independently
  verified historical identities. Runtime and driver also bind to their explicit
  original-to-frozen snapshot mappings.

The successor records each resolution in its output. Historical reference
verification does not set the final candidate API/attempt binding flags; those
must still come from each real owner report and its fresh checked emission or
diagnostic provenance. There is no global allowance for hash mismatch and no
substitution of older owner results.

After installation, the reference's old `dist/typed-api.mjs` declaration will
also name a changed location; the same exact reference-only mapping resolves it
to the immutable Phase32 API. Historical Base metadata is handled likewise.
Original plan inputs contain no `selfhost/dist` entries, so the exact postinstall
runner remains usable and its installed API assertion remains strict.

Root runs a fresh audit directory after current measurements finish:

```sh
python3 selfhost/tools/performance/phase35/final-gate-audit-v2.py \
  selfhost/build/phase35/final-plan-09 NEW_AUDIT \
  --owner-controls selfhost/build/phase35/final-owner-retry09-01/owner-report.json \
  --require-closed
```

Use another new directory and add `--post-install` after installation and all
42 CLI checks. At this document's initial cutoff, the successor is prepared and
AST checked; it has not been executed. This repair closes no gate by itself.

## Executed successor

Root subsequently ran the successor into `final-audit09-preinstall-v2`.
Its retained `gates.json` reports **14/14 groups accepted**, complete/pass, and
all **225 canonical files** matching the selected checked09 source. The original
13/14 failure remains untouched. This establishes preinstall closure; the
installed 42-CLI gate and a fresh postinstall audit are still required.

The later `final-audit09-postinstall` also reports complete/pass: **15/15 groups**,
all **42 ordinary/relocated CLI checks**, installed API exactly checked09, and
the same **225 canonical files**. Historical reference resolution therefore
survives the real installed-API transition without relaxing the new release's
identity checks.
