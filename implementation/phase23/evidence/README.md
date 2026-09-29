# Phase23 evidence preservation

The closed Phase23 producers are captured and independently recovered.
[The recovery receipt](recovery-01.json) verifies all 66,245 members, including
55,119 files containing 382,078,181 bytes. Every restored byte, mode and type
matches the manifest; a separate enumeration also verifies the current original
producer roots with no additions or omissions. The compressed archive is
18,532,332 bytes, SHA256
`7c83167b08b33b3ab0e87c94da41a70e954ef0c9b36824d696cb4ebbcfa81442`.
Failed experiments retain their original verdicts.

[The closed prerequisite inventory](../evidence-prerequisites-closed.json) scans
339 report/configuration files and records 4,539 external file/hash references,
with no unexplained restoration gaps. It checks the actual bytes of all 3,285
upstream Git blobs and 122 selected aliases in the Phase23 capture. Six current
tracked package/test identities also match production commit
`ab246cdd24e7695a14d3b725d5323b95c5f5892b` byte for byte.
Each reference retains originating JSON pointers and an explicit route.
Identity-shaped historical references do not mean that an old compiler or
command executed during Phase23. The [initial draft](../evidence-prerequisites.json)
and intermediate audits remain unchanged. The separate
[route-closure receipt](prerequisite-closure-01.json) binds the final inventory,
capsule and independent recovery, with the explicit external limits below.

Reproduce the closed-producer inventory in a fresh output file:

```sh
python3 implementation/phase23/evidence/prerequisites-scan.py NEW_OUTPUT --verify-git --producers-closed --production-commit ab246cdd24e7695a14d3b725d5323b95c5f5892b
```

The script never archives or extracts files. The separate closure script hashes
the existing prerequisite metadata and compressed archives again, and validates
all captured aliases against the recovered Phase23 manifest. Historical capsule
payloads retain their earlier hash-bound independent recovery receipts; they
were not all extracted again during this Phase23 closure.

## Required historical evidence

- **Phase21 group capsule:** restores the exact assembled ordinary-checking
  workload `group-range-build-02/.../compiler.bend`, SHA256
  `fac061286a2683914244178eb1f9b4dc2fbc2d393560739663e8bd08bbc12996`, from
  `experiments-01.tar.gz`. Its manifest is
  `2a533fd08cd17a368dec8d3d4ab3740471302871ae9c933013d245ce7ce76228`.
- **Phase22 context capsule:** restores the old `context-build-16` checked and
  derived APIs, runtime, frozen host, broader196 selection and integration198
  selection. It also preserves the explicitly selected older fixture trees.
  Its manifest is
  `5073b24f8561feb2c67cb8d3c38813fa89e8b9d4bf2eb1bcac469ae84e01eeca`;
  all36 exact XZ part hashes are in the prerequisite registry.
- **Phase12 capsule and its eight declared predecessor capsules:** restore
  original Phase11/12 request/session/worker/API identities needed to validate
  the53/60-request history prefixes. The manifest is
  `a62927bd40dfad4fb55c1c676baa7cddac091e6ed0905738e0c4e3d339688fb4`.
  The registry records the exact external manifests, archive paths and hashes;
  omitting those predecessor objects would make this capsule incomplete.
- **Phase23 production commit `ab246cdd24e7695a14d3b725d5323b95c5f5892b`:**
  supplies the six tracked package/test identities listed as
  `phase23-production-git`. Its blob bytes match the consumed hashes.
  Superseded component helpers and fixtures have exact copied bytes inside
  the Phase23 build evidence.

For compact Phase21/22 capsules, the inventory maps each exact historical path
and hash to an archive part. Verify the metadata and compressed hashes, then
extract selected members into a fresh confined destination with the declared
modes and link policy. Existing compact recovery tools independently verify
all parts but remove their temporary extraction directories; those commands
are verification recipes, **not persistent tree exporters**. The Phase12 generic
collector can materialize a fresh complete tree using the command in the JSON.
Never overwrite an existing experiment or rewrite an old observation.

The Phase21 source reconstruction additionally binds Phase20 commit
`c385d3913e9f10c6c4d9c5cfef3f34bc0682d351`; Phase22 reconstruction binds Phase21
commit `a784e0e1a0de1ee085cc188ca0f1f19038679bdb`. Their captured patches and
recovery receipts remain distinct from the already captured compiler images.
Reconstructing source does not manufacture a new checked bootstrap or fixed point.

## Reference checkouts and toolchains

Restore separate immutable upstream checkouts at
`b2111cf43244e65f76ddc278ee695e669f720cbf` (the old Phase8 path) and
`018751270e800bc222a93dad7f257083ee53a5f7` (Phase23). Both exact commits are
available from `https://github.com/bendlang/bend`. The former supplies original
history fixtures and the old TypeScript/Base comparator; the latter supplies
the new compiler, Base, tests and bootstrap. Keep Git revision metadata needed
by pin checks. Do not replace either with moving `main` or alter the existing
historical checkout. Preserved absolute paths describe the original execution;
restoring bytes elsewhere does not itself prove an exact relocated replay.

Node24.18.0, Clang16, include files, linked libraries and the Linux execution
environment are external prerequisites. Recorded Node SHA256 is
`41a74efb34cbde5c7632cdac0cf8bd1a14d0b8d73dc1e82755014d9a9ce70f5c`;
the Clang executable SHA256 is
`8a3f27cb0d8904a46986cbcc6437c2049939204d1c9f7caa3898c36ba067c0e2`.
The exact CC/CPATH/LIBRARY_PATH/LD_LIBRARY_PATH settings are recorded from the
successful installed/relocated CLI receipt. This is not a hermetic toolchain
bundle. Bun-dependent reference IO, unavailable ThreadSanitizer runtime support
and GPU/device execution are not supplied or validated by preservation.

## Explicit additions and historical omissions

The consumed file
`selfhost/build/phase16/wave6-backend-environment-01.json`, SHA256
`db973a862955df917132ee67dd7d7c79efbba6d3732e808ee300ef1f6f925e23`, has no exact
entry in the inspected Phase12/16/17/21/22 capsule inventories. The Phase23
package includes its unchanged bytes at the original path. Its embedded old command references are
historical metadata, not proof that Phase23 re-executed those commands.

The 122 byte aliases include superseded backend helpers and every consumed
intermediate component helper/fixture version. Thirteen other identities are
current Phase23 source files inside the selected tool/test roots. All these
routes are bound to the independently recovered manifest. The package preserves
the complete Phase23 build/tool/test roots, including unsuccessful attempts.

Three Phase12 Base cache identities occur only inside copied historical replay
reports. Their exact paths and hashes appear in the Phase12 manifest's explicit
derived-cache omission list. They were not opened by Phase23: the history
runner creates and validates new per-variant caches from its frozen API/Base.
This classification preserves the historical omission; it does not claim those
old cache bytes are inside an archive.

## Independent restoration

To reproduce independent recovery, choose a new destination and receipt:

```sh
python3 implementation/phase23/evidence/recover.py implementation/phase23/evidence /tmp/phase23-independent-recovery-NEW implementation/phase23/evidence/recovery-NEW.json --original-root "$PWD"
```

Both the destination and receipt must be new. The independent tool checks the
compressed archive hash, restores every member, then independently rereads all
restored bytes, modes and types. It rejects missing, duplicate or extra members;
the receipt separately lists necessary ancestor directories outside the capture
roots. It retains the restored tree. A successful receipt proves archive
restoration, without claiming a new compiler run or hermetic external closure.
The completed recovery tree is retained at `/tmp/phase23-independent-recovery-01`;
this temporary tree is a convenience, while the committed capsule is durable.

The route-closure check can also be repeated into a new receipt:

```sh
python3 implementation/phase23/evidence/close-prerequisites.py implementation/phase23/evidence/prerequisite-closure-NEW.json
```
