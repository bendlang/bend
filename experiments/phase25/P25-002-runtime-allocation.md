# P25-002: executed runtime machinery explains emitted-program cost

Owner: root; diagnostics: history_conformance.
Status at freeze: investigate; correctness and timing unmeasured.

Hypothesis: runtime argument arrays, matcher/closure construction and trampoline
messages account for substantial allocation and CPU work in selected corpus cases.
Use separately instrumented copies, independent counters and sampled allocations
including collected objects. Check exact outputs and tiny counter controls.
No allocation frequency, heap size or syntax count is treated as time saved.
Missing dynamic evidence or hot costs elsewhere weakens/refutes the explanation.

Instrumented copies stay private diagnostics; never change the installed runtime.
See the [design](../../design/phase25/generated-code-analysis.md) for controlled
setup and [report](../../implementation/phase25/generated-code-analysis.md) for
all attempts and the final decision.
