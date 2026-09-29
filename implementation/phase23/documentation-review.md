# Phase23 documentation review

Independent read-only review of `README.md`, `selfhost/README.md`,
`docs/BEND-IN-BEND.md`, `selfhost/CONFORMANCE.md`,
`selfhost/docs/ARCHITECTURE.md` and
[the main Phase23 report](upstream-graph-conversion.md), against
[the completed final cost screen](final-cost-screen.json) and the already
reviewed final frontend evidence. No new tests were run for this review.

No release-blocking discrepancy found. The current pin is
`018751270e800bc222a93dad7f257083ee53a5f7`; historical Phase22, old-pin and
version5 references are identified as history or retained implementation
policy. The guide explicitly states that version6 recognizes the new Base
dependency chain. Current installation claims refer to the final derived API
`5596f914fd245a5085a614b81099360aeaf601ed61f16357fc491c85106c1102`, with its
genuinely checked parent and guarded derivation, rather than a new fixed point.

The published 11.01 s versus 3.55 s, 3.10× TypeScript ratio, +0.39% process,
+0.52% request and +7.52% RSS versus Phase22 agree with the JSON values
(3.1008416874×, +0.3891079%, +0.5155985%, +7.5234671%). The unchanged-source
refreshed bundle is separately identified. Two samples, different Base-loading
policies, inclusion of startup/hashing, checking-only scope and concurrent
non-benchmark depth32 controls are disclosed. No broad speedup claim is inferred
from these near-neutral ordinary checking results.

The 3,026 main observations and 196 broader cases are finite, overlapping scopes.
The four raw later-emission failures are retained; request-history reuse,
pre-atomic integration evidence, unavailable TypeScript JavaScript TCP cases,
sanitizer limitations and excluded kernel/GPU/hub/fixed-point claims remain
explicit. The source census reports +148 lines, not a simplification gain.

Small editorial findings forwarded to the parent for correction:

- `docs/BEND-IN-BEND.md` says “Directional subtype checks cannot rewrite the
  graph.” More precise: “Directional subtype success never establishes symmetric
  sharing.” Evaluation still caches forced values, and equality sub-obligations
  can share after proof. The architecture and main report already use the
  narrower, correct statement.
- The main report's “arrays/RFC machinery” appears to mean arrays/reference
  counting (RC).
- The conformance and architecture introductions call the pin Bend2 2.0.34;
  “after Bend2 2.0.34” would match the root README and guide more exactly.

This review covers the observed document contents. The parent is still updating
component/evidence-publication paragraphs and the preservation receipt; those
future edits are not attested here.
