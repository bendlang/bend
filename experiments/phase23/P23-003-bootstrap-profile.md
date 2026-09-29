# P23-003: retain guarded bootstrap optimizations after Base simplification

Hypothesis and prospective gates were frozen in the Phase23 migration design.
The new Base changes the equality dependency chain while retaining the emitted
library runtime bytes. A separately guarded profile can preserve string and
choice optimizations without weakening source, body, export or provenance checks.

Version6 guards String.eq, String.order, Pair.snd, Cmp.is_eq and the existing
String/Char comparison closure. Auto selection uses runtime plus equality-body
identity; explicit old profiles keep exact replay. The first checked build and
derived image passed36 focused controls;151,084 primitive pairs, nine mutation
refusals and byte-for-byte replay of versions1–5 passed. Independent review is
linked from implementation/phase23/profile-review.md.

Decision: retain for integration. Full request histories and final installed
release verification remain separate gates; this is not a new self-emitted image.
