# Phase11 experimental evidence

The publication record `publication.json` binds `capsule-01/manifest.json`, its
`raw.tar.gz`, verification and independent recovery checks. Keep those files
together. Archive verification establishes byte identity; retained failed runs
remain failures and profiling runs do not become controlled timing samples.

This selection uses the unchanged [Phase8 collector](../../phase8/migration-evidence/collect.py).
Its historical schema name remains `phase8-migration-evidence`; the manifest
identifies the Phase11 scope. The Phase10 capsule, the Phase9 capsule, and five prerequisite Phase8
capsules provide shared byte objects. Their exact manifest/archive identities
are bound in the final capsule. Keep all seven prerequisite capsules available.
The transitive Phase9 profile gzip remains separately retained as documented in
[its evidence index](../../phase9/checker-evidence/README.md).

The archive preserves actual Phase11 attempts, failed probes and superseded
harness versions, operation controls, complete CPU-profile data, exact checked
builds and equality derivatives, differential observations, controlled timing,
final source and installed-release validation. Plans, tools, fixtures and reports
are captured after the root closes their producers. Publication metadata lives
alongside the immutable capsule to avoid circular self-inclusion.

Rebuildable Base caches and Python bytecode are excluded with recorded identities
and reasons. Old result JSON copied incidentally with historical test fixtures is
not a new Phase11 observation. Unrelated live Phase6 payloads are excluded.
Dirty-tree references in the initial state record retain only omitted identities
and reasons. Exact historical records actually read are retained with the owned
Phase11 experiment evidence, and frozen compiler snapshots keep the actual
inputs their provenance consumed. Node, Clang and host libraries are
external prerequisites with recorded identities, not embedded toolchains.

From the repository root, with Python3.9 or later and without `-O`:

```sh
python3 implementation/phase8/migration-evidence/collect.py verify implementation/phase11/evidence/capsule-01
python3 implementation/phase8/migration-evidence/collect.py materialize implementation/phase11/evidence/capsule-01 /tmp/phase11-evidence-recovery
python3 implementation/phase11/evidence/recovery-check.py implementation/phase11/evidence/capsule-01 /tmp/phase11-evidence-recovery /tmp/phase11-evidence-recovery-check.json
```

Recovery requires a new destination and reconstructs repository-relative paths
and file modes. The independent recovery check rehashes every restored file and
checks modes. Original requests retain absolute paths, so replay elsewhere must
supply the compatible toolchain and point at recovered API/Base/source/host paths.
No arbitrary-host portability or GPU-validation claim follows from preservation.

Any unresolved historical references or required unavailable inputs are listed
explicitly in the publication record. A local ignored path or checksum alone is
not durable preservation. Until publication is complete, `selection.json` and
preflight records are a preparation plan, not a completed capsule.

The failed status-only call launchers are preserved with their audit: completed
worker files do not make a process launch containing EPERM valid. The affected
microbenchmark ratios are excluded, and corrected release controls are separate
fresh attempts. Archive closure does not reverse that decision.
