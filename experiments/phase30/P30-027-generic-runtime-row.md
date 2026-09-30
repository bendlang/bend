# P30-027 — Generic constructor prebinding explains the row regression

Owner: phase30_prototype; independent derivative owners: phase30_analysis and
phase30_review. The [prospective design](../../design/phase30/generic-runtime-row-diagnosis.md)
isolates dispatch on the same newly checked source after P30-026 held release.

- Invariant: every value in four 128-slot arrays agrees with the independent
  oracle; generic storage and public source definitions stay fixed.
- Gates: 196 numeric observations across seven variants, plus two suites of
  28 oracles/16 alias/257 ordered public boundaries pass. Independent runtime/helper
  proofs and the deliberate prototype-observation restoration are retained.
- Screen: large opposing warmup drift; retained without accepting its magnitude.
- Confirmation: checked14 median 0.606265 ms, generic delayed constructor path
  0.446850 ms, Phase29 0.450682 ms. The simpler generic path removes 26.29% of row
  time and recovers Phase29 speed within overlapping ranges.
- Other variants: inline exact dispatch is effectively null; registered fused
  prebinding saves 2.32%; restoring the original method-read expression saves 9.68%.
- Decision frontier: integrate and verify the isolated generic path first.
  This prototype does not itself lift the release hold or establish whole-program
  transfer; no combination has been measured.

The [implementation report](../../implementation/phase30/generic-runtime-row-diagnosis.md)
has complete ranges, drift and exact artifact paths. All original failed
performance expectations remain in P30-026. The seven-way confirmation took
147.51 seconds, versus the 27-minute full comparison, validating the smaller
iteration loop for this mechanism without replacing final transfer checks.
