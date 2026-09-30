# Phase32 verified raw evidence capsule

[campaign.tar.gz](campaign.tar.gz) contains **20,807 regular files** and
207,091,523 logical bytes from the closed `selfhost/build/phase32` acquisition tree.
The gzip is **33,930,135 bytes** (32.36 MiB); no transport chunks are needed.
Its SHA256 is:

```
390a34356eb14b2792643969f8728be3ab6b84ac2d67ee8cdfa85be729b14925
```

The [receipt](receipt.json) records every member's name, size, SHA256 and mode.
Capture checked the live file set and hashes before and after writing, then
independently reopened the gzip/tar stream and checked every member against that
inventory. It preserves hardlinked inputs as independent regular members and
rejects symlinks. No raw acquisition was deleted. Archive verification does not
rerun compiler tests or establish another self-hosted fixed point.

## Producer and execution

[archive.py](archive.py) is the Phase31 preservation algorithm with only the
phase names substituted. [Producer provenance](producer-provenance.json) binds
its parent SHA256 and exact inverse. This phase's producer SHA256 is
`f6b3f23f7c45db85f6f6589880d9ccade93ca9bfedeaad80418e21f2641f33a5`.

All compiler, benchmark, integration and installation producers had closed before
capture. The [supervised receipt](capture-run/run.json) records completion in
23.809 seconds, a 118,263,808-byte process-tree RSS peak, a 1 GiB RSS budget,
180-second deadline and 2 GiB available-memory floor. Wrapper output resides
outside the captured tree; the shared execution lock remained held during capture.
The wrapper's consumed bytes and stdout/stderr hashes are retained beside it.
The producer independently reopens the archive; no separate extraction run is
claimed. The [release report](../release-03.md) closes installation and correctness
separately from this storage verification.

## Recovery

Verify the payload before extracting into a separate directory, from the repo root:

```sh
python3 - <<'PYVERIFY'
from pathlib import Path
import hashlib, json
root = Path('implementation/phase32/evidence')
receipt = json.loads((root / 'receipt.json').read_text())
payload = root / 'campaign.tar.gz'
assert payload.stat().st_size == receipt['archive']['bytes']
h = hashlib.sha256()
with payload.open('rb') as stream:
    for chunk in iter(lambda: stream.read(1024 * 1024), b''):
        h.update(chunk)
assert h.hexdigest() == receipt['archive']['sha256']
PYVERIFY
mkdir -p /tmp/bend-phase32-recovery
tar -xzf implementation/phase32/evidence/campaign.tar.gz -C /tmp/bend-phase32-recovery
```

Absolute acquisition paths in reports remain provenance. Replay needs explicit
adaptation to the recovery root and the stated dependencies; extraction alone
neither reruns experiments nor verifies semantic claims.

## Scope and dependencies

The capsule retains failed, rejected, superseded and interrupted attempts,
consumed tools, checked-source snapshots, emitted programs, controls, timings and
resource receipts. The interrupted broader frontend acquisition remains beside
its successful retry. Original Clang permission failures remain beside the native
retry and explicit 60 + 21 backend closure. Deliberate supervisor stops remain
expected controls. Neither partial evidence nor failures were relabeled as passes.

The [Phase31 capsule](../../phase31/evidence/README.md) supplies the previous
compiler/local-data baseline; its earlier dependencies still apply. Checker
experiments identify their retained H17 inputs separately. Canonical compiler
source, designs, reports and small producers are tracked in the repository.
External Node 24.18.0, pinned Clang16, Python and system tools are identified where
consumed and are not bundled. The 103 unrelated starting files remain outside
this capture root; [their final audit](../protected-files-final.json) confirms
unchanged bytes. The previous installed release is also retained byte-for-byte
under `selfhost/dist/release-history/d8f609c99b3acef932f90040d0c6152c96605493bef926e46f25559ac125029b`.
