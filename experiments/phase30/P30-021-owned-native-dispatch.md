# P30-021 — Remove native dispatch inside the same local region

Owner: phase30_prototype; independent reviewer: phase30_review. Retrospective
index of the prospectively frozen
[native-call design](../../design/phase30/closed-owned-row-native-calls.md).

- Invariant: preserve exact native helper methods, non-tail force, original
  handle/Tuple results, deferred setter demand, public definitions and generic
  gen/init setup. One outer Array marker refusal closes a discovered hook gap.
- Correctness: original full-state/alias/host gates pass with the sixth module;
  independent 27 marker/first-use and 27 deferred/foreign-array cases pass.
  A real old-domain getter→umin mutation counterexample is retained; the new
  variant agrees with generic fallback.
- Measurement: 0.368370→0.340405 ms, 1.082× incremental throughput, disjoint
  confirmation ranges. Full ladder is 1.759× generic but still 40.6× TypeScript
  on this complete fixture. Storage/force counts remain fixed; apply 794→630.
- Decision: measured opportunity, still prototype-only. Stop at any unresolved
  forcing or locality counterexample; do not broaden to storage specialization.

The [implementation report](../../implementation/phase30/closed-owned-native-calls.md)
is canonical. It links the exact controls, frozen configs and retained drifting
screen. Evidence is under `selfhost/build/phase30/prototype-owned-native-*`,
`review-owned-native-*` and `owned-native-{screen,confirm}-01`; campaign
consolidation still owns durable packaging of large raw artifacts.
