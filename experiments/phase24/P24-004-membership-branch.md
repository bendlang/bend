# P24-004: direct Boolean membership branch

Prospective, 2026-09-29. Baseline CPU02 has_name owns127.5ms exclusive CPU;
allocation02 assigns465.6MB (5.01% of sampled allocations) to this tiny helper.
The function currently builds lazy Unit branch closures for each list miss.
Hypothesis: direct matching on the computed Boolean lets the existing bootstrap
compiler lower tail recursion as a loop, removing per-miss closures/messages.
Preserve exactly one String.eq on each demanded head, first-hit short circuit,
miss order, empty result and malformed unused-tail non-demand. No helper, datatype,
cache, representation or altered String contract is needed. This is the same
measured allocation pattern as earlier lookup workers, now in a different helper.

Freeze this source idea before editing. Check generated output, focused checked
B1, direct finite-list/duplicate/Unicode/surrogate and unused-tail controls, then
full frontend/selected histories. Measure final bundle against released/local-only
and TypeScript in serial samples; don't infer performance from instrumented runs.
If direct matching fails checked emission or measured benefit, preserve and reject.
