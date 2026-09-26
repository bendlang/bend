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

1. S2: write and freeze a bounded explicit-term/provenance design before code.
   S0 found only675 gross lines before replacement; the old2,500-line allocation
   is unsupported. Start with a falsifiable end-to-end slice and account for all
   variants, metadata, bridges and host costs. No increase can complete a phase.
2. S3–S7 remain sequential, with50% and75% overall goals. Keep checked facts,
   binding changes and backend factoring out of the S2 implementation until their
   own designs/gates. Prior proven narrow candidates remain available as evidence.

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
