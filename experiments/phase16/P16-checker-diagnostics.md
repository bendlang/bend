# P16-checker-diagnostics — preserve the first structured checker failure

Owner:phase15_behavior; reviewer:root. Prospective plan frozen before execution.
Correctness:unchecked. Measurement:not run. Decision:investigate.

[Design](../../design/phase16/checker-diagnostics.md) freezes the hypothesis,
ownership, strict55-observation selection and boundary controls. Cheapest
disproof:a preserved DTrace changes primitive acceptance/order or an unrelated
existing exact diagnostic. First candidate edits only kernel.bend/trace.bend;
span and parser changes are separate experiments.

Use maintained checked B1 workflow run checker-source-01/config.json into a new
checker-build-01, then validate checker-selection.json into checker-focused-01.
No compiler jobs during root's exclusive timing. Commands, tool/source hashes,
raw reports and all failed attempts stay in selfhost/build/phase16/checker-*.
Root owns full conformance, exclusive timing, integration and commits.

Outcomes:[checker report](../../implementation/phase16/checker-diagnostics.md).
