# P30-001 — Private direct entry across function and match chains

- Owner: root / phase30_prototype; independent reviewer: phase30_review.
- Started:2026-09-30 07:28 UTC; first investigation bounded to20minutes.
- Correctness: not run. Measurement: not run. Decision: investigate.
- Design: [Phase30](../../design/phase30/direct-generated-code.md).
- Baseline:77aecb2 / checked API10510efd / runtime40823818 / pin0187512.

Hypothesis: eliminating private partial-function chains in edit-distance cell
helpers materially reduces emitted-program time while arithmetic, arrays,
projection and construction remain unchanged. Compare identical complete row
states against an independent oracle. Preserve public descriptors and early
argument demand; use exact fallback for unknown foreign field-vector shapes.

Cheapest disproof: a changed effect/error/ownership trace, no dynamic dispatch
opportunity, or a counter reduction without a clean timing improvement. Inspect
matched helpers first, derive immutable JS prototype second, implement a general
Bend emitter rule only after measured support. The detailed oracle/derivation
receipt and frozen comparator config will be named in the report before timing.

Reports: `implementation/phase30/prototype-findings.md`,
`implementation/phase30/semantic-plan.md`; raw attempts under
`selfhost/build/phase30/`. Preserve failures and superseded variants. No prototype
is an installed compiler; no unrelated runtime or representation change is
part of this ablation. A later hypothesis will separately test loop/data changes.
