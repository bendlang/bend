# Current compiler experiment strategy

The [Phase23 compiler](../implementation/phase23/upstream-graph-conversion.md)
is installed at upstream018751270e800bc222a93dad7f257083ee53a5f7, after2.0.34.
User authorization covers this migration, continued conformance/speed/simplicity
work and pushes to rom1504/bend selfhost/bootstrap. The earlier publication
block was resolved by verifying the authenticated fork owner's push rights;
Phase22 was pushed before this migration. No old multi-hour budget is renewed.
Preserve the103 unrelated paths in the Phase23 starting inventory.

## Released frontier

Installed API5596f914, genuine checked parent5f539f81, guarded profile6.
One contextual frontend and loadABI2 remain. Conversion now shares the existing
graph evaluator with strong normalization: rigid comparison before unfolding,
fresh heap per policy, and sharing only after EQ obligations succeed. LE success never
merges cells. No global equality cache, extra graph representation or new datatype.
There is no TypeScript fallback in ordinary compilation.

Full new-target frontend3026/3026 and broader196/196 are exact on the installed
image, with stable identities and no worker failures. Raw main statuses remain
2525pass/497observed/4fail; the four expect later-emission errors. Final histories
226paired+2fresh are exact without a diagnostic exception. Maintained36,
installed/relocatedCLI42 and harness114 pass; overlapping counts are not additive.
The report distinguishes candidate01 integration198 evidence from final-image
acquisitions and explicitly verified reference reuse.

New backend24 candidate verdicts pass;22 pairs are exact and2 JS TCP reference
executions require unavailable bun:ffi under Node. Retained array18 are exact;
100 native repetitions pass at1/2/3/4workers. All nine atomic operations use
existing uniform array slots and reference counting; clone keeps the original first.
Foreign scanner4116 and JS TCP16 controls pass. Sanitizer attempts could not run
with the available compiler/runtime combination; no race-detector pass follows.
Concurrent structural reads during atomic mutation and GPU hardware remain open.

Exclusive TS/old/refreshed/final/final/refreshed/old/TS: final11.0135s,
old10.9708s, refreshed10.9199s, TS3.5518s. Final is3.1008×TS, process+0.39%
and request+0.52% against the release. Peak RSS+7.52% against old,−0.80% against
refreshed. Two samples/image: near-neutral ordinary cost, not a statistical bound
or generated-code speedup. All ordinary observations agree. Two depth32 CLI
checks that formerly OOMed at1GiB now pass in1.36/1.41s under that cap; these are
bounded concurrent correctness observations, not comparable successful timings
of the old compiler.

Canonical source:15,748physical/13,442nonblank,586,637bytes,60modules,
1,700definitions/640laws/68types. AgainstPhase22:+148physical(+0.95%),
+137nonblank,+6,173bytes,+9defs,+2laws, unchangedmodules/types. Functionality grew
modestly; this phase does not claim a line reduction or the historical50%/75% goal.

## Next priorities

1. Preserve this usable release and all failed attempts with exact recovery.
   Commit/push explicit owned paths; local commits alone are not publication.
2. Profile the final ordinary checker before the next speed change. The repeated
   shared-term conversion defect is fixed; the remaining3.10× ratio comes from
   a different ordinary workload. Separate process, request and generated-code
   cost. Use the same inputs, host/cache policy, resources and serial order.
3. Challenge exact frontend agreement with independent generated/metamorphic
   programs and richer import/scope/error boundaries. Universal equivalence,
   independent kernel validity, GPU/device coverage and a new fixed point remain
   open. Do not weaken frozen oracles or relabel environment failures as matches.
4. Keep one frontend and the existing representations. Prefer deleting a
   duplicated responsibility over compressing lines. Phase23 checked bootstrap,
   Base and36 focused gates occupied about31s of their observed runs; reuse
   checked artifacts for fixture-only edits and reserve broad gates for integration.

## Retained experiments and operating rules

[Phase22](../implementation/phase22/contextual-conformance.md) retires old raw
parser/later-scope replay routes and closes measured frontend gaps. Phase23 keeps
its source-prefix safeguards and contextual first-error behavior.
[Phase13](../implementation/phase13/structured_rewriter.md) worker lifting remains
slower; selector fusion remains deferred because its extra helpers trade off
simplicity. [Phase12](../implementation/phase12/avoidable_work.md) preserves the
failed seed/inlining stack controls. Profile6 changes guarded compatibility,
not the retained transformation algorithm; versions1–5 replay exactly.

Use [checked B1 development](../docs/PHASE5_DEVELOPMENT.md). Keep checked B1,
guarded derivatives and self-emitted H distinct. Freeze plans before probes;
put outcomes in reports and ledger entries. Unknown profiles/identities fail
closed. Retain request order, complete results, resource limits, failures and
identities. A historical failure cannot excuse a newly changed result.

Phase23 also restores maintained harness/component fixtures to current public
and internal contracts; retired fixture files remain historical evidence.
No new self-hosted fixed point, proof-kernel or GPU conformance is claimed.
Capture closed producers and exact external prerequisites; independently recover
archived bytes before treating an ignored build tree as durably preserved.
