# Phase9 checker evidence

The [publication index](publication.json) identifies the final
[capsule-01](capsule-01/manifest.json), its archive hash and size, verification,
and complete recovery checks. Keep the manifest and `raw.tar.gz` together.
Archive verification establishes byte identity; recorded failed experiments
remain failures.

The archive is **51,300,565 bytes** and recovers **25,194 files**, all independently
rehashed with their modes checked. The separate baseline-profile gzip is
54,791,942 bytes; decompression reproduces its exact original bytes and hash.

One documentation command was corrected after capture: the main report's
unsupported `--check` became `--check-only`. The single capsule remains intact
with its earlier report snapshot. The
[correction record](authored-correction-01/manifest.json) binds that old hash and
the exact [corrected bytes](authored-correction-01/checker_speed.md.snapshot),
verified identical to the final tracked report and differing by only that one
replacement. Publication metadata is tracked alongside the capsule. After
ordinary recovery, copy this sidecar over `implementation/phase9/checker_speed.md`
in the recovered tree to obtain the corrected publication text.

The capsule uses the unchanged
[content-addressed collector](../../phase8/migration-evidence/collect.py). Its
historical schema name is `phase8-migration-evidence`; the manifest explicitly
identifies the Phase9 content scope. Five prior Phase8 capsules supply shared
objects rather than duplicating old payloads. Their exact manifests and archive
hashes are bound as prerequisites; retain all five with this capsule.

The selection preserves all Phase9 attempts, including rejected compiler/helper
candidates, raw comparisons, timeout/resource failures, exact snapshots, emitted
programs, operation controls, baseline/residual profiles, the final frontend
vector, six controlled timing rows, installed/relocated release checks, and
final source/report/experiment records. Version-1/version-2 equality evidence and
version-3 promotion remain distinct. The original P9-003 prospective record was
recovered by exact hash from its committed version and retained beside later
outcomes. Final compiler, source, runtime and tool identities are preserved.

The 1,573,317,008-byte baseline CPU profile is stored separately as its verified
lossless gzip in [profile-evidence](../profile-evidence/README.md). Its raw and
gzip identities are bound without duplicating those bytes in the main archive.
Keep that tracked gzip and its manifest. The complete residual profile and
streaming attribution arrays are inside the main capsule. Collector labels such
as `omitted-derived-input` and `external-toolchain-identity` are historical format
labels; explicit reasons identify the separately retained profile as experimental
evidence, not a discarded cache or tool.

Other exclusions are derived Base caches, Python bytecode, and incidental old
conformance-result JSON copied with test fixtures. All 264 initially observed
old-result copies were verified equal to their tracked historical originals;
these are not Phase9 attempts. Excluded files retain identities and reasons.
Unrelated live untracked Phase6 tools are excluded; actual frozen compiler
snapshots retain their original contents and provenance. Base caches should be
primed again from the recovered compiler, Base and driver.

Node, Clang and shared libraries remain external prerequisites with recorded
identities. The literal native gates used the unpacked Clang16 toolchain:

```sh
export CC="$PWD/selfhost/build/phase1/clang/root/usr/bin/clang-16"
export CPATH="$PWD/selfhost/build/phase1/clang/root/usr/include"
export LIBRARY_PATH="$PWD/selfhost/build/phase1/clang/root/usr/lib/x86_64-linux-gnu"
export LD_LIBRARY_PATH="$LIBRARY_PATH"
```

Reproduction needs the compatible host/toolchain and headers; the toolchain is
not embedded. Original requests retain their absolute paths, so point replay
harnesses at recovered API, Base, source and host paths. The capsule does not
claim arbitrary environment portability or GPU validation.

Run from the repository root with Python 3.9 or later, without `-O`:

```sh
python3 implementation/phase8/migration-evidence/collect.py verify implementation/phase9/checker-evidence/capsule-01
python3 implementation/phase8/migration-evidence/collect.py materialize implementation/phase9/checker-evidence/capsule-01 /tmp/phase9-evidence-recovery
```

Recovery requires a new destination and recreates original relative paths and
file modes. Restore the baseline profile separately with the gzip command and
SHA256 check in its linked index. `publication.json` records independent checks
of recovered files and the decompressed profile stream. Remaining historical
external references and any closure limitations are listed there explicitly.
