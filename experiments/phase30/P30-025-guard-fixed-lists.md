# P30-025 — Avoid repeated fixed-list allocation in the complete guard

Owner: phase30_prototype; independent reviewer: phase30_review. The
[prospective design](../../design/phase30/scalar-guard-fixed-lists.md) freezes
the supported intrinsic scope and decision threshold before timing.

- Hypothesis: fixed prototype/key lists and the per-dependency descriptor
  array/callback create avoidable guard work at small scalar entries.
- Invariant: all metadata reads, predicates, early returns and live snapshots
  stay in the same order. No result cache, public freeze or skipped validation.
- Correctness: direct core, generated helper/tree and independent full reflection
  controls pass. The first tooling-only parser failure is retained separately.
- Measurement: helper 0.00696200→0.00666057 ms (4.33% less time), whole
  0.216142→0.212245 ms (1.80% less time), both with disjoint confirmation ranges.
- Decision: defer. Before measuring, promotion required at least 5% stable
  helper time saving or 3% whole saving, with no confirmed regression above 3%
  on the other. Both measured benefits are below those unchanged thresholds.
- Alternative: larger pure regions amortize guard cost, but add compiler proof
  scope; this final bounded experiment first tests a small runtime expression
  change without adding concepts.

The [implementation report](../../implementation/phase30/scalar-guard-fixed-lists.md)
records exact gate scopes and `guard-lists-plan-02` inputs. Fixed-list hoisting
and explicit four-descriptor checks form one temporary-allocation variant, so a
result cannot distinguish their individual contribution. No compiler-produced
variant was built or promoted. Raw durability remains
part of campaign consolidation; immutable local receipts are not by themselves
a storage guarantee.
