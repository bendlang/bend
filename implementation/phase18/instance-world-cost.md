# Checker world representation: controlled cost result

Carrying checker state has no material measured cost on this screening workload.
It clears the prospective 5% process-overhead threshold. It does not establish a
speedup, fix error order, or justify installing the representation alone.

| Fresh-process lane | Mean process time | Mean request time | Maximum RSS |
| --- | ---: | ---: | ---: |
| Pinned TypeScript | 3.40979 s | 2.34033 s | 475,544 KiB |
| Installed Phase17 | 11.71029 s | 10.54375 s | 633,056 KiB |
| World source03 | 11.68392 s | 10.58514 s | 635,716 KiB |

Process time falls 0.225%; request time rises 0.393%; peak RSS rises 0.420%.
Those small changes, from two samples per lane, do not establish a general
performance difference. The same-window TypeScript ratios are 3.434× and 3.427×.
Earlier release measurements used other sources/windows and are not combined
with this result.

The six process samples in execution order are TS 3.41651 s, baseline 11.69161 s,
candidate 11.66817 s, candidate 11.69967 s, baseline 11.72898 s, TS 3.40306 s.
Every lane accepts ordinary typing and reports the expected unsafe-definition
trust refusal; all unsafe-definition sets agree. This is not a proof-trust pass.

## Controlled scope

The unchanged Phase16 `check-matrix-v2.mjs` consumes prospective Phase18 matrix
inputs and complete host review. All 35 frozen host files have identical
membership and SHA. Runtime, pinned Base and version5 derivation are unchanged.
The two APIs check identical assembled source03, SHA
`dee402a8130092ebfc8e844b8874bf5455aeb87f473a579ae4519f3895ed40b6`.
Baseline API is `9b20de50`; candidate API is `dc884368`, derived from its genuine
checked B1. Only five compiler source modules differ.

The sequence is TS/B/C/C/B/TS, fresh processes on CPU0, Node24.18.0, 4MiB stack,
4GiB heap. The other three agents closed compiler/probe/compression/recovery jobs
and held new jobs throughout. Existing system services were left alone. Each
Bend API uses its independently validated Base cache; TS checks Base. OS caches
were not flushed. Request timing wraps adapter execution including lazy API load;
process timing also includes startup, hashing and output capture. No emission,
generated-program execution, sustained-server throughput or fixed point is timed.

The [prospective decision rule](../../design/phase18/representation_cost.md), raw
six-lane report, readiness acknowledgements and complete identities are referenced
by the [machine receipt](instance-world-cost.json). The output is
`selfhost/build/phase18/instance-world-matrix-01/`; no sample is removed or replaced.

## Decision and remaining work

The [correctness checkpoint](instance-world-correctness.md) preserves 22 targeted
results, including both known TS diagnostic-order differences, and passes 42
direct controls plus eight memo/name fixtures. Source grows 87 physical lines,
13 definitions and two types; no semantic visitor is removed.

Review found a compatibility boundary outside those whole-program results:
exported `specialize_book` exposes an enlarged KChecked through KSpecialized.
The projectors and DResult observations remain unchanged, but the raw payload
shape is not preserved. Resolve that in Bend with a stable public projection
before promotion; do not describe this experiment as full public ABI equivalence.
Then test ordered child-state propagation and immediate instance checking using
the existing checker. This source03 remains an isolated, uninstalled ablation.
