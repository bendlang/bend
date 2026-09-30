# Checked16 renewed controlled comparison

Status: the actual-image small confirmation passes and retains both the generic
row recovery and scalar speedup. The renewed complete matrix is still pending.
Checked14's complete matrix and release hold remain documented in
`final-timing.md`; these are separate checked16 results.

The candidate integrates the confirmed generic constructor-field runtime repair
and removes unused prebinding source machinery. The original ten programs have
all been freshly compiled and their exact public outputs pass. The row and
scalar source/control provenance is documented in
`generic-runtime-row-diagnosis.md`, including the independent checked15→16
structural proof and complete-state/alias/effect observations.

`runtime-cleanup-timing-plan-16/confirm.json` freezes a five-way row32/scalar128
confirmation (Phase29, held14, repaired15, cleaned16, pinned TypeScript). The
pending15-only plan remains unexecuted; the combined comparison replaces its
execution without modifying that historical plan.

The complete final batch is frozen in
`selfhost/build/phase30/final-timing-batch-plan-16/plan.json`: 13 serial jobs and
751 input identities. Its exact retained launcher derivation lives in
`final-timing-launchers-16/derivation.json`. It executes the ten unchanged
original transfer points, ordinary compiler check, two-source checked-library
cost matrix, and four-point scaling confirmation. Per-case receipts and drift
remain separate. Original-case outer limits remain 1,200 seconds; no 100-call
microbenchmark floor is substituted for expensive original programs.

The scaling correctness precheck passes all 12 public source/variant points.
Only its acquisition affinity changes from CPU7 to CPU2 to avoid frontend workers;
the frozen derivative and exact edit record are in
`scalar-scaling-cpu2-check-16`. Measured scaling remains on CPU3 with the original
confirmation protocol.

## Actual-image row and scalar confirmation

`runtime-cleanup-confirm-16` completes in 209.80 seconds with every exact result
check passing. Median milliseconds per call:

| Point | Phase29 | Held14 | Repaired15 | Cleaned16 | TypeScript |
| --- | ---: | ---: | ---: | ---: | ---: |
| Complete row32 | 0.448173 | 0.601983 | 0.448121 | 0.444585 | 0.008421 |
| Scalar128 | 0.396410 | 0.006965 | 0.006972 | 0.006975 | 0.001703 |

Cleaned16's row range is 0.442894–0.458928 ms, compared with repaired15's
0.447231–0.451254 and Phase29's 0.444422–0.451538. The recovered generic speed
holds: cleaned16 takes 26.15% less time than held14, with disjoint ranges.
The 0.79% median difference against repaired15 is inside overlapping ranges and
does not establish a further speed gain from source cleanup. Row half drift is
−0.16…+2.31% for cleaned16 and −0.55…−0.02% for repaired15.

The scalar ranges of held14, repaired15 and cleaned16 all overlap. Cleaned16
takes 0.006955–0.007050 ms, retaining the scalar win: 56.83× Phase29 throughput
and 4.096× TypeScript time at 128 iterations. Its half drift is +0.68…+2.38%;
all scalar variants stay within 3.00% absolute half drift. These results support
preserving the repair while deleting unused machinery, not a new compounded
optimization claim.

The final original-program matrix, separate long-warmup comparison and release
gates remain required; this small confirmation alone is not a release verdict.
