# Phase34 current frontier

User authorization covers compiler research, experiments, implementation,
design/report and commit/push to `rom1504/bend`, branch `selfhost/bootstrap`.
No PR comments without an explicit request. Prior timed campaigns are historical.
The 103 unrelated starting files remain unchanged and unstaged; preserve them.

## Current generated-program loop

The user requested current results, opportunities and automatic program profiles
plus generated-source comparison. [Phase34 design](../design/phase34/program-diagnostics.md),
[report](../implementation/phase34/README.md) and
[ranked opportunities](../implementation/phase34/opportunities.md) complete that task.
The installed compiler is unchanged: this is tooling, not a claimed optimization.

Use the [maintained suite](../selfhost/tools/performance/programs/README.md):
20 / 60 / 300 / 600-second timing ceilings with independent sets or explicit cases.
Prepare checked candidates separately; frozen references run from a normal clone.
Add `--diagnostics all --diagnostic-budget 60` for a separate instrumented phase,
or use `diagnose.py --from-run DIR` without repeating timing. The
[guide](../selfhost/tools/performance/programs/DIAGNOSTICS.md) covers CPU/allocation
profiles, AST counts, source ownership and standalone side-by-side HTML.

Current clean fifteen-point timings remain the [Phase33 full run](../implementation/phase33/measurements/600s.md):
edit distance 3.05×, Mandelbrot 4.16×, tree sort 71.21×, lexer 91.13×, symreg 89.33×,
raytrace 261.17× pinned TypeScript. Local pair/fold are 3.06×/5.94×; long scalar
region is 1.40×. This fixed-input corpus is not a production average. Keep compiler
throughput, output execution and conformance separate. Same-compiler noise is
visible, and historical medians must not become fresh comparison denominators.

Fast diagnostics complete 30/30 profiles in 17.98s; full 60/60 in 244.88s. `apply`
receives 49.81% raytrace CPU self weight versus 2.26% GC; runtime machinery is hot,
but sampled attribution is not a causal decomposition. Four sphere selectors
account for 29.92% of fine-profile raytrace sampled allocation. Private pair
`cell.f4` accounts for 65.40% of its longer-window allocation estimate and still
returns a four-slot vector every cell. Fold carries a similar two-slot vector.

Fine raytrace allocation capture peaked at 1,221 MiB. Maintained diagnostics use
256 KiB allocation sampling for both raytrace roles, 32 KiB elsewhere; the focused
control peaks at 541.6 MiB and retains consistent hotspots. Preserve both runs.
V8 samples absent from their tree remain explicitly unattributed; tree/sample
estimates are never added together. All 28 Python, 15 AST and 13 profile scenarios
plus aggregation/preservation controls pass. Raw failures, exact modules and
producers are retained in the [Phase34 capsule](../implementation/phase34/evidence/README.md).

## Ranked next experiments

1. Cheap discriminator: scalar-replace private pair/fold loop-carried vectors,
   preserving write order, aliasing, swaps and complete state. Reuse the existing
   closed-region proof. Test saved-output ablations before another checked build.
2. Broader transfer: direct saturated regions through complete matches/argument
   chains in `nearest.t`, short lexer state transitions and scalar `colf` traversal.
   Keep representation/arithmetic fixed first; guard substantial work once.
3. Small raytrace discriminator: finite Nat-to-F32 selector tables. Check all
   branches/defaults, large Nat, exact F32 constants and live helper dependencies.
4. Larger extension: private tree traversal and construction/matching elimination
   for symreg/tree sort. Require ownership, evaluation and stack-order controls.

Do not promise gains from the 71–261× deficits. Tiny per-call guarded F32 roots
previously regressed 2.87×/6.99×; public descriptor/getter mutation is observable.
Native Nat countdowns previously improved only 1.057×; byte reduction and fewer
syntax sites alone did not establish a gain. Start with a falsifiable mechanism,
clean same-case timing and semantic boundary controls, then widen program transfer.

## Installed compiler and accepted costs

Target remains upstream `0187512`, after Bend 2.0.34. Phase32 checked03 is installed
and release verification passes. All 14 pre-install gate groups pass, 223 canonical
source identities match and all 42 ordinary/relocated CLI controls pass.
[Release](../implementation/phase32/release-03.md),
[design/admission](../design/phase32/admission.md),
[full report](../implementation/phase32/README.md).

API `8be506d8…`, checked parent `c3cc54c1…`, assembled source `e3cc4424…`,
runtime `4121f338…`, Base `c742fae9…`. The selected API is a maintained guarded
version 6 derivative of its checked parent, not a new self-emitted H fixed point.
Its statement unpacking, typed read bridges and private record/Sigma vectors
retain producer-time reads, ordered fields and initial zero rebinding. Public
terminal-record results stay boxed. The compiler remains 17,071 physical /
14,580 nonblank Bend lines, 1,884 definitions, 640 laws, 70 types and 66 modules.
Phase32 accepted +57 physical lines and a 1.91% Mandelbrot compilation cost;
no compiler-throughput or line-reduction improvement is claimed in Phase34.

Phase32 gates retain 3,026 main + 196 broader frontend observations; backend81
has 69 pass / 8 N/A / 4 shared failures. Primitive/worker/library/component/HVM
scopes and the preserved interrupted/EPERM attempts are documented in the
[gate closure](../implementation/phase32/final-conformance/gates.md).
No full backend, GPU or proof-kernel conformance claim follows from these tests.
Private checker fields, whole-world checkpoints, compact memoization and mutable
stop-list reuse remain rejected/deferred as described in the Phase32 report.

## Resource and evidence discipline

Only root runs heavy work. Use one worker, explicit Node heaps, the shared
execution lock, process-tree RSS/deadline supervision and 2 GiB available-memory
floor. Checked builds take about 40 seconds with a 1 GiB heap. Polling can overshoot
limits; counters do not establish the cause of prior session interruptions.
Do not repeat completed gates after restart or benchmark while archiving.

Keep exact staged paths separate from protected files. Historical evidence
capsules retain failed/superseded attempts and frozen producers. Keep compiler
source, generated compiler images, output prototypes and measurements distinct.
For compiler-throughput work, first establish an actually private source-only
worker boundary; public defaults are mutable. Broad semantic gates follow a
surviving compiler change, not diagnostic counts alone.
