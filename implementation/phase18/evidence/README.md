# Recovered Phase18 experiment evidence

Capture and independent recovery passed. This preserves **two uninstalled
transport experiments**; installed Phase17 remains the release. The cursor
candidate is the reconstruction anchor, not a promoted Phase18 compiler.

The [receipt](preservation.json) binds the exact inputs and outcome records.
[Inventory review](selection-review.json) records the selected scope and seven
explicit prior fixture sibling trees. No Phase18 topic roots were omitted at
freeze; Phase19 and protected Phase6 payloads are excluded.

- 4,546 regular files, 141,621,511 uncompressed bytes; no symlinks.
- Four archives totaling 20,882,557 bytes; largest 8,340,867 bytes.
- All extracted members verified by exact coverage, bytes, type and mode.
- All 214 cursor-anchor project members independently reconstructed from
  committed Phase17 `fddfc84b3f48aecc77c2424ddc8227cd7f63251f` plus the saved patch.
- All 75 protected Phase6 hashes/statuses and all nine root-frozen input hashes
  remain unchanged; no protected source payload was copied.

The source03 checker-world cost matrix remains evidence for source03. The later
source06 public-ABI correction has its own checked image and gates; its cost was
not measured in that earlier matrix. Both remain uninstalled. Original failed
builds, transport misses and public-result compatibility failures are retained.
No new conformance or performance claim follows from preservation.

The [manifest](capsule-01/manifest.json), [inventory](capsule-01/inventory.json)
and [independent recovery](recovery-01.json) identify capsule-01. No failed
preservation attempts or selection corrections occurred. The [prospective plan](PLAN.md)
and [root freeze](root-freeze.json) remain unchanged.

To repeat independent recovery from the repository root, choose a new report:

```sh
python3 selfhost/tools/performance/phase16/compact-recover.py \
  implementation/phase18/evidence/capsule-01 \
  /tmp/phase18-recovery-repeat-01.json
```

The unchanged verifier creates fresh temporary extraction/reconstruction roots.
Its historical `phase16` format/path labels do not change the baseline commit
recorded in this inventory. It uses committed Git bytes, never working-tree
compiler source, for reconstruction. Its nine previously recorded policy tests
were not repeated because its bytes and policy are unchanged.

The Phase17 capsule and its declared Phase16/older prerequisites, pinned upstream
`b2111cf43244e65f76ddc278ee695e669f720cbf`, and recorded executable toolchains remain
external prerequisites. Outcome docs, this receipt and the post-capture audit
are outside archive inputs to avoid self-reference. No original file was deleted.
Root owns commit and publication; this receipt makes no remote-publication claim.
