# Phase30: direct generated code

Agent-generated ongoing campaign, started2026-09-30 07:28 UTC. The user requested
at least seven hours of work. This is an in-progress evidence index, not a claim
of a completed optimization or released compiler.

The selected candidate is checked attempt16, following the held14 matrix and
the checked15 runtime repair at[4e5b7fe](https://github.com/rom1504/bend/commit/4e5b7fe). The
[consolidated report](generated-program-performance.md) records its source,
mechanisms and current release status; the [decision table](decisions.md)
separates promoted, deferred and rejected experiments.

It adds owned fresh argument vectors, exact private entry, constant scalar
shifts, lexical scalar regions, terminal records, ordinary roots, a bounded
private scalar tree, reused traversal frames and private-helper Let statements.
**14 was held:** the broader matrix found roughly20–25% regressions on several
generic workloads despite the large scalar gain. The seven-way confirmation
isolated constructor-matcher overhead: delayed application cuts row time26.29%
and recovers Phase29 speed. Checked16 also removes64 implementation lines,
eight functions and the obsolete arm-prebinding module. The distribution API
still contains Phase29; the consolidated default awaits installation and CLI
validation after the remaining16 gates.

The completed16 matrix measures original Mandelbrot at **0.214181 ms versus
Phase29's21.416666 ms: approximately100× faster**. A separate longer-warmup
window leaves **4.59× TypeScript overhead**. The scalar helper at8192 iterations
is192.96× faster than Phase29 and1.34× TypeScript time. These are selected
scalar results: generic programs still cost roughly60–409× TypeScript in the
original short-window matrix, with several warmup-sensitive observations.
The [full timing report](final-timing-16.md) includes regressions and compiler
costs; no combined average or multiplied historical speedup is claimed.

All ten original libraries compile and produce their checked results. Fresh16
also passes the focused, selected upstream, primitive/worker,23-library,
compiler-component and HVM integration scopes. Whole frontend renewal passes
3,026 main and 196 broader exact observations, with the explicit module-layout
migration independently reviewed. Bounded self-emission succeeds and its H
module passes small positive/negative compilation controls. A separate warmed-
once small request puts H5.21× behind the genuine TypeScript-produced parent
for the same Bend compiler source. The81-row backend pilot now matches all
historical observations in the approved native execution environment, keeping
69 passes,8 expected refusals and4 shared failures separate. The final runtime
experiment and installation remain pending; no installed16 release is claimed yet.

- [Actual helper measurements](checked-helper-timing.md)
- [Original-program and compiler-cost integration measurements](final-timing.md)
- [Renewed16 measurements](final-timing-16.md)
- [Renewed frontend observations](frontend-renewal.md)
- [Independent module-layout review](frontend-layout-independent-review.md)
- [Bounded self-emission and its validation scope](bounded-self-emission.md)
- [Warmed generated compiler versus genuine parent](warmed-generated-compiler-cost.md)
- [Renewed selected backend observations and environment boundary](backend-pilot-renewal.md)
- [Checked16 diagrams and exact plotted samples](final16-figures/report.md)
- [Registration-dispatch experiment and controls](registration-dispatch.md)
- [Independent empty-registry transition controls](empty-registry-independent-review.md)
- [Final source review](final-source-review.md)
- [Remaining optimization hypotheses](remaining-hypotheses.md)
- [Independent retirement of arm prebinding](retired-arm-independent-review.md)
- [Held14 comparison figures and exact plotted data](held14-figures/report.md)
- [Generic matcher registration investigation](partial-prebinding-registration.md)
- [Private-helper Let statements in the checked compiler](private-let-compiler.md)
- [Broader Let statements: deferred](general-tail-let-statements.md)
- [Fixed scalar guard lists: below promotion thresholds](scalar-guard-fixed-lists.md)
- [Helper hoisting: no settled gain](hoisted-private-helpers.md)
- [Owned native-call ladder: prototype only](closed-owned-native-calls.md)
- [Preservation scope and prerequisites](evidence/README.md)
- [Compiler implementation and actual terminal controls](terminal-compiler.md)
- [Independent lexical controls](independent-integration-08.md)
- [Independent terminal admission and budget controls](independent-terminal-admission-09.md)
- [Ordinary scalar root experiment](ordinary-scalar-root-regions.md)
- [Runtime method-read experiment](exact-entry-call-read.md)
- [Corrected-runtime constructor-arm retry](exact-constructor-arms-retry.md)
- [Actual ordinary-root compiler and measurements](ordinary-compiler.md)
- [Actual tree compiler and complexity](scalar-tree-compiler.md)
- [Actual tree timings and retained warmup drift](actual-scalar-tree.md)
- [Checked-source tree result and refusal coverage](source-scalar-tree-controls.md)
- [Combined integration gates](final-integration.md)
- [Reusable tree-frame experiment](scalar-tree-frame-reuse.md)
- [Closed owned edit-distance row experiment](closed-owned-row.md)
- [Exact-entry state slots: mixed small benefit, deferred](scalar-exact-entry-state.md)
- [Independent tree admission and shared-header regressions](independent-tree-admission-12.md)
- [Tree prototype and warm-up limits](pure-scalar-tree-region.md)
- [F32 guarded entry: rejected regression](f32-ordinary-root.md)
- [Number-counter retry: small gain, deferred complexity](private-counter-lexical-retry.md)

The checkpoints below retain the order of the investigation; their earlier
pending/rejected states are superseded only where a later report says so.

- [Prospective design](../../design/phase30/direct-generated-code.md)
- [Starting artifacts and protected files](start-state.json)
- [First hypothesis](../../experiments/phase30/P30-001-direct-entry.md)

The baseline is Phase29 at77aecb2; pinned upstream is0187512. Performance,
correctness and promotion outcomes will be reported separately. No PR comments
will be posted as part of this campaign.

- [Paired generated-code inspection](code-comparison.md)
- [Private edit-distance mechanism and retained failure](prototype-findings.md)
- [Fresh argument ownership: first checked implementation](owned-arguments.md)
- [Independent semantic review](semantic-review.md)
- [Prospective scalar-region review](region-semantic-plan.md)

First checkpoint: checkedattempt01passes36focused cases,120fixture points and
22independent emitter/runtime observations. The owned-vector prototype confirms
1.137× on the small Mandelbrot input; a separate private edit-row prototype
confirms1.379× under immutable globals,1.287× with replacement guards. Neither
private prototype covers in-place descriptor mutation. Phase29 remains installed.

The actual owned-vector compiler now independently confirms1.133×. A guarded
closed scalar-region prototype confirms2.679× on original Mandelbrot bench(0,0);
the per-call guarded version regresses53.8%. These are different workload scopes
and must not be multiplied. Exact constructor-arm saturation measured1.023× on
the complete-state edit-row fixture, but is now rejected: an independent test
found it executes arm effects before an enclosing oversaturation boundary.
General scalar-region compilation is in progress. Its corrected entry design
also repairs inherited Phase29 scheduling and mutable-self-binding failures;
attempt03 is retained and must not be promoted.

- [Region experiments and measurements](direct-region-findings.md)
- [General compiler implementation plan](../../design/phase30/scalar-region-compiler.md)
- [Independent private-plan review](region-private-plan-review.md)
- [Native IR reuse audit](native-ir-reuse-audit.md)
- [Five inherited loop counterexamples](nat-loop-scheduling-review.md)
- [Corrected entry contract](../../design/phase30/scalar-region-entry-correction.md)
- [Runtime entry controls and diagnostic limitation](scalar-entry-runtime.md)
- [Array-call experiment: guarded bypass is slower](native-array-calls.md)
- [Numeric counter experiment: defer a marginal gain](private-counter-representation.md)
- [Record loop investigation](record-carrying-nat-loop.md)
- [Bounded bootstrap diagnostics](bootstrap-diagnostic-bound.md)

The literal-shift ablation confirms 4.024× over the same private region on the
small helper point. The rule is now implemented and passes 12,600 scalar
comparisons plus scoped host/order controls. Attempt07 also passes the corrected
region and entry suites. See the [compiler checkpoint](compiler-checkpoint.md)
and [literal-shift report](constant-native-shifts.md). Actual performance and
broader integration remain pending; Phase29 is still installed.

Attempt04's genuine bootstrap followed by recipe-hash rejection remains in the
record. The reviewed diagnostic recipe is now admitted with historical replay
preserved; the failure was not silently replaced by the successful later build.
