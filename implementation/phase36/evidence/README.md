# Phase36 evidence preservation

**Capture and fresh independent source/archive verification both pass.** The
closed tree contains **21,345 files / 259,269,871 logical bytes** and 4,649
directories, stored as **39,968,376 compressed bytes in one volume**. No regular
files were excluded. Failed, rejected and superseded experiments remain intact.

[Capture receipt](capture.json) · [Manifest](manifest.json) ·
[Capture resource receipt](capture-run/process.json) ·
[Independent verification](verify-run/stdout.log) ·
[Verification resource receipt](verify-run/process.json)

Capture takes **19.238 seconds** and peaks at **62,169,088 bytes** process-tree RSS;
independent verification takes **7.630 seconds**, peaking at **54,206,464 bytes**.
Both remain below the 1 GiB cap and above the 2 GiB available-memory floor.

| Volume | Bytes | SHA256 |
| --- | ---: | --- |
| [validation.tar.gz.part-00001](validation.tar.gz.part-00001) | 39,968,376 | `60a4cd2d10dec24d9491ef1f92a4f5f69694ef8bd4bc1ed3012caf036fae693a` |

There is one volume, so its hash also identifies the concatenated gzip stream.
The manifest hash is `f7c0c388043082dba8356ca31b5d17d4784ccb5abedd42e64fd025a5fee42917`.
All agents acknowledged closed writers, and root closed all acquisition jobs
before capture. The raw tree is now immutable; subsequent documentation and
publication records are outside it.

The [derivation](derivation.json) binds these successors to the frozen Phase35
[preservation producer](../../phase35/evidence/preserve.py) and
[bounded launcher](../../phase35/evidence/capture-run.py). Only phase labels,
`selfhost/build/phase36` source root and the exact expected producer hash change.
The streamed method, bounds, complete inventory checks and locks are unchanged.
Preparation did not execute either producer; the completed runs above are root-owned.

Before root starts capture, **all compiler, benchmark, profiler, control,
acquisition and report writers under the raw Phase36 tree must have stopped**.
Root must obtain writer acknowledgements or verify that agents are idle,
interrupted or shut down and cannot still write. An agent that was interrupted
need not respond merely to satisfy a receipt. Root's explicit `--closed` confirms
that check; this is an orchestration requirement, not another user approval.
Optional `writers-closed.json` may record the observed agent states and completed
jobs. The execution lock alone cannot detect an unsupervised report writer.
No further raw-tree mutation is allowed after capture begins.

Root runs the bounded launcher from the repository root, using new supervisor
receipt directories **outside** the captured source:

```sh
python3 implementation/phase36/evidence/capture-run.py capture \
  implementation/phase36/evidence/capture-run
python3 implementation/phase36/evidence/capture-run.py verify \
  implementation/phase36/evidence/verify-run
```

The child [preserve.py](preserve.py) owns the shared campaign execution lock at
`selfhost/build/phase32/execution.lock`. The outer [launcher](capture-run.py) uses
the distinct `implementation/phase36/evidence/supervisor.lock`, preventing a
nested acquisition of the campaign lock. CPU3,1GiB process-tree RSS ceiling,
2GiB available-memory floor and600-second deadline remain explicit. The launcher
passes `--closed`; verification also passes `--verify-only --check-source`.

The complete closed `selfhost/build/phase36` tree is the intended scope, including
failed, rejected, superseded, incomplete and successful attempts, consumed tools,
checked snapshots, generated programs, raw profiles, logs and process receipts.
Only regular `.pyc`/`.pyo` files are excluded and listed explicitly. Empty
directories and modes remain. Symlinks or special entries fail capture; they are
never silently omitted. Archiving does not turn a failed experiment into success.

Files, compression, splitting, decompression and member hashing use bounded
stream buffers. Each volume is at most40MiB, a consecutive part of **one gzip/PAX
tar stream**. The inventory records every file path/mode/size/SHA256, volume
identities and concatenated gzip identity. Every volume and tar member is
reopened and checked, the gzip trailer is consumed, and the entire source tree
is re-inventoried to detect changed bytes, additions, removals or modes.

Capture is usable only when `capture.json` and `manifest.json` report
`complete: true` and `sourceRehashed: true`, the manifest records
`reopenedVerified: true`, and its identity matches the completed receipt. Root
then requires a fresh independent source verification. Existing attempts are
never overwritten; failed partial volumes and receipts remain, and a successor
must use a fresh `--out` directory.

Standalone verification after relocation requires no source tree or writer
acknowledgement and writes nothing:

```sh
python3 implementation/phase36/evidence/preserve.py --verify-only
```

After successful capture, restore into a fresh directory:

```sh
mkdir /tmp/bend-phase36-evidence
cat implementation/phase36/evidence/validation.tar.gz.part-* \
  | tar -xzf - -C /tmp/bend-phase36-evidence
```

The manifest is authoritative about volume order. Zero-padded volume names make
that concatenation unambiguous. Its `archive.sha256` describes the complete gzip
stream, not any individual volume. Receipt paths are acquisition provenance;
reproducing a compiler or benchmark still needs the pinned toolchain/sources
specified in its own report. This archive does not copy external resources merely
because an archived JSON file refers to them.
