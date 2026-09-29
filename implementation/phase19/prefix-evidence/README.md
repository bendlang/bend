# Recovered installed prefix correction evidence

Capture and independent recovery passed. This checkpoint preserves the installed
Phase19 prefix identity correction, release `506f5ca01139d0878c4fef840bbb6f30c1cc9ee4`,
API `66d6ce45c0c6ea8947190ff210274f1e6f0c7bf85f7ad3f215076f8820acd7c7`. The active contextual parser and live checker
migration are excluded.

The [receipt](preservation.json) binds the exact inputs and outcome records.
[Selection review](selection-review.json) confirms all 22 root release paths,
eight exact/proof boundary trees and all 214 source-project members. The original
parent's five identity failures and accepted-invalid cached reflexivity proof
remain unchanged beside the independently captured oracle and corrected results.

- 1,028 regular files, 54,540,178 uncompressed bytes; no symlinks.
- Two archives totaling 6,216,151 bytes; largest 6,199,148 bytes.
- Every extracted member verified for exact coverage, type, bytes and mode.
- All 214 source members reconstructed from committed Phase17
  `fddfc84b3f48aecc77c2424ddc8227cd7f63251f` and the 669-byte source patch.
- All 75 protected Phase6 hashes/statuses and all 33 root-frozen input hashes
  remain unchanged. No protected Phase6 source payload was selected.

The [manifest](capsule-01/manifest.json), [inventory](capsule-01/inventory.json)
and [independent recovery](recovery-01.json) identify capsule-01. No failed
preservation attempt or selection correction occurred. The [prospective plan](PLAN.md)
and [root freeze](root-freeze.json) remain unchanged.

The inventory explicitly excludes 45 then-existing Phase19 roots, including all
active contextual parser/checker work and the V2 boundary migration results.
Shared original oracle inputs contain broader source fixtures, but their
preservation does not assert migration validation for this installed correction.
No additional conformance, backend or performance claim follows from capture.

To repeat independent recovery from the repository root, choose a new report:

```sh
python3 selfhost/tools/performance/phase16/compact-recover.py \
  implementation/phase19/prefix-evidence/capsule-01 \
  /tmp/phase19-prefix-recovery-repeat-01.json
```

The unchanged verifier creates fresh temporary extraction and reconstruction
roots. Its historical Phase16 labels identify its format, not the source baseline.
It reconstructs from committed Git bytes and the saved patch without reading
working-tree compiler source. Its nine existing policy controls were not rerun
because the verifier bytes and policy are unchanged.

Phase17/18 capsules and their earlier declared prerequisites, pinned upstream
`b2111cf43244e65f76ddc278ee695e669f720cbf`, the fixed release commit's unchanged
host/runtime files and recorded executable toolchains remain external
prerequisites. The inventory review verifies 282 exact Phase17 input identities
against its durable inventory. Outcome docs, this receipt and the post-capture
audit are outside capture inputs. No original files were deleted. Root owns git
and publication; this receipt makes no remote-publication claim.
