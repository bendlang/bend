# Phase35: remove representation and dispatch work measured by Phase34

Baseline is the installed Phase32 checked03 compiler at repository `573284a`.
Target and input corpus stay pinned. The user authorizes aggressive generated
program optimization, primary literature/GitHub research, implementation,
documentation and commit/push. No PR comment is authorized. The 103 unrelated
files remain protected. Only root runs compiler, profile and benchmark processes.

## Prospective experiments

1. **Private state scalar replacement.** The pair/fold profiles locate allocation
   in loop-carried record vectors. Inline or fuse their immediate private producer
   and consumer, then carry separate fields. Preserve evaluation/write order,
   aliases, zero cases and public boxed results. Begin with saved-output ablations;
   surviving rules must be structural, bounded and implemented in Bend.
2. **Finite Nat decisions.** Raytrace's small selectors spend repeated work in
   native Zero/Succ matchers. Test a bounded decision lowering with selected leaves
   evaluated at their original demand point. Public prototype hooks and live
   descriptor dependencies constrain standalone lowering. Prefer amortization
   inside an already guarded region if per-call guards defeat the gain.
3. **F32 and conditional loop tails.** Existing private scalar admission excludes
   F32; its kept loop prefix also excludes residual Bool matches. Extend the
   existing typed proof and statement emitter, preserving F32 rounding, exact
   saturation, public partial/error order, descriptor mutation and tail-stack
   behavior. Start with complete nearest-distance folds, then original raytrace.
4. **Wider transfer.** Use profiles and current syntax to assess lexer/symreg/tree
   match work. Do not introduce an unbounded rewrite or a second compiler merely
   to fit the fixed corpus. A missing proof or a failed ablation remains a reported
   result. Keep useful general rules small and reuse current analyses.

The [literature review](literature.md) will connect primary research to concrete
proof boundaries. Published compiler performance is motivation, not an estimate
of gains in this implementation. Numerical gains require current measurements.

## Measurement and promotion

Use the committed Phase33 reference and Phase34 diagnostics. Every speed ratio
comes from the same fresh unprofiled run, with unchanged catalog points and exact
outputs. A manual JavaScript prototype remains unchecked until compiler source
implements the rule and a genuine checked B1 emits the result. Profiles run
separately from timing; preserve allocation estimates, raw files and limitations.

Use20/60-second exact-case screens first. Confirm a selected improvement with
300-second depth and transfer to originals before a full15-point600-second run.
Aim for at least5% improvement with disjoint observed ranges; any disjoint
regression over3% requires explicit investigation and an admission decision.
Retain all attempts, bad outputs, exhausted budgets, warming/drift and rejected
changes. Never silently lower inputs or compare against historical medians.

Build frozen checked attempts serially with1GiB heaps, a supervised process-tree
RSS ceiling and2GiB available-memory floor. Use existing focused semantic gates
plus independent full-state, effect/alias, F32, mutation and stack controls specific
to the changed boundary. Broader frontend/backend/release checks follow only a
candidate that survives the short loop. Source and generated-code size, complexity
and compilation costs accompany performance admission. Faster than pinned
TypeScript is an aspiration, not a stopping rule or a promised result.

Write per-hypothesis records and a comprehensive implementation report, preserve
evidence, update the maintained compiler guide/frontier, and commit/push the
reviewed result. Ordinary installed use must remain one usable checked version.
