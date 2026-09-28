# Current compiler experiment strategy

Current authorization (2026-09-28): optimize further and reread pinned TypeScript.
The [Phase11 design](../design/phase11/known_work.md) preceded implementation.
No historical time budget is renewed. Preserve unrelated Phase6 dirty work.

## Phase11 release frontier

The [report](../implementation/phase11/known_work.md) integrates lazy offload
lookup, one shared constructor telescope, bounded native open-Succ compaction
and guarded literal-choice lowering in the checked B1 derivative.
Upstream remains b2111cf; selected API is
`63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f`.
The `equality` profile now selects version4, with exact v1/v2/v3 replay.

Controlled full-source checking is **29.73 s**, versus **51.44 s** Phase10 and
**2.79 s** pinned TypeScript: **1.73× faster**, with a **10.67×** process gap.
The same-source six-process matrix excludes emission; maximum RSS falls modestly.
Nat300 JS is **24.45→15.61 s (1.57×)** with identical generated JS.
Native C emission is **27.03→3.61 s (7.49×)**, and C shrinks **98.69%** to269KB.
That exact C builds with Clang16 and returns306n; emission timings exclude Clang.
All matrices pause intentional competing compiler/archive jobs and retain failures.

All1,001 positive frontend fixtures check; all482 validation negatives reject.
The former long-string stack overflow passes at the same4MiB stack, reproduced
by choice lowering alone with unchanged Bend source. This is not compact strings.
Other2,995 observations match Phase10. There are730 exact TS differences
(198parse/532check); four imported-law trust cases still fail early.
No invalid acceptances/timeouts were observed;37paired backend rows pass.

Source is15,138physical/12,923nonblank Bend lines, +31/+28 overPhase10; two helpers,
one law and two private native tags are added. Simplification50%/75% goals remain
open. No new self-hosted fixed point, proof-kernel/GPU gate or general runtime
speedup is claimed. The checked/focused development observation is23.54s.

Duplicate exact-comparison work is deferred for inconsistent benefit; delayed
normalizer fallback remains unimplemented. New speed work should first profile
this final artifact. Imported-law fills and exact diagnostics are the next
semantic priorities. Keep checked B1, derivatives and self-emitted artifacts
distinct. Invalid call microtimings with EPERM remain excluded.

## Phase10 baseline (historical)

The [report](../implementation/phase10/repeated_work.md) preserves loader/index/
layout changes. Its older-source result was51.75s versus67.04s Phase9 and2.89s TS.
Do not combine that ratio with Phase11's same-source matrix. It preserved all
2,996 Phase9 observations, with one positive string failure. Native Nat300 emitted
20.59MB and exceeded the90s Clang build limit. All artifacts remain preserved.

## Phase9 release frontier (historical)

The [Phase9 report](../implementation/phase9/checker_speed.md) records immutable
`integrated-03`, chronological checker reuse, conversion/lambda/lookup reductions,
guarded native equality, descent repairs and compact Nat literals. Its own older
final-source comparison was 66.84 s versus 208.22 s Phase8 and 2.94 s TypeScript
(3.12× improvement, 22.74× gap). Different-source measurements must not be combined
with Phase10 ratios. The exact frontend vector is the Phase10 regression baseline.

## Consolidated Phase8 frontier (historical)

The [migration checkpoint](../implementation/phase8/upstream_and_conformance.md)
was installed and validated against upstream b2111cf (2.0.32 era). It has a genuine
checked B1 and independently preserved source/host/runtime identities, no fallback,
30 ordinary/relocated release checks, and the best validated S4 simplifications.
The rejected generic binder/evaluator prototypes remain unpromoted.

Fresh paired frontend evidence covers 2,996 observations: 997/1,001 positives
accept types,481/482 validation negatives reject, one negative times out and
zero are observed incorrectly accepting. Seven migration false acceptances are
fixed. There are 734 exact differences; four positive literal cases and four
imported-law trust cases remain. Do not call this full upstream equivalence.

The controlled current full-source checking workflow takes 205.26s versus 2.80s
for TypeScript (73.20× process wall); it excludes emission and does not replace
the historical full-compilation ratio. Short checked-bootstrap/focused iterations
take about 27s in the recorded integration attempt. Use those for routine work.

Next bounded priorities are compact literal semantics, imported-law fills, and
checker profiling/validated adaptation of guarded equality. Diagnostic carets
are a separate exact-compatibility gap. Do not broaden into generic walkers or
an unconditional checked-output prototype without new discriminating evidence.
A new full fixed point, broader native/runtime equivalence and GPU execution are
separate future gates, not inherited claims. No historical time budget is renewed.

## Historical Phase7 checkpoints

S0's [read-only report](../implementation/phase7/s0-report.md) is complete.
S1's [retirement report](../implementation/phase7/s1-report.md) is complete:
15,961 lines / 494,957 bytes after removing548 obsolete lines. Fresh checked and
optimized selected APIs exactly match the prior release; the smaller-source
release is installed. Component checks,51 harness tests and 21 focused controls
pass, with known diagnostic differences and raw setup failures retained.

## Previous simplification frontier

1. S2 is [complete](../implementation/phase7/s2-report.md): shared provenance trace,
   135 fewer lines, 15,826 total. Checked/focused/component/exact provenance gates
   pass; the validated release is installed. Explicit terms/direct spans remain
   deferred, and no full-source speed or fixed-point claim is added.
2. S3 is [complete](../implementation/phase7/s3-report.md): one authoritative
   checker result, 139 fewer Bend lines, 15,687 total; host adds2lines. All 2,756
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
gates. Use existing Node 24.18.0 by absolute path or a process-local PATH; Clang's
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
