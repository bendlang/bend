# P10-003 — Repeated work in deep-pattern layout validation

- Owner: layout investigation agent; reviewer/integration owner: root.
- Started: 2026-09-28, initial investigation bounded to 15 minutes.
- Status: prospective plan; no candidate or measured outcome yet.
- Scope: checked Phase9 B1 equality derivative; shared backend layout validation.
- Report: [layout.md](../../implementation/phase10/layout.md).

## Claim and disproof

Deep Nat patterns reconstruct nested default-arm terms. The layout pass may repeat
constructor lookup, literal recognition, or type recovery on overlapping subterms.
Count actual generated Bend helper entries on Nat depths 8, 16, 32, 64, 128
(and 300 only if the smaller series justifies it). A linear series without a
substantial repeated-work caller disproves this proposed mechanism. No source
change is justified only by the previous 22-second phase trace.

Preserve exact layout errors, live/erased traversal, constructor provenance,
argument-demand order and imports. Candidate source must be separately checked;
instrumented generated code is diagnostic evidence only. Never bypass the layout
gate or infer safety merely from a constructor's spelling.

## Setup and gates

Freeze the installed Phase9 selected API and source identities, Node 24.18.0,
Base/runtime/driver identities and actual generated fixtures. Run CPU2 with
4 MiB stack, 4 GiB heap and <=60-second subprocess deadlines. Other phase owners
may run concurrently; these initial times identify mechanisms, not compiler-wide
speed ratios. Each fixture must pass ordinary checking; capture exact layout
result and operation counts. Short-circuit after layout only for the diagnostic
probe, labeling that no emitted program was validated.

Rank repeated failed literal recognition first, constructor lookup second and
repeated normalization/type recovery third; actual counters decide. Test a minimal
source candidate only if counters show avoidable work. Require a checked isolated
B1, paired exact layout positive/negative controls, the deep Nat case, and actual
JS/native output where applicable before proposing integration. Preserve failures
and unknowns; no broad suite, full-source run or production edit belongs to this
owner. Root owns final integration, measurement and release.
