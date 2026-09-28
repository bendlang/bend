# Phase14 compiler evidence

Publication is complete only when `publication.json` records both `complete` and
`pass` as true. That record binds `capsule-01/manifest.json`, `raw.tar.gz`, archive
verification and independent recovery. Keep these files together. Preservation
establishes byte identity; failed runs remain failures and compiler promotion
requires the separate gates in the [phase report](../conformance_and_dispatch.md).

The [collector adapter](collect.py) imports the unchanged
[Phase8 collector](../../phase8/migration-evidence/collect.py). Its historical
schema name remains `phase8-migration-evidence`; the manifest scope identifies
Phase14. The only inline-source exception is the inherited set of 61 fields in
three named Phase13 control reports. Those complete reports are additionally
pinned to exact hashes, and each source string's UTF-8 hash and source range are
checked. The original JSON bytes remain captured. Unknown `source` fields remain
normal references; there is no generic exception that can hide missing files.
The [adapter checks](inline-source-check.json) record the positive and refusal
controls. Any new inline-source case requires an explicit reviewed contract.

Preflight01 exposed a recursion limit in the inherited reference walker on raw
linked compiler books. The original adapter and failure logs are retained. The
Phase14 adapter uses iterative depth-first traversal with the identical hash/path
pairs and pointer order. [Equivalence controls](reference-walk-check.json) compare
200 fixed-seed shallow cases and every positive pair with the unmodified walker,
then retain the exact reference through 2,000 nested tails where the old walker
overflows. No raw book is omitted and no stack limit is increased.

Ten prerequisite capsules supply shared objects: five Phase8 capsules and one
each from Phases9, 10, 11, 12 and 13. Their exact manifests and archives are bound
in the final manifest, in dependency order. Retain all ten and the separate
[Phase9 profile gzip](../../phase9/checker-evidence/README.md).

The selection captures all Phase14 designs, reports, tools, rejected and successful
attempts, consumed snapshots, checked/compiler lineage, original histories,
conformance observations, controlled measurements and final installed release
state after root closes every producer. It includes failed fixture preparations,
the cancelled divergent template witness and failed strict diagnostic results.
Capturing these records does not change their status.

Rebuildable Base caches and Python bytecode are omitted with identities and
reasons. Re-prime caches using the recorded API, Base and host. The 75 unrelated
Phase6 dirty files remain identity-only preservation inputs, as do incidental
Phase6 tools copied into the isolated laws projects but never consumed by their
checked workflow. Exact snapshots of actually consumed compiler, development and
conformance inputs remain included. Old incidental conformance-result copies and
unrelated pre-Phase8 release history have explicit inherited omission rules.

Node, Clang and host libraries remain external toolchain prerequisites with exact
identities. The separate Phase9 profile gzip remains a required durable payload.
An inherited unavailable lexical-selfhost image is historical context, not a
Phase14 consumed compiler. Publication records disclose unresolved repository
references; successful publication requires none.

From the repository root, with Python 3.9 or later and without `-O`:

```sh
python3 implementation/phase14/evidence/collect.py verify implementation/phase14/evidence/capsule-01
python3 implementation/phase14/evidence/collect.py materialize implementation/phase14/evidence/capsule-01 /tmp/phase14-evidence-recovery
python3 implementation/phase14/evidence/recovery-check.py implementation/phase14/evidence/capsule-01 /tmp/phase14-evidence-recovery /tmp/phase14-evidence-recovery-check.json
```

Recovery requires a new destination outside selected roots and reconstructs every
repository-relative path and mode. The independent checker rehashes every restored
file, checks sizes, types and modes, and checks symlink targets. This is complete
byte/mode recovery, not automatic relocated execution of all archived experiments.
Original records retain absolute paths; rerunning experiments requires compatible
toolchains and adapting recorded input, API, Base and host paths.

`selection.json` stays incomplete until root explicitly authorizes freeze and
capture. A passing preflight is required before publication. Publication metadata,
preflight output and recovery output remain outside captured roots to avoid
self-inclusion. No inventory/archive operation runs during a controlled timing
window. The final root freeze, publication record and independent recovery record
are published beside the immutable capsule.
