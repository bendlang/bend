# P32-004: compact-analysis

Status at creation: investigate; no measurement or promotion.

Hypothesis: Repeated region analysis or an unnecessarily costly representation contributes enough compilation cost to justify a compact plan.

Domain, proof obligations, ownership, falsification and integration gates are in
[the campaign design](../../design/phase32/representation-and-reuse.md).
The owner must freeze the exact derivative and measurement plan before timing.
Failures and neutral outcomes remain evidence; no gain is presumed.

Results will be linked from [the Phase32 report](../../implementation/phase32/README.md).

Completed without production promotion. Query repetition is real, but global
wrappers and scoped 4k/16k memo variants fail prospective speed criteria. The
16k run does not saturate: edit improves 3.32%, Mandelbrot 2.19% with overlap,
and the small case worsens 5.16%. No new IR is justified by this evidence.
[Report](../../implementation/phase32/compact-counts.md).

A subsequent duplicate stop-list query probe is promising on two cases, but
the proposed default-API ownership check fails an executed mutation witness.
The production driver remains unchanged.
[Boundary and measurements](../../implementation/phase32/compact-stop-reuse.md).
