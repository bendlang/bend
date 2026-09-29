# Phase15 compiler evidence

Publication is complete only when `publication.json` records both `complete` and
`pass` as true. That record binds `capsule-01/manifest.json`, `raw.tar.gz`, archive
verification and independent recovery. Keep those files together. Preservation
establishes byte identity; failures stay failures, and compiler promotion requires
the separate Phase15 validation gates.

This reuses the Phase14 machinery. `collect.py` imports the unchanged Phase8
collector and retains Phase14's iterative depth-first reference walk: the exact
hash/path pairs and pointer order remain unchanged, while deeply linked compiler
books do not consume Python call-stack depth. No generic `source` exception or
stack-limit increase is introduced.

The only inline-source exception remains **61 fields in three byte-pinned
Phase13 reports**, with exact row schemas, ranges and UTF-8 hashes: 23 fields in
`control-selector-bodies-01`, 28 in `control-selector-bodies-02`, and 10 in
`control-const-bodies-01`. Their original JSON bytes are included. The two inherited
adapter checks are rerun before final capture; their JSON results are capture
inputs. Unknown source/hash fields remain ordinary file references. A new shape
requires explicit review, never an unrestricted ignore rule.

## Required earlier capsules

Eleven manifests, in dependency order, supply shared objects. Each manifest and
its associated archive is verified and bound exactly in the final manifest:

1. `implementation/phase8/conformance-harness-evidence/manifest.json`
2. `implementation/phase8/selected-js-evidence/manifest.json`
3. `implementation/phase8/selected-js-evidence/release07-manifest.json`
4. `implementation/phase8/migration-evidence/capsule-01/manifest.json`
5. `implementation/phase8/migration-evidence/capsule-02/manifest.json`
6. `implementation/phase9/checker-evidence/capsule-01/manifest.json`
7. `implementation/phase10/evidence/capsule-01/manifest.json`
8. `implementation/phase11/evidence/capsule-01/manifest.json`
9. `implementation/phase12/evidence/capsule-01/manifest.json`
10. `implementation/phase13/evidence/capsule-01/manifest.json`
11. `implementation/phase14/evidence/capsule-01/manifest.json`

The separate tracked Phase9 `checking.cpuprofile.gz` is also required. Node24,
Clang16, headers and host libraries remain identified external toolchain inputs.
The inherited unavailable lexical-selfhost image is historical context, not a
consumed Phase15 compiler.

## Selection and exclusions

The selection covers every Phase15 design, experiment, report, tool, failed and
successful attempt, consumed snapshot, checked/derived API and provenance manifest,
profile, operation count, exact saved history, full frontend/backend result,
controlled measurement and final installed release. Superseded tools and failed
logs remain included; archiving does not turn failed strict probes into passes.

The 75 unrelated Phase6 paths from `selfhost/build/phase15/start-state.json` are
included as identity-only preservation records and excluded from new payloads.
The three additional Phase15 exclusions name only the corresponding
`project/tools/performance/phase6/` subdirectories of `behavior-source-01`,
`behavior-source-02` and `behavior-source-03` under `selfhost/build/phase15/`.
Those 33 files per directory were incidental copies in source preparations.
`incidental-source-review.json` records no checked snapshot directory or consumed
hash/path reference to them across eight checked attempts and 1,318 stable JSON
reports at review time. This is a scoped pre-freeze review, not an archive or a
claim about future producer output. An initial read-only scan raced a transient
frontend artifact deletion; its failure record is retained and the corrected
scan excludes live scratch trees. These exceptions do **not** match checked snapshots,
compiler APIs, source manifests, tests or logs. Any new incidental source copy
needs a separately reviewed exact path. The inherited Phase14 laws-project
source-only exception remains for recursively referenced baseline records.

Rebuildable Base caches and Python bytecode retain identities and reasons while
their bytes are omitted. Referenced excluded files must also be initial selection
inputs so the collector can record their omission identities; do not resolve a
missing cache record by broadly ignoring references. Old incidental conformance
result copies and unrelated pre-Phase8 release history retain their inherited
explicit omission policies. Actual consumed compiler inputs stay captured.

## Root freeze and publication

`selection.json` remains incomplete until root explicitly authorizes the freeze.
No inventory, archive verification, capture or recovery runs during a controlled
timing window. Required order:

1. Finish compiler jobs, profiling/timing, frontend/backend/helper/history/CLI
   checks, installation and all product/phase reports. Obtain closed-producer
   acknowledgements and the unchanged-75-files audit.
2. Root writes `root-freeze.json`, binding the selected/installed API and final
   reports and declaring `rootExplicitFreeze` and `captureAuthorized`. Only
   evidence preparation/publication may continue.
3. Run `inline-source-check.py` and `reference-walk-check.py`. Finalize exact
   includes/exclusions, add any specifically referenced omitted cache paths,
   preserve any failed preflight tools/logs, and set selection complete.
4. Run `collect.py plan selection.json NEW_PREFLIGHT.json`. Require no unresolved
   repository reference and audit all external/omitted classifications. If the
   preflight fails, preserve it and its consumed tool, correct only the identified
   issue, and use a fresh preflight path.
5. Run `publish.py --root-freeze-record root-freeze.json --recovery NEW_TMP_PATH`.
   Recovery must be outside selected roots. The publisher captures one capsule,
   verifies all prerequisite/archive objects, materializes every path, and runs
   the independent full byte/type/size/mode/symlink check. Each published archive
   and manifest must be below 100 MB.
6. Inspect publication/recovery records and unchanged Phase6 identities before
   explicit staging and publication. Do not rewrite captured files afterward.

Run commands from the repository root, using Python3.9+ without `-O`. Prefix
these script names and selection paths with `implementation/phase15/evidence/`.
Publication/preflight/recovery metadata stays outside capture inputs to avoid
self-inclusion; specifically retained failed preflights may be included after
they close. The evidence README deliberately describes completion through the
publication record so it need not be rewritten after capture.

To verify and recover the completed capsule:

```sh
python3 implementation/phase15/evidence/collect.py verify implementation/phase15/evidence/capsule-01
python3 implementation/phase15/evidence/collect.py materialize implementation/phase15/evidence/capsule-01 /tmp/phase15-evidence-recovery
python3 implementation/phase15/evidence/recovery-check.py implementation/phase15/evidence/capsule-01 /tmp/phase15-evidence-recovery /tmp/phase15-evidence-recovery-check.json
```

Recovery recreates repository-relative paths and modes. This is complete byte
recovery, not automated relocated execution of every experiment. Historical
records retain absolute paths; experimental replay needs compatible toolchains
and explicit adaptation of input, compiler, Base and host paths.
