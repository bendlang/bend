# Phase28 evidence

The closed `campaign.tar.gz` preserves the complete `selfhost/build/phase28` tree.
Its [receipt](receipt.json) gives the archive hash, compressed/logical sizes and
every member's path, size and SHA256. The [capture tool](archive.py) independently
reopens the gzip/tar stream and compares every decompressed byte with its source.
Preservation is separate from the [measurement audit](../measurement-audit.md).

The capsule contains all emitted libraries/programs and source receipts, original
and retried acquisitions, both library timing windows, the whole-process HVM
comparison, every calibration/check/sample stdout and stderr, frozen configs,
provenance, exact original and derived harnesses, and the release/closure checks.
The two rejected raytrace wrappers and incorrect-extension HVM launch remain
failures. The final consumed-tools snapshot includes the fixture corpus and shared
Phase25/26 acquisition/measurement helpers.

The checked compiler itself is an unchanged prerequisite in the
[Phase27 capsule](../../phase27/evidence/README.md), specifically attempt02 and its
snapshot/runtime/Base/driver lineage. Pinned upstream source is available from
Git commit018751270e800bc222a93dad7f257083ee53a5f7. The capture does not duplicate
that Git checkout or the Node24.18.0 executable; their consumed identities are
recorded. All emitted program bytes needed to inspect/replay this comparison are
included here. No compiler regeneration is needed just to time those saved outputs.

```sh
sha256sum implementation/phase28/evidence/campaign.tar.gz
mkdir /tmp/phase28-recovery
tar -xzf implementation/phase28/evidence/campaign.tar.gz -C /tmp/phase28-recovery
```

JSON receipts retain historical absolute paths. Relocation preserves evidence,
not the validity of those paths on a new host. A fresh replay must use new configs
pointing at the recovered bytes, record new config/environment identities, and
follow the [reproduction instructions](../README.md). Do not rewrite old receipts
or describe new timings as the historical run.
