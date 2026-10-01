# Phase36 performance admission

**Admit checked03 for installation.** The final unchanged fifteen-point run
passes all expected results. Two complete programs improve with disjoint
observed ranges: symbolic regression **3.653×** and ray tracing **2.319×** versus
same-run Phase35. Their remaining TypeScript gaps are **3.834×** and **23.473×**.
The [root decision](admission-decision.json) binds this decision to exact inputs
before installation; the [release record](release-03.md) records its outcome.

The other thirteen points have overlapping ranges. Map/set's apparent 3.190%
slowdown prompted a same-protocol follow-up, which measured a 0.523% improvement
with overlap. Both runs are retained; no regression fix or additional win is
claimed. Read the [execution findings](execution-findings.md) and
[complete timing table](execution-table.md). Ranges are empirical observations,
not confidence intervals; fixed workloads do not define average application speed.

## Accepted costs

Normal checked requests are separate from generated execution. All 36 outputs
match independently acquired bytes. Three rotated fresh-process medians show:

| Source | Phase35 request ms | Phase36 request ms | Change | Phase36 / TS |
| --- | ---: | ---: | ---: | ---: |
| Pair | 1,721.342 | 1,694.482 | −1.56% | 5.411× |
| Mandelbrot | 1,856.294 | 1,864.166 | +0.42% | 5.698× |
| Symreg | 1,985.074 | 2,074.394 | +4.50% | 7.167× |
| Raytrace | 2,586.862 | 2,690.923 | +4.02% | 6.572× |

All four request ranges overlap. This limited sampling does not establish
neutral compilation cost: root accepts the observed possible increases for the
large execution gains. Using these medians only, symreg's extra 89.320 ms is
recovered after about eight complete calls; ray's extra 104.061 ms is smaller
than one call's 1,057.696 ms saving. These illustrative amortizations combine
separate measurement boundaries, not a measured application throughput result.
The [cost report](compiler-cost.md) retains imports, process wall, RSS and samples.

Source grows by **124 physical Bend lines (0.687%)**, 109 nonblank lines,
16 definitions and one module: **18,174 lines / 69 modules / 2,024 definitions**.
Types and laws remain 71 and 640. Runtime grows 25 lines and 1,005 bytes.
Generated program sections grow 1,440 bytes for symreg and 186 for ray;
thirteen complete program suffixes are byte-identical. This is a small source
cost for execution speed, not a simplification or compiler-throughput claim.

## Separate semantic and diagnostic gates

All 38 preinstall steps pass; the corrected inherited audit closes all 14 groups
and matches 226 canonical files. Seven new owner groups separately bind actual
checked emissions to the final API. Exact frontend agreement remains 3,026 main
plus 196 broader observations; backend81 retains 69 pass / 8 N/A / 4 shared
failures. Finite scopes, shared failures and proof/platform limits remain in
[conformance](../../selfhost/CONFORMANCE.md).

Separate profiling completes all 24 CPU/allocation acquisitions with exact
module and point bindings. Ray guard ancestry falls 50.12→0.44%; symreg producer
ancestry falls 63.92→12.30%. These diagnostic shares are not clean speed ratios,
and overlapping ancestry groups must not be summed. See
[profile findings](profile-findings.md) for remaining generic dispatch costs.

The source is frozen at checked03. The rejected compile-analysis preflight and
additional reflection shortcut remain excluded. No new self-emitted fixed point,
full backend/GPU, independent proof-kernel or universal host-equivalence result
is claimed. Ordinary compilation continues without TypeScript fallback.
