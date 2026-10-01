# P34-001 — Diagnose generated-program cost alongside clean timing

- User objective: state current execution results, identify the best opportunities,
  and make the maintained loop produce profiles and generated-source comparisons.
- Owner: root; independent implementation/review: diagnostic_static,
  diagnostic_profiles and diagnostic_findings. Only root runs processes.
- Scope: diagnostics and evidence. Installed Phase32 checked03 is unchanged.
- [Design](../../design/phase34/program-diagnostics.md),
  [report](../../implementation/phase34/README.md),
  [current results and opportunities](../../implementation/phase34/opportunities.md),
  [maintained commands](../../selfhost/tools/performance/programs/DIAGNOSTICS.md).

## Claim and falsification

Separate CPU/allocation capture and true AST comparison of exactly the timed
modules can identify mechanisms worth testing within the existing bounded loop.
It must not contaminate ordinary timing, silently omit requested coverage, execute
code during static inspection, invent missing source mappings, or discard failed
observations. A profile hotspot is not a causal performance improvement.

## Method and disposition

Retain Phase33 unprofiled speed comparisons because the compiler is unchanged.
Add explicitly budgeted fresh serial profile workers, exact result checks,
raw V8 files, function-origin attribution and source-owned AST inventories.
Use both the frozen two-role corpus and exact prior three-role timing modules.
Keep profiler and timing status separate, with immutable timing snapshots.

All 30 fast and 60 full profiles complete in 17.98 and 244.88 seconds. The first
fast attempt exposed a V8 sample absent from its tree: preserve the failure,
account explicitly for unattributed bytes, and add the exact regression control.
Analyzer export mapping also failed an initial control; retain its failure and
correct runtime/program boundaries before retrying. All documented controls pass.

Fine raytrace allocation capture peaked at 1,221 MiB. An explicit 256 KiB interval
for both compiler roles, versus 32 KiB elsewhere, reduced the focused capture's
observed peak to 541.6 MiB while retaining consistent hotspots. This is a profiler
cost improvement, not faster generated code. Old fine captures remain immutable.

Current profiles support private loop-state scalar replacement as a cheap next
experiment, and larger saturated regions / finite Nat selector lowering as the
broader transfer opportunity. Raytrace's roughly 50% `apply` self weight and
2.3% GC weight do not prove which instructions explain the 261× clean timing gap.
Guard boundaries, demand order and public mutation witnesses constrain proposals.
No compiler rewrite or optimization is promoted from this diagnostic evidence.
