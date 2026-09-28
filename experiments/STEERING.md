# Current compiler experiment strategy

Phase14 is complete under its [design](../design/phase14/conformance_and_dispatch.md).
The [report](../implementation/phase14/conformance_and_dispatch.md) selects
combined-01, API9136be92, with unchanged upstream b2111cf. Imported-law resolution,
checker caret rendering and source normalizer dispatch are installed. No earlier
multi-hour budget is renewed. All unrelated Phase6 work remains untouched.

## Released Phase14 frontier

Same-final-source checking is **27.40→24.98s**, **8.82% less time** than Phase12.
Pinned TypeScript is **2.81s**, leaving an **8.88×** process gap (old release9.74×
in this same matrix). Each variant has two serial fresh-process samples, CPU0,
4MiB stack/4GiB heap; intentional competing compiler/archive jobs were closed.
The comparison binds exactly two trust-report host edits and unchanged remaining
hosts/Base/runtime. The identical-host dispatch pilot separately saves9.03%.
Do not multiply these ratios or combine them with older different-source samples.
Peak observed RSS rises1.47%; no memory or user-program runtime gain is claimed.

All2,996frontend observations finish with all1,001positive accepts,482negative
refusals and11exact intended trust refusals. Exact differences fall730→603
(194parse/409check,409unique fixtures), with127new matches and zero lost matches.
Strict checks are1,085pass/413fail. Twenty-six further checker observations add
carets but retain old gaps; two alias-declaration observations restore parser
refusal while retaining diagnostic differences. No unexpected semantic delta,
invalid acceptance, timeout or missing observation is observed.

The final compiler passes26maintained focused cases,41paired backend rows
(three known exact differences),16unchanged helper groups,five authentic byte
replays, and42ordinary/relocated CLI checks. The imported-law program returns5n
through interpretation, JS and actual native execution. A fresh long string and
both exact53/60request histories pass for conformance-only versus combined,
all226paired observations and predecessors exact at the original resource limits.
The first full audit's null/undefined postprocessing failure is preserved; a
strict identity-bound audit reuses its healthy vector without rerunning fixtures.

Source is15,264physical/13,038nonblank Bend lines,501,056bytes across59modules,
1,495defs/793laws/63types: +134lines,+4,670bytes,+11defs. Imported law loading adds
two temporary markers removed before checker entry. Six dispatch workers replace
intermediate choices; three renderer helpers use existing spans. The maintained
JS helper/runtime are unchanged; two host arguments add14bytes and focused tests
addfourcases. Research launchers and evidence are counted separately. Historical
50%/75%simplification targets remain open.

## Next priorities

1. Classify the remaining603exact differences and select another shared cause with
   cheap paired witnesses. Parser messages and originating spans remain separate
   from the corrected checker renderer. The71/78selected renderer family still
   fails for seven inherited spans; do not claim they are fixed.
2. Profile this exact installed release before another speed round. Source branch
   workers avoid allocation/dispatch without additional JS rewriting, but the
   normalizer chain is not a mutually recursive loop. Require demand/order controls
   and exact saved histories before broadening this technique.
3. Reuse the Phase13 selector prototype only for a substantially larger measured
   opportunity or a cheaper implementation. Do not revive rejected seed cleanup
   or broader branch inlining without addressing their saved counterexamples.

The full acceptance corpus has no observed positive rejection or invalid negative
acceptance, but rejection reason/phase and exact diagnostics still differ. Backend,
proof-kernel and GPU coverage remain separate. There is no new self-hosted fixed
point or universal stack-safety/compiler-soundness claim.

## Retained experiments and operating rules

[Phase13](../implementation/phase13/structured_rewriter.md) remains deferred:
named-worker lifting is1.01%slower; six-owner selector fusion saves10.56%but adds
239helperlines/7,010bytes. Phase14's smaller source change was accepted because
it avoids that maintained JS machinery. The original profiles, controls and
prototype remain preserved.

[Phase12](../implementation/phase12/avoidable_work.md) retains typed constructor
lookup/literal reuse and guarded version5 literal-choice/leaf-branch lowering.
It rejects seed cleanup and broader inlining despite passing finite controls:
matched histories overflow with those candidates while their baseline passes.
The initial Absent fallback allocation remains. Delayed normalizer reconstruction
stays deferred for weak benefit and added protocol cost.

A different history (the old21focused cases before the string) can overflow even
Phase11. The maintained selection keeps the string first. Do not use inherited
failure under one history to excuse changed results under another. Preserve
actual request order and resource policy; finite controls are not universal safety.

[Phase11](../implementation/phase11/known_work.md),
[Phase10](../implementation/phase10/repeated_work.md),
[Phase9](../implementation/phase9/checker_speed.md) and
[Phase8](../implementation/phase8/upstream_and_conformance.md) retain their own
artifact-specific measurements and gates. S4 simplifications and older genuine
fixed points remain in the [Phase7 report](../implementation/phase7/s4-report.md).

Routine edits use [checked B1 development](../docs/PHASE5_DEVELOPMENT.md). Keep
checked B1, guarded derivative and self-emitted H distinct. Unknown profiles,
bindings or identities fail closed. Freeze plans before probes; put outcomes in
reports/ledger. Preserve failures and superseded consumed tools. Close all producers
before evidence capture; verify every restored byte/mode. Capture completion is
not a correctness pass. Check errors, signals, timeouts and overflow alongside
exit status and semantic oracles. Archive/recovery and toolchains are documented
in the [Phase14 evidence](../implementation/phase14/evidence/README.md).
