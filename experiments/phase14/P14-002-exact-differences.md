# P14-002: a shared exact-difference cause

Status: prospective, before census or implementation.
Owner: exact-difference workstream; root integrates. Follow the
[Phase14 design](../../design/phase14/conformance_and_dispatch.md).

Hypothesis: some of the 730 exact parse/check observation differences share one
small correctable cause. Census original observations by lane, phase and diagnostic
shape; preserve raw strings and fixture identity. Count observations and unique
fixtures separately. A normalized cluster is not a passing exact comparison.

Select and document one concrete family after reading its implementation and
pinned upstream. Freeze a family-specific addendum before candidate execution.
Prefer one shared change with exact-output controls and clear error precedence.
Coordinate overlap with imported-law changes; never alter another owner's snapshot
or the live source. Root decides integration from full delta accounting.
Report in [exact-differences.md](../../implementation/phase14/exact-differences.md).
