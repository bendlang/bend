# P29-002: known calls across matches

Status: frozen before acquisition; outcomes belong to the implementation report.

Hypothesis: a private saturated worker/direct loop removes nested unary calls,
partial descriptors and argument-array copying around a known matched function.
Use unchanged/worker-only/arithmetic-only/combined disposable copies to distinguish
interactions. Preserve the public partial descriptor, algorithm, Nat representation,
argument demand and bounded tail stack. See the
[design](../../design/phase29/generated-program-fast-loop.md).

A fast prototype does not establish a sound general emitter rule. Production
lowering needs a reviewed recognizer and checked emitted-code semantic controls.
Infeasible or unsound derivations are retained as negative evidence.

## Outcome

The disposable worker-only fixture improves1.38× with longer warmup; combined
with arithmetic it improves3.70×. The checked compiler's combined fixture improves
3.65×. Production uses the separately frozen narrow native Nat rule, preserving
public descriptors. Original Mandelbrot improves2.70× with longer warmup.

Attempt02 source admission and03 eager-guard stack failures are retained. Explicit
branch fences and bounded counts repair admission; a small witness fails on03
and passes on04. Broader record/match workers remain a proposed next experiment,
not implemented functionality. See the [report](../../implementation/phase29/generated-program-fast-loop.md).
