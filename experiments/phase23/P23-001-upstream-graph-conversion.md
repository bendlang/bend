# P23-001: upstream update and shared conversion

Plan: [Phase23 design](../../design/phase23/upstream-graph-conversion.md).
Baseline: pushed Phase22 commitfb42457, pinb2111cf, APIade8ef02.
Target: upstream018751270e800bc222a93dad7f257083ee53a5f7.

Hypothesis: reusing the graph evaluator in conversion plus a rigid prepass can
pass new depth32 equality regressions without exponential expansion, while
preserving existing exact observations and the short checked development loop.

Status: investigate; no promotion or new-target speed claim. The assessment's
1GiB OOMs remain counterexamples to the old implementation. Implementation,
cost screens, negative attempts and decisions will be recorded separately in
implementation/phase23/upstream-graph-conversion.md.
