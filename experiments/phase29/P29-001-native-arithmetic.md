# P29-001: expose native arithmetic

Status: frozen before acquisition; outcomes belong to the implementation report.

Hypothesis: guarded inlining of saturated, identified native primitive operations
removes generic dispatch and exposes scalar arithmetic to the JS optimizer.
Compare unchanged/arithmetic-only generated copies and later checked Bend emitter
output. Preserve argument order, wrapping, shift/division behavior and fallback.
See [design](../../design/phase29/generated-program-fast-loop.md).

Falsifiers: incorrect or differently demanded results, identity/partial-call
counterexamples, no meaningful clean benefit, or a material transfer regression.
No production decision follows from a hand-edited emitted module alone.

## Outcome

Promoted in checked attempt04 after independent identity/numeric/order controls.
The arithmetic-only longer-warm fixture improves1.96×; the original Mandelbrot,
lexer and sorting arithmetic transfer improves2.02×/1.59×/1.20× in its separate
initial window. Final controlled measurements and warmup qualifications belong to
the [report](../../implementation/phase29/generated-program-fast-loop.md).
The rule handles54 identified native operations, with no runtime change.
