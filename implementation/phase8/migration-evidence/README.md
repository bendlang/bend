# Phase8 migration evidence

`collect.py` preserves completed experiments, including failed and abandoned
attempts. It verifies bytes and provenance; it does not turn a recorded failure
into a passing test. `selection.json` is deliberately marked incomplete until
all selected producers have stopped. The collector is independent of the Bend
compiler and performs no compilation or benchmark execution.

The final capsule is [capsule-02](capsule-02/manifest.json). The earlier
[capsule-01](capsule-01/manifest.json) retains the first completed snapshot,
before the root corrected spacing in authored prose. No compiler experiment
changed. `cosmetic-recapture.json` records the affected document identities.
Capsule-02 reuses capsule-01 objects, avoiding a duplicate full payload. Its manifest maps each
original repository path to a SHA256 object, file mode and owning archive. The
new archive holds only objects absent from the explicitly bound prior Phase8
conformance capsules. Keep those sibling capsule manifests and archives with
this capsule: their exact hashes are prerequisites, and verification reads all
of them. Do not replace a published capsule; add a new numbered capsule.

## Scope and exclusions

The selection includes all `selfhost/build/phase8` attempts; exact source, API,
Base, bootstrap and host snapshots; emitted JS/C; native executables; original
requests, reports, logs and failure witnesses; old and new upstream source and
test snapshots; final installed release lineage; maintained Phase8 test
harnesses; and the Phase8 designs, experiment records and reports. The collector
also follows recognizable repository-local JSON path/SHA256 references when
current bytes match. Historical references are resolved by content identity
when a matching object exists under another captured path.

Every excluded file keeps its path, size, SHA256 and omission reason. Exclusions
are derived Base caches, Python bytecode, incidental pre-Phase8 result JSON
copied into `bootstrap-original-project/tests/conformance`, and external Clang
installation files. Base caches should be primed again from the captured
compiler, Base and driver. The original failed Phase8 attempts are retained.
The collector reports unparsed negative-control JSON and unresolved references
explicitly; a valid archive is not a claim that every external prerequisite is
embedded. Node, Clang and host libc identities are recorded without embedding
toolchain binaries or shared libraries. Reproduction still needs the stated
platform and toolchain, and preserves the documented libc limitation on native
`Process.run`. The final preflight resolved every repository-local reference.
Its remaining 36 external occurrences are all the same inherited earlier-phase
`lexical-selfhost` API, referenced by copied `src/back/js/experiments` reports;
that historical artifact is not the Phase8 release compiler. Details are in
`preflight-03.json`.

## Commands

Run from the repository root with Python 3.9 or later. Optimized `-O` mode is
rejected because integrity checks use assertions:

```sh
python3 implementation/phase8/migration-evidence/test_collect.py
python3 implementation/phase8/migration-evidence/collect.py plan implementation/phase8/migration-evidence/selection.json /tmp/phase8-evidence-plan.json
```

A plan reads current bytes but makes no immutability or experiment-completion
claim. After closing all producers, review the inventory, set `complete` to
`true`, then capture into a new directory:

```sh
python3 implementation/phase8/migration-evidence/collect.py capture implementation/phase8/migration-evidence/selection.json implementation/phase8/migration-evidence/capsule-02
python3 implementation/phase8/migration-evidence/collect.py verify implementation/phase8/migration-evidence/capsule-02
python3 implementation/phase8/migration-evidence/collect.py materialize implementation/phase8/migration-evidence/capsule-02 /tmp/phase8-evidence-recovery
```

Capture refuses an incomplete selection or existing destination. It verifies
all archive objects and rechecks selected membership and included/omitted
original identities before atomically publishing the directory. Source files
may legitimately evolve after capture; verification uses the archived bytes.
Recovery requires an empty destination and reproduces original relative paths,
bytes and file modes. Original request records retain their original absolute
paths; replay uses the archived harness instructions with API, Base and project
paths pointed at the recovered tree. Safe local symlinks are preserved; absolute symlinks,
parent-traversing targets and selected paths beneath symlinks require manual
review and are refused before recovery starts. The archive itself contains
only regular files named `objects/<sha256>`.

`collector-controls-01.json` records synthetic controls for duplicate-object
reuse, CRLF provenance references, malformed JSON preservation, omitted-cache
identities, mode/symlink recovery, corruption rejection, prerequisite hash
binding, draft/overwrite refusal and recovery path safety. The initial suite passed 19/19 controls; `collector-controls-02.json` adds
nested-capsule reuse/recovery and missing/mutated-prerequisite controls, passing
23/23. All prerequisites must appear before their dependents in the selection. These are collector
controls, not additional compiler conformance results.

## Published result

[publication.json](publication.json) records the final verification and full
recovery check. The final capsule indexes 27,286 files. Its 32,836-byte archive
contains 16 new objects and reuses the 21,314,537-byte capsule-01 archive plus
three previously published conformance archives. Keep all bound prerequisites.
Both main manifests remain intact, preserving the pre-correction prose and the
final authored documents without duplicating the large experiment payload.

The publication index explains one harmless reference-index ambiguity:
`raw.tar.gz` in the cosmetic-recapture metadata is relative to capsule-01,
while the generic provenance scanner assumes repository-relative paths. The
archive is present, hash-bound and independently verified. This is separate
from the explicitly retained historical external API reference and toolchain
requirements.
