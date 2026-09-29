# Current compiler experiment strategy

Phase16's [consolidated compiler](../implementation/phase16/consolidation.md) is
installed under the [frozen integration plan](../design/phase16/compact-final-gates.md).
The user authorizes continued conformance, speed and simplicity work, including
pushes; publication is currently blocked by an earlier automatic approval review.
No older multi-hour budget is renewed. Preserve all 75 unrelated Phase6 files.

## Released frontier

Installed API `35044ae6`, genuine checked parent `83113283`, unchanged upstream
`b2111cf`. The maintained version5 derivative and runtime are unchanged. Compact
literals, explicit lambda quantity presence, canonical specialization keys,
precise source ranges and contextual module parsing are installed together.

The final exclusive identical-source matrix measures **30.5837→12.3570 s**,
**2.475× faster /59.60% less process time** than Phase15. TypeScript takes 3.6108 s:
the same-window gap falls **8.47×→3.42×**. Maximum RSS falls 1,745,756→651,156 KiB
(**62.70%**). TS/B/C/C/B/TS fresh processes use CPU0, stack 4 MiB / heap 4 GiB; all
intentional compiler/archive jobs are closed. Host changes are reviewed in full.
Bend uses separately validated Base caches; TS checks Base. Emission is excluded.
The earlier prototype 2.87×/3.58× result uses different source/window and is not
the final release result. No generated-program runtime speedup is measured.

The final full frontend preserves all 2,996 primitive outcomes and reduces exact
differences **459→2**, 457new matches/0lost. All 1,001 positive accepts, 482 validation
refusals and 11 trust refusals agree. Strict checks 1,493 pass / 5 fail include four
later-emission expectations and the do-block diagnostic oracle. Both remaining
exact rows concern `check/monad_do_destructure.bend`.

Broader controls remain explicit: integration 197/198 exact, marked-pattern 71/114
exact (raw oracle `pass:false`; separate unchanged-outcome audit passes), and one
known decorator/import wording gap in each contextual 39/host 43 selection.
These are overlapping sets, not a count of unique missing language features.
Final backend 41, literal 176, literal execution 20, instance 29, growth 2, key 61,
helper 16 groups / replays 5, standalone 25-module loader and CLI 42 gates pass their
recorded contracts. Original53/60 histories preserve 226 complete paired results
under a reviewed common final host, with original inputs/order/resources.

Source is **16,345 physical /13,947 nonblank lines**, 581,177 bytes in 59 modules,
1,656 definitions / 775 laws / 66 types. Versus Phase15:  +1,057 physical lines (+6.91%),
+157 definitions, −15 laws, +3 types. Allocation improvement is not a source-size
reduction. The prior 50%/75% reduction goals remain unmet.

## Next priorities

1. Close explicit parser checkpoint semantics with cheap paired witnesses before
   another full gate. The [group-boundary investigation](../design/phase16/group_checkpoint_boundary.md)
   proves that flattening erases relevant grouping information. A bounded group
   wrapper is a proposed prerequisite for a general chronology solution, not yet
   a fix for the do-block or same-body live-instance cases. Avoid source-text or
   offset heuristics and do not thread new context through 104 parser functions
   without evidence that smaller ownership changes cannot work.
2. Profile the exact installed compact image before another speed change. The
   old allocation profile describes an eliminated representation cost; do not
   reuse its percentages as current opportunity estimates. Preserve semantic
   identities, lazy demand and original request histories in any new shortcut.
3. Keep focused checked builds and frozen-attempt fixture validation as the edit
   loop. Broad frontend/backend, timing, installation and evidence recovery are
   integration gates. Prefer shared ownership and removing duplicate work; any
   line-count benefit must be measured independently of execution speed.

## Retained experiments and operating rules

[Phase14](../implementation/phase14/conformance_and_dispatch.md) installed imported
law fixes, checker carets and six normalizer workers. Its corrected attribution
is 71 checker diagnostics, 48 trust-reporting observations and eight imported-law
observations. Its separate 8.82% improvement and 8.88× TS ratio are historical.

[Phase13](../implementation/phase13/structured_rewriter.md) stays deferred: named
worker lifting is slower; six-owner selector fusion gains 10.56% but adds 239
helper lines/7,010 bytes. It is not installed. [Phase12](../implementation/phase12/avoidable_work.md)
retains guarded v5 transformations but rejects seed cleanup and broader inlining
because matched histories overflow while their baseline passes. Do not revive
these candidates without addressing their saved counterexamples.

The old 21-case history can overflow even Phase11; the maintained selection keeps
the long string first. Historical failure cannot excuse a new changed outcome.
Preserve request order, resource limits, failures, complete results and identities.
No new self-hosted fixed point, proof-kernel or GPU conformance is claimed.

Use [checked B1 development](../docs/PHASE5_DEVELOPMENT.md). Keep checked B1,
guarded derivatives and self-emitted H distinct. Freeze plans before probes; put
outcomes in reports and ledger entries. Unknown profiles/identities fail closed.
Make one bounded optimization only after fresh evidence. Commit explicit owned
paths; preserve unrelated Phase6 work. Capture all consumed/failed tools and
artifacts with closed producers, exact exclusions and independent byte recovery.
