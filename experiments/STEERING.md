# Current compiler experiment strategy

Current authorization (2026-09-28): further optimization, including larger changes
and rereading pinned TypeScript. [Phase11 design](../design/phase11/known_work.md)
was committed as `cf29bae` before candidate implementation. No old time budget is
renewed. Baseline is released Phase10 `5f561c4`; production remains unchanged.

## Phase11 investigation

Fresh final-release profiling owns CPU0. Independent bounded owners compare
pattern reconstruction/native expansion, checker normalization, and branch/call
lowering with pinned TypeScript. Plans precede probes; isolated checked candidates
precede review/integration. Root owns controlled comparison, release and archive.
Outcomes: [Phase11 report](../implementation/phase11/known_work.md).

## Phase10 release frontier (baseline)

The [Phase10 report](../implementation/phase10/repeated_work.md) integrates
conditional loader membership, loop-emitting index workers and typed/Nat layout
validation. Immutable `integrated-01` targets unchanged upstream b2111cf. Its
selected API is `ff876a357db2d44d3e1fbd37ab694a16d2fa0f47d60c9d500603e634c8c645f9`.

Controlled checking of the same final source takes **51.75 s**, versus **67.04 s**
for Phase9 and **2.89 s** for TypeScript: **1.30× faster**, with a **17.93×**
process-wall gap. Two serial fresh samples per compiler run on one CPU. This
excludes emission; memory stays about 1.5 GiB. The separate Nat300 JS process falls
34.17→24.74 s (1.38×), with identical generated JS; layout falls 9.48→0.50 s (19.09×).
Native Nat300 still emits 20.59 MB C and exceeds the 90 s Clang build bound.

All 2,996 frontend observations match Phase9 exactly:1,000/1,001 positive types,
482/482 negative refusals, zero observed invalid acceptances/timeouts,731 exact
TypeScript differences. Long strings and four imported-law trust cases remain.
No new self-hosted fixed point, Lean/GPU gate or general runtime improvement is
claimed. The source grows 57 lines to 15,107; 50%/75% reduction goals remain unmet.

Use the checked build/focused loop (observed 26.19 s) and small discriminating
probes for routine work. Next semantic priorities are compact strings and
imported-law fills. Next speed work should profile the final release afresh and
investigate repeated reconstructed pattern terms/native code expansion. Keep
whole-compiler measurements separate from operation and component speedups.
Preserve unrelated Phase6 work; all intentional compiler/archive jobs pause for
controlled comparisons. Failed and superseded attempts remain evidence.

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
