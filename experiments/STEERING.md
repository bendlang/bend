# Current compiler experiment strategy

Current authorization (2026-09-28): try another round of avoiding known redundant
work. [Phase12 design](../design/phase12/avoidable_work.md) starts from Phase11
`f8244c9`. No historical time budget is renewed. Preserve unrelated Phase6 work.

## Phase12 investigation

Root first verifies and profiles the actual Phase11 release on CPU0. Parallel
owners initially inspect normalizer fallback, residual generated choices/calls,
and reused checked/literal structure without compiler jobs. Prospective plans
precede probes and stay unchanged; outcomes go in reports and this frontier.
Use bounded counts/counterexamples and actual checked isolated candidates before
integration. [Canonical report](../implementation/phase12/avoidable_work.md).

No Phase12 gain, semantic fix or release is claimed yet. The1.2–1.5× estimate is
only a planning hypothesis. Avoid broad compact-string or semantic-value changes
unless current evidence justifies their validation and complexity cost. Root owns
integration, controlled timings, preservation, release and commit/push.

## Phase11 release frontier

The [report](../implementation/phase11/known_work.md) integrates lazy offload
lookup, one shared constructor telescope, bounded native open-Succ compaction
and guarded literal-choice lowering in the checked B1 derivative.
Upstream remains b2111cf; selected API is
`63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f`.
The `equality` profile now selects version4, with exact v1/v2/v3 replay.

Controlled full-source checking is **29.73 s**, versus **51.44 s** Phase10 and
**2.79 s** pinned TypeScript: **1.73× faster**, with a **10.67×** process gap.
The same-source six-process matrix excludes emission; maximum RSS falls modestly.
Nat300 JS is **24.45→15.61 s (1.57×)** with identical generated JS.
Native C emission is **27.03→3.61 s (7.49×)**, and C shrinks **98.69%** to269KB.
That exact C builds with Clang16 and returns306n; emission timings exclude Clang.
All matrices pause intentional competing compiler/archive jobs and retain failures.

All1,001 positive frontend fixtures check; all482 validation negatives reject.
The former long-string stack overflow passes at the same4MiB stack, reproduced
by choice lowering alone with unchanged Bend source. This is not compact strings.
Other2,995 observations match Phase10. There are730 exact TS differences
(198parse/532check); four imported-law trust cases still fail early.
No invalid acceptances/timeouts were observed;37paired backend rows pass.

Source is15,138physical/12,923nonblank Bend lines, +31/+28 overPhase10; two helpers,
one law and two private native tags are added. Simplification50%/75% goals remain
open. No new self-hosted fixed point, proof-kernel/GPU gate or general runtime
speedup is claimed. The checked/focused development observation is23.54s.

Duplicate exact-comparison work is deferred for inconsistent benefit; delayed
normalizer fallback remains unimplemented. New speed work should first profile
this final artifact. Imported-law fills and exact diagnostics are the next
semantic priorities. Keep checked B1, derivatives and self-emitted artifacts
distinct. Invalid call microtimings with EPERM remain excluded.

## Historical evidence and constraints

[Phase10](../implementation/phase10/repeated_work.md) preserves loader/index/layout
improvements and its own different-source performance baseline. [Phase9](../implementation/phase9/checker_speed.md)
records earlier checking/Nat changes. [Phase8](../implementation/phase8/upstream_and_conformance.md)
records the upstream migration. Never multiply different-source speed ratios.

S4's validated simplifications and genuine older fixed points remain in the
[Phase7 report](../implementation/phase7/s4-report.md). The rejected generic binder,
unconditional checked-output and semantic-value trials remain in the
[architecture report](../implementation/phase7/architecture-report.md); investigate
new discriminating evidence before reconsidering them. The50%/75% source-reduction
goals remain open, and archive/tool lines are distinct from compiler source counts.

Routine edits use [checked B1 development](../docs/PHASE5_DEVELOPMENT.md), not a
full self-reproduction. Unknown generated shapes and changed input identities
must fail closed. Keep checked B1, guarded derivative, self-emitted H, native
compiler host and emitted user code distinct. Complete observation coverage can
retain strict conformance failures; do not turn capture completion into a pass.

CPU0 belongs to root profiling/final comparisons; isolated tiny development
probes may use CPU1/2/3 after root releases the slot. Pause all intentional
compiler/archive jobs for controlled comparisons. Use existing Node24.18.0 and
record Clang availability before native gates. Preserve errors, timeouts,
counterexamples, invalid timings and superseded tools with exact identities.
