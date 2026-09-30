# Phase30: direct generated code

Agent-generated ongoing campaign, started2026-09-30 07:28 UTC. The user requested
at least seven hours of work. This is an in-progress evidence index, not a claim
of a completed optimization or released compiler.

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
