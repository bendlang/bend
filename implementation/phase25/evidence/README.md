# Phase25 durable evidence

All archives below are tracked with the report. Their receipts bind every original
byte; ignored local paths are convenient working copies, not the sole evidence.

| Archive | Contents | Verification |
|---|---|---|
| [campaign.tar.gz](campaign.tar.gz) | `phase25/` tree containing corpus-01, calibration-01, timing-01, diagnostics-01/02, traces-01 and focused-01 | [Per-file receipt](campaign-receipt.json): every regular tar member read back and matched by SHA256 and byte length |
| [structure.json.gz](structure.json.gz) | Complete corrected46-module AST census, including per-function/site/shape data | [Receipt](structure-receipt.json): byte-identical gzip recovery |
| [structure-01.json.gz](structure-01.json.gz) | Superseded census missing the multi-constructor matcher helper category | [Receipt](structure-01-receipt.json) and [consumed original tool](structure-tool-01.mjs) |
| [corpus-pilots.tar.gz](corpus-pilots.tar.gz) | Original fixture attempts, source snapshots, generated pilot libraries, independent-oracle observations and consumed tools | [Per-file recovery receipt](corpus-pilots-receipt.json) |

The current small corpus sources and independent oracle implementation are tracked under
[`selfhost/tools/performance/phase25/corpus/`](../../../selfhost/tools/performance/phase25/corpus/).
Original failed/superseded fixture attempts and their receipts are preserved in
`corpus-pilots.tar.gz`; extract into that corpus directory to restore its
`pilot-evidence/` subtree. The ignored local copy is retained for convenience.
Canonical summary tables, figures and review notes live one directory above.
The campaign archive excludes only Python bytecode and the Matplotlib font cache.
It includes all failed diagnostic/trace attempts and original launcher scripts.

## Recover and verify

From the repository root, choose a new empty destination:

```sh
mkdir /tmp/bend-phase25-evidence
tar -xzf implementation/phase25/evidence/campaign.tar.gz -C /tmp/bend-phase25-evidence
gzip -dc implementation/phase25/evidence/structure.json.gz > /tmp/bend-phase25-evidence/structure.json
```

The receipt's `files` map uses paths relative to the extracted `phase25/` directory.
Verify each extracted file's SHA256 and length against that map. The structural
receipt records the uncompressed report hash and compressed archive hash. A local
relocation verification is also recorded in the phase's closure report.

The generated corpus libraries are self-contained for their pure benchmark exports
apart from Node builtins. They retain unused absolute foreign-library paths from
ordinary emission; these benchmarks do not call those foreign exports. Do not
claim general relocation of arbitrary foreign programs from this observation.
For a saved numeric-pattern comparison:

```sh
python3 selfhost/tools/performance/phase25/compare.py \
  /tmp/bend-phase25-evidence/phase25/corpus-01/pinned-u32-table/upstream.mjs \
  /tmp/bend-phase25-evidence/phase25/corpus-01/pinned-u32-table/selfhost.mjs \
  /tmp/bend-phase25-evidence/phase25/timing-01/pinned-u32-table-1/config.json \
  /tmp/bend-phase25-focused-replay
```

The focused command uses its module arguments, not the historical absolute paths
inside reports. Set `PHASE25_NODE` to the current Node24.18.0 binary as needed.
Diagnostic JSON configs do contain historical module paths: create a new config
pointing to the restored module rather than modifying archived evidence.

## External prerequisites and scope

Node itself and the complete pinned upstream checkout are not duplicated in this
capsule. Their identities, the installed API/runtime/Base and harness hashes are
recorded in `corpus-01/manifest.json`; the release and source live in the repository.
Re-emission needs that release and clean pinned checkout, as described in the
[reproduction guide](../README.md). Artifact execution needs neither recompilation
nor a stage-two compiler. Historical sampling, GC events and wall times are
observations to inspect, not bytes a new run must reproduce.
