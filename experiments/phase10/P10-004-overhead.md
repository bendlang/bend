# P10-004 — Bounded generated-call and allocation overhead

Date: 2026-09-28. Owner: `research_binders_semantics`; integration/review: root.
Prospective plan, before probes. Initial investigation is bounded to roughly
15 minutes; it may end with a falsifier or an explicitly unmeasured proposal.
No production source, distribution, runtime or upstream edits are authorized.

## Question and historical exclusions

Inspect the final Phase9 integrated03 API and fresh profile for one avoidable
source-level cost. The final same-source checking result remains 66.84 s versus
2.94 s TypeScript until root measures another valid comparison. Profile shares
are not additive speedup forecasts or allocation counts.

Do not repeat the guarded saturated/positional-call transforms: historical whole
compilation gains were only 1.03×/1.05×. Do not retry the rejected generic binder
walker, unconditional typed output, or semantic-value replacement. The old
P6-002 Boolean-worker experiment is relevant positive but unpromoted evidence:
roughly 6% less small-core compilation time, five extra helpers, and an unresolved
malformed-host-data H gate. Its B1 result cannot be transferred to today's pin or
self-emitter.

## First discriminator

Current `core_subst_stable` still builds nested `kc` branch closures. Check whether
the current pinned language/emitter accepts a locally computed Boolean matched
directly, a formulation rejected by the old pin. A tiny actually checked Bend
component tests this syntax and forcing/branch behavior before touching compiler
source. If it remains rejected, preserve the rejection and stop that formulation.
Do not add helper workers merely to recreate the old experiment without fresh
profile evidence identifying a meaningful current cost.

If the fresh profile instead identifies a smaller source-visible duplicated
operation, record its exact invariant and smallest counterexample before a
candidate. Generic dispatch, GC and anonymous samples alone do not justify a
runtime change or arbitrary generated-JavaScript patch.

## Gates and scope

- Immutable target: upstream `b2111cf43244e65f76ddc278ee695e669f720cbf` and final
  Phase9 `integrated-03`; capture exact API/source/runtime/Base/tool identities.
- Work only under owned phase10 experiment/report/tool paths and
  `selfhost/build/phase10/overhead-*`; CPU3, absolute Node v24.18.0. Announce any
  compiler launch larger than tiny components and coordinate root's timing slots.
- Tiny components are checked by pinned upstream; they are not B1 or fixed
  points. Preserve failures, compiler output, inputs and emitted helper bodies.
- Preserve condition/branch demand and first error, successful and rejected
  cases, affine usage and deep stack behavior. A source candidate requires an
  isolated checked B1 and relevant existing controls before root integration.
- Time only uninstrumented actual compiled operations with verified outputs and
  fixed identities. Concurrent operation screens remain distinct from exclusive
  whole-compiler comparisons. Root owns final measurement and promotion.

Decision now: investigate. Canonical outcomes:
[overhead report](../../implementation/phase10/overhead.md). No source or speed
improvement is claimed by this plan.

## Profile-directed candidate, before candidate build

The final-release profile (`current-profile-01`, 6,547 samples) places 8.256% and
2.983% exclusive weighted samples in two `index_find` branch closures. This
supports a local index trial; it does not allocate the 12.189% GC, 9.582%
`run_loop`, or 5.379% `run_tail` totals to this function. Local Boolean matching
remains rejected by the current pin; the parameter-match control checks.

Freeze an isolated source candidate which introduces three Boolean-parameter
workers for the existing absent/leaf/hash decisions and matches the existing
`right` parameter directly in `index_child_list`. Every condition is evaluated
at its original demand point. Do not change hash calculation, index construction,
child order, collision bucket order, cache bookkeeping, or any caller ABI.
Compare baseline/candidate real compiled index operations for empty/singleton,
left/right branches, forced full-hash collisions, duplicates/first-win,
replacement persistence, noncanonical kinds, and malformed raw boundaries.
A checked B1 plus maintained public gate is required separately from private
checked component controls. Abort on a demand/error-order divergence; no generic
generated-code transform is authorized.

## Outcome

Completed the isolated bounded trial; see
[the report](../../implementation/phase10/overhead.md) for exact identities and
limitations. Local Boolean matching still fails (retained). The profile-directed
index worker candidate is actually checked, passes the maintained 21 observations
with complete baseline-output preservation, 5,769 persistent-index controls and
21 demand/malformed/deep controls. Eight fresh component workers show successful
complete lookup speedups 1.77–2.21× at 16–4,096 entries. This is a concurrent
component screen, not final whole-compiler timing. Three helpers cost +36 physical
lines/+550 bytes; the generated mutual-tail loop is the inspected mechanism.
Recommendation: root integration gate, not independent promotion. No production
source or distribution edited by the investigator.
