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
