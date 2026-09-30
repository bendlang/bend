# P30-026 — Complete checked-14 comparison exposes the generic fallback cost

Owner: phase30_prototype; release decision: root. The original-program,
compiler-cost and scaling protocols were frozen before this batch; the
[orchestration design](../../design/phase30/final-timing-batch.md) binds their
serial execution without changing those protocols.

- Question: does the consolidated checked14 image transfer its scalar-region
  improvements to the original ten programs, compiler workflows and different
  helper sizes?
- Correctness: all ten original outputs, nine ordinary-check observations,
  eighteen checked-library output hashes and four scaling points pass.
- Measurement: original Mandelbrot is 97.35× faster than Phase29 and 4.83×
  TypeScript time in this transfer window. Edit-distance, lexer and ray tracing
  regress by approximately 20–24%; other small cases have substantial warmup
  drift and are retained as unsettled measurements. Scalar8192 is 190.74× faster
  than Phase29 and 1.34× TypeScript; scalar0 pays 2.68× Phase29 time.
- Compiler cost: ordinary request median increases 3.80%, while library request
  medians increase 6.85% and 2.16% for the two retained sources.
- Decision: **hold checked14 release** and isolate the generic runtime overhead.
  Correctness passing and a large specialized gain do not cancel regressions.

The [complete implementation report](../../implementation/phase30/final-timing.md)
contains individual point times, separate request/process boundaries and drift
limitations. The frozen batch has 13 jobs and 752 bound input identities; all jobs
completed in 1,631.07 seconds. No original point, slow ray-tracing sample or failed
performance expectation was dropped. The follow-up uses the separately frozen
[exact row diagnostic](../../design/phase30/generic-runtime-row-diagnosis.md).
Raw receipts remain immutable under `selfhost/build/phase30`; campaign storage
consolidation must retain them before claiming durable reproduction.

## Separately frozen checked16 renewal

After the isolated runtime repair in P30-027 and source cleanup in P30-028,
the [checked16 batch design](../../design/phase30/final-timing-batch16.md)
renews all 13 jobs with 751 bound identities and unchanged point protocols.
Every output check passes; outer elapsed time is 1557.58 seconds. The original
checked14 comparison and release hold above remain historical evidence.

The large generic regression is recovered on edit distance, lexer and raytrace:
their checked16/Phase29 ranges overlap. Original Mandelbrot retains about 100×
Phase29 throughput. The registered scalar helper at 8192 iterations is about
193× faster than Phase29 and 1.34× TypeScript time; this is one controlled helper,
not a general-program speed claim. Its zero-work guard cost remains visible.

The renewal does not pass an unconditional performance release verdict. RLE is
10.30% slower with disjoint ranges and small half drift; the ordinary compiler
request is 3.86% slower, and Mandelbrot library compilation is 5.93% slower.
Several small original cases retain warmup ambiguity. A separately frozen
15-second tree-bitonic follow-up retains a 4.15% regression with disjoint ranges;
warmup reduces its transition but does not eliminate the remaining difference.
The separate long-warmup15/16/TS Mandel comparison confirms preserved scalar speed
with overlapping15/16 ranges, without an additional deletion-speed claim.

The [canonical checked16 report](../../implementation/phase30/final-timing-16.md)
contains the full table, costs, ranges and scope; do not pool these samples with
checked14. **Release remains on hold** pending the P30-030 residual-dispatch
investigation and native backend gates. Passing correctness does not erase the
remaining regressions or authorize an installation claim.
