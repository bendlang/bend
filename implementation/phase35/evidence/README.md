# Phase35 evidence preservation

The root orchestrator runs [preserve.py](preserve.py) only after all Phase35
compiler, benchmark, profiler and report writers have finished:

```sh
python3 implementation/phase35/evidence/preserve.py --closed
```

Capture and a fresh independent `--verify-only --check-source` both completed.
The capsule contains **24,717 files / 395,912,134 logical bytes**, plus 5,573
directories, in **52,475,156 compressed bytes across two volumes**. The
[manifest](manifest.json), [capture receipt](capture.json),
[capture supervisor](capture-run/process.json) and
[verification supervisor](verify-run/process.json) record exact identities.
Capture took **25.199 seconds**, peaking at **68,743,168 bytes (65.6 MiB)**;
the separate verification took 9.611 seconds, peaking at 60,190,720 bytes.
The [bounded launcher](capture-run.py) gives the child the shared campaign lock,
with a distinct outer supervisor lock, 1 GiB RSS cap, 600-second deadline and
2 GiB available-memory floor. All report writers were closed before capture.

The concatenated gzip SHA256 is
`905fca0e9eec65d70b540df8009d4f8f8c67adb1e6ccd9eca4fd2eb980113b31`.

| Volume | Bytes | SHA256 |
|---|---:|---|
| `validation.tar.gz.part-00001` | 41,943,040 | `b31b8acc0033dfce64e4b931cccb8961abfdc1f1967bf8f9395ab7e1846b2045` |
| `validation.tar.gz.part-00002` | 10,532,116 | `9deded3c959430812becc99c3d8ea88cf5ce7d5223e9eb014b94549f085c0895` |

Each volume is at most **40 MiB (41,943,040 bytes)**. The files are consecutive
pieces of **one gzip-compressed tar stream**; individual volumes are not separate
tarballs. The inventory contains every archived file's path, size, mode and SHA256,
each volume's size/hash, and the concatenated gzip stream's size/hash.

Scope is the complete closed `selfhost/build/phase35` tree, including failed,
superseded, incomplete and successful attempts, consumed producers, checked
snapshots, generated programs, raw profiles, logs and process receipts. Only
regular `.pyc`/`.pyo` files are excluded; their paths are listed. Empty directories
and directory modes are retained. Symlinks, device files or other special entries
cause capture to fail instead of silently omitting or following them. Historical
failure status inside a captured report is not changed by successful archiving.

The implementation extends Phase34's capture/reopen/source-rehash method. File
contents, compression, splitting, decompression and member hashing all stream
through bounded buffers; only inventory metadata scales with file count. Every
volume is reopened and checked, every tar member is checked against the complete
inventory, the gzip trailer is consumed, and every source file is rehashed after
capture. A fresh source inventory also detects additions, removals and mode
changes. The producer takes the same nonblocking execution lock as campaign jobs.
That lock supplements root's `--closed` confirmation; it cannot determine whether
an unrelated report writer outside the supervisor is still active.

Existing capture attempts are never overwritten. If a capture fails, its partial
volumes and incomplete `capture.json` remain; use a fresh `--out DIRECTORY` for a
successor. A capsule is usable only when both receipts report `complete: true`
and `sourceRehashed: true`, the manifest reports `reopenedVerified: true`, and
its size/hash match the identity stored in `capture.json`. Both verification
modes enforce this completion policy before reading the archive stream.
Large files are not loaded whole into memory, and no network tool is invoked.

Verify a completed capsule without extracting or changing it:

```sh
python3 implementation/phase35/evidence/preserve.py --verify-only
```

To verify the source tree as well, after its writers have closed:

```sh
python3 implementation/phase35/evidence/preserve.py --verify-only --check-source --closed
```

The manifest is authoritative about volume ordering. The zero-padded filenames
also make this exact concatenation and restore command safe with the producer's
bounded naming scheme; create a fresh destination so extraction cannot overwrite
a prior acquisition:

```sh
mkdir /tmp/bend-phase35-evidence
cat implementation/phase35/evidence/validation.tar.gz.part-* \
  | tar -xzf - -C /tmp/bend-phase35-evidence
```

To inspect the logical compressed hash directly:

```sh
cat implementation/phase35/evidence/validation.tar.gz.part-* | sha256sum
```

Compare it with `archive.sha256` in `manifest.json`; do not compare it to an
individual volume hash. `--verify-only` performs both levels of checking plus all
member checks automatically. Receipts may retain acquisition-machine absolute
paths; those are provenance, not portable replay dependencies. Reproducing a
compiler or benchmark still requires the pinned sources/toolchain and commands
identified in its own retained receipts. The archive does not duplicate resources
outside `selfhost/build/phase35` merely because a report references them.
