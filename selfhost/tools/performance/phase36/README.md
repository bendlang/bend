# Phase36 optimization tools

Start with the maintained [program suite](../programs/README.md). Its catalog,
execution worker and timing presets are unchanged. The selected compiler and
final results are recorded in the [phase report](../../../../implementation/phase36/README.md).
Only root runs compiler, test, timing, profile or archive jobs; use CPU3, explicit
heaps, serial execution and the shared memory/deadline supervisor.

## Routine loop

1. Acquire a checked compiler with `tools/development/workflow.mjs`.
2. Use `../programs/prepare.py --attempt ATTEMPT` to freeze its checked output.
3. Run `../programs/run.py` with a 20/60/300/600-second ceiling and independent
   case selection. Profile separately with `../programs/diagnose.py`.

Phase36 uses an explicit immediately previous release as its incremental
baseline. `freeze-baseline.py` verifies Phase35 checked09 and copies its checked
fifteen-point outputs, retaining their emission receipts and the maintained
complete-row observer. TypeScript remains the original pinned portable reference.
Pass the resulting `manifest.json` as `--baseline`; the maintained default
reference is still the historical portable Phase32 bundle.

## Actual compiler controls

- `cohort-acquire-v2.py`: serial baseline/candidate/TypeScript acquisition of the
  corrected overflow, array-refusal, producer and selector sources.
- `guard-checked-controls-derive.mjs`: bind existing colf/scope assertions to
  checked output using diagnostic counters only. It never synthesizes an optimizer.
- `guard-overflow-controls-v2.mjs`, `guard-array-controls-v2.mjs`: actual source
  error/reentry and mixed-array refusal observations.
- `producer-fixture-controls.mjs`, `producer-reviewed-controls.mjs`,
  `producer-selector-controls.mjs`: independent numerical/complete-tree/alias
  oracles, actual entry, dependency mutation and selector refusal controls.
- `owner-close.py`: close all seven owner groups against the selected API and
  exact checked emission receipts. See the [mapping protocol](../../../../implementation/phase36/owner-closure-protocol.md).
- `final-integration-plan.py`: derive the unchanged inherited frontend/backend,
  fifteen owner groups and release/CLI gates. See the [planner guide](final-integration-README.md).
- `compiler-cost-plan.py`: freeze normal checked-library cost inputs against an
  explicit prior attempt; run with the unchanged Phase35 cost runner and Phase30
  worker. Compilation costs are separate from generated-program execution.

## Preserved experiments

`producer-derive.mjs` and `producer-clean.py` create generator-only/full-producer
saved-output ablations with diagnostic counters removed from timed modules.
`guard-derive-v2.mjs` tests scoped proof reuse; `guard-exact-derive.mjs` tests a
further reflection shortcut. None of these manually derived outputs constitutes
a checked compiler. The cost preflight and exact-reflection proposals were
rejected; their files remain evidence, not production features.

Earlier numbered fixtures, proposals and tool versions retain failed or
superseded attempts. Use the latest names above for the final controls. Every
execution needs a new output directory. The [evidence capsule](../../../../implementation/phase36/evidence/README.md)
preserves the complete closed raw campaign, including failures.
