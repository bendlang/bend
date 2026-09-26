# S4-A independent migration and proof-launch review

The corrected **423-pair source migration** has no blocking source-edit issue in
this review. The original 425-pair attempt is rejected: passing its 21 focused
controls did not preserve two selected exports. Corrected artifact/root equality
and genuine checked self-reproduction remain promotion gates; no completed
B1→H→H proof is claimed here.

## Small controls actually run

The frozen genuine S3 API `ba121e4098044d9f106c4e7cb3e37b0e1ce1bc77f7e42f7e5418556b7f0f3e90`
parsed, graph-loaded and checked both assembled four-core-module source forms
with empty errors. Before SHA is
`f9977208ec98802295684c912836141b01a802d14590e33b71d004f14f8dd659`;
pilot SHA is
`d087e217e30fc9835bf0c111a9300d988596b15f4415552380fe12f163796ef6`.
See [the retained core result](core-source-pair-result.json). The root separately
owns the pinned TypeScript build, seven-root emitted-byte comparison and existing
normalization/index tests; those were not rerun by this reviewer.

[declaration-controls.mjs](declaration-controls.mjs) passed 12 before/after cases
against pinned TypeScript and the same frozen S3 API. Cases cover multiline typed
headers including a final trailing comma, erased dependent types, unrestricted
versus affine arguments, unsafe signature formation versus safe rejection,
decreasing and unsafe self-recursion, retained mutual laws, a missing forward
law, malformed marked parameters, and an illegal typed fill of an existing law.
Positive cases compare alpha-normalized final type signatures, quantities and
unsafe flags, sorted by declaration name. Final-map selection follows the loaded
book's chronological order, taking the last event for each name. Raw source IDs
and declaration-event identity are deliberately not asserted unchanged.

The initial runner attempt stopped before compiler calls because piped Git
capture returned `EPERM`; its failed report remains under
`selfhost/build/phase7/s4/declaration-controls-01/`. The runner now uses file-backed
Git output and rejects spawn errors. Attempt 02 passes all 12 rows, retained in
[the control result](declaration-controls-result.json). These are small parse/check
controls, not source-wide self-reproduction or runtime benchmarks. This reviewer
authored these controls; their authoring and execution are not an independent
review of the test author's own work.

## Source migration and the failed capability hypothesis

The migration verifies the frozen inventory, module manifest and all 59 input
module hashes. It copies into a new isolated source directory and refuses to
overwrite existing snapshots/reports. The edit set consists only of selected
law-block removals and replacement definition-header lines. Typed binders copy
the law's literal names, quantities, types, order and return expression. The
original definition parameter names/order and adjacent `@unsafe` are checked;
the body bytes are outside the edit ranges. Edits must be disjoint, and the
post-edit declaration sequence must be exactly the original minus selected laws.
No definition sorting, source generation at build time or hidden law injection
is introduced.

An independent extractor compared all **1,450 function bodies and unsafe markers**
in original versus both isolated source candidates, verifying the 59 module hash
pairs and unchanged definition order. It found zero differences. This extraction
excluded trailing separator newlines from body equality; the migration's disjoint
raw edits were separately read and reviewed. Candidate host, assembler, lazy ABI
adapter, maintained selfhost runner and runtime bytes match the baseline.

Source spelling is also a build contract. The maintained host has three literal
law probes: `law j_layout_error:`, `law annotate_selected:`, and
`law j_program_selected:`. The first two were in the 425 migration, silently
removing exports even though their typed definitions remained. The third was
never selected and remains intact. The additional `nc_annotation_stops(` probe
still matches its existing typed definition. Module-presence probes are unchanged.
The maintained assembler recognizes the same `def name(` first line; the
multiline continuation is retained as part of that declaration.

The corrected migration explicitly retains `j_layout_error` and
`annotate_selected`, preserving the existing host without a capability-rule edit.
Independent source inspection confirms **423 conversions, 799 remaining laws**,
and totals **14,857 physical / 12,668 nonblank / 474,656 bytes**. Savings are
830 physical lines, **425 nonblank lines**, and 12,112 bytes; 405 physical lines
are removed blank separators. The earlier 425 candidate, its original tool
version, failed artifact comparison and correction remain evidence. Fresh export
and artifact equality must verify that this fixes the observed omission.

Reviewed corrected migration SHA-256:
`23c542bd0f0e6db77b2b7a66b6eb35e69ab685f3b0d8deecbe1004f940f5d1c9`.

## Genuine self-host launcher: approved to run after corrected cheap gates

Read [checked-selfhost.mjs](checked-selfhost.mjs), SHA-256
`2682ab4684de583b601b840ca566acd6098ae7253b8807c647e6153412ff971b`,
plus the maintained workflow verifier, process supervisor and frozen selfhost
runner. No blocking execution/provenance issue found:

- `verifyAttempt` verifies the checked bootstrap and artifact lineage. The
  initial compiler is explicitly `m.checkedApi`, not the equality derivative or
  a fabricated H sidecar. The source comes from that checked bootstrap record.
- A fresh output directory is required. Ambient `BEND_*` and `NODE_OPTIONS`
  settings are cleared; resume/repeat cannot leak into the maintained runner.
- The unchanged runner executes ordinary source loading, checking, ownership,
  specialization and library emission. Actual stage2 output is the compiler
  invoked for stage3 against the same frozen source. There is no skip-check or
  injected precomputed output.
- The launcher requires stages `[2,3]`, both successful and input-verified, no
  prior/resumed/interrupted attempt, and stage3's compiler hash equal to stage2's
  output hash. It reads and hashes both actual output files and compares bytes.
  Source/API/Base/runtime/runner/driver/helper identities are verified before and
  after by the launcher, verifier and maintained runner.
- CPU affinity is 0; Node stack is 4 MiB and heap ceiling 12 GiB. The maintained
  runner verifies at least 8 MiB OS stack. Each stage has a 40-minute deadline;
  the outer process has 55 minutes and rejects spawn failure, signal, timeout,
  log overflow or nonzero exit. Its supervisor tracks/kills descendant processes.

The cheapest genuine command now uses this reviewed wrapper, once corrected
artifact equality and focused gates pass:

```sh
/home/ai/.nvm/versions/node/v24.18.0/bin/node \
  implementation/phase7/s4-evidence/checked-selfhost.mjs \
  selfhost/build/phase7/s4/attempt-a02 \
  selfhost/build/phase7/s4/checked-selfhost-a02
```

This performs only required stages2/3, using existing checked B1 input; no optional
stage4 or duplicate build is necessary. Keep heavy compiler/archive jobs serial
with it. The earlier Phase 5 proof took about 11 minutes for B1→H and 27 minutes
for H→H under these resources; those historical observations are not a duration
guarantee or speed result for this source.

`tools/selfcheck.mjs` only establishes frontend/kernel acceptance and cannot
replace this gate. `tools/bootstrap.mjs` targets the older `src/compiler.bend`
pipeline and is not the current manifest compiler's proof. A selected API that
is byte-identical to S3 still does not prove it can compile this changed source
into an H compiler which reproduces itself. Root owns the launch, completion
audit, release integration and remaining S4 gates.
