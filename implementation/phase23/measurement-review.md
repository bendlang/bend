# Phase23 final cost-screen review

Read-only review of the root-owned measurement found no blocking issue for the
stated same-workload, usable-bundle comparison. No new probe was run by this
reviewer. The final cost result is owned by the main Phase23 report.

Reviewed input identities:

- `selfhost/tools/performance/phase23/check-matrix.mjs`:
  `4a3bd6052658bfc8bcf4d7bd39acc0de453b9326844d8a51df9b2e6ba1786d1d`.
- Copied worker `selfhost/tools/performance/phase8/check-worker.mjs`:
  `fc6ad2c09b80b51951f4daf54f05df3d48372364d981599aaaec65915dd27d08`.
- `selfhost/build/phase23/cost-config-02.json`:
  `0f99a3b875119b5389a263b428958fb4dd1c1efda34563d41ed804e748eef225`.

All variants check the exact same frozen Phase21 assembled compiler source.
Each attempt is verified through its frozen workflow helper, including genuine
bootstrap/derived lineage. The configuration has no upstream override: each
variant uses its own recorded pin and Base. Compiler, runtime, host, snapshot,
Base-cache, upstream compiler and workload inputs are hashed before/after every
row, including inside the measured worker. The result must be an accepted type
check followed by the expected unsafe-definition trust refusal. Entire result
objects must match after removing only host provenance, which is independently
checked against the actual adapter/driver identities.

The order is TS/released/refreshed/candidate/candidate/refreshed/released/TS.
Every observation uses a fresh process, CPU0,4MiB stack and4GiB heap, with a180s
outer deadline. The worker records and the launcher asserts actual affinity.
The lead waits for other agents' heavy work to finish before starting this run.
The tool itself does not establish external machine-wide idleness; this is an
explicit execution precondition, not an inferred measurement property.

The request clock wraps `adapter.probe`, including lazy compiler loading, source
loading/checking and the adapter's final result. Adapter import is separately
recorded outside that clock. Process wall also includes startup, identity hashing
and result/log capture. Bend uses pre-existing validated Base caches; TypeScript
loads and checks Base. Filesystem caches are not flushed. RSS is the whole
process peak, including loading and input verification, not isolated graph-heap
allocation.

Interpret the comparisons at their actual boundaries:

- Candidate versus released compares the complete migration to the preserved
  Phase22 bundle, including changed pin, Base, profile, source, runtime and host.
- Candidate versus refreshed compares the new combined source/runtime bundle
  with the old compiler implementation rebuilt against new upstream/Base/profile.
  It does not isolate graph conversion from all other migration changes.
- Candidate versus TypeScript is the ratio for these checking workflows and this
  frozen input. It measures neither emission nor generated-program execution.

Every process hashes the same union of all variants' inputs within this screen.
That union can differ from an earlier screen, so absolute startup/process times
across screens are not a clean attribution of compiler changes. Prefer the
within-screen paired comparisons and report request time separately. Two samples
per image are a small cost screen with mirrored ordering, not a statistically
established speedup or universal slowdown bound. Retain both rows and any failed
outcome; do not select only the faster observation.
