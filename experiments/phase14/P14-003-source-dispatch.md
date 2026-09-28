# P14-003: source-level normalizer dispatch

Status: prospective, before implementation or measurement.
Owner: dispatch workstream; 90-minute initial feasibility cap from owner start.
Follow the [Phase14 design](../../design/phase14/conformance_and_dispatch.md).

Hypothesis: Boolean-parameter match workers for norm_eval_node let pinned upstream
emit direct selection or a loop, saving intermediate closure/Unit/message work
with less maintained infrastructure than the Phase13 JS selector rewriter.
Speed and total line/concept effects are unknown. Restrict this pilot to one owner.
The Phase10 rejected local-Boolean-match form and Phase12 seed/broad-inlining
failures stay rejected; preserve fallback, condition order and branch demand.

Inspect emitted code first, then real operation counts on valid small graphs.
Require semantic/demand controls plus fresh and exact 53/60-request histories at
4 MiB stack / 4 GiB heap before any timing. Compare every predecessor and result.
Coordinate an exclusive timing window; use paired same-source runs and count all
source laws/helpers, JS dependencies and maintained tests in complexity.
Stop on weak opportunity or failed cost/resource tradeoff; no broad expansion is
implicitly authorized. Report all attempts and decision in
[source-dispatch.md](../../implementation/phase14/source-dispatch.md).
