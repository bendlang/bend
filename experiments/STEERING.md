# Current compiler experiment strategy

Authorization covers compiler work and pushes to `rom1504/bend` on
`selfhost/bootstrap`. No new PR comments without an explicit request. Phase30
began2026-09-30 07:28:01 UTC with a seven-hour minimum, through14:28:01 UTC.
Finish the concrete release/evidence after that minimum if needed. Preserve the
103 unrelated starting paths in `implementation/phase30/start-state.json`.

## Active Phase30 consolidation

[Design](../design/phase30/direct-generated-code.md),
[report](../implementation/phase30/generated-program-performance.md),
[decisions](../implementation/phase30/decisions.md), and
[release sequence](../design/phase30/consolidated-release.md).
The target remains upstream `018751270e800bc222a93dad7f257083ee53a5f7`, after2.0.34.
Checked16 is selected: API33545640, genuine parent60aa968f, source678bafd6,
runtimefab241ae, Basec742fae9, guarded profile6. Source checkpoint73912c3;
validation checkpoint9d89045. The default distribution API still contains29 while
development source/runtime are16: do not claim a verified consolidated default
before installation and CLI checks.

The emitter now supports fresh argument ownership, private lexical scalar
regions, constant native shifts, flat terminal records, nested countdowns,
ordinary scalar roots containing loops, bounded two-child scalar trees, reused
frames and private-helper Let statements. Unsupported shapes retain generic
execution. Entry permission is single-use; guards retain live descriptor and
public callback semantics. Five inherited Nat-loop scheduling/self-binding
counterexamples are repaired. No second public value representation is added.

Held14 is not released. Its full original-program matrix found roughly20–25%
generic regressions despite a97× Mandelbrot gain. Seven isolated row variants
attribute that regression to constructor-arm prebinding, not a proven V8-specific
allocation/inlining cause. The winning delayed matcher restores generic speed;
fused wrappers/ordinary-dispatch changes do not. Checked16 then deletes64
implementation lines, eight functions and the obsolete arm-prebinding module.
The cleanup has no independently established incremental speed gain.

Actual16 small confirmation: complete row0.444585ms, overlapping29/15 ranges;
scalar1280.006975ms,56.83× faster than29 and4.096× TypeScript. Final ten-program,
ordinary-check, library-generation and scaling comparisons are running in one
exclusive slot. Original Mandelbrot so far is0.214181ms versus29's21.416666ms
and TypeScript's0.045452ms, about100× improvement and4.71× residual overhead.
Edit distance recovers29 speed but remains408.69× TypeScript. Do not extrapolate
these selected cases or multiply historical incremental factors.

Canonical Bend source:16,778 physical /14,327 nonblank lines,65 modules,
1,844 definitions,640 laws,70 types. Net571 lines (+3.52%),82 definitions and
two analysis records above29. Maintained runtime core233 lines, up66. This is
a performance phase with a modest source increase, not a50% simplification.

## Current correctness and self-emission scopes

Fresh16 frontend:3026/3026 main and196/196 broader exact observations, with an
independently audited five-module layout migration. Original strict manifest
failure retained. Main raw2525 pass/497 observed/4 shared fail; broader195/1.
Shared failures expect later emission errors and are not rewritten as passes.

Fresh selected gates pass36 focused observations,15 upstream JS cases,
23 libraries/127 points, ten original library outputs,22 compiler components
and full HVM output. Primitive/worker/entry/tree/terminal/alias controls are linked
from the report; their overlapping counts are not unique conformance totals.

Backend pilot has attempted all81 rows.64 match complete historical outcomes;
17 native rows report the same Clang EPERM on both paths. Retained binaries show
this may be the environment's pipe-capture issue; raw spawn status is unavailable.
Keep failures and retry native only under an explicitly recorded environment
change after timing. Historical81 itself means69 paired passes,8 paired
unprintable-main not-applicable outcomes and4 shared check failures, not81 passes.
The811 further JS rows are new coverage, not historically executed observations.

B1 emits H in30.841 seconds in one bounded acquisition; H builds its own actual-
hash Base cache and matches positive/negative small compilation, exact emitted
bytes and result8. Acquisition overlapped correctness work: no historical speed
ratio. H is not installed; no H-to-H or full H-conformance claim. The separate
warmed-once H versus genuine TS-produced parent request comparison is prepared;
this is not comparison with the hand-written upstream TypeScript compiler.

## Next decisions

1. Close final clean timings before further execution, profiles, plots or
   compression. Only root grants the measurement slot. Report every original
   workload, sample ranges/drift and compiler costs separately.
2. Resolve native host-process evidence, install the exact16 attempt, verify
   its manifest and run42 ordinary/relocated CLI checks. Preserve29 in release
   history. Optional811 new JS coverage needs its own explicit raw-outcome policy.
3. Close all producers, verify protected paths, capture and independently reopen
   the Phase30 capsule, update documentation/figures and push. Preserve unsuccessful
   attempts; hashes alone and ignored files are not durable evidence.
4. For the next optimization, isolate generic setup and record administration in
   the retained closed-array row. That prototype still costs40.6× TypeScript;
   its general locality/delayed-demand proof is unfinished. Tiny F32 roots and
   per-call guards already lost. See the [remaining hypotheses](../implementation/phase30/remaining-hypotheses.md).
5. Keep two cheap canaries in every runtime screen: scalar work and a complete
   generic row. Build only surviving rules, then run broad transfer once stable.
   Checked builds plus36 focused checks took35–40 seconds, fixture emission~5s;
   these acquisition durations are not compiler-throughput comparisons.

## Operating boundaries

Read `experiments/README.md`. Freeze mechanisms, identities and limits before
probes. Keep genuine checked B1, guarded derivative and generated H distinct.
Bend `&&` is eager: use explicit `kc` fences before bounded recursive analysis.
Preserve argument-demand ordering, parallel-Let scope, escaped aliases and
native identities. Unsupported shapes fall back rather than weaken semantics.

Independent BendTT `--verdict`, GPU/device execution and package fetching remain
unsupported or unvalidated. Frontend agreement and finite backend controls are
not proof-kernel validation or universal equivalence. Native/device speed and
full compiler throughput are not inferred from emitted scalar helper speed.
Historical source reductions, fixed points and speed ratios apply only to their
recorded artifacts and protocols. No PR publication beyond the authorized fork
push is part of this campaign.
