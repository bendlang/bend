# P11-003 — Checker and normalization repeated work

Prospective record, 2026-09-28, before probes. Owner: binder/checker agent;
integration and final measurement: root. Baseline is Phase10 commit `5f561c4`,
checked `integrated-01` equality API
`ff876a357db2d44d3e1fbd37ab694a16d2fa0f47d60c9d500603e634c8c645f9`.
Pinned TypeScript remains `b2111cf43244e65f76ddc278ee695e669f720cbf`.
Initial read-only investigation is bounded to roughly ten minutes; no previous
campaign time budget is renewed. Report: [checker.md](../../implementation/phase11/checker.md).

## Question and historical exclusions

Compare actual pinned `bend.ts` checking/normalization with current Bend modules.
Find avoidable repeated traversals before changing representation. Phase7's full
semantic-value evaluator regressed ordinary data/memory and retained an All-demand
counterexample; its generic binder walker grew source and slowed transformations.
Neither is retried without a distinct discriminator. Phase9 already removed
unconditional lambda-kind checks, repeated successful context lookup and most
whole-book freshness scans; Phase10 already removes index branch trampolines.
Do not relabel those existing changes as new gains.

## Ranked code findings before the fresh profile

1. `compare` first calls `norm_exact`. On false it enters `norm_cmp_loop`, whose
   first `norm_cmp_quick` repeats exactly that comparison for App/Ref/Var inputs.
   Test a direct transition to the existing `norm_cmp_heads` after the same fresh
   bound and weak normalization, only on the known-unequal first pair. This
   removes a proven duplicate exact traversal without modifying later worklist
   pairs, alternatives or equality demand. Cheap falsifier: actual helper-entry
   counts on unequal App inputs, then complete conversion outcomes including
   divergence short circuits, arity mismatches and explicit fresh binders.
2. `check_mat_ctr` independently computes the same `tele_fill` for `mat_lhs` and
   `mat_goal`; upstream `term_check` binds that telescope once. Likewise
   `check_ctor_domain` weak-normalizes the same kind twice for one parameter.
   A local shared value/helper may save work. Count calls before implementing;
   preserve the condition that computation follows successful prior checks.
3. `ctx_dead` and the Efq branch use eager disjunction, while upstream exits on
   the first live empty datatype. This is wasted work, but changing demand could
   affect divergent unsafe context types; test a first-empty context followed by
   a divergent type and distinguish valid public checked programs from raw APIs.
   No broad Boolean rewrite is authorized by this observation.

A separate larger difference is upstream's delayed reconstruction of stuck
reference calls (`lhs.t`) versus eager `norm_apply(t,args)` fallback construction.
Keep this a source finding until actual counts/profile justify the added state.
Do not start a normalization representation redesign in this bounded trial.

## Gates

Fresh root profile determines whether a code finding merits a candidate. Work
only in owned experiment/report/tool paths and isolated `checker-*` build trees;
no production/upstream/dist edits. CPU2 for tiny probes, absolute Node24.18.0,
explicit Base and exact input/tool/API hashes. Announce larger checked builds.

Instrumented helper counts establish operation demand only, never timings or
allocation counts. Any candidate must compile from actual checked Bend source,
pass existing kernel/normalizer and adversarial controls, and preserve complete
public observations before root integration. Selected supplemental components
are not B1 or fixed points. Keep each ablation separate and preserve failures.
Whole-source timing, broad conformance, installation and git belong to root.

## Final disposition

Shared telescope promoted; exact/combined shortcuts deferred. See [checker report](../../implementation/phase11/checker.md).
