# P30-022 — Reuse private continuation frames at the same depth

Owner: phase30_review for ablation, root for compiler, phase30_prototype for
timing and actual integration gates. Retrospective index of the frozen
[frame design](../../design/phase30/scalar-tree-frame-reuse.md).

- Invariant: private per-invocation pool, overwritten scalar parent slots,
  phase and left result before reuse; unchanged DFS order, guard and fallback.
- Correctness: actual12→13 complete modules differ only in frame push/pop.
  Fresh 74 oracles, 130 ordered boundaries, eight depth sentinels, 85
  independent supplemental cases, 24 count rows and 16 repeated calls pass.
  Original visits/leaves/combines stay 511/256/255; fresh pairs 255→8.
- Measurement: isolated longer-warmup run saves 8.06%; separate actual compiler
  run saves 6.45% (0.263759→0.246737 ms), with disjoint ranges and small drift.
- Decision: implemented in checked attempt13; broad release remains separate.
  Standard Array intrinsics and the existing bounded private tree still apply.

Canonical [report](../../implementation/phase30/scalar-tree-frame-reuse.md)
records ranges, long-warmup freeze, counters, earlier tooling failure and the
pre-launch ENOSPC event. Raw frame prototype/actual identities and all failed
attempts remain retained; consolidation owns final durable packaging.
