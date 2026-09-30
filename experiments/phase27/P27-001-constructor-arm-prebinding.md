# P27-001 — remove one redundant arm application

- Owner: implementation agent/root; reviewer: independent speed agent.
- Started2026-09-30, before candidate build or timing.
- Correctness: pending scoped checked-source and emitted-library controls.
- Measurement: pending, generated JavaScript and extracted component only.
- Decision: investigate; no promotion yet.
- [Design](../../design/phase27/constructor-arm-prebinding.md);
  [results destination](../../implementation/phase27/constructor-arm-prebinding.md).

Claim: a selected constructor arm with more leading lambda slots than live
constructor fields can return the same partial descriptor directly, avoiding an
initial fn record, bounce and apply call. Expected gain must be measured, not
inferred from counters. Outer arity, demand, capture scope, argument copies and
returned descriptor remain unchanged. Unknown shapes use existing emission.

Stop on any semantic mismatch, altered field/argument read order, lost generic
fallback, unbounded source expansion or unresolved representative regression.
Preserve custom-slice saturation behavior; merely creating a prebound function
and applying an empty vector changes the old operation schedule.

The Phase27 design freezes baseline/provenance, controls, warmup/order/repetitions
and promotion criteria. Comparison uses the actual Phase26 before artifacts,
pinned TypeScript and new immutable checked B1 emissions. Full H, native/device
performance and universal language equivalence remain unmeasured.
