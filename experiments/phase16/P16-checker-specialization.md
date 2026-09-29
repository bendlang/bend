# P16-checker-specialization — retain existing typed instance failures

Prospective frozen transport-only ablation. Owner:phase15_behavior; reviewer:root.
Correctness:unchecked. Measurement:not run. Decision:investigate.

[Design](../../design/phase16/checker-specialization.md) specifies representation,
first-error invariants,ABI compatibility and boundaries. A change to acceptance,
instantiation demand or unrelated error precedence disproves the transport-only
claim. Five corpus errors are opportunities, not assumed exact improvements.
Retain actual checked attempts and strict strings; root owns final promotion.

[Report](../../implementation/phase16/checker-diagnostics.md).
