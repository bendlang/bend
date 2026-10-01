# P36-003 — Avoid an identity private-inlining traversal

- Owner: phase36_cost; independent predicate review: producer owner; final rejection: root.
- Evidence cutoff: Phase35 checked09, commit `88619d9`.
- Objective: recover compile latency without losing the generated-program gains.
- Correctness: root's cost-only checked01 passes Focus36, ten internal controls,
  all 15 catalog module comparisons and all 36 checked-request output checks.
- Measurement: four normal checked-library sources, three fresh rotated samples
  per baseline/candidate/TypeScript role; 272.232 seconds total.
- Decision: rejected and reverted; not part of the final compiler.
- [Design and falsification](../../design/phase36/cost-preflight.md).
- [Patch](../../implementation/phase36/cost-preflight.patch) and
  [source identity](../../implementation/phase36/cost-preflight-identity.json).
- [Diagnostic controls](../../selfhost/tools/performance/phase36/cost-inline-controls.mjs).

The private-vector inline pass has exactly one transformation rule. When none
of a closure's original helpers can satisfy its existing predicate, it traverses
and reconstructs terms only to return identical terms. A bounded preflight can
skip this pass; require exact emitted bytes and retain the vector-positive path.

Static inspection counts 31 private declarations in five Mandelbrot closures,
31 in four symreg closures and 29 in four ray closures. This is not a profile
attributing Phase35's request regressions to this pass. The cheapest falsification
is a checked cost-only build plus synthetic helper controls and exact Mandelbrot
emission. Follow with four ordinary checked request comparisons before admission.

Root alone runs builds, tests, timings and profiles, serially under the shared
execution guard. Keep the 103 unrelated files and the closed Phase35 raw tree
unchanged. Record all failures and attempts in new Phase36 paths. Do not edit
the benchmark catalog, worker, budgets or TypeScript source to favor the candidate.

## Results

The [report](../../implementation/phase36/cost-report.md) and
[complete extracted data](../../implementation/phase36/cost-data.json) record
the result. All observed generated modules are byte-identical. Scalar workload
request medians improve 1.77% (Mandelbrot), 1.86% (symreg) and 1.13% (ray), with
disjoint observed ranges. Pair's median rises 4.48% with overlap. The small gains
do not justify an additional pass/definition and uncertain adverse vector-case
effect. Root reverted the 11-line production patch; preserve the checked attempt
and all measurements as negative evidence.

Independent review by the producer owner confirms the predicate includes every
condition the original sole rewrite rule can match, and budget failures preserve
the original body. This supports the identity argument; it does not change the
empirical rejection. Neither a generated-program speedup nor a final compiler
throughput win may be attributed to this rejected experiment.
