# Resolve literal native shift counts during compilation

Prospective experiment, 2026-09-30. Re-reading pinned TypeScript output reveals
another recurring difference after generic calls disappear. Our native shift
emitter still evaluates BigInt comparison and Number conversion for literal
counts such as8n and31n. Upstream emits numeric literal shifts, allowing ordinary
JavaScript constant folding. Mandelbrot's arithmetic-shift helper repeats both
operations three times per iteration.

First derive one diagnostic variant of the frozen private-BigInt-region helper
fixture. Change only the two literal shifts in its private asr8 helper. Preserve
the BigInt loop counter, region guards, public functions, helper calls, masking,
input point and fallback. Refuse derivation unless both exact call shapes are
present. Compare against the same unmodified region, Phase29 and pinned upstream.
The121 independent fixture/boundary points must pass before frozen exclusive
CPU3 screen and confirmation. This isolates literal shift lowering from the
separate numeric-counter experiment.

If supported, the compiler rule belongs in the existing primitive emitter,
after its native identity and telescope checks. Initially admit only a compact
native Nat literal after annotations. For shifts below32 emit the same unsigned
JavaScript shift with the numeric literal. For counts32or larger still evaluate
the left operand once, then return0; do not erase an effectful or throwing operand.
Dynamic counts, unknown constructors, wrong native identity and partial calls
keep the previous path. No global Nat representation change is required.

Production controls cover both directions, counts0/1/8/31/32/33/2^32-1, U32
boundaries, annotated literals, evaluation and error order, native provenance,
partial/overapplication and dynamic counts. Measure generated-program gains
separately from compiler acquisition and source size. Preserve unsuccessful
variants and do not combine a positive prototype with an unreviewed compiler.
