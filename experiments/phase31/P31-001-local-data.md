# P31-001 — remove private record administration

- Owner: phase31_local_data; independent reviewer: phase31_semantics; integration: root.
- Started:2026-09-30; initial bounded investigation20minutes, then review evidence.
- Correctness: unmeasured prospective controls, no generalization claim.
- Measurement: not run; clean timing requires root grant.
- Decision: investigate.

Hypothesis: closing setup then removing a proven private Dp shell substantially
reduces the complete local-array fixture's execution cost. The former1.759×
ladder/40.6×TS result belongs to its own historical window. Rebind checked17 and
pinned TS first. Local aliasing and delayed Array.set order are preserved;
scalar public entry guards and generic fallback remain. No public object ABI or
array storage change is allowed in the first experiment.

The [campaign design](../../design/phase31/local-data-and-compiler-throughput.md),
[exact ladder](../../design/phase31/local-data-ladder.md) and
[independent review](../../design/phase31/local-data-independent-review.md)
define individual interventions and controls. Any complete-state/order mismatch
rejects the candidate. Less than20% confirmed time reduction or persistent
large drift defers production work until a stronger mechanism is identified.
Counters are not CPU shares. All derivations, failures and prior windows remain.
