# Resolve final16 tree-bitonic warmup

The unchanged final16 transfer point passes its exact output, but both Bend
variants remain in a strong warmup transition: Phase29 improves by about
19–21% between sample halves and checked16 by about 17–18%. The observed
26.047 versus 26.938 ms medians therefore do not settle the small apparent
regression.

Freeze one separate diagnostic comparison before measuring it. Reuse the exact
three checked modules, `bench(8, 0)`, and expected result `971629740` from
`final-transfer-plan-16/tree-bitonic.json`. Use the established CPU3 long-warmup
runner unchanged: three alternating samples per side, a 15-second warmup with
a three-call minimum, and a one-second measured target. Preserve all raw
halves and process outputs. Do not alter or replace the original transfer
receipt and do not mix samples from the two windows.

The sides are pinned TypeScript, Phase29, and checked16. Every module, source,
emission receipt, checked16 attempt identity, original timing report, prospective
design, and existing runner is bound into the new plan. No emitted code or
runtime is rewritten. The plan is metadata preparation only; execution requires
a fresh explicit timing grant after the active final batch and planned
Mandelbrot confirmation finish.

Interpretation is narrow. Agreement after warmup would classify the transfer
difference as unresolved transition cost rather than settled throughput loss.
A persistent difference with disjoint ranges and small half drift would retain
that regression for source-level diagnosis. Continued large drift remains an
inconclusive result; this plan does not authorize repeated windows or tuned
warmup lengths. Report medians, ranges, and both-side half drift regardless of
outcome.
