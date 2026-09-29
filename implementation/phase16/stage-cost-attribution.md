# Complete checking stage attribution

The [prospective plan](../../design/phase16/stage-cost-attribution.md) uses four
serial fresh processes, Phase15–wave4–wave4–Phase15, CPU0, with identical final
wave4 compiler input. Both images and their own validated Base caches are bound
by identity. `selfhost/build/phase16/stage-matrix-01/report.json` passes the
ordinary type-acceptance and exact unsafe-definition-set checks in every row.
This is diagnostic instrumentation, not a replacement for the ordinary timing
matrices.

| Boundary | Phase15 mean | Corrected wave4 mean |
| --- | ---: | ---: |
| Parsing | 2.660 s | 2.777 s |
| Loading and elaboration | 5.917 s | 7.125 s |
| Checking | 15.845 s | 14.730 s |
| Specialization | 1.846 s | 1.344 s |
| TODO scan | 0.203 s | 0.269 s |
| Trust report and unsafe-name list | 0.562 s | 0.691 s |
| Remaining host work and instrumentation | 0.126 s | 0.493 s |
| Complete instrumented request | 27.178 s | 27.447 s |

The baseline loader samples differ substantially (6.696 and 5.138 s), as do
checking (14.669 and 17.020 s) and specialization (1.223 and 2.470 s). Candidate
samples are close to each other. These two samples do not justify a claim that
checking became faster, or that the previously observed 11.88% cost disappeared.
Wrapping public API calls can alter optimization and garbage-collection behavior.
The original uninstrumented measurements retain their scope and status.

The clearest next investigation is loading and the host's source-validation
walks. Successful checking never calls the error-only origin reconstruction API;
that reconstruction cannot explain these loader samples. Inspect repeated
elaboration and allocation while carrying larger terms, and measure before
removing any work. Preserve all provenance validation at public boundaries.
The stage report retains raw per-call observations, full verdicts, affinity,
memory, exact source/API/runtime/Base/host identities and consumed tools.
