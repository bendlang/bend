# P36-002 — Saturate private tree production

Status: **accepted in installed checked03**. Final unchanged symreg is 3.653×
faster than Phase35 and remains 3.834× slower than TypeScript output. All owner,
integration and release gates pass. See the
[release](../../implementation/phase36/release-03.md).

## Preregistered proposal and chronological checkpoints

- **Hypothesis:** after iterative consumers, gen/node/gen.leaf dispatch causes
  most remaining symreg cost; a private dynamic-depth producer materially improves
  the original workload without a new tree representation.
- **Evidence entering:** checked09 symreg generator ancestry64.33%; 15.529ms/call,
  14.02× TS in the unchanged Phase35 full run. These are prior observations.
- **Design:** [private producers](../../design/phase36/private-producers.md).
- **Owner:** phase36_producers. Root executes bounded serial jobs.
- **Artifacts:** [saved-output derivation](../../selfhost/tools/performance/phase36/producer-derive.mjs).
- **Correctness:** not run. Inherited complete oracle/mutation controls plus
  varying private producer outputs and admission/refusal witnesses prepared.
- **Measurement:** not run. Distinguish generator-only and full producer.
- **Decision:** investigate. No production source edits, installation or claims.

The proposed implementation reuses the existing scalar-tree continuation stack,
with a private sum-result plan, safe two-let normalization and saved parent aliases.
It does not specialize literal benchmark depth or fuse away the generated tree.
Failures, inconclusive timing and rejected broader admissions will stay recorded.

### First actual observation

Root's `selfhost/build/phase36/producer-controls01/report.json` passes106 oracle
rows and121 boundary observations across original/baseline/generator/producer.
The source proposal remains unbuilt; timing and real-compiler admission are still
separate pending decisions. No production promotion follows from this result.

### Clean mechanism result

Root's counter-free `producer-screen01` gives15.8691ms baseline,
10.9321ms generator-only,4.19892ms full producer and1.16612ms TypeScript on the
unchanged original benchmark, in10.75s. Ranges are disjoint. Full selection is a
meaningful extra gain and merits the10-net-line existing-IR extension in
[producer-selectors](../../design/phase36/producer-selectors.md).

Initial general fixture acquisition failed baseline checking on an affine binder
used twice. Original source and failure remain; v2 fixes binder multiplicities
and leaves types/optimizer assertions intact. Actual checked emission, complete
private trees, aliasing and positive/negative entry are still required. No
release/promotion claim follows from the saved-output screen.

### Actual compiler checkpoint

Checked03 API93e55ad7… passes175 fixture oracles/5 admission checks,108 complete
private trees/36 alias checks/9 positive entries/27 mutation boundaries and243
selector oracles/10 admissions-refusals/6 active mutation boundaries. Exact raw
report hashes and compiler identities are in the
[checked03 evidence index](../../implementation/phase36/producer-checked03-evidence.json).
This is a real emitted-code result, separate from saved-output timing and pending
final-image integration. Any later image must be rebound and revalidated.

Final integration closes on the same checked03 API. The complete fifteen-point
run, separate normal compiler costs, all 24 profiles and installed CLI checks
are recorded in the [phase report](../../implementation/phase36/README.md).
