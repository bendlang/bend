# Complete setup and one local record shell

The experiment has freshly acquired the exact historical row fixture using
checked17 (5.075 seconds) and pinned TypeScript (0.767 seconds). These are
acquisition durations, not a compiler-throughput comparison. All generated
variants preserve the public definitions and exact source hash. The prospective
[design](../../design/phase31/local-data-ladder.md) keeps setup and record
administration as separate ablations. No production change follows yet.

`selfhost/build/phase31/local-data-01` holds generic17, the freshly rebound
private/native ladder, private setup, private Dp-shell elimination and TypeScript.
The old Phase30 modules and ratios are not relabeled as current measurements.

The retained public/alias suite passes all 28 complete-array oracle points,
16 alias cases, 257 ordered boundary cases and 15 admission checks. It covers
raw, forged, constructed and overapplied entry, descriptor changes before first
use, saved partials, mutation/reentry, prototype markers and public foreign rows.
Independent `review-local-data-01` additionally passes 99 complete-array oracle points, 12 full allocation/read/write schedules against a separate BigInt oracle, 24 alias/freshness scenarios, and 39 hostile public boundaries. Eager-write and omitted-zero-swap negative witnesses are retained. The frozen five-way timing plan covers n32 and n64 and awaits the root's exclusive timing grant.

Separate diagnostic modules at `local-data-counts-01` pass all 16 runs. For
n32/seed17:

| Named operation | Generic17 | Native private reference | Private setup | Plus Dp shell |
| --- | ---: | ---: | ---: | ---: |
| Apply | 1852 | 727 | 6 | 6 |
| Fn / partial | 1073 / 360 | 464 / 264 | 4 / 1 | 4 / 1 |
| Jump | 838 | 292 | 1 | 1 |
| Force entry | 1014 | 600 | 331 | 427 |
| Project | 355 | 258 | 161 | 130 |
| Build / ctor | 33 / 34 | 33 / 34 | 33 / 34 | 1 / 3 |
| Private helper copied slots | 0 | 384 | 384 | 256 |
| Array allocation / read / write | 4 / 128 / 129 | 4 / 128 / 129 | 4 / 128 / 129 | 4 / 128 / 129 |

The last variant additionally copies the four initial Dp fields once; that copy
is not included in the historical private-helper copy counter. Force entry is
a function-call counter: manually forcing each original field creates more
entries while eliminating the old build-stack traversal. These are mechanism
counts, not CPU shares or speed estimates. The complete Array schedule is the
important next semantic gate.

The Dp step keeps the exact four field thunks. Its fourth Array.set remains
pending until the original per-cell demand, after the first three fields have
been forced. A private immutable vector carries fields between cells; Array
handles remain shared unchanged. It reconstructs the public Dp and executes the
original zero-row swap at completion. Tuple helpers and Array storage remain
unchanged.

## Controlled comparison

The frozen screen passes all outputs in 19.20 seconds. Its stronger warmup effects are retained in `local-data-screen-01`; it is screening evidence. The unchanged confirmation in `local-data-confirm-01` passes every output in **210.18 seconds**, with five fresh samples per variant/point, three-second warmup (at least 100 calls), 300 ms timed target and rotating serial CPU3 order. Every call includes four allocations, setup, one complete row and full four-array serialization. No diagnostic module enters timing.

| Point | Variant | Median ms | Sample range ms | Half-change range |
| --- | --- | ---: | ---: | ---: |
| 32 | baseline | 0.415394 | 0.413367–0.418728 | -0.61% to +1.46% |
| 32 | private_native | 0.237987 | 0.236344–0.240236 | -1.21% to +2.89% |
| 32 | private_setup | 0.069109 | 0.068927–0.073823 | -2.79% to +3.02% |
| 32 | private_dp | 0.062612 | 0.062207–0.066535 | -1.09% to +1.23% |
| 32 | typescript | 0.008408 | 0.008365–0.008544 | +0.51% to +6.22% |
| 64 | baseline | 0.815666 | 0.808738–0.836924 | -1.57% to +4.80% |
| 64 | private_native | 0.449725 | 0.447275–0.454546 | -0.60% to +0.42% |
| 64 | private_setup | 0.112644 | 0.112363–0.113244 | -1.20% to +0.23% |
| 64 | private_dp | 0.103311 | 0.102690–0.103548 | -2.71% to -1.26% |
| 64 | typescript | 0.009485 | 0.009426–0.009510 | +1.29% to +2.28% |

The setup step and combined Dp step clear the prospective 20% improvement gate against the fresh native reference at both sizes. The Dp-only incremental result is reported separately; it is smaller than the setup gain. Ranges are sample extrema, not confidence intervals.

**Scope limitation:** the fixture pays generation and initialization for only one row. Complete edit distance performs 256 rows after one setup. These gains do not establish the speed of full edit distance, compiler throughput, or a production compiler implementation. The next transfer must cover the actual scalar `pair(p)` computation, followed by source-level generalization if justified.
