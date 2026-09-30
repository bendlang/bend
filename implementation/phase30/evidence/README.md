# Phase30 evidence preservation

Capture and transport verification are complete. The capsule contains **39,272
regular files / 1,605,739,665 logical bytes**, compressed to **125,260,680 bytes**.
Every archived member was independently reopened and compared by name, size,
SHA256 and mode; the live pre/post inventories were identical. The full
[receipt](receipt.json) records every member, and the [capture process](capture-run/run.json)
records the successful 113.755-second acquisition and verification.

Because the archive exceeds GitHub's per-file limit, its committed payload is
two ordered chunks. [Transport verification](transport.json) independently
rereads both chunks and verifies their concatenation against the original
archive's exact size and SHA256. Only after that check was the newly created
redundant whole file removed. No experiment bytes were removed. `receipt.json`'s
`campaign.tar.gz` path identifies the logical reassembled archive, not a third
committed payload file.

Full archive SHA256:
`641f71900de35a077265bcd373dfd0c9f98cb050469ca0265ba797a8bd73c60d`.
From this directory, verify or recover into a separate destination:

```sh
cat campaign.tar.gz.part-* | sha256sum
mkdir -p /tmp/bend-phase30-recovery
cat campaign.tar.gz.part-* | tar -xz -C /tmp/bend-phase30-recovery
```

Recovery expands to approximately 1.61 GB and does not rerun any experiment.
The committed chunks are 67,108,864 and 58,151,816 bytes; individual hashes and
ordered paths are in `transport.json`. The [transport process](transport-run/run.json)
retains its own successful receipt. The independent review and exact CLI
receipts are also linked directly from the [release report](../release-17.md).

`archive.py` captures every regular file under `selfhost/build/phase30`, including
failed experiments, superseded measurements, exact consumed tool/config copies,
checked attempt snapshots, logs and process receipts. It refuses symlinks and
existing output identities, stores input hardlinks as regular bytes, then reopens
the archive and compares every member's name, byte count, SHA256 and mode against
the pre-capture inventory. It also verifies that the live source inventory did
not change during capture. A partial archive from failure is retained and is not
a successful capsule; any retry must use a distinct output identity.

The capsule is a Phase30 acquisition record, not a stand-alone copy of every
transitive historical or system dependency. Reproduction also uses:

- The [Phase21 source history](../../phase21/) and committed source revisions
  named by the checked attempts. Each attempt's snapshot and manifest preserve
  its actual source and guarded derivation lineage.
- [Phase23 evidence](../../phase23/evidence/README.md) for explicitly attested
  frontend references and the maintained frontend harness history.
- [Phase24 evidence](../../phase24/evidence/README.md) for the retained backend
  selection, census tool and historical pilot
  inputs named by any renewed backend plan.
- [Phase25 evidence](../../phase25/evidence/README.md) for the selected library
  sources, and [Phase27 evidence](../../phase27/evidence/README.md) for the
  earlier compiler-component and checked-release prerequisites.
- [Phase28 evidence](../../phase28/evidence/README.md) for unchanged original
  program sources, pinned TypeScript emissions and original expected outputs.
- [Phase29 evidence](../../phase29/evidence/README.md) for the preceding checked
  compiler, baseline runtime and exact fast-loop protocols.
- Committed release artifacts/history and the exact upstream Git revision
  `018751270e800bc222a93dad7f257083ee53a5f7`.
- External Node24.18.0, the explicitly identified Clang16 environment for native
  smoke checks, and ordinary system/Python tools. Their executable identities
  and invocation environments are recorded where consumed; they are not
  vendored by this capsule.

Recorded absolute acquisition paths describe provenance. Recover files beneath
a chosen repository root and adapt invocation paths explicitly; do not overwrite
live evidence trees. Recovery of archived bytes alone does not rerun or validate
the compiler, establish a fixed point, prove conformance outside measured scopes,
or establish successful GitHub publication.

The campaign's 103 unrelated starting paths are excluded from the capture root
and protected by the separate start/final hash inventories. Earlier evidence is
not removed to create this capsule. The documented disk recovery removed only
two independently hash-verified duplicate temporary extraction trees and kept
their original committed archives.
