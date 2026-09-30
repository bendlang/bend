# P25-003: JIT and scaling distinguish residual explanations

Owner: root; independent review after acquisition.
Status at freeze: investigate; correctness and timing unmeasured.

Hypothesis: representative emitted-program gaps remain after warmup and correlate
with hot generic runtime paths, missed direct loops or JIT instability. Compare
multiple sizes with clean alternating samples; use selected V8 traces and CPU
profiles separately. Do not infer deoptimization from a closure count. Stable
optimized functions with dominant generic dispatch would instead favor changing
the work expressed by the emitter. Startup-only gaps get their own classification.

See the [design](../../design/phase25/generated-code-analysis.md) for controls,
deadlines, unchanged compiler identities and evidence retention, and the
[report](../../implementation/phase25/generated-code-analysis.md) for outcomes.
