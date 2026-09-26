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
2. S3 is [complete](../implementation/phase7/s3-report.md): one authoritative
   checker result, 139 fewer Bend lines, 15,687 total; host adds2lines. All2,756
   fresh frontend observations match S2 exactly;318strict failures remain.
   Components,52harness tests and focused controls pass. Late rejection is about
   33.5% faster by request with accepted overhead below0.7%; resource guards pass.
   The validated release is installed and raw evidence preserved.
3. S4 has an installed [bounded checkpoint](../implementation/phase7/s4-report.md):
   14,667 physical / 12,505 nonblank lines / 470,062 bytes. The rejected 425-law
   draft lost two exports; corrected A02 retains them and passes genuine B1→H→H.
   B01 shares loader/error/list operations and preserves all 2,756 observations;
   serial host and graph runtime/RSS guards pass. B02 moves generic joins beside
   their datatypes and produces identical checked/default compiler bytes. Release
   integrity and ordinary/relocated check/interpreter/JS/CPU-native smoke pass.
   The final serial ABBA checked/focused loop is about 35 seconds, within
   ±0.8% paired wall cost and +3.3% RSS; its guards pass.
4. The 50% milestone remains **open**, with another 6,413 lines required. The
   continuation-fusion proposal was falsified by pinned language syntax; the
   other architectural savings remain unfunded. Further implementation requires
   a new bounded architectural hypothesis and deletion/replacement budget inside
   S4. Do not advance to S5–S7 or claim the 50%/75% targets were achieved. Review
   context is not uniformly smaller after including new validation obligations.

Parallel agents may review independent parts of the active phase. No future-phase
source implementation while the current phase is open. Root owns integration,
release artifacts, commits and controlled timing. Ordinary work uses the existing
checked development workflow; full reproduction belongs to justified integration
gates. Use existing Node24.18.0 by absolute path or a process-local PATH; Clang's
19.1.7 was restored locally for S4; its package identities and reproduction
procedure are preserved with the report. Recheck availability before new native gates.

The interrupted Phase 6 steering is preserved byte-for-byte in the
[S0 snapshot](../implementation/phase7/s0-evidence/phase6-steering-at-start.txt).
Its candidates remain unpromoted unless a current phase explicitly adopts and
validates one. Existing failed provenance/Boolean/cache attempts remain failed.
