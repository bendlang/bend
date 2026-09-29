# P16: diagnose populated-range checking cost

Prospective profile investigation after the completed exclusive
`populated-span-matrix-01`. On identical assembled integration03 source, Phase15
averages 25.5882 s and integration03 28.1905 s (+10.17% process, +10.61% request).
TypeScript averages 2.8902 s. Both samples per image pass the workload's ordinary
type/trust checks. Peak RSS is 1,452,500→1,478,180 KiB (+1.77%). This exceeds the
phase design's 3% investigation threshold. Integration03 also retains known
conformance failures; it is not selected regardless of timing.

First compare diagnostic CPU profiles on the identical source, CPU0, same resource
limits and validated caches as the matrix. Profiles run concurrently with other
agents' correctness work and cannot supply speed ratios. Preserve complete raw
profiles and streamed summaries, including failures.

Leading hypotheses:

1. Rebuilding a node and then copying it again to preserve a range adds allocation
   and projector work across scope/freshening/normalization. Inspect allocation
   sites and sampled callers before collapsing constructors.
2. Indexed lexing traverses token text again for UTF16 widths and adds repeated
   cursor arithmetic. Inspect parser/lexer samples and distinguish necessary
   Unicode accounting from avoidable rescans.
3. Host source/cache range validation adds graph traversal and hashing. Inspect
   host samples and ensure existing immutable cache validation is reused.
4. Unrelated combined checker/parser work or sample variation contributes to the
   measured difference. Do not attribute the entire 10% to representation without
   a controlled component ablation.

Choose one bounded change based on those observations. Range ownership, original
error order and exact checked behavior remain invariants. Reuse existing numeric
fields and common-child reconstruction where possible; no new runtime rewrite is
justified by this profile alone. A surviving candidate needs exact focused gates,
the full integration gate and a confirming exclusive matched-source comparison.
No theoretical profile share is a promised recoverable gain.
