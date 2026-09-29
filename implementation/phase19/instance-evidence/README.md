# Recovered live-checker release evidence

Capture and independent recovery passed for installed release
`fd9e8b28c906dff13471fab9afc6975fd5574edd`, API
`a15d150a920b89d9c0781372356424e559edabef3246ca281741069b0fe739b6`. This checkpoint preserves the live checker and its
experiments. The active contextual parser and Phase20 work are excluded.

The [receipt](preservation.json) binds the exact capture and outcome records.
[Selection review](selection-review.json) confirms all 59 release paths, 65
root-frozen inputs, 214 source-project members and 23 explicitly referenced
fixture sibling trees. The largest fixture expansion is the previously reviewed
220-file `unbound-marker-source-02` tree; no protected Phase6 payload is included.

- 5,016 regular files, 162,789,405 uncompressed bytes; no symlinks.
- Five archives totaling 21,102,971 bytes; largest 7,091,790 bytes.
- Every extracted member verified for exact coverage, type, bytes and mode.
- All 214 source files reconstructed from fixed prefix-release commit
  `506f5ca01139d0878c4fef840bbb6f30c1cc9ee4` and the saved six-file patch.
- All 75 protected Phase6 hashes/statuses and 65 root-frozen hashes unchanged.

The [manifest](capsule-01/manifest.json), [inventory](capsule-01/inventory.json)
and [independent recovery](recovery-01.json) identify capsule-01. The original
[prospective plan](PLAN.md), [reviewed proposal](selection-proposal-01.json),
[final amendment](FINAL-SELECTION.md) and [root freeze](root-freeze.json) remain
unchanged. No failed capture/recovery attempt occurred; the initial prospective
selection was retained before adding the closed supplemental release evidence.

Failed builds and preparations, the original 100-row boundary result with 20
failures, and the public18 gate's six expected transition differences remain
verbatim. The broader grouped runner's incomplete/false result and inherited
strict mismatches remain alongside its complete acquisition/regression audit.
The unchanged final 104 boundary controls, backend/history/full-frontend gates,
same-source cost matrix and installed CLI results have their own exact identities;
preservation adds no new conformance or performance claim.

The original source handoff describes 59 pre-promotion live-path hashes. The
selection review verifies each against both fixed prefix-commit bytes and the
prefix capsule's source snapshot. Exactly six current live paths differ, as
expected after promotion. Those original records were not rewritten or silently
validated against newer bytes.

To repeat independent recovery from the repository root, choose a new report:

```sh
python3 selfhost/tools/performance/phase16/compact-recover.py \
  implementation/phase19/instance-evidence/capsule-01 \
  /tmp/phase19-instance-recovery-repeat-01.json
```

The unchanged verifier creates fresh temporary extraction/reconstruction roots
and uses committed Git bytes plus the patch, never working-tree compiler source.
Its historical Phase16 format labels do not identify this release. Its nine
existing policy controls were not repeated because its bytes and policy are
unchanged.

The original prefix checkpoint, Phase18 capsule and their declared older
prerequisites, pinned upstream `b2111cf43244e65f76ddc278ee695e669f720cbf`, and
recorded executable toolchains remain external. The inventory records 62
then-existing unselected Phase19 entries. No original prefix/direct/proof or
active parser/Phase20 experiment is claimed recaptured. Outcome docs, the audit
and this receipt are outside capture inputs. No original file was deleted.
Root owns git and publication; this receipt makes no remote-publication claim.
