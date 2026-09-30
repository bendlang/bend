# Phase27 evidence

`campaign.tar.gz` contains3,388 files and73,515,482 logical bytes, compressed to
13,308,567 bytes. SHA256:
`0a15e6b0f7354fd6c3801ef551a69698da8e74996477d9be682e2e6632ce983b`.

The capsule preserves the complete closed `selfhost/build/phase27` tree. Its
[receipt](receipt.json) identifies every file by path, size and SHA256. The
[capture tool](archive.py) rejects unsafe paths/links, then reopens the finished
gzip/tar and independently verifies every decompressed member against the source.
Byte recovery is separate from semantic validation and measurement review.

Included evidence:

- Both immutable checked attempts, canonical source/host snapshots, genuine
  checked bootstrap and guarded derivatives, Base caches and focused results.
- Frozen installed Phase26 baseline; all inline/shared corpus and real compiler
  component emissions and independent scalar oracles.
- Original68-observation controls and expanded72-observation acquisitions,
  numeric controls/supplements, shared-runtime ABI test and selected upstream
  execution acquisitions. Earlier successful narrower suites remain preserved.
- All360 clean samples in four separately reported windows, calibration,
  warmup/import/process observations, exact configs and module/receipt identities.
- Separate counter/AST diagnostics, including correct per-variant runtime guards.
- Original inline source patch, diagnostic V8 traces, untimed generator/substitution
  ablations and their initial script failure; original Base-path comparison and
  aligned replacement baseline. None is relabeled a clean timing success.

The old numeric/corpus baseline modules are supplied by the separate
[Phase26 capsule](../../phase26/evidence/README.md); TypeScript corpus modules
and original source receipts are supplied by [Phase25](../../phase25/README.md).
The current capsule does not duplicate those complete histories or the Node
binary/upstream Git checkout. Exact prerequisites remain identifiable.

Inspect or restore to a new directory:

```sh
sha256sum implementation/phase27/evidence/campaign.tar.gz
mkdir /tmp/phase27-recovery
tar -xzf implementation/phase27/evidence/campaign.tar.gz -C /tmp/phase27-recovery
```

Historical JSON records retain the original host's absolute paths. Recovery
proves their bytes survive; it does not make old path-dependent build verification
current. See [reproduction](../README.md) for fresh acquisition. A separate
[measurement audit](../measurement-audit.md) checks raw timing evidence.
