# Inert parser cursor: controlled cost result

The cursor representation adds **0.926% process time, 1.062% request time and
0.740% peak RSS** on this screening workload. It clears the prospective 5%
process-overhead threshold. This supports testing contextual parsing; the inert
representation itself fixes no conformance gap and remains uninstalled.

| Fresh-process lane | Mean process time | Mean request time | Maximum RSS |
| --- | ---: | ---: | ---: |
| Pinned TypeScript | 3.42387 s | 2.35550 s | 477,744 KiB |
| Installed Phase17 | 11.63390 s | 10.52959 s | 653,412 KiB |
| Inert cursor source02 | 11.74163 s | 10.64140 s | 658,248 KiB |

There are two samples per lane. The same-window TypeScript ratios are 3.398× and
3.429×. Do not add this overhead to the separately measured checker-world result:
the candidates are independent and their input sources and windows differ. A
combined semantic implementation would need its own measurement.

## Scope and controls

The unchanged Phase16 matrix tool runs TS/B/C/C/B/TS, fresh processes on CPU0,
Node24.18.0, stack4MiB and heap4GiB. Other agents closed compiler, probe,
compression and recovery jobs and held further CPU work throughout. Existing
system services and OS caches were left alone. All 35 frozen host files have
identical membership and SHA; runtime, Base and the maintained version5
derivation are unchanged.

All lanes check the identical assembled candidate source, SHA
`6ac781b59fa89d4ed8ccd92b6fdd2f8c681d6b8333da2a688f1dce6640d12a7c`.
Baseline API is `9b20de50`; candidate API is `5d19edf5`, derived from its genuine
checked B1. No probe instrumentation enters either timed API. All six lanes
accept ordinary types and report the expected unsafe-definition trust refusal,
with identical unsafe-definition sets. Trust does not pass.

Bend has independently validated Base caches; TypeScript checks Base. Request
time wraps adapter execution and lazy API load. Process time also includes
startup, hashing and output capture. This does not measure emission, generated
programs, sustained-server throughput or a self-hosted fixed point. The complete
raw output is `selfhost/build/phase18/cursor-matrix-01/`; the
[machine receipt](cursor-cost.json) binds inputs, readiness and all samples.

The [correctness report](cursor-representation.md) records 196 identical complete
outcomes, including 68 known strict differences, plus 194 direct controls and
equal raw/lowered Base and compiler books. The new context remains inert. Source
grows 77 physical lines, 13 definitions and two types across nine modules.

The separate counter probe observes 2,236,971 executed generated cursor
constructions for 192,461 compiler tokens, about11.62 per token. These are
constructor-expression executions, not measured physical V8 heap allocations;
JIT optimization can remove objects. The uninstrumented timing is the relevant
cost screen. No representation optimization is justified by that count alone.

## Next decision

Proceed to a private contextual-parser slice with explicit lexical names,
pattern checkpoints and scope restoration. Preserve raw public parser/loader
contracts deliberately. Reuse existing semantic operations and compare saved
error-order witnesses before any full migration. The alternative stopped-body
layer needs its own propagation and partial-scope machinery across at least27
owners, without removing the later scoping authority; the
[independent review](../../design/phase18/parser-semantic-slice-review.md) records
that tradeoff. Neither route has a demonstrated conformance or source-size gain
yet. The [prospective cost rule](../../design/phase18/representation_cost.md)
applies to this representation screen only.
