# P30-023 — Emit private helper Lets as statements

Owner: phase30_analysis; timing: phase30_prototype; compiler integration: root.
Retrospective index of the frozen
[private-Let design](../../design/phase30/private-let-statements.md).

- Invariant: evaluate all RHS expressions before entering the source binder
  block; fresh immutable aliases; unchanged terminal expression, guards and
  public fallback. No new runtime or ownership representation.
- Correctness: isolated original/tree/host/source-shadowing gates pass. Actual14
  matches independently reconstructed output changing only seven helper bodies;
  74 numeric, 130 host, four depth and 85 supplemental observations pass.
- Measurement: original Mandelbrot longer-warmup baseline 0.267175 versus
  candidate 0.237970 ms, 1.123× throughput / 10.93% less time; disjoint ranges,
  timed half drift below 1%. The opposing short-screen drift is retained.
- Actual measurement: checked13→14 gives 0.246549→0.215416 ms, 12.63% less time,
  with stable, disjoint samples. TypeScript is 0.045613 ms in that window,
  leaving 4.723×. This window includes frame reuse on both compiler sides.
- Decision: eight-line/one-function implementation passes actual scoped gates;
  final release remains parent-owned. Do not infer generic callback gains from
  this private-helper subset.

Canonical [report](../../implementation/phase30/private-let-statements.md)
and [implementation supplement](../../design/phase30/private-let-emitter-supplement.md)
retain exact scope. The separate longer-warmup plan and immutable raw outputs
are `private-let-long-plan-01` and `private-let-long-confirm-01`. Packaging of
large local evidence remains part of campaign consolidation.

The [actual compiler report](../../implementation/phase30/private-let-compiler.md)
binds the separate `private-let-compiler-long-confirm-14` result and all actual
compiler/source/runtime/control identities.
