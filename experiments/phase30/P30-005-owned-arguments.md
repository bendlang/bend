# P30-005 — Fresh non-tail argument vectors need no defensive copy

Owner: root. Independent reviewer: phase30_review. Started2026-09-30.
Correctness:not run; measurement:not run; decision:investigate.

[Prospective design](../../design/phase30/owned-arguments.md) records the narrow
ownership proof. This is a separate mechanism from worker formation and loop
lowering. Public call, bound.concat, oversaturation copies and every tail-message
vector remain unchanged. First test immutable generated-JS variants on the
existing small Mandelbrot fixture; instrument counts separately from timings.
No arithmetic/representation/native identity changes are part of the ablation.
