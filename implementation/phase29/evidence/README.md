# Phase29 evidence

`campaign.tar.gz` preserves the closed `selfhost/build/phase29` tree. Its
[receipt](receipt.json) records every file's path, size and SHA256, plus compressed
and logical sizes: 4,322 files / 83,002,901 logical bytes, compressed to
12,214,911 bytes. The [capture tool](archive.py) reopens the archive and independently
decompresses and hashes every member. This verifies recovery, not compiler semantics
or performance conclusions; those have separate reviews in the parent report.

Included are the frozen baseline release, all checked/failed attempts, snapshots,
prototype derivations, checked final emissions, oracles, controls, counters,
clean timing windows, raw stdout/stderr, configs, consumed tools and release checks.
The source-admission failure and recognizer stack overflows remain recorded failures.
Disposable generated-JS variants are clearly distinct from checked compiler images.

Historical prerequisites are explicit:

- [Phase27 capsule](../../phase27/evidence/README.md): baseline checked attempt02,
  its driver/Base/runtime lineage and prior actual-component/library outputs.
- [Phase28 capsule](../../phase28/evidence/README.md): original program fixtures,
  checked TypeScript/Phase27 emissions and their acquisition provenance.
- [Phase25 capsule](../../phase25/evidence/README.md): the23-library corpus and
  original checked TypeScript outputs and independent scalar oracles.
- Pinned upstream Git commit `018751270e800bc222a93dad7f257083ee53a5f7` and the
  hashed Node24.18.0 executable are external prerequisites, not duplicated binaries.

```sh
sha256sum implementation/phase29/evidence/campaign.tar.gz
mkdir /tmp/phase29-recovery
tar -xzf implementation/phase29/evidence/campaign.tar.gz -C /tmp/phase29-recovery
```

Receipts retain historical absolute paths. Replaying on a relocated workspace
requires new configs referencing recovered files and a new recorded environment;
do not rewrite old evidence or present new runs as the historical measurements.
Already emitted bytes suffice for focused runtime experiments without rebuilding
the compiler. See the [reproduction guide](../README.md) for the three iteration loops.
