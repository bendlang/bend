# P28-001 — broader existing-program speed comparison

Frozen before acquisition. Question: do the large slowdowns in targeted traversal
kernels also occur in a broader mix of existing upstream algorithms and mixed
tests? No expected ratio is assumed; selection precedes measurements.

[Design](../../design/phase28/broader-program-comparison.md),
[results](../../implementation/phase28/broader-program-comparison.md).

Correctness: pending exact outputs on the same checked source and inputs.
Measurement: pending separately scoped first-call/warmed or process-level timing.
Decision: investigate; no compiler change or release promotion planned.

The design names all six runtime algorithms, four tiny integration tests and
the larger application attempt. Preserve every failure and all samples. Keep
unsupported cases visible and avoid claiming selected small inputs establish
typical production throughput or a whole self-emitted compiler speed ratio.
