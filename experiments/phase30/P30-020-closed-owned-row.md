# P30-020 — Close a local-array row behind one scalar entry

Owner: phase30_prototype; independent reviewer: phase30_review. This is a
retrospective index of the prospectively frozen
[first-ladder design](../../design/phase30/closed-owned-row-first-ladder.md),
not a new pre-execution plan.

- Correctness: 28 independent full-state points across five variants, 16
  alias/freshness/zero-swap cases, 257 ordered boundaries, 15 admission checks
  and 27 additional independent deferred/foreign-array observations pass.
- Measurement: controlled row32/seed17 confirmation gives 0.588137 ms generic
  versus 0.367874 ms private row, 1.60× faster; TypeScript 0.008413 ms. Separate
  counters preserve allocation/read/write/build/constructor effects.
- Decision: investigate general proof; no production admission. Standard Array
  intrinsics are an explicit scope. Locality permits aliasing, not uniqueness.
- Cheapest disproof: escaped private deferred work, a changed public descriptor
  observed after entry, or a changed full array/handle alias. Full root forcing
  and exact-entry fallback address the checked cases.

Canonical outcomes, ranges, drift, inputs and commands are in the
[implementation report](../../implementation/phase30/closed-owned-row.md).
Immutable local evidence is `selfhost/build/phase30/prototype-owned-*` and
`owned-row-{screen,confirm}-01`; diagnostic modules were never timed. The
separate [general proof outline](../../design/phase30/closed-local-graph-proof.md)
does not claim a production implementation. Campaign consolidation owns durable
raw-artifact packaging; local ignored paths alone are not preservation claims.
