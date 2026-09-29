# P15-004: prospective combined validation policy

Frozen before the integrated build or full run. The
[main design](../../design/phase15/parser_conformance_and_speed.md) owns this phase.
Baseline is Phase14 combined-01 and frontend-audit-02/candidate.json; reference
is the unchanged Phase8 pinned vector. Keep every original exact result field.

Every full-vector delta must be one of:

1. A new exact reference match, including verdict/evidence consequences.
2. One of the20named parser/load observations restoring all reference semantic
   and output axes, while a separately retained diagnostic difference remains.
3. A parser diagnostic adding only caret rows while every semantic/output axis
   and error phase stays unchanged. Deleting caret rows classifies the delta;
   it never defines exact conformance or converts a strict failure into a pass.

An existing exact match may not regress. The10named fixtures are
`import/cross_file_io.bend`, `import/cross_file_proof.bend`,
`import/cycle_terminates.bend`, `import/diamond_dedup.bend`,
`import/dotted_path.bend`, `import/hub_head_local.bend`,
`import/hub_head_path.bend`, `import/path_canonical.bend`,
`import/tilde_path.bend`, and `parse/prefix_operator_dead.bend`.
Every other unexpected difference fails the gate and remains retained. Any
necessary additional policy must be justified prospectively from isolated
evidence, with the earlier policy/failed attempt preserved.

Require all1,001positive accepts,482negative refusals,11exact intended trust
refusals, unchanged later-emission acceptance, no invalid/missing/timeout/drift
observations, and fewer than603exact differences. Attribute gains by changed
axes and isolated candidate evidence, avoiding the corrected Phase14 attribution
mistake. Keep strict fixture verdicts separate from compatibility comparisons.

The integrated routine gate may append the10fixed upstream check cases to the
existing26, using explicit refusal-at-parse oracles when exact wording remains
different. Preserve the long string first. Full/raw reference comparisons and
isolated controls remain responsible for exact diagnostic/result fields.

If source-speed survives, both conformance-only and combined checked attempts
share the same reviewed host and selection. Their fresh/string and exact53/60
histories must agree at every predecessor/result field. Earlier historical host
or diagnostic changes are recorded explicitly. Runtime/ABI/resource limits and
request order stay fixed. Final backend/helper/CLI gates precede promotion.

For the final timing matrix, compare every frozen host file. A differing file
requires an explicit reviewed before/after hash and patch; a generic drift
allowance is insufficient. The unchanged Phase8 worker checks the identical
final source with pinned TypeScript, Phase14 and selected candidate serially,
intentional compiler/archive jobs closed, per-image validated Base caches, CPU0,
4MiBstack/4GiBheap and two samples each. The measured result is each complete
workflow when a reviewed host correction differs. No TS ratio comes from an
isolated pilot or profile, and all ordinary results/resource checks must pass.
