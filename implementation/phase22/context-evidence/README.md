# Phase22 evidence: contextual compiler release

Capture and independent recovery are complete; the [outcome receipt](preservation.json)
binds both and the final protected-file audit. The usable compiler and its
reports are committed at `1e640798c7b74c32a1d3f3335727d7be918795b9`.
See the [compiler report](../contextual-conformance.md) for conformance, controlled
cost and simplicity; preservation validates recoverability, not a new compiler
check, self-hosted fixed point or proof-kernel result.

## Preserved artifacts

The [capture manifest](capsule-01/manifest.json) binds **24,804 members**
(24,803 regular files and one fixture link), **1,249,820,320 logical bytes**,
and36 tar/XZ parts totaling **23,647,460 compressed bytes**. Its SHA256 is
`5073b24f8561feb2c67cb8d3c38813fa89e8b9d4bf2eb1bcac469ae84e01eeca`.
The [exact inventory](capsule-01/inventory.json) has SHA256
`624ec44ab13ed5ac33c5787d20993e7de67a082cbc4940e7766f8f18ef889a99`.
Every part is at most1,405,372 compressed bytes, below the40,000,000-byte cap.

The inventory includes the original and failed parser candidates, all selected
control inputs and raw outcomes, all rejected cost screens, profiles, checked
builds, generated APIs, frozen tools, final gates, promotion and CLI records.
It also includes all314 files in the compiler checkpoint and the seven current
root documents. Earlier failed expectations and raw runner failures retain their
original values. The [selection](selection-proposal.json), [producer freeze](root-freeze.json)
and [independent inventory review](inventory-review-final-01.json) define the scope.

The final215-file source/host project is reconstructed from committed baseline
`a784e0e1a0de1ee085cc188ca0f1f19038679bdb` and the captured patch. Its guardedv5 API
is `ade8ef020e439b81ecb53057b33a473c34a3cbd993b98a044121ecc3c2b8c9c3`;
the genuine upstream-checked B1 is separately preserved as
`9cf01096f395817470ef0515e0ee98da85a53eb1b05823c88c9f2d5531e6072a`.
Recovery checks both identities without relabeling one as the other.

Twenty explicit prior fixture trees are included. One disclosed dependency,
Phase16 `unbound-marker-source-02`, includes220 members/1,284,975 bytes because
its fixture sits beside a214-file historical project. That exact tree was
separately reviewed and accepted; it is not the current215-file project or a
fixture-only count. Prior capsule receipts, the pinned upstream checkout at
`b2111cf43244e65f76ddc278ee695e669f720cbf`, and recorded Node/Clang toolchains remain
explicit external prerequisites. The75 unrelated Phase6 payloads and28 preexisting
release-history files are excluded and retain their original hashes/statuses.

## Independent recovery

The [independent recovery](recovery-final-01.json), SHA256
`06258c20df50511e7f7942fa7b61e5ef10591ccce85462a488ea9d2aba7d1749`, verified
every byte, mode and link, then reconstructed all215 source members from Git and
the patch without reading live source. Manifest, inventory and all36 archives
were unchanged before/after. Recovery completed in18.60 seconds and removed only
its own temporary scratch. The [process receipt](recovery-process-final-01.json)
binds the consumed tool, command and complete execution.

To repeat from a checkout containing the baseline commit, use a fresh output path:

```sh
python3 selfhost/tools/performance/phase22/context-recover-v3.py \
  implementation/phase22/context-evidence/capsule-01 \
  /tmp/bend-phase22-recovery.json
```

Run from the repository root. The report must be outside the capsule. The tool
extracts one part at a time, verifies it, removes that owned scratch, and retains
only explicitly selected artifacts. The largest actual regular part payload is
37,618,428 bytes; retained payload is2,074,285 bytes, totaling39,692,713 bytes.
Reserve additional space for filesystem metadata and reports. Source reconstruction
runs after part scratch is removed. Paths, links and complete source membership
are checked before permissions are restored.

## Storage and audit history

The original gzip proposal required150,088,149 bytes and did not fit. Encoding
those same provisional tar streams with explicit XZ/LZMA2 preset9,64MiB dictionary
and CRC64 required23,465,700 bytes. The final inventory adds later policy/closure
records, yielding the final23,647,460-byte archive above. This changes compression,
not logical evidence. Both decompressed positive tar frames matched exactly;
all27 safety controls and two additional codec-refusal controls passed. See the
[codec review](codec-xz-independent-review.json).

Three reviewed hardlink operations coalesced only identical closed scratch files,
preserving every logical path, byte and mode. No existing evidence tree was
deleted to make room. Their plans, estimates and replacement journals are retained.
Historical recoverer versions, caught safety defects, failed selection/receipt
preparations, original gzip estimates and superseding fixes remain available.
Use the current v3 recovery command for this XZ capsule.

The capture manifest's `recoveryPending:true` records its state at capture time.
It stays immutable; the separate successful recovery above closes that state.
This README, final outcome receipt, recovery/process records and preservation
index are outside captured inputs, so recording completion does not rewrite them.
Local capture, recovery and commits do not imply remote publication; the earlier
automatic approval block on pushing remains unresolved.
