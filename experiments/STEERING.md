# Current compiler experiment strategy

Current authorization: sequential simplification, starting 2026-09-26.
[Overall design](../design/phase7/compiler_simplification.md).
Each phase has a design, implementation/validation and report, committed and
pushed before the next phase begins. There is no renewed historical time budget.

S0's [read-only report](../implementation/phase7/s0-report.md) is complete.
Production is unchanged at 16,509 lines / 509,937 bytes; the existing release
verifies. The pinned upstream remains `6018e28`. Prior conformance and timing
results retain their artifact scope; this audit does not improve those metrics.

## Immediate frontier

1. S1: implement only the reviewed 548-line retirement, targeting 15,961 lines.
   Verify source/block hashes, roots, genuinely checked builds and selected output.
   Preserve active graph evaluation, stack-safe freshening and public APIs.
2. S2: after S1 closes, write a bounded explicit-term/provenance migration design.
   Its former 2,500-line reduction allocation is not supported by S0's evidence:
   only 675 gross lines were identified before replacement costs. No unsupported
   target becomes a completion claim.
3. Later S3–S7 remain sequential, with 50% and 75% overall goals. Each completed
   phase must lower net source size and conceptual complexity and pass its gates.

Parallel agents may review independent parts of the active phase. No future-phase
source implementation while the current phase is open. Root owns integration,
release artifacts, commits and controlled timing. Ordinary work uses the existing
checked development workflow; full reproduction belongs to justified integration
gates. Use existing Node24.18.0 by absolute path or a process-local PATH; Clang's
availability must be restored/verified before native execution gates.

The interrupted Phase 6 steering is preserved byte-for-byte in the
[S0 snapshot](../implementation/phase7/s0-evidence/phase6-steering-at-start.txt).
Its candidates remain unpromoted unless a current phase explicitly adopts and
validates one. Existing failed provenance/Boolean/cache attempts remain failed.
