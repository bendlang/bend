# Recovered Phase20 declaration release evidence

This capsule preserves the installed declaration checkpoint release
`c385d3913e9f10c6c4d9c5cfef3f34bc0682d351`, checked source04/build04/API40c8. The final release source
and all earlier Phase20 attempts are included, including rejected source02/source03,
the independent semicolon counterexamples, failed audits/promotions and the raw
grouped runner's false/incomplete result. The neutral performance matrix is kept
with its original samples; this capsule makes no additional speed claim.

Capture contains 3303 members in 3 archives,
15,603,867 compressed bytes (121,192,708 payload bytes).
Largest archive: 7,631,341 bytes. Exact membership, modes and hashes are in
`capsule-01/inventory.json` and `capsule-01/manifest.json`. Three fixture symlinks
remain relative to captured regular files. No Phase6 payload, git metadata or
private contextual project is included; the exact guard patch is the sole
contextual input. The frozen release paths include the prospective
`design/phase21/group-boundaries.md` document; no Phase21 build/tool payload is
included. The protected75 identities and git statuses remain unchanged.

Independent unchanged compact-recover restored every member and reconstructed
all214 source files from fixed prior release
`fd9e8b28c906dff13471fab9afc6975fd5574edd` plus `prefix-to-anchor.patch`, without using
working-tree source. Only `src/front/declarations.bend` differs from that baseline.
The capture manifest's recoveryPending field describes capture-time state; the
completed independent result is `recovery-01.json` and `preservation.json`.

To verify in a checkout containing the declared prior commit and unchanged tool:

```sh
python3 selfhost/tools/performance/phase16/compact-recover.py \
  implementation/phase20/declaration-evidence/capsule-01 \
  /tmp/phase20-independent-recovery.json
```

Use a new output path. Recovery uses temporary extraction directories and removes
them on completion. The prior Phase19 capsule, pinned TypeScript checkout and
recorded Node/Clang toolchains remain explicit external prerequisites. This is a
preservation/reconstruction check; it does not rerun compiler conformance.

Selection review, post-capture audit and final receipts are outside the immutable
capture inputs. Root owns git publication; no network upload was performed by
the preservation owner.
