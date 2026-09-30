# Phase32 raw evidence capsule — capture pending

The producer is prepared; capture has not run. Do not treat this directory as a
completed or verified capsule until archive.py finishes, receipt.json reports
complete=true, and the root records archive size/hash and a closed-producer audit.
The installed release and broad gates are separate decisions.

[archive.py](archive.py) is byte-for-byte the Phase31 preservation algorithm with
only Phase31/phase31 substituted by Phase32/phase32. [Producer provenance](producer-provenance.json)
retains the parent SHA256
`50e36485135c173875f9a75404cc433ee9a90168fc2b7b2802090873401fe84a`
and verifies the exact inverse. The producer rejects existing archive/receipt
identities and symlinks, inventories every regular file, preserves hardlinked
inputs as independent regular members, checks the live input set and hashes after
capture, then independently reopens every tar member and compares exact name,
size, SHA256 and mode. A partial archive is retained as a failed attempt, never
overwritten or relabeled as verified evidence.

## Capture procedure

Wait for all Phase32 builders, control/timing producers, integration checks and
release operations to close. Run one supervised acquisition. Its output directory
must be outside `selfhost/build/phase32`, otherwise the supervisor would change the
very inventory being captured. This command keeps the wrapper logs with the
capsule and takes the same exclusive execution lock as other acquisitions:

```
python3 selfhost/tools/performance/phase32/bounded-run.py \
  --seconds 180 --rss-mib 1024 \
  implementation/phase32/evidence/capture-run -- \
  python3 implementation/phase32/evidence/archive.py
```

`execution.lock` is an ordinary zero-length acquisition-root file and may be
captured normally. Taking its advisory lock does not alter its bytes. Do not
start another root-owned producer before the final input-set check completes.
The producer uses memory proportional to its inventory and largest file; it does
not import a compiler or rerun experiments. A pre-capture stat-only inventory is
not a forecast of the final corpus or compressed size.

## Transport and recovery

After successful capture, inspect the actual gzip size before staging. If it is
at most95,000,000 bytes, keep the single campaign.tar.gz. If it exceeds that
conservative threshold below GitHub's100MB per-file limit, transport it in ordered
32MiB binary chunks. Keep the verified full archive and receipt locally; preserve
a manifest with each chunk's ordinal, size and SHA256 plus the complete archive
size/SHA256. Verify the concatenated chunks byte-for-byte against the complete
archive before staging chunks instead of the oversized archive. Never change the
archive bytes or relabel the original receipt as a different payload. No chunking
has been performed or is implied by this preparation.

Recovery must validate the receipt hash (or manifest and ordered chunks), then
extract below a separate destination. Exact commands and final storage size will
be filled in after capture. Absolute acquisition paths in reports are provenance;
replay needs explicit adaptation to the recovery root. Extraction alone does not
rerun correctness, prove conformance or establish another self-hosted fixed point.

## Scope and dependencies

Capture covers all regular files under `selfhost/build/phase32`: failed/rejected
attempts, consumed tools, checked-source snapshots, emitted programs, complete
controls, timing inputs/results and supervised resource records. It does not
silently omit the interrupted cleanup evidence or the expected supervisor stops.

The [Phase31 capsule](../../phase31/evidence/README.md) supplies the prior selected
compiler and local-data baseline; its earlier capsule dependencies still apply.
Phase32's checker experiments also use the retained H17 artifacts identified by
their exact acquisition inputs. Canonical compiler source, designs, reports and
small producers are tracked separately in the repository. External Node24.18.0,
pinned Clang16, Python and system tools are bound by identities where consumed,
not bundled. The103 unrelated starting files remain outside this capture root
and under their separate protection audit.
