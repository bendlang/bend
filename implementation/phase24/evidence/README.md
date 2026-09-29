# Phase24 evidence

The capsule captures closed `selfhost/build/phase24`, Phase24 tools and focused
fixtures, including unsuccessful profiles/builds and failed controls. `manifest.json`
records every included byte, mode and path; `external-exclusions.json` names only
the six external Bun/Clang-runtime files whose official URLs, hashes and recovery
recipes are in the [environment report](../backend-environment.md). All environment
logs, sanitizer control sources, emitted-program executions and results are retained.
Backend batch archives remain in the outer capsule with their verified inventories.

Create the capsule only after producers stop:

```sh
python3 implementation/phase24/evidence/package.py
python3 implementation/phase24/evidence/recover.py implementation/phase24/evidence /tmp/phase24-independent-recovery-01 implementation/phase24/evidence/recovery-01.json --original-root "$PWD"
```

Recovery audits membership, bytes, file types and modes against both the manifest
and original included producers. It does not rerun experiments or silently install
toolchains. The recovery receipt records its exact scope separately.

## External experiment prerequisites

Existing Phase23 frozen inputs are deliberately reused through the durable
[Phase23 capsule](../../phase23/evidence/README.md), its exact prerequisite closure
and production commit `ab246cdd24e7695a14d3b725d5323b95c5f5892b` (reported in
Phase23). Restore it and its named historical capsules before replaying paths.
In particular Phase24 consumes the released `phase23/combined-build-03` attempt,
its frozen source/runtime/host/validated Base cache, the Phase21 `fac06128` workload,
the full main/broader Phase23 reference reports and retained Phase12 histories.
The earlier capsule's closure receipts identify how those older bytes are retained;
Phase24 does not replace them with current checkout files.

Upstream018751270e800bc222a93dad7f257083ee53a5f7, Node24.18.0 and the retained
Clang16 environment remain pinned external prerequisites. The new Bun1.2.22 CPU
baseline and Clang16 TSan package are additional external dependencies only for
environment probes. Exact paths, arguments, executable/input identities, resources,
order, complete observations and all attempts are recorded in each run report.
Absolute original paths are historical provenance; restoring an archive elsewhere
does not relabel them as new observations. Use a checkout at the final Phase24
commit plus these recovered dependencies to reproduce the experiments in new
output directories. The installed release itself needs neither the experiment
capsules nor Bun/TSan for ordinary Node compilation.

## Interpretation

CPU/allocation reports are instrumented diagnostics, with discovery/Base already
warmed. Allocation sampling includes profiler/report overhead before stopSampling.
Only `cost-01` and `cost-02` are controlled serial timing screens, with other compiler/test/profiler
workers paused, exact same-workload observations and individually validated
bundles. No generated-program speed claim follows from checking timings.
The broad frontend reference reuse is explicit and identity-checked; candidate
observations and paired request histories are newly acquired. TCP/TSan environment
runs use unchanged saved Phase23 emissions, distinct from fresh Phase24 backend
emissions. The main report and backend report enumerate the tested scope.


The [installed-cache supplement](cache-supplement-01/README.md) captures the current
API7b523/dist-Base cache produced and used by installed CLI smoke tests outside the
primary producer roots. Its independent [recovery receipt](cache-supplement-recovery-01.json)
verifies current bytes/mode/membership. The original smoke report did not hash
that individual cache file, so this is explicitly a post-run produced-cache
capture, not a retroactive claim that the original observation recorded its hash.

The independent [preservation review](preservation-review-01.json) verifies both
recoveries, the six exclusions and the recovery routes for 4,187 external input
identities. Its bounded review found no unresolved experimental payload; the two
remaining design inputs are included in the final Phase24 commit. This does not
claim a hermetic environment or replace compiler validation.
