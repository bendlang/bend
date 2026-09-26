# Current compiler experiment strategy

Current authorization: sequential simplification, starting 2026-09-26.
[Overall design](../design/phase7/compiler_simplification.md).
Each phase has a design, implementation/validation and report, committed and
pushed before the next phase begins. There is no renewed historical time budget.

S0's [read-only report](../implementation/phase7/s0-report.md) is complete.
S1's [retirement report](../implementation/phase7/s1-report.md) is complete:
15,961 lines / 494,957 bytes after removing548 obsolete lines. Fresh checked and
optimized selected APIs exactly match the prior release; the smaller-source
release is installed. Component checks,51 harness tests and21 focused controls
pass, with known diagnostic differences and raw setup failures retained.

## Immediate frontier

1. S2 is [complete](../implementation/phase7/s2-report.md): shared provenance trace,
   135 fewer lines, 15,826 total. Checked/focused/component/exact provenance gates
   pass; the validated release is installed. Explicit terms/direct spans remain
   deferred, and no full-source speed or fixed-point claim is added.
2. S3: implement the committed [authoritative-checker design](../design/phase7/s3_authoritative_checker.md).
   Revalidate the prior 140-line candidate against S2, including full frontend
   preservation and a serial accepted/rejected pilot. Retained type facts remain
   deferred until their replacement costs and validity are demonstrated.
3. S4–S7 remain sequential. The 50% and 75% milestones are still unachieved and
   unsupported by the current gross deletion inventory; do not fake their gates.

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
