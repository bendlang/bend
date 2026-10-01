# Phase36 normal checked compilation cost

The selected compiler greatly improves the two targeted programs' execution, but
does not establish a compilation-speed improvement. Normal request medians rise
**4.500% for symreg and 4.023% for raytrace** against the immediately preceding
release. These are possible compilation costs of the accepted changes. All four
observed baseline/candidate ranges overlap; that does not prove equal cost.

The baseline is Phase35 checked09, API
`467bc7dec2751a94cb677c5eb2da22a8fb69ee3522c6e164cb2bfcc147a78d82`.
The candidate is Phase36 checked03, API
`93e55ad7ee456eebb5fa3dd9606c2cf262ea386c6f66bfd891ffe187d8f50a75`.
Pinned upstream TypeScript remains
`018751270e800bc222a93dad7f257083ee53a5f7`.

## Measured requests

All **36 requests pass** in **254.736 seconds**: four fixed sources, three roles
and three fresh processes per role/source, with rotated order. Every emitted
module must exactly match its independently acquired checked output. The
unchanged normal checked-library worker is
`f0dea569bdb02df60ed1156b0cead389e197291f1c3a3c6775102c7a03790f42`.
This is the normal `inspect`/Base path for the self-hosted compiler and
`book_load`/`valid`/`js_lib` for TypeScript, not an emission-only microbenchmark.

Milliseconds per request: median **[observed minimum–maximum]**. Ranges are not
confidence intervals. Ratios use same-run medians, without removing outliers.

| Source | Phase35 | Phase36 | TypeScript | Candidate change | Candidate / TS |
| --- | ---: | ---: | ---: | ---: | ---: |
| local-pair | 1,721.342 [1,696.855–1,805.775] | 1,694.482 [1,694.429–1,707.228] | 313.149 [300.737–329.037] | −1.560% | 5.411× |
| Mandelbrot | 1,856.294 [1,852.309–1,897.044] | 1,864.166 [1,863.099–1,897.602] | 327.156 [327.002–331.747] | +0.424% | 5.698× |
| symreg | 1,985.074 [1,975.440–2,160.115] | 2,074.394 [2,062.266–2,083.194] | 289.420 [287.769–316.180] | +4.500% | 7.167× |
| raytrace | 2,586.862 [2,531.902–2,882.163] | 2,690.923 [2,685.013–2,746.018] | 409.436 [405.834–410.103] | +4.023% | 6.572× |

The symreg/ray increases are **89.320/104.061 ms per request** at these points.
Their baseline high samples remain in the record. Three samples are sufficient
to disclose the observed tradeoff, not to identify the cost of an individual
analysis pass. No stage attribution or statistically established neutral-cost
claim follows from this experiment.

## Timing boundaries and memory

Host import is separate. Median host import is 12.8–13.1 ms for Phase35,
13.2–13.7 ms for Phase36 and 218.6–221.4 ms for TypeScript across these sources.
The self-hosted compiler's lazy API loading and ordinary Base handling remain
inside the request. The import-plus-request medians below preserve that alternate
boundary; they are not sums of separately rounded medians.

| Source | Phase35 import + request | Phase36 import + request | TypeScript import + request |
| --- | ---: | ---: | ---: |
| local-pair | 1,734.213 ms | 1,708.041 ms | 531.741 ms |
| Mandelbrot | 1,869.260 ms | 1,878.677 ms | 548.532 ms |
| symreg | 1,997.973 ms | 2,087.606 ms | 508.194 ms |
| raytrace | 2,599.704 ms | 2,704.083 ms | 629.511 ms |

Receipt verification/preflight and process supervision also take time. They are
included in the 254.736-second experiment wall time, not in `requestMs`. The
largest observed process-tree RSS is **537,202,688 bytes** for Phase35,
**540,422,144 bytes** for Phase36 and **515,469,312 bytes** for TypeScript. These
are bounded-process peaks, not precise compiler heap attribution. Runs are
serial on CPU3 with Node24.18.0, a 1 GiB Node heap, 2 GiB process-tree RSS cap and
2 GiB available-memory floor.

## Source and emitted-code cost

Frozen checked snapshots give the following compiler source counts; generated
images, design/report files and experimental tools are excluded.

| Metric | Phase35 | Phase36 | Change |
| --- | ---: | ---: | ---: |
| Bend modules | 68 | 69 | +1 |
| Physical Bend lines | 18,050 | 18,174 | +124 (+0.687%) |
| Nonblank Bend lines | 15,436 | 15,545 | +109 |
| Definitions | 2,008 | 2,024 | +16 |
| Types / laws | 71 / 640 | 71 / 640 | unchanged |
| Bend source bytes | 725,068 | 733,685 | +8,617 |
| Runtime JavaScript lines | 630 | 655 | +25 |
| Runtime JavaScript bytes | 51,689 | 52,694 | +1,005 |

Every emitted module includes the runtime increase. Of the fifteen fixed catalog
points, thirteen have byte-identical complete program suffixes after their
verified frozen runtime prefixes. Symreg's suffix grows 1,440 bytes and ray's
186 bytes, giving total module growth of **2,445/1,191 bytes** respectively.
This [static comparison](static-prefix-comparison.json) establishes the scope
of emitted changes; it does not attribute dynamic costs.

The earlier eleven-line preflight experiment was independently
[rejected](cost-report.md). Its modest compilation results do not contribute to
this final compiler. The accepted phase pays a small source cost for the guarded
private execution and tree producer mechanisms; it is not a simplification or
line-count reduction.

## Evidence

The raw [cost report](../../selfhost/build/phase36/compiler-cost-run03/report.json)
has SHA-256
`a6b34fce941e8fd40135e7cb4e4bc04bd851fe4323eba699dc06dd7d222c5e87`.
The [plan](../../selfhost/build/phase36/compiler-cost-plan03/config.json) binds
the normal worker, exact source/compiler identities and expected emitted outputs.
[Final results](final-results.json) preserve the unrounded samples, timing
boundaries, memory observations and frozen-source counts alongside separate
execution/profile evidence. [Execution findings](execution-findings.md) report
the benefit being traded against these compilation costs.
