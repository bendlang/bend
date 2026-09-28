# Current compiler experiment strategy

Current authorization (2026-09-28): update to current upstream, improve
conformance, and retain the best validated simplifications. The
[Phase8 design](../design/phase8/upstream_and_conformance.md) supersedes the
percentage-reduction-first strategy. The historical 50%/75% goals remain unmet;
they no longer block migration or correctness work. No historical time budget
has been renewed.

## Active Phase8 frontier

1. Freeze S4 B02 (`69947fc`) and old upstream `6018e28` as the control; release
   integrity passes. New target is immutable `b2111cf` (2.0.32-era), verified
   against upstream main. Keep its checkout separate until migration is validated.
2. Adapt bootstrap APIs and test real checked output/host ABI before any speed
   claim. Preserve full source checking and reject holes. Internal Number Nat
   does not imply a changed public BigInt ABI.
3. Migrate upfront declarations, current Base, language/namespace changes and
   conformance oracles. Retain authoritative errors/shared provenance. Revalidate
   prior Phase6 fixes against the new target instead of replaying their old claims.
4. Validate changed JS/native runtime boundaries, measure frozen candidates,
   install one usable compiler only after appropriate gates, and publish reports.

Root owns integration/release/timing. Agents own only explicitly assigned files.
Old pin/reference source remains an immutable control; merging the new upstream
commit and changing the active pin is explicitly authorized. Rejected Phase7
semantic-value and generic-walker prototypes remain unpromoted. Checked-output
ownership is deferred behind the upstream/conformance migration.

## Historical Phase7 checkpoints

S0's [read-only report](../implementation/phase7/s0-report.md) is complete.
S1's [retirement report](../implementation/phase7/s1-report.md) is complete:
15,961 lines / 494,957 bytes after removing548 obsolete lines. Fresh checked and
optimized selected APIs exactly match the prior release; the smaller-source
release is installed. Component checks,51 harness tests and21 focused controls
pass, with known diagnostic differences and raw setup failures retained.

## Previous simplification frontier

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
   other architectural savings remain unfunded. The old S5–S7 simplification sequence is deferred by the new migration
   authorization; do not claim the 50%/75% targets were achieved. Review
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

## Architectural research inside S4

The [first comparison](../implementation/phase7/architecture-report.md) is complete.
P7-A01 checked output helps compile preparation but penalizes check-only requests;
its unconditional implementation is not promoted. P7-A02 semantic values help a
substitution-heavy workload but regress closed data and memory; demand-order
counterexamples and fixes remain preserved, including a final unresolved
All-domain demand regression. P7-A03 runtime shared binding
traversal is rejected: larger source and slower operations. All are isolated,
actually checked prototypes; production/default source remains unchanged.

The next bounded hypothesis is A01 output/discard policy before allocation,
followed by a real annotation-pass deletion boundary only if both workload lanes
pass. No savings are earned yet. Five alternative ideas remain deferred in the
[design](../design/phase7/architectural_experiments.md). Keep measured operations,
full compiler throughput, correctness and promotion separate. No new TypeScript
ratio or conformance reduction was measured, and the 50% milestone remains open.
