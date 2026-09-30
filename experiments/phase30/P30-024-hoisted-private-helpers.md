# P30-024 — Hoist private helper declarations out of repeated roots

Owner and semantic reviewer: phase30_review; independent scope audit:
phase30_analysis; timing: phase30_prototype. Retrospective index of the frozen
[hoist design](../../design/phase30/hoisted-private-helpers.md).

- Invariant: preserve private lexical dependencies, initialization order,
  complete entry guard and generic fallback; no public callable changes.
- Correctness: helper/tree/entry/initialization/forward-reference controls pass.
- Measurement: short whole-program screen suggests 5.8% throughput gain, but
  the prospectively frozen 15-second confirmation shows baseline 0.265628 versus
  hoisted 0.270437 ms: overlapping ranges and 1.81% slower candidate median.
- Decision: defer. The smaller emitted module does not justify roughly 90–160
  lines of compiler plumbing without a measured execution improvement.
- Falsification: the isolated experiment removed the suspected allocation
  mechanism without a warmed speed benefit. Allocation syntax alone did not
  identify an actual steady-state bottleneck.

The [hoist report](../../implementation/phase30/hoisted-private-helpers.md)
is canonical; `hoist-screen-01` and `hoist-long-confirm-01` retain both outcomes
with exact source/runtime/control/config identities. No production source
change followed. Large raw packaging remains campaign consolidation work.
