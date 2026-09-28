# Phase13 experimental evidence

The [publication record](publication.json) binds `capsule-01/manifest.json`, its
`raw.tar.gz`, verification and independent recovery checks. Keep those files
together. Archive verification establishes byte identity; retained failed runs
remain failures. Preservation does not promote the experimental compiler.

The [Phase13 adapter](collect.py) imports the unchanged
[Phase8 collector](../../phase8/migration-evidence/collect.py), which uses its historical schema name `phase8-migration-evidence`; the scope identifies
Phase13. The initial preflight failed because a literal `source` plus `sha256`
was interpreted as a file reference. The failure is retained in
`preflight-01-failure.json`. The adapter recognizes only the exact inline-source
fields in three named control reports, verifies all 61 UTF-8 hashes and source
ranges, and records them in the manifest. Original JSON bytes and all other file
references remain intact. A mismatch aborts capture.

Nine prerequisite capsules provide shared byte objects: Phase12, Phase11,
Phase10, Phase9 and five Phase8 capsules. Their exact manifest/archive identities
are bound in the final manifest. Keep all nine available, together with the
separately retained [Phase9 profile gzip](../../phase9/checker-evidence/README.md).

The selection preserves all Phase13 attempts, consumed tools and superseded
versions, full raw CPU-profile bytes, exact request histories, failed controls,
operation counts, timing samples and the self-contained helper feasibility image.
It also binds the unchanged checked parent and installed Phase12 release, source,
host, runtime and Base. It captures final designs, tools and reports after all
producers close. Publication metadata is kept beside the immutable capsule to
avoid circular self-inclusion.

Rebuildable Base caches and Python bytecode are omitted with recorded identities
and reasons. Cache preparation must use the recorded API/Base/host identities.
Unrelated live Phase6 work is omitted: its 75 original file identities are used
only to verify that this phase leaves the pre-existing dirty workspace unchanged.
Historical consumed records and any available original bytes remain in their
prerequisite capsules. Incidental old conformance JSON is not a Phase13 attempt.
Node and inherited Clang/library prerequisites are recorded rather than embedded;
this phase does not run a new native build.

From the repository root, with Python 3.9 or later and without `-O`:

```sh
python3 implementation/phase13/evidence/collect.py verify implementation/phase13/evidence/capsule-01
python3 implementation/phase13/evidence/collect.py materialize implementation/phase13/evidence/capsule-01 /tmp/phase13-evidence-recovery
python3 implementation/phase13/evidence/recovery-check.py implementation/phase13/evidence/capsule-01 /tmp/phase13-evidence-recovery /tmp/phase13-evidence-recovery-check.json
```

Recovery requires a new destination and reconstructs repository-relative paths
and file modes. The independent recovery check rehashes every restored file and
checks modes. This is complete byte/mode recovery, not automatic execution of all
experiments after relocation. Original records retain absolute paths; rerunning
a probe requires compatible toolchains and adapting its API/Base/source/host
paths. No arbitrary-host portability or GPU validation follows from this archive.

The publication record explicitly lists external references and limitations.
The inherited unavailable lexical-selfhost API is historical context, not a
Phase13 consumed compiler. A hash or ignored path alone is not durable storage.
`selection.json`, the final root freeze and passing preflight record describe the frozen
inputs; only a complete passing publication record establishes final capture.
The [phase report](../structured_rewriter.md) separates bounded correctness,
controlled measurement and the decision to defer production integration.
