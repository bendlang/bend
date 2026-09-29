# P24-003 — Reject constructor/foreign-definition emission collisions

- Owner: backend agent; reviewer: coordinating agent.
- Frozen before source edits, 2026-09-29. Bound: one shared validation helper and focused execution controls.
- Correctness: counterexample on installed Phase23; candidate unchecked.
- Measurement: no performance claim. Decision: investigate.

The current pinned TypeScript emitter rejects every foreign definition whose exact qualified name is also a constructor, before reachability. The installed compiler instead executes `io/effect_ctr_name.bend` and prints 7. Both accept its check-only request. Evidence is retained in `selfhost/build/phase24/backend-pilot-01`, `-02`, and `-03`, with full original result vectors and roundtrip-verified archives.

Add the same full-book check to `driver_emit_owned` after the existing reserved-name check. Reuse `j_find_ctor`, the existing foreign term representation and exact diagnostic. Keep check-only and pure interpreter behavior, ordered first errors, runtime and upstream oracle unchanged. A reachability-only emitter check is insufficient because unused conflicting foreign definitions are also rejected upstream.

Falsify with any changed accepted renamed program, qualified-name false positive, changed check-only result, changed diagnostic priority, or remaining collision execution. Test the original fixture in every eligible lane, plus unused and renamed foreign controls with both JS and C imports. Use checked B1 from the combined frozen candidate and unchanged paired harness, 4 MiB stack/4 GiB heap, 30-second probes on CPU3–6 after the coordinator's exclusive timing window. Retain every failed attempt. Rerun the complete 81-row pilot; counts include four check rows, ten boundary execution rows and 67 positive execution rows. Do not count this as all 2,644 eligible positive executions.

The resulting report is [backend census](../../implementation/phase24/backend-census.md). This prospective record stays frozen; outcomes and hashes belong in that report. Parent owns the combined build, review and promotion.
