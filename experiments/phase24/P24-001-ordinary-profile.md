# P24-001: locate ordinary request cost

Prospective, 2026-09-29; owner root; scope installed Phase23 checker.
Hypothesis: after Phase23 fixes shared conversion, ordinary compiler checking is
still dominated by removable repeated work in frontend/checker or generated dispatch.
The alternative is diffuse unavoidable work, GC or startup. No optimization chosen.
Use CPU sampling and separate allocation sampling on frozen fac06128 source after
validated Base priming; attribute generated frames to source owners. These samples
are diagnostic and warmed; do not report them as benchmark improvements.
A follow-up hypothesis must identify an exact invariant and counterexamples before
production edits. See design/phase24/profile-and-coverage.md and the eventual
implementation/phase24/profile-and-coverage.md for outcomes. Preserve all attempts.
