# Compiler experiment ledger

This ledger records decisions and links evidence; it does not replace the reports.
Read [workflow](README.md) and [current strategy](STEERING.md) before a new investigation.
User objective: make the Bend compiler written in Bend and its validation loop much faster while preserving correctness. The current authorized optimization window ends about 20:16 UTC on 2026-09-22.

## Migration checkpoint — 2026-09-22, 17:13 UTC

The file workflow is adopted during Phase 4 in response to the user's `rom1504/math` suggestion. These records summarize already completed or active experiments; they were not preregistered. Existing designs, detailed reports and raw evidence stay in place. Earlier phases remain indexed by their reports rather than being retroactively relabeled as this wave.

| ID | Experiment | Decision at checkpoint |
| --- | --- | --- |
| [P4-001](phase4/P4-001-private-calls.md) | Private compiler calling convention | Accepted |
| [P4-002](phase4/P4-002-indexed-book.md) | Indexed final-definition selection | Accepted |
| [P4-003](phase4/P4-003-telescope-facts.md) | Reuse substitution-invariant telescope suffixes | Accepted |
| [P4-004](phase4/P4-004-projection-layout.md) | Projection copies and direct child access | Deferred |
| [P4-005](phase4/P4-005-normalization-shortcut.md) | All/ADT weak-head shortcut | Rejected |
| [P4-006](phase4/P4-006-tag-comparisons.md) | Direct private tag comparisons | Rejected |
| [P4-007](phase4/P4-007-nullary-sharing.md) | Share private nullary values | Deferred |
| [P4-008](phase4/P4-008-native-flags.md) | Native PGO and compiler flags | Deferred |
| [P4-009](phase4/P4-009-stability-memo.md) | Memoize completed private stability facts | Pending |
| [P4-010](phase4/P4-010-wnf-pair-memo.md) | Memoize private weak-head normalization | Rejected |
| [P4-011](phase4/P4-011-ordinary-uncurry.md) | Flatten ordinary partial-call chains | Rejected |
| [P4-012](phase4/P4-012-boolean-matchers.md) | Specialize exact private Boolean matchers | Pending |
| [P4-013](phase4/P4-013-edit-loop.md) | Checked B1 rebuild and persistent focused validation | Accepted |
| [P4-014](phase4/P4-014-full-profile.md) | Full-source inspector sampling | Rejected |

“Accepted” means the stated implementation/boundary is supported by the linked gates, not complete language conformance or a universal speedup. “Rejected” includes valid transformations that did not help; it does not necessarily mean semantically incorrect. “Pending” is not promoted.

### Updated frontier

The combined source has completed checked self-reproduction: both H stages have SHA `b33b38e32a263bf78e1d43cf459b7abf9a41d78d112d71a25f87ddba7bd09bf8`. Full frontend observations remain unchanged, with 560 existing differences from pinned TypeScript. The actual focused developer loop is already seconds rather than a full-build iteration.

Prioritize a controlled full-source private-image comparison and the reviewed Boolean/stability combination. Keep the unchanged control image. Do not revisit weak-head memoization, direct tag comparisons or ordinary-function uncurrying without explicitly overcoming their recorded obstruction. Native O2 is a proven useful full-source lane; PGO setup is a separate amortization decision. Large term-layout migration remains an open research direction, not an inferred requirement.

Next wave must use the current [strategy](STEERING.md), specify the quickest falsifying check, and preserve exact output and resource evidence before promotion. Update this frontier after each material decision; preserve the older entry as history.

## Full-source private-image counterexample — 2026-09-22

[P4-016](phase4/P4-016-private-lexical-scope.md) records a lexical-scope bug found
by the whole-source gate. The canonical private image completed checking but
failed emission with `F is not defined`. Specialized workers had been
hoisted out of their generated helper-table blocks. The 602-second failed run
is retained and provides no successful-compilation speedup. The public compiler's
fixed point and earlier scoped observations remain valid.

The new small comparison passes all 54 observations, with successful B1 requests
7.6%/12.8% faster. A negative-case regression is retained; a separate five-round
confirmation finds a smaller 4.9% request regression, with all 15 exact outcomes.
See [the complete comparison](../implementation/phase4/small-comparison.md).

### Updated frontier

Correct the private lexical-scope transformation first, using a tiny reproducer
and independent review, then issue new image identities and repeat the affected
full-source gate. Other prototypes remain experimental. Do not multiply their
standalone gains: the four-way Boolean/stability comparison already shows
interactions and run variation. The exact Con-arm pilot
[P4-015](phase4/P4-015-exact-con-arms.md) is rejected for inconsistent material
benefit; retain its proof and measurements without escalating to a full build.

## Private scope correction — 2026-09-22

The fix for [P4-016](phase4/P4-016-private-lexical-scope.md) is independently
reviewed. Only proven module-level generated functions can be hoisted; captured
workers use the original closure. Twenty-five package tests and fourteen actual
split-worker controls pass. The escaped-string fixture's actual output equals
public H byte for byte. The new private image is `61e7d94c…`; its full-source
request is running under the original resource limits.

### Updated frontier

Complete that full-source gate and regenerate the Boolean/stability comparison
on the corrected base. The original four-way results remain scoped historical
evidence. Prioritize exact final-image frontend observations once the candidate
is chosen. Archive principal checked artifacts so later investigations can start
from verified bytes without repeating an eleven-minute emission solely to
recover their starting image.

## Corrected combined private candidate — 2026-09-22

[P4-019](phase4/P4-019-private-combined-profile.md) records the freshly rebased
four-way experiment. All 48 selected observations agree exactly. Combined
Boolean/stability specialization reduces core request median 26.902→23.855
seconds (11.3%), with all three pairs improving and no observed peak-RSS increase.
Focused Boolean, graph, changed-source/import, escaped-string and package
provenance controls pass. The earlier matrix stays separately archived because
its original base had the lexical-scope bug.

The corrected default private image has completed whole-source compilation with
exact H bytes. Its 780.022-second process and 778.536-second request observations
are single-run results; they are not paired medians. The combined candidate's
whole-source and exact frontend gates are running. Canonical profile integration
is staged only, leaving the default and all active tool identities unchanged.

### Updated frontier

Finish and independently review those final candidate gates before exposing the
named profile. Require exact output and retained resource evidence; preserve
the unchanged default and the ordinary checked B1 development loop. Do not
launch more percentage-scale private variants while the selected candidate is
under integration validation. Native frontend/annotation feasibility remains
a separate investigation with its own source and semantic boundaries.

## Final private gates — 2026-09-22, 18:41 UTC

[P4-020](phase4/P4-020-private-full-source.md) passes all four planned source
emissions, each exactly equal to the proven H. Opposite-order profile gains are
3.91% and 0.75%; mean process wall improves 805.634→787.260 seconds (2.28%), with
3.16% higher mean maximum-child RSS. Preserve the roughly 10% candidate drift.
The final private frontend independently preserves all 2,756 raw results and
verdicts, with the same 560 differences from TypeScript. Canonical named-profile
packaging is being finalized; the default bytes remain a separate identity.

[P4-018](phase4/P4-018-native-annotation-parallelism.md) rejects the disposable
two-worker native annotation wrapper: exact trees agree, but component wall is
11.5% worse in both orders. Propagation of may-fork metadata is a concrete
suspected cause, not a proven causal ablation. No four-worker/full-source
escalation follows this negative result.

### Updated frontier

[P4-021](phase4/P4-021-frontend-scheduling.md) measures four-core validation and
an idle serial bracket with no competing compiler experiment. Finish this route
before interpreting its wall-time improvement. Keep the seconds-scale B1 focused
loop as the default edit workflow.

[P4-022](phase4/P4-022-residual-private-profile.md) finishes bounded final-core
profiles: private generic apply remains 28.16% exclusive samples, while checking
and annotation dominate API spans. The
[next lowering design](../design/phase4/next_compiler_lowering.md) identifies typed
workers spanning matches, but the cheapest next gate is actual family/staging
counts plus strict demand-order controls. A sample share is not a speed ceiling.
Do not reopen rejected memoization or claim a tenfold gain from overlapping
micro-optimizations.

## Faster validation and a surviving B1 ablation — 2026-09-22, 19:21 UTC

[P4-021](phase4/P4-021-frontend-scheduling.md) is accepted as a resource-scheduling
workflow. The idle serial gate takes 1,036.017 seconds; four-core runs immediately
before/after take 299.376/297.699 seconds. Their median gives 3.47× throughput,
71.18% less wall, with all 2,756 raw results, verdicts and replay histories exact.
The earlier loaded serial is 9.04% slower and remains outside the primary ratio.
[P4-019](phase4/P4-019-private-combined-profile.md) now also passes canonical
packaging: actual default/profile images reproduce `61e7`/`4318`, with 25 unit cases
and seven guards. The named profile is opt-in; source/public APIs stay distinct.

[P4-023](phase4/P4-023-matcher-family-counts.md) completes its bounded exact-output
counter gate. The two substitution helpers account for 18.22% of actual partial
records and 8.68% of generic applications in this core workload. These are
operation counts, not time or bytes. They justify a narrowly guarded semantic
falsifier, now planned as P4-025, rather than a general lowering rewrite.

[P4-024](phase4/P4-024-b1-string-equality.md) passes 909 helper controls and 12 exact
selected observations. Core request reductions are 35.58% and 35.13% in opposite
orders; list and the retained rejection also improve. The derived image also
preserves every full frontend observation. Its single full-source exact-H gate
is running. This is a guarded JavaScript artifact derived from checked B1,
explicitly not a new checked bootstrap or a changed default API.

### Updated frontier

Finish the derived B1 full-source gate and preserve its measured scope. Complete
the bounded substitution-worker falsifier only if demand/error/deep-stack
controls pass; timed escalation still requires consistent material core gains.
Stop new experiment work by 19:55–20:00, leaving the final 15 minutes for report,
artifact/link review, commits and push. No production source mutation is needed
for either remaining experiment.

## Whole-source equality gate and worker rejection — 2026-09-22, 19:33 UTC

P4-024's experimental B1 emits the exact full H in 348.373 seconds, with unchanged
source, host, runtime and proof inputs. This completes its correctness escalation;
the earlier full B1 build is not used as a paired performance control. The image
remains an exact-artifact derivative, not a new checked bootstrap or default API.

P4-025 passes 157 semantic controls and all four exact core emissions. Request
gains are 7.25% and 1.99% in opposite orders, so the predeclared consistent-5%
threshold rejects this narrow worker implementation. No broad/full-source gate
or canonical integration follows. The general lowering question remains open;
the observed partial-record count did not predict a stable material gain.

### Updated frontier

[P4-026](phase4/P4-026-b1-full-source-comparison.md) is the final timed experiment:
four fresh complete-source observations in opposite orders, exact H and memory
checks, with all competing compiler work stopped. Its absolute 20:09 deadline
leaves time to retain any incomplete comparison before the 20:16 campaign end.
Archive and review the completed gates in parallel; do not launch another
optimization or source edit during this final measurement.

## Controlled full-source equality result — 2026-09-22, 20:09 UTC

[P4-026](../implementation/phase4/b1-native-equality-full-comparison.md) completes
all four planned observations at 20:08:44, before the unchanged 20:09 deadline.
Control/candidate/candidate/control process times are 628.273 / 339.318 /
340.665 / 631.779 seconds. Both opposite-order pairs pass the preregistered
request and process thresholds: process reductions are 45.99% and 46.08%.
Means are 630.026→339.992 seconds, **46.04% less time / 1.85× faster**. Every
actual H output and captured input agrees exactly. Mean peak RSS is 1.56% lower;
per-run values remain visible, including the slightly higher second candidate.

This establishes a material complete-source gain for the exact derived B1.
It does not promote arbitrary future builds, change the default distribution,
establish faster emitted programs, or turn a derived JavaScript artifact into
a newly checked bootstrap. The original single correctness observation remains
outside the four-row comparison. The consumed preregistration file is preserved
unchanged, with results in the dedicated report rather than appended to it.

### Updated frontier

The six-hour pass has finished compiler experiments and independent archive
review. The final comparison preserves 259 file identities in 120 verified
compressed objects. No compiler job remains running. The established loop is
a checked B1 rebuild, targeted persistent
witnesses, then four-core broad regression and justified source self-reproduction.

For later work, first make equality portable across genuinely new checked builds
without false provenance or an H regression. The new lowering design compares
the artifact and source routes. Shared identifier/index counts remain a useful
algorithm investigation; the narrow worker's rejected result still constrains
larger lowering proposals. Conformance work can already use the seconds-scale
focused loop while retaining the 560 known upstream differences explicitly.

## Phase 5 authorized: conformance and simpler development — 2026-09-22, 21:39 UTC

The user authorized another six hours after reviewing current performance,
conformance and code-size metrics. The new design prioritizes conformance,
targeted simplification and bounded reusable optimization. Baseline is `7d69850`;
Phase 4's observations and rejected experiments remain unchanged.

Initial independent tracks are P5-001 frontend binder/decorator witnesses,
P5-002 maintained development workflow, P5-003 portable checked-B1 equality
interpretation, and P5-004 current mismatch triage/diagnostic fidelity. See
[the design](../design/phase5/conformance_and_development.md). No new measured
result is claimed by this entry.

### Updated frontier

Commit/push the design, reproduce cheap semantic witnesses, then implement and
validate bounded candidates. Root coordinates shared source, full-suite gates
and uncontended timings. Work ends 2026-09-23 03:39:36 UTC, with source freeze
and final evidence/documentation time reserved before that deadline.

## Phase 5 first integrated checkpoint — 2026-09-22, 22:24 UTC

P5-001, P5-002, P5-003 and P5-004 have focused evidence and archived attempts;
see the [campaign report](../implementation/phase5/report.md). P5-004's concrete
first target became do-notation grammar/desugaring after current mismatch triage.
The genuine checked combined API `a17d909d9c48…` completes all2,756 frontend
observations, preserves919/919positive fixtures and introduces zero new live
TypeScript differences. Strictcheck failures377→376; liveexact differences
560→558, acceptance/phase50→48. The fresh reference is unchanged. Known failures
remain failures; selected local improvements do not inflate full-suite metrics.

A failed reference setup and an incomplete180-second single-core attempt are
retained alongside the completefour-worker retry. Workflow times are not
controlled performance samples. The maintained workflow and reusable equality
derivative have correctness/provenance gates, but no new Phase5 speed claim.

### Updated frontier

Continue bounded adjacency, diagnosticreason and exactsource-origin experiments,
then integrate reviewed candidates. Keep sourcefreeze/finalproof time reserved;
the six-hour campaign remains active until03:39:36UTC.

## Phase 5 second integrated checkpoint — 2026-09-22, 23:03 UTC

P5-006/007/008/009/010 are integrated in genuine checked API `c3c2ac7b1456…`.
All 213 selected observations meet their declared oracles; the full frontend
preserves all 919 positive fixtures and introduces zero new live differences.
Strict check failures are now 374 (377 at campaign start); live differences are
556, including 38 acceptance/phase observations. The remaining 518 diagnostic
and report discrepancies still count as failures. See the
[campaign report](../implementation/phase5/report.md) and its second integration
archive for exact source, tool and input identities.

[P5-005](../implementation/phase5/application-origins.md) is rejected: four exact
diagnostic repairs do not justify repeated quadratic application reconstruction.
The failed attempts and original timings remain archived, with no promoted code.
[P5-012](../implementation/phase5/equality-performance.md) confirms the reusable
derivative on the new source: core request median 19.278→12.262 seconds and list
2.464→1.849 seconds. All ten rows pass. Pinned TS list request is 0.397 seconds;
the derivative is 4.65× slower on this small workload and stated cache policy.
This does not replace the historical complete-source comparison.

### Updated frontier

Review structured parser transport, matcher heads and unqualified operators;
separate the discovered namespace-delimiter error-loss bug from formatting.
Run the prepared controlled four-core complete frontend ABBA comparison only
when competing compiler jobs are paused. Keep final source freeze, CPU coverage
and checked self-reproduction time reserved. Campaign ends at 03:39:36 UTC.

## Phase 5 validation checkpoint — 2026-09-23, 00:20 UTC

[P5-015](../implementation/phase5/equality-frontend.md) completed the controlled
full-inventory ABBA comparison. All11,024raw observations and worker histories
agree; mean wall301.905→229.753s,23.90%less. Each run retains the same374strict
check failures for its source. This does not alter the historical full-source
ratio to TypeScript.

P5-011/013/014/016/017 are reviewed and integrated in checked API8cfa124d….
A complete full control now preserves919/919positives with365strictcheck
failures. The selected diagnostic composition failure is retained and addressed
by P5-022. Later checked API9bb69d… also includes P5-018/020/022:361of362selected
semantic observations agree, with one unchanged missing-import phase gap exposed
by an incorrect joint oracle. The original case and failed run remain; the
confirmed subset is explicitly separate.

[P5-018](../implementation/phase5/frontend-nat-prefix.md) repairs both adjacency
and an actual8-versus5 result discrepancy. Its intermediate error-order regression
was corrected and retained. [P5-017](../implementation/phase5/core-filter-layering.md)
restores standalone frontend layering and passes23existing definition-selection
controls. [P5-020](../implementation/phase5/imported-freshness.md) repairs18selected
acceptance/phase observations; a focused overhead gate finds no material regression.

P5-019 adds45exact diagnostics in167cases with no previously exact losses or
classification changes. P5-019/022 retain their original failed unchanged-or-exact
gates. Independent review approves faithful rendering of the same chosen error,
while existing parser/first-error mismatches continue to count as differences.
No grammar tags or fixture filters conceal those residuals.

[P5-021](../implementation/phase5/persistent-base-decoding.md) identified repeated
Base JSON decoding/verification as44.14%of a focused request sample. The private
session memo passes84mixed comparisons and15adversarial groups. A168-observation
ABBA pilot measures39.00%less request time. The full same-compiler, different-host
ABBA is running under a20-minute budget; no full gain or promotion is claimed yet.

### Updated frontier

Compiler source is frozen. Complete the memo gate, final combined build/frontend
inventory, actual CPU/backend coverage, fresh complete-source TS/B1/derived
comparison and genuine checked self-reproduction. Recount production, maintained
support and experimental code separately. Preserve all failed or incomplete
attempts. The campaign remains active until03:39:36UTC.

## 2026-09-23 00:38 UTC — P5-021 full gate and final combined build

The full Base memo comparison completes with all 11,024 result/history records
exact and mean 292.602→242.597 seconds (17.09% less). Both orders improve about
17%; all 919 positives and 365 known strict failures are retained. The exact
measured two-file host candidate is promoted under SHA guards; full evidence
and historical cost/gate tools are archived. Integration05 starts from frozen
combined source with 371 focused fixtures/387 observations and the unfiltered
1,378-fixture frontend inventory. The known missing-import phase residual stays
in the original failed selection/evidence and is explicitly excluded only from
the confirmed focused repairs. No final combined metric or fixed point is claimed.

## 2026-09-23 00:44 UTC — final combined source gates

Integration05 is genuine checked API5969c53d34a0… for sourcee3b927d13dc2… .
All387 focused declared oracles pass (277exact/110diagnostic differences).
The full unfiltered frontend completes2,756observations and preserves919positive
fixtures in both lanes. Strict check failures377→318,59repairs/0regressions.
Against fresh pinnedTS, exactdifferences560→444 (116resolved/0new); status/phase
differences50→16, with428remaining differences in text fields. This does not
classify every text difference as cosmetic. All2,756reference observations are
unchanged. The separate42-percompiler backend gate passes84actualobservations,
including9positive interpreter/JS/native executions and exact pinnednegative
diagnostics, while retaining10custom diagnostic differences. Final integration
evidence archives4,890historicalfileidentities/3,260objects/9,383,519compressed
bytes. Full-source timings and genuine checked self-reproduction remain pending.

## 2026-09-23 01:33 UTC — P5-023 complete; final proof running

The [final-source comparison](../implementation/phase5/full-source-comparison.md)
completed at01:25:56UTC. All six fresh-process checking, emitter-family byte and
execution gates pass. Mean process wall is60.248s for pinned TypeScript,
642.581s for genuine checked B1 and363.392s for its maintained derivative:
43.45%less than B1,6.03×the TypeScript workflow. Both opposite-order pairs
improve. The documented Base-cache asymmetry, two samples per variant and distinct
emitter/export policies remain explicit. An independent raw-file audit passes;
the archive preserves253fileidentities/205objects/1,926,588compressedbytes.
The consumed precommitted plan is unchanged; its later association record is
dated honestly and does not rewrite benchmark inputs.

A [targeted static-review counterexample](../implementation/phase5/static-counterexample.md)
confirms an existing multiline-string lexer cursor defect and a new wrong source
excerpt in final05. The actual offending line is5; both earlier/final Bend report4,
and the new renderer highlights string content on that line. Rejection phase and
checked flags are unchanged; the valid neighbor agrees exactly. Both four-case
paired gates retain two exact diagnostic mismatches. No fix was attempted on
the frozen source.

The fresh unchanged maintained self-host procedure started at01:32:44UTC from
genuine final B1, in its own directory with no imported measurement stages.
Competing compiler jobs are paused. After actual B1→H→H completion, the plan is
full public-H/derivative frontend equivalence followed by bounded paired broad
JS/native execution. No proof or unexecuted backend coverage is claimed yet.

## 2026-09-23 02:12 UTC — fresh checked fixed point complete

The unchanged maintained self-host procedure completed its fresh B1→H→H proof
at02:10:22UTC. Both stages exited0 without signals and verified their recorded
inputs. Stage2 and stage3 report identical SHA5043267732f5178b12d14708e7dc07e3aa1a71b9d1d5949ef279af23c4297edd;
actual stage2 already matches the four P523 Bend outputs. Independent final-byte
and module auditing follows before archiving. B1stage took661.410seconds and
publicHstage1595.546seconds; these are descriptive proof-stage observations,
not a repeated controlled H/TS comparison. No competing intentional compiler or
archive job ran during the proof. Small documentation/read-only metadata work
and a Git checkpoint pinned toCPU3 overlapped the CPU0 proof.

The audited P523/report checkpoint is pushed as307962c. Automatic review first
rejected the push for unverified destination; read-only account/repository checks
established authenticated rom1504 ownership, ADMIN access and the configured fork
of bendlang/bend. The same authorized destination then accepted the push.

All three broad-wrapper guard tests pass, and fresh snapshot03 retains the exact
corrected tool. Previous snapshots remain unexecuted history. The full publicH
then derivative frontend gates launch with unchanged2756-observation inventories;
the H cap is prospectively25minutes rather than30 to reserve derivative time
before the02:45cutoff. Broad paired JS/native execution remains held until those
compiler jobs finish. No unexecuted coverage is counted as passed.

## 2026-09-23 02:36 UTC — consolidate the validated compiler

The final H and maintained derivative frontend gate completed at02:30:30UTC.
Both reproduce all2,756 B1 observations exactly, preserve all318 strict failures,
and close/revalidate all91 worker histories. The verified archive preserves
5,034 members in5,175,824 bytes; see the [artifact gate](../implementation/phase5/final-artifact-frontend.md).

The user now explicitly requests one usable compiler version, then remaining
semantic gaps and the6× deficit. The [consolidation design](../design/phase5/consolidated-release.md)
promotes the validated equality-derived B1 as the ordinary CLI default, with
a relocatable release manifest and genuine historical lineage kept distinct.
This supersedes older default-distribution holds; it does not rewrite original
proof or timing evidence. Broad backend preparation04 will test this selected
derivative, rather than the unexecuted checked-parent preparations01–03.
No broad result or release completion is claimed by this decision entry.

## 2026-09-23 03:00 UTC — usable default checkpoint

Commitd5a7bd8 is pushed to the authorized selfhost/bootstrap fork branch.
The [consolidated release](../implementation/phase5/consolidated-release.md)
uses APIe2b546… without overrides; actual npm build reproduces its exact bytes.
Default check/interpreter/JS/native and relocation/integrity controls pass.
An observed native subprocess error with status0 now returns exit1; five host
regression groups and an actual default-CLI EPERM reproduction verify the fix,
followed by another genuine checked build and21paired controls. No compiler
source/API bytes changed. A clean relocated package without upstream/build data
also verifies and runs pure/IO JavaScript programs.

The broad backend sweep remains running on its frozen pre-fix host and same API.
It retains unsupported reference cases and actual failures. The fresh
[optimized profile](../implementation/phase6/optimized-residual-profile.md)
identifies residual trampoline/closure/allocation work. An isolated explicit
Boolean-worker candidate passes438direct controls and exact core emission; its
controlled ABBA timing is held until competing compiler jobs close. An isolated
erased-name parser candidate repairs14exact focused observations with no lost
exact result; it remains unpromoted, and a marked-name noncapture experiment
is still running. None of these candidate results changes release metrics.

## Consolidation and opening Phase 6 outcomes — 2026-09-23T03:22:29+00:00

The Phase 5 default is installed and already pushed (`d5a7bd8`), with actual
checked rebuild, source/runtime/host-bound manifest, native error-exit fix and
relocated ordinary CLI evidence. The [campaign report](../implementation/phase5/report.md)
links all final integration gates.

The [broad JS/native run](../implementation/phase5/broad-backends.md) closed at
03:08:40 UTC: 3,962 observations, no missing rows or drift, 315 negative strict
Bend failures and one positive native timeout. Its 24,148 verified archive members
include actual generated C and native executables. Complete coverage remains
distinct from conformance/infrastructure pass.

The [Boolean pilot](../implementation/phase6/boolean-branches.md) passed both
predeclared opposite-order ≥5% request/process thresholds, with exact core-library
bytes: 6.72%/6.18% less request time and 6.30%/5.79% less process wall. This does
not change the default or its measured 6.03× TS full-source ratio. Public-H
behavior and timing require separate gates. The [marked-name candidate](../implementation/phase6/marked-name-analysis.md)
is rejected for a concrete `+f(1)` precedence regression despite selected phase
repairs. The separate [erased-name guard](../implementation/phase6/semantic-gap-analysis.md)
improves its focused comparisons but remains unpromoted. New `+U32` false
acceptance outside the pinned inventory is retained explicitly.

The [native footprint analysis](../implementation/phase6/native-arity-wall.md)
identifies quadratic scalar-field continuation saves in the timed-out large
record, a separate problem from JS library compilation. The [Phase 6 report](../implementation/phase6/report.md)
links the follow-up designs, bounded experiments and remaining promotion gates.

## Last bounded follow-ups — 2026-09-23T03:28:07+00:00

The [native scaling falsifier](../implementation/phase6/native-arity-wall.md)
completed checked emission for 32/64/128 fields. Literal continuation bytes
62,299 / 230,651 / 888,091 nearly quadruple with each doubling, corroborating
quadratic prefix repetition against the retained 255-field anchor. No Clang,
user-program execution or optimized emitter was run.

The [actual-H Boolean follow-up](../implementation/phase6/boolean-branches.md)
retains two distinct verdicts: original positional malformed-data graph gate
failed after 430 completed controls; separately named checked core-emission gate
passed exact output. Baseline H itself fails the inherited raw-function identity
comparison, so this is an unresolved oracle/partial-function contract, not a
silently repaired success. No H speed claim, new fixed point or source promotion.
All compiler experiments are now closed. Remaining campaign work is final
source recount, documentation/evidence checks, commit and push.

## New authorized Phase 6 campaign — 2026-09-23 05:06:12 UTC

The user authorizes all proposed speed, complexity/line-count and conformance
improvements, with up to ten hours. The new deadline is 15:06:12 UTC. Baseline
`a6459af` is clean and already pushed. The [campaign design](../design/phase6/ten_hour_campaign.md)
separates nine concrete experiments covering the eight proposals, isolated
implementation, measured promotion gates and a final usable release. Earlier
Phase 6 opening results and failed candidates retain their original scope.

Initial parallel read-only assignments cover prefix semantics, source provenance
and native immediate words. Root handles baseline identity, obsolete-path audit,
missing imports and checked-result reuse. Source implementation starts after the
design checkpoint. No new speedup, simplification or conformance repair is claimed
at this starting entry.

## First ten-hour campaign checkpoint — 2026-09-23T05:40:05.229181+00:00

The [campaign report](../implementation/phase6/campaign-report.md) records five
frozen candidates: prefix/erased semantics, native immediate fields, multiline
lexer positions, obsolete freshening and missing-import phase classification.
Checked isolated gates and independent reviews are retained; production remains
unchanged. The native255-field witness now actually compiles and runs, with95.31%
less generated C. The cleanup removes184lines with byte-identical selected APIs.
These results do not change the release's6.03×TypeScript speed claim.

Source provenance v2 fixes112missing-excerpt cases while preserving141prior exact
negatives, but has material metadata allocation/cache cost. Measure that cost
serially before promoting; retain the earlier one-case diagnostic regression.
Root's structured-error candidate removes140Bend lines and passes its first
checked/default gate; exact broader gates remain. The next frontier is accepted
provenance overhead, one authoritative checker result, typed-fact opportunity
measurement, parser families and the Boolean H oracle.

## 2026-09-26 — sequential simplification, S0 complete

The user authorizes the [phased simplification design](../design/phase7/compiler_simplification.md)
with design, work and report for each phase in sequence. The [S0 audit](../implementation/phase7/s0-report.md)
changes no implementation. It verifies unchanged source/release identities and
finds an exact 548-line obsolete-code candidate for S1, projecting 15,961 lines.
The larger 50%/75% budgets remain unproven; S0 identifies substantial shortfalls
in the proposed later allocations rather than crediting hypothetical savings.
The previous steering is preserved as an audit input. S1 is the next authorized
implementation; prior Phase 6 candidates remain separate.

## 2026-09-26 — S1 obsolete paths retired

[S1](../implementation/phase7/s1-report.md) removes548 physical compiler lines,
460 nonblank lines and14,980bytes, reaching15,961lines. The54-root checked and
optimized APIs are byte-identical to their baseline; active compiler behavior,
host and runtime remain unchanged. Fresh checked build,21 focused controls,
compiler/runtime components and51/51 harness tests pass. A stale artifact-test
mock export was repaired; sandbox EPERM and an omitted gated-test environment
remain preserved attempts. The smaller-source release verifies and ordinary
check/interpreter/JS smoke passes. No new full-source timing or fixed point is
claimed. S2 design is next; 50%/75% goals are still unachieved.

## 2026-09-26 — S2 shared provenance trace

[S2](../implementation/phase7/s2-report.md) retires duplicate source reparsing and
origin/event alignment:135 fewer lines,134 fewer nonblank lines,3,764 fewer bytes;
15,826 total compiler lines. Its bounded design was pushed before implementation.
Fresh checked build,21focused controls,all components,51harness tests,530new
cross-version provenance comparisons and204existing diagnostic comparisons pass.
52of54selected root closures retain identical generated code; changed origin
routes preserve exact outputs. CPU0 serial provenance medians improve25.4%/40.5%
for all/filtered loading; existing-trace lookup has no regression. No new whole
compiler/TS ratio or fixed point is claimed. The usable release is installed and
all raw evidence preserved. S3 design is next; 50%/75% targets remain unmet.

## 2026-09-26 — S3 authoritative checker result

[S3](../implementation/phase7/s3-report.md) removes139Bend lines and adds2host
lines by preserving the original structured failure and deleting duplicate event,
prefix and diagnostic replay workers. The compiler is15,687lines (822removed,
4.98%). Fresh full parse/check vectors match on all2,756observations, including
919positive/459negative check fixtures;318strict failures remain. Checked/focused,
allcomponents,52harness tests,204diagnostic and39first-error comparisons pass;
actualhost counters establish4→1selected failing-body checks. Serial ABBA shows
33.5%faster late rejection byrequest,30.6%byprocess, accepted overhead<0.7% and
maxpairedRSSgrowth2.91%; exact outputbytes remain. The usable release is installed.
No new full-sourceTSratio orB1→H→Hproof isclaimed. S4mustfund another7,433lines
before the50%milestone; the targetremains unmet.

## 2026-09-26 — S4 bounded checkpoint installed; milestone remains open

[S4](../implementation/phase7/s4-report.md) removes another 1,020 physical /
588 nonblank lines / 16,706 bytes, reaching 14,667 / 12,505 / 470,062. The original
baseline reduction is 11.16% physical, 9.40% nonblank and 7.82% bytes. Corrected
declaration candidate A02 passes genuine checked B1→H→H byte equality; the first
425-law attempt is preserved as rejected after losing two bootstrap exports.
B01 shares loader and embedded-error walks and common list operations. All 2,756
frontend observations match S3 exactly; 318 strict failures remain. Component,
harness, provenance, diagnostic and native smoke gates pass. Serial host cost
increases at most 1.53%; raw/parsed graph medians increase 1.94%/2.63%; memory
and size guards pass. This is simplification with small cost, not a speedup.

The proposed continuation fusion is rejected with a reproducible pinned-language
falsifier. B02 relocates unchanged generic joins to their datatype owner and
produces byte-identical B01 compiler images. Its own genuine checked bootstrap
is installed; default and relocated integrity/check/interpreter/JS/native smoke
pass. Source-only context improves, but new test obligations prevent uniform
context/byte reduction. A02's H proof remains A02's, not B02's. All rejected
attempts, raw measurements and artifact identities are preserved. Another 6,413
lines are needed for the 50% milestone; no later phase is reported complete.
The final controlled S3/S4/S4/S3 development-loop gate takes about 35 seconds
per fresh checked/focused attempt: paired wall differences −0.71%/+0.72%,
maximum RSS increase 3.30%. The failed first measurement setup is retained;
all four actual attempts and runtime/memory guards pass.

## 2026-09-27 — architectural experiment design

The user authorizes recording eight architectural ideas and trying the recommended
first three to find the best direction. The [prospective design](../design/phase7/architectural_experiments.md)
starts isolated P7-A01 checked output, P7-A02 semantic values, and P7-A03 binding
operations inside the still-open S4 milestone. Each hypothesis has its own record
under phase7. Candidate implementation, correctness, measurement and promotion
remain separate; no prototype has run and no source saving is claimed. The
installed 14,667-line compiler is the unchanged comparison control.

## 2026-09-27 — three architectural trials compared

The [comparison report](../implementation/phase7/architecture-report.md) records
three actual isolated Bend prototypes. A01 checked output passes genuine B1,
21 focused controls and 148 direct-output assertions; its preparation workload
takes about 17% less time but check-only costs about 25% more and 45% more peak RSS.
A02 semantic values reduce substitution-heavy normalization time about 47%, but
closed constructor data costs 3.415× and median process RSS about 1.95×. Stronger
controls expose and retain quotation, shape and conversion-demand failures before
correction. The final selected suite passes 100 controls, but a later All-domain
witness remains a known demand regression; a codomain probe is inconclusive.
A03's 965 observations pass, but the runtime generic walker adds 22 lines and
slows freshening 19–23% and shifting 81–82%.

These are bounded operation measurements, not whole-compiler or TypeScript
comparisons. None is promoted and no production simplification is credited.
Checked-output ownership is the best next investigation, beginning with output/
discard policy before allocations. The installed 14,667-line S4 compiler remains
byte-identical and passes release verification; 318 strict failures remain the
previous recorded full-frontend result. Sources, original failed attempts, exact
artifacts, measurement workers and final decisions are preserved in the
[shared evidence capsule](../implementation/phase7/architecture-evidence/README.md).

## 2026-09-28 — upstream and conformance migration authorized

The user authorizes updating upstream, improving conformance and using validated
simplifications. The [prospective Phase8 design](../design/phase8/upstream_and_conformance.md)
freezes target `b2111cf43244e65f76ddc278ee695e669f720cbf`, 118 commits beyond the
old pin. S4 B02 source/API/release identities are preserved; initial release
verification passes. New and old upstream checkouts are separate. Bootstrap API,
Nat host boundaries, upfront declarations and current verdict rules need explicit
migration. No compiler candidate has run yet and no speed gain is claimed.
Percentage line goals are no longer prerequisites; the rejected general evaluator
and runtime generic walker remain out. P8-001 and P8-002 own the first bounded
bootstrap and conformance hypotheses. Prior dirty Phase6 work remains untouched.


## 2026-09-28 — upstream migration consolidated

The [Phase8 report](../implementation/phase8/upstream_and_conformance.md) records
one installed genuine checked release targeting b2111cf, after2.0.32. The API is
e928f777…6374bbe4; source0f5425ac…6a47822; final runtime1766d6d6…5e772f0.
Whole-book bootstrap, ABI controls, focused language and backend gates, and
30 ordinary/relocated release steps pass. All19 component groups ran;18 pass,
while six source diagnostics retain missing-caret differences.

The final2,996-row paired frontend run accepts997/1,001 positives, rejects481/482
validation negatives and leaves one negative timeout. Seven incorrect acceptances
are fixed; none is observed in the final vector. Exact differences fall743→734
within the new target. Four new positive literal cases and four imported-law
trust cases remain. All913 common-path current positives pass;121 paths were
added, one removed, and510 common source hashes changed. Reports preserve these
categories instead of borrowing old-pin conformance claims.

All192 focused parse/check observations,18 semantic outputs,35 import/JS outputs,
44 final foreign-runtime outputs and13 native/scanner controls pass their explicit
oracles; selections overlap. The first tag guard's primitive regression and the
subsequent generic-parameter falsifier remain beside corrected actual executions.
Native Process is blocked by the same unavailable libc symbol in upstream.
GPU and interactive devices remain outside measured coverage.

The compiler retains S4 simplifications and grows310 lines for new behavior:
14,977 physical /12,779 nonblank lines across 59 modules, still9.28% below the
original16,509-line baseline. Generated API shrinks27.80%. No new50%/75% claim or
unchecked generic rewrite is promoted.

P8-001's unchanged-source operation comparison improves1.45–1.52×. P8-003's
separate controlled full-source **checking** comparison records205.26s Bend versus
2.80s TypeScript,73.20× process wall; it does not measure full compilation.
A coarse profile locates most time in checking. The measured checked-build plus
focused loop is about27s. All samples, failed attempts, exact identities and
archived byte objects remain linked from the [preservation index](PRESERVATION.md).
The checked release is not relabeled a fresh self-hosted fixed point.

## 2026-09-28 — targeted checker speed phase authorized

The user requests design, implementation and report. The prospective
[Phase9 design](../design/phase9/checker_speed.md), committed as `e7b2846` before
experiments, preserves the Phase8 release and targets measured checker work.
P9-001 adapts the native equality derivative; P9-002 tests three independent
checker work reductions; P9-003 separates duplicated descent from compact
literal representation; P9-004 owns baseline/residual profiling and the final
same-source controlled comparison. No candidate is promoted at this point.

## 2026-09-28 — Phase9 checked compiler released

The [final report](../implementation/phase9/checker_speed.md) records the installed
`integrated-03` checked B1 and version-3 equality derivative. Chronological law
checking shares an immutable binder-bound seed; exact conversion, lambda checking
and successful lookup avoid redundant work. Descent avoids repeated failed-child
comparison, and compact Nat literals repair the two Nat checking failures.
The initial cache-metadata and later Nat-inference diagnostic regressions are
repaired; both failed attempts remain preserved. Native equality retains guarded
provenance and exact historical version replay.

The controlled same-final-source checking comparison is **66.84 s versus 208.22 s**
for Phase8, **3.12× faster**. Pinned TypeScript takes **2.94 s**, leaving a **22.74×**
process-wall gap. Two serial fresh processes per compiler use one CPU and retain
every result; peak memory remains about 1.5 GiB. These are checking costs, not
full compilation or generated-program runtime. The approximately 27-second
checked-build/focused loop remains appropriate for routine edits.

All 2,996 frontend observations complete without timeouts. Positive type acceptance
improves from 997/1,001 to **1,000/1,001**, and all **482/482** validation negatives
determinately refuse, with zero observed invalid acceptances. Exactly four baseline
observations improve; all others are unchanged. There remain 731 exact reference
differences, one long-string positive failure and four imported-law trust cases
that fail before the intended phase. All **42** ordinary/relocated release checks
pass across interpreter, JS and native execution. No new self-hosted fixed point
or full backend-equivalence claim is made.

**Updated frontier:** investigate remaining declaration-membership scans,
generated-call/allocation overhead and deep-pattern layout costs with small
controlled series. Compact strings and imported-law fills are semantic priorities.
Source is 15,050 physical lines across 59 modules, 73 more than Phase8; the earlier
50%/75% simplification goals remain unmet. The
[preservation index](../implementation/phase9/checker-evidence/README.md) retains
failures, complete measurements, exact inputs and the final release. Unrelated
Phase6 work remains outside this promotion.

## 2026-09-28 — Phase10 repeated-work cycle started

The user asks to repeat the successful method. The
[prospective design](../design/phase10/repeated_work.md) is committed and pushed
as `1449aaf`; Phase9 `f21e9f0` remains the installed baseline. A fresh profile of
its immutable `integrated-03` passes checking and input-identity guards. Loader
membership, deep-pattern layout and profile-ranked generated/index overhead
have separate bounded owners and prospective records. The
[outcome report](../implementation/phase10/repeated_work.md) will distinguish
operation counts, measured times, semantic gates and actual promotion. No new
speed gain or conformance change is claimed at this checkpoint.

## 2026-09-28 — Phase10 repeated-work compiler released

The [final report](../implementation/phase10/repeated_work.md) installs checked
`integrated-01` and its guarded equality derivative on unchanged upstream b2111cf.
Conditional alias/membership guards avoid unnecessary scans; Boolean-parameter
index workers become an upstream-generated loop; typed constructor lookup and
layer-by-layer Nat validation remove repeated layout searches. Raw malformed-book
boundaries, failed syntax probes and the native Nat300 timeout remain explicit.

Serial same-final-source checking improves **1.30×**, **67.04→51.75 seconds**,
with pinned TypeScript at **2.89 seconds**: **17.93×** remaining process-wall gap.
Memory stays about 1.5 GiB. Separate serial Nat300 JS runs improve **1.38×**
(34.17→24.74 seconds), and the layout pass improves **19.09×** (9.48→0.50 seconds).
The emitted JS is byte-identical and all four runs produce 306n; no generated-
program runtime speedup is claimed. Two samples per variant remain descriptive.

All **2,996** frontend observations match Phase9 exactly; 1,000/1,001 positive types,
482/482 negative refusals and 731 exact TypeScript differences are unchanged.
All **42** installed/relocated release checks pass with interpreter, JS and native
execution; the final Nat32 native witness also passes. The initial sandboxed
smoke's six Clang EPERM failures remain beside the successful fresh permitted run.
No new self-hosted fixed point, Lean kernel check or GPU evidence is asserted.

Source adds 57 physical lines to **15,107** across 59 modules, five helper definitions
and no new type. The observed checked-build/focused interval is 26.19 seconds.
Long strings/imported-law fills remain semantic priorities; a fresh final-artifact
profile and reconstructed-pattern/native code expansion are next speed targets.
The [verified evidence capsule](../implementation/phase10/evidence/README.md)
retains exact inputs, rejected attempts, complete measurements and release lineage.
Unrelated Phase6 files remain outside the commit. The 50%/75% reduction targets
remain unmet.

## 2026-09-28 — Phase11 upstream-guided optimization started

The user authorizes further work and larger conceptual changes, and suggests
rereading TypeScript. [Design](../design/phase11/known_work.md) `cf29bae` preserves
released Phase10 `5f561c4` and unchanged upstream b2111cf. Fresh actual-release
profiling, pattern/native expansion, checker normalization and branch/call costs
have independent bounded investigations and prospective records. The
[report](../implementation/phase11/known_work.md) will separate component evidence,
whole-workflow measurements, semantic gates and promotion. No new performance,
conformance or fixed-point result is claimed at this checkpoint.


## 2026-09-28 — Phase11 final integration

[Design](../design/phase11/known_work.md), [report](../implementation/phase11/known_work.md),
[evidence](../implementation/phase11/evidence/README.md). Promote lazy offload
lookup, shared constructor telescope, bounded open-Succ lowering and reviewed
version4 choice derivative. Exact-comparison shortcut deferred; delayed fallback
unimplemented. Current pin stays b2111cf. Final API63c861e9 is an explicit
checked-B1 derivative with historical replay, not a new bootstrap/fixedpoint.

Serial same-source checking51.443→29.729s (1.7304×); TS2.785s, remaining10.674×.
Nat300 JS24.450→15.611s with identical code; native emission27.032→3.609s,
C20,589,858→269,358B. Actual Clang/run succeeds306n. Full frontend:1,001positive
acceptances,482negative refusals, zero invalid acceptances/timeouts,730exactTS
differences. Long-string fixture improves; all other2,995observations unchanged.
Four imported-law trust cases still fail early. Final37row paired backend gate
passes with3exact differences. Source adds31lines to15,138; reduction goals open.

Independent operation/derivation/boundary controls and final release validation
are linked in the report. Preserve every failed attempt, including zero-count
underflow, setup/oracle mistakes, and status-zero EPERM launch records. Invalid
call microtimings are excluded. No performance ratio is inferred from archive
capture, profiling, operation counts, or historical different-source measurements.


## 2026-09-28 — Phase12 avoidable-work investigation started

User authorizes another optimization round. The
[prospective design](../design/phase12/avoidable_work.md) preserves Phase11
`f8244c9`, selected API63c861e9 and unchanged upstream b2111cf. Root profiles the
actual final release before choosing integrations. Independent bounded owners
inspect delayed normalizer fallback, remaining branch/call work and rediscovered
checked/literal structure; plans precede probes and no live source changes happen
before evidence. The [report](../implementation/phase12/avoidable_work.md) will
separate actual correctness, measurements and promotion from the1.2–1.5× estimate.
No new speed, conformance or fixed-point result is claimed.

## Phase12 final avoidable-work round — 2026-09-28

The [report](../implementation/phase12/avoidable_work.md) selects integrated-03,
API0975a4a8, with typed constructor lookup/literal reuse and guarded version5
leaf branch lowering. Same-source checking improves29.56→26.90s (9.0%), versus
pinned TypeScript2.86s (9.42×gap); Nat300JS15.73→7.90s (1.99×), and native
emission3.71→2.78s (1.33×), with unchanged generated bytes and actual execution.
Source loses8lines/onehelper; maintained host transformation/test complexity grows.

All2996frontend observations match Phase11, retaining730exact TS differences,
all1001positive accepts,482negative refusals and four early imported-law failures.
The37paired backend rows pass. Normalizer seed cleanup and broad inlining remain
rejected after fresh and exact-history counterexamples; integrated01/02 remain
failed. The corrected leaf candidate passes both53/60request histories at4MiB.
The focused selection adds the string first, since baseline itself can overflow
after the older21-case prefix. No general stack-safety claim follows.

[Preservation](../implementation/phase12/evidence/README.md) retains original
plans, checked attempts, failures, exact tools, measurements and release checks;
publication binds full byte/mode recovery and explicit prerequisites. Next work
starts from a profile of this final API. No new fixedpoint, kernel/GPU gate or
generated-program runtime gain is claimed. Unrelated Phase6 work stays untouched.

## Phase13 structured-rewriter experiment started — 2026-09-28

The user authorizes the staged [design](../design/phase13/structured_rewriter.md):
profile the actualPhase12release, reproduce its guarded transformations through
a shared structured view, then try explicit branch workers that preserve execution
boundaries. Independent capture/demand/stack review and exact53/60histories precede
whole-source timing. Expansion requires meaningful benefit; no speedup is promised.
The [report](../implementation/phase13/structured_rewriter.md) will retain failures
and distinguish checked provenance, correctness, timing and promotion.

## Phase13 structured-rewriter experiment completed — 2026-09-28

The [report](../implementation/phase13/structured_rewriter.md) closes the staged
[design](../design/phase13/structured_rewriter.md). The installed Phase12 compiler,
upstream b2111cf, Bend source and conformance frontier remain unchanged.
A shared structural view replays authentic transformation versions 1–5 exactly.
Named-worker lifting removes closures but adds capture arrays; complete-source
checking is 1.01% slower, so it is rejected. Actual unsafe-capture cases and their
corrected recognizer remain preserved.

Selector fusion removes intermediate selection work while retaining selected
body arrows. Its one-owner pilot reduces process time by 6.63%; bounded const-scope
recognition in six owners reaches **27.36→24.47 s, 10.56% less time**. Each image
passes independent semantic controls, a fresh long string and both exact saved
53/60-request histories before timing. These are finite controls, not a general
stack-safety or compiler-soundness proof. All timing rows use separate exclusive
ABBA comparisons with two samples per image; no new TypeScript ratio is inferred.

**Decision: defer integration.** A self-contained helper reproduces the prototype
and historical versions exactly, but grows from 296 to 535 lines and adds 7,010
bytes. The smaller gain does not compensate with simpler maintained machinery
and misses the roughly 20% checking target. No new checked release or broad
conformance gate is claimed for the experimental image. The last installed
TypeScript comparison remains 9.42×, and semantic gaps remain unchanged.

**Updated frontier:** remove measured intermediate work, not just closure syntax.
Keep this selector prototype for a cheaper implementation or a demonstrably
larger opportunity; do not broaden branch inlining past saved counterexamples.
Imported-law semantics and exact diagnostics remain useful next priorities.
The [evidence capsule](../implementation/phase13/evidence/README.md) preserves
profiles, failed attempts, consumed tools, exact histories and all measurements;
publication checks full byte/mode recovery. All 75 unrelated Phase6 files remain
unchanged and unstaged.

## Phase14 conformance-first phase started — 2026-09-28

The user authorizes the recommended next phase. The
[design](../design/phase14/conformance_and_dispatch.md) preserves Phase12 API
0975a4a8 and upstream b2111cf. Independent bounded owners investigate the four
imported-law cases, group exact differences and select one shared correction,
and test source-level normalizer dispatch following the successful index pattern.
The [report](../implementation/phase14/conformance_and_dispatch.md) will separate
semantic changes, exact output, scoped controls, controlled timings and promotion.
No new result is claimed at this checkpoint; all unrelated Phase6 work stays untouched.

## Phase14 conformance and source dispatch completed — 2026-09-28

The [report](../implementation/phase14/conformance_and_dispatch.md) promotes
combined-01 API9136be92, retaining upstream b2111cf. Deferred imported-law fills
now inherit canonical signatures after dependency loading; all11trust refusals
match exactly. Source-order trust reporting uses final declarations. Checker
carets remove a shared diagnostic gap, and six source normalizer workers avoid
intermediate choices without extending the maintained JavaScript helper.

The full2,996-observation gate preserves all1,001positive accepts and482negative
refusals. Exact differences fall730→603(194parse/409check),127new matches and no
regressions. The two alias-declaration observations now refuse at the proper parse
phase;26other checker changes add only carets while retaining an exact gap. No
unexpected semantic delta, invalid acceptance or timeout is observed. The71/78
strict diagnostic family still fails for seven prior span errors.

Controlled identical-final-source checking is27.40→24.98s,8.82%less process time;
pinned TypeScript is2.81s, leaving8.88×gap. Exactly two reviewed host argument edits
are explicit; remaining hosts/Base/runtime match. The separate identical-host
pilot saves9.03%. Ratios are not multiplied. Source grows134lines/4,670bytes/11defs
and two temporary markers; maintained JS helper/runtime stay unchanged. This is
not a source reduction or generated-program runtime speed claim.

Both checked builds pass26focused controls. All226paired saved-history observations,
41paired backend rows,16helper groups,five authentic replays and42installed/relocated
CLI checks pass within their stated scopes. The full launcher's null/undefined
postprocessing failure remains failed; a strict identity-bound audit reuses the
healthy vector without rerunning fixtures. Earlier failed fixtures/attempts and
strict differences remain in [preserved evidence](../implementation/phase14/evidence/README.md).

**Updated frontier:** address another measured shared diagnostic cause; profile this
exact release before expanding source dispatch. The Phase13 rewriter stays deferred.
Keep rejected seed/branch transformations excluded until their history failures
are addressed. All75unrelated Phase6 files remain unchanged and unstaged.


## Phase14 attribution correction

A read-only follow-up audit separates the127new exact matches into71checker-caret
improvements,48trust-reporting improvements and8imported-law observations. The
initial main report/CONFORMANCE incorrectly attributed119to checker rendering.
The [corrected report](../implementation/phase14/conformance_and_dispatch.md) and
[per-observation audit](../implementation/phase14/exact-match-attribution.json)
retain the exact breakdown. Total improvement, compiler, timings and validation
results are unchanged. The original capsule preserves the pre-correction wording
and all raw evidence; it has not been rewritten.


## Phase15 parser conformance and checking speed started — 2026-09-29

The user authorizes all recommended next steps. The prospective
[design](../design/phase15/parser_conformance_and_speed.md) binds Phase14 API9136be92
and unchanged upstream b2111cf. Independent owners inspect10parser/load behavior
gaps,66parser-caret fixtures and a fresh profile before one bounded source-speed
experiment. Root retains strict full-corpus delta/acceptance, exact histories,
backend and installed/relocated release gates. The
[report](../implementation/phase15/parser_conformance_and_speed.md) will separate
exact attribution, measured costs, remaining failures and promotion. No new
performance or conformance result is claimed at this checkpoint. All75unrelated
Phase6 files remain unchanged and unstaged.


## Phase15 completed — 2026-09-29

**Installed:** combined-02 API `b8d658c5`, genuine checked parent `32ec77a3`, unchanged
upstream `b2111cf`. The [report](../implementation/phase15/parser_conformance_and_speed.md)
and [per-observation attribution](../implementation/phase15/exact-differences.md)
record parser/import/cycle fixes, shared caret rendering and two source lookup
workers. Exact differences fall 603→459 with 144 new matches and none lost:
132 parser carets, ten missing-file contexts, two binder-plus-caret observations.
All measured behavior/output axes agree across 2,996 observations; remaining
exact differences are diagnostic. All 1,001 positives, 482 validation refusals
and 11 exact trust refusals retain their required results.

Controlled identical-source checking takes 25.0780→24.1023 s (3.89% less process,
3.92% less request time); TypeScript takes 2.8858 s, leaving an 8.3520× gap. The
host patch is explicit and all other hosts/Base/runtime agree. The isolated lookup
pilot separately gains 3.49%; ratios are not multiplied. Source is 15,288 lines,
+24 overall: formatter −35, behavior +37, lookup +22. No new maintained JS rewrite.

Both corrected builds pass 36 focused cases. The standalone component, 226 paired
history observations, 41 backend rows, 16 helper groups, five authentic replays and
42 installed/relocated CLI checks pass. Three known backend exact differences
remain. The initial cycle precedence regression and both first 32/36 integration
failures stay rejected; corrected scoped witnesses do not weaken upstream oracles.
All superseded tools/failed audits remain in [preserved evidence](../implementation/phase15/evidence/README.md).
All 75 unrelated Phase6 files are unchanged and unstaged.

**Updated frontier:** another shared diagnostic cause, then a fresh installed-image
profile for any larger representation/allocation experiment. The source-worker
pattern still pays but does not close the 8.35× gap. Keep routine edits on the
36-case checked workflow; no old multi-hour campaign is renewed.


## Phase16 exact conformance started — 2026-09-29

The user authorizes continued work toward full conformance with low checking cost
and simple implementation, and explicitly approves project evidence archives to
`rom1504/bend` / `selfhost/bootstrap`. Phase15 evidence commit `2ab7b14` is pushed.
The [design](../design/phase16/full_conformance.md) freezes unchanged upstream,
459 exact differences, successful behavior axes and 75 unrelated-file identities.
The fresh same-image baseline averages 24.5512 s Bend and 2.6651 s TS (9.2122×);
1.82% variation between identical Bend groups is not an optimization result.
Independent owners inspect parser errors, checker errors and missing source
origins. Numeric full-range provenance requires an isolated cost/ABI gate before
instrumentation. Outcomes go in the [report](../implementation/phase16/full_conformance.md).


## Phase16 first complete conformance wave — 2026-09-29

The isolated wave1-build-02 full gate reduces 459→364 exact differences, with
95 new matches (82 parser / 13 checker), zero lost exacts and unchanged primitive
behavior on all 2,996 observations. The installed compiler remains Phase15.
The metadata-only numeric-span experiment costs 1.01% process time and 8.93%
peak RSS in the same-source exclusive matrix; populated spans remain unmeasured.
The common rebuild helper removes 90 repeated projections and 275 source bytes
with its 22-group gate passing; its speed is unmeasured. The [report](../implementation/phase16/full_conformance.md)
preserves scoped results, the omitted-file first composition and the corrected
complete-owner preparation guard. Continue semantic controls and explicit source
provenance before final integration/promotion.

## Phase16 populated origins and second complete wave — 2026-09-29

Integration04 passes the full gate with **459→145** differences: **314 new exact,
zero lost**, all 2,996 primitive observations still agree with pinned TypeScript.
The range group is 160/169 exact. Two bounded semantic controls also expose and
fix canonical negation-name capture and implicit bare-family instantiation; their
tiny changes are integrated and documented separately. The failed integration02
partial-parser ranges and every first attempt remain preserved.

The first populated-span same-source comparison costs **10.17% process time**:
25.5882→28.1905 s, TS 2.8902 s. This exceeds the prospective threshold. No Phase16
compiler is installed. Diagnostic profiles motivate a guarded unsafe recursion
scan and one-copy range construction; operation counts and 32 range controls
pass, and their composition passes focused36 plus twelve exact recursion checks.
Exclusive recovery timing is pending. Read the [conformance report](../implementation/phase16/full_conformance.md)
and [cost investigation](../implementation/phase16/range-cost-recovery.md).

The next parser candidate makes another 62 targeted observations exact with
16/16 positive controls and no loss in its 244-observation family census; final
composition is pending. A proposed scoped memo-key correction is explicitly
rejected after growth-limit and literal-versus-constructor counterexamples.
Correctness includes first-error order and syntax-sensitive memo identity.

## Phase16 corrected fourth wave — 2026-09-29

`wave4-build-02` / `wave4-frontend-02` reaches **51 exact differences**:
408 new matches against Phase15 and94 against integration04, with no losses
under either comparison. Primitive outcomes remain exact on all2,996 observations.
The first wave4 accidentally reverted the bare-family predicate; the new adjacent
gate detects and preserves that failure, and the corrected candidate reruns the
whole corpus plus all eight family boundaries. Current source is15,616 lines
in59 maintained modules (+328 versus Phase15), not a net LOC reduction.

The first wave4 cost matrix is **25.9805→29.0659 s**, TS2.9332 s: +11.88% process
cost and a9.91× TS ratio for that unselected image. The small scan/copy changes
did not demonstrate recovery. An existing-index template-membership experiment
passes27 operation controls and24 complete-program comparisons; timing is pending.
All remaining semantic, platform, history and release limitations stay explicit
in the [Phase16 report](../implementation/phase16/full_conformance.md).


## Phase16 fifth full wave and cost attribution — 2026-09-29

The accepted wave5 gate reaches **48 exact differences**, three fewer than wave4,
with zero lost matches and all 2,996 primitive outcomes unchanged. See the
[report](../implementation/phase16/full_conformance.md),
[invalid-binder controls](../implementation/phase16/unbound-binder-marker.md) and
[kind-origin controls](../implementation/phase16/kind-origin-fallback.md).

The [template membership index](../implementation/phase16/template-membership-index.md)
is correct on its controls but flat at 28.8561→28.8768 s; leave it unselected.
[Stage attribution](../implementation/phase16/stage-cost-attribution.md) directs
investigation toward loader allocation and host source validation. It is an
instrumented diagnostic with variable baseline stages, not a replacement for the
ordinary +11.88% cost result. Base-prefix reuse needs an exact law/operation probe
and original request-history gates before any change can be selected.

The next integration keeps parser/import ownership explicit. New module-name
controls expose the semantic alias/local-binder precedence gap; retain it and
its positive witness. No Phase16 compiler is installed and no full-conformance,
new fixed-point or generated-runtime speed claim is made.


## Phase16 sixth full wave — 2026-09-29

Wave6 passes the adjacent full gate at **24 exact differences**, 24 newly exact
and none lost since wave5; 435 newly exact versus Phase15. All 2,996 primitive
outcomes agree with pinned TypeScript. The unchanged maintained backend selection
is now **41/41 exact**, clearing its three historical diagnostic differences.
[The report](../implementation/phase16/full_conformance.md) distinguishes these
scoped results from full conformance and an installed release. Source is 15,759
lines, +471 versus Phase15; no net source reduction is claimed.

The Base-prefix law passes, but operation counts bound its opportunity to 1.32%
of actual-source freshening visits, so its cache change is deferred. The stronger
lead is elaboration from roughly 105k parsed/alias nodes to 2.17M terms. Attribute
literal expansion before changing representation. Keep exact memo/literal and
same-history counterexamples as mandatory boundaries. Production stays Phase15.


## Phase16 seventh full wave — 2026-09-29

Wave7 passes the adjacent full gate at **18 exact differences**, six newly exact
and none lost since wave6;441 newly exact versus Phase15. All2,996 primitive
outcomes still agree. Lexical alias handling fixes a separately measured invalid
rejection. Integrated controls are157/159 exact, with only the two known imported
law wording gaps;16 direct alias controls pass. See the [report](../implementation/phase16/full_conformance.md).
The separately checked qualified-pattern fix closes six erroneous acceptances
and awaits integration. Production remains Phase15.

The [literal census](../implementation/phase16/checker-compact-literal-census.md)
finds about2M literal-construction terms within the2.17M raw source graph.
Compact literal representation is now the principal performance experiment;
operation counts do not establish an end-to-end speedup. Contextual module
parsing and final program-completeness ordering proceed in isolated snapshots.


## Phase16 eighth full wave — 2026-09-29

Wave8 reaches **16 exact frontend differences**, two new and none lost against
wave7; all2,996 primitive outcomes remain exact. The unchanged maintained backend
selection remains41/41 exact. Final completeness ordering and constructor-note
eligibility close the two remaining checker-only corpus rows. Qualified pattern
controls also close six erroneous acceptances outside that corpus. See the
[report](../implementation/phase16/full_conformance.md).

A controlled isolated completion comparison is flat at29.2656→29.3768s (+0.38%),
TS2.9708s, with unchanged memory. Keep the semantic correction; claim no speedup.
The accepted [wave7 capsule](../implementation/phase16/wave7-evidence/README.md)
now preserves917 files, with independent byte recovery and214-source-file
reconstruction from committed Phase15 plus the patch. Earlier/later experiment
preservation remains separate. Contextual completion and compact literal gates
continue; no Phase16 image is installed.


## Phase16 ninth full wave — 2026-09-29

Contextual module parsing brings the accepted full gate to **two exact
differences**, fourteen new matches and none lost since wave8; 457 new versus
Phase15. All 2,996 primitive outcomes agree and the maintained backend selection
remains 41/41 exact. Integrated independent controls are 197/198 exact; their
remaining same-body instance chronology gap is outside the main corpus. The two
main rows concern one do-block's earlier pattern error. See the
[report](../implementation/phase16/full_conformance.md).

The complete source is 16,038 lines, 750 more than Phase15. Compact literal
representation separately removes 92.97% of loaded terms on identical compiler
source, with literal/backend/host controls passing. It still needs exact
syntax-sensitive memo keys and final combined gates; no end-to-end speed claim
or production promotion follows from the structural reduction.


## Phase16 compact-literal timing — 2026-09-29

The compact-literal/context union preserves wave9's two exact frontend gaps and
all primitive outcomes, with no lost matches; all176 literal observations remain
exact. The [controlled comparison](../implementation/phase16/compact-literal-cost.md)
now measures30.8339→10.7300 s,2.87× faster, with peak RSS down65.20%. TS takes
2.9962 s, so the gap falls10.29×→3.58× within that single measurement window.
Six serial fresh-process rows are healthy and other compiler/archive jobs stayed
closed. Known memo-key and size-boundary gaps still block promotion; final
Lambda/JSON-key integration and release gates remain open. Source grows104 lines
over wave9. No generated-program runtime speedup is claimed.


## Phase16 consolidated release — 2026-09-29

The [final report](../implementation/phase16/consolidation.md) installs
`compact-final-build-01`, API `35044ae6`, with genuine parent `83113283` and
unchanged maintained version5 transformation. All42 installed/relocated CLI checks
pass. The previous Phase15 API and lineage are retained in release history.

On identical final source, the exclusive TS/B/C/C/B/TS matrix measures Phase15
30.5837s, final12.3570s and TS3.6108s: **2.475× faster**, same-window TS gap
**8.47×→3.42×**, peakRSS**−62.70%**. The complete two-file host delta is reviewed;
this is checking/trust reporting with validated Bend Base caches and TS checking
Base. The prototype2.87× result remains historical, not a final release ratio.

Main frontend459→2 exact differences,457new/0lost; all2,996 primitive outcomes
agree. Full inventory1498 fixtures retains1001positive accepts/482validation
refusals/11trust refusals. Broader gaps stay visible: integration197/198exact;
marked-pattern71/114exact/rawpassfalse with a separate114-outcome preservation
audit; contextual/host controls retain a decorator/import wording gap. Backend41,
literal176/execution20, instance29/growth2, canonical-key61, loader/helper/history
and CLI gates bind the final image. No full-conformance, new fixed-point, kernel
or GPU claim is made.

Source grows to16,345lines(+1,057 vs Phase15),59modules,1,656definitions,775laws,
66types. Compact terms remove allocation, not source complexity. Promotion01/02
fail before copying anything; promotion03 corrects identity-schema handling and
explicitly records the known marked-pattern oracle failure. Original reports
and tools remain preserved. No test oracle is changed to manufacture a pass.

### Updated frontier

Finish durable topic-capsule recovery and commit the usable release. Then isolate
parser chronology and profile the installed compact compiler. A small raw-body
group wrapper preserves information needed by a future general checkpoint
solution; it does not itself fix the remaining monad/instance cases. Pushes
remain blocked by the earlier automatic approval review despite standing user
authorization; no publication success is claimed.


## Phase17 direct frontend lookup — 2026-09-29

The [eight-line worker](../implementation/phase17/find-worker.md) is installed as
API `9b20de50`, genuine checked parent `59317ea5`. The original emitter lowers
its mutual tail calls to a direct loop, removing a dispatch record/argument array
on each missed declaration. No host/runtime/cache/transformation change is needed.

The exclusive final-source matrix measures12.4407→11.6255s, **6.55% less process
time**, versus TS3.3998s: same-window gap3.66×→3.42×. Both order pairs improve;
request time falls7.17%, RSS0.43%. The older Phase16 TS ratio also rounded3.42×
in a different window; cross-window values are not mixed or multiplied.

All2,996 full frontend results, including existing diagnostics, are unchanged.
Demand23/expected46, selected backend41, context39/host43, original histories226,
helper16/replay5, standalone25-module loader and installed/relocatedCLI42 pass
their explicit contracts. The first promotion preparation misread paired
provenance and copied no source; its successor verifies both identities and
installs one file. Source is16,353 physical lines in59 modules (+8), not smaller.

### Updated frontier

The separate [group trial](../implementation/phase17/group-boundary.md) preserves
196 outcomes and passes92 structural controls without a conformance gain. It
remains uninstalled. Its further checkpoint proposal needs comparison with a
single parser/context authority to justify250–400 extra lines. The
[instance investigation](../implementation/phase17/instance-chronology.md) proves
both ordinary-vs-instance and nested-instance ordering gaps;22 observations have
20 exact results and all8 memo/name controls are exact. Phase18 begins only the
shared-world/result representation-cost ablation before semantic migration.
Neither research direction is a current production conformance improvement.
Publication remains blocked by the earlier automatic approval review.


## Phase18 representation screens — 2026-09-29

The [checkpoint report](../implementation/phase18/representation-checkpoint.md)
keeps the installed Phase17 release unchanged. Two independent prototypes clear
the prospective5% process-overhead screen: checker-world source03 is essentially
flat (11.7103→11.6839 s), while inert parser cursor source02 costs0.93%
(11.6339→11.7416 s). These use separate identical-source TS/B/C/C/B/TS windows;
their percentages are not combined. Cursor construction counts are generated
expressions executed, not measured physical V8 heap objects.

World source06 restores historical raw KSpecialized/KChecked output after a
review found the internal-state leak. Its maintained36, chronology22, direct42,
memo8 and public18 scoped gates pass; both known TS chronology gaps remain.
The final adapter is not timed. Cursor direct194 and all196 saved outcomes pass
their preservation contracts; the raw suite retains68 strict differences.
Source costs are+107lines/+16definitions/+3types for world06 and+77lines/
+13definitions/+2types for cursor02, each against the same installed parent.
No source reduction, conformance improvement or new release is claimed.

### Updated frontier

Investigate two private Phase19 semantic slices: authoritative live-instance
checking and contextual parser checkpoints. Keep source and checked output,
private scopes, first-failure worlds and public parser stages explicit. A narrow
stopped-body alternative still needs substantial propagation machinery without
removing a semantic owner. The measured cursor cost makes testing the coherent
contextual route reasonable. Phase17 recovery is committed as`b34f8cd`; Phase18
failures and corrected artifacts are being preserved separately from Phase19.
Remote publication remains blocked by the earlier automatic approval review.

## P19-001: exact cached-prefix identity — 2026-09-29

Promoted [the two-line correction](../implementation/phase19/prefix-identity.md)
from Phase17 as API66d6ce45. Independent review found literal payload and lambda
quantity presence absent from exact_term. Twelve direct controls expose five
parent failures; the corrected image passes all twelve. A pinned proof witness
shows a real invalid cached acceptance: old check_from_exact_prefix accepts
`{0n == 1n : Nat}` against an old `{0n == 0n : Nat}` prefix, while its own full
checker rejects. The candidate rejects in both paths. This concerns the public
prefix API, without demonstrating a failure of the separately hashed host cache.

Genuine checked B1/maintained36, exact unchanged frontend2996 and installed/relocated
CLI42 pass. Controlled TS/B/C/C/B/TS is neutral: process11.6119→11.6171s,
request10.4848→10.5106s; TS3.4176s, current gap3.3992×. Same35host files, Base,
runtime, v5 profile and resource policy; expected trust refusal, no emission.
Compiler delta+2lines/+186bytes, zero new defs/laws/types. Source/host214 and all75
unrelated Phase6 states verified around installation.

Updated frontier: the usable default contains only this correction. The separate
live-checker rewrite now matches all22 saved chronology observations, but needs
remaining first-error, recursion, output, broad regression and cost gates. The
private parser names/calls slice has real order witnesses and explicit unsupported
boundaries, without a complete Core/loader route. Phase18 experiments are preserved
and independently recovered. Prefix evidence capture is the next publication
checkpoint; an earlier automatic approval review still blocks remote pushes.

## P19-002: one checker for live instances — 2026-09-29

Installed the [shared live checker](../implementation/phase19/live-checker-release.md),
APIa15d150a from genuine checkedd4e57543. Source events and live template uses now
share one semantic traversal. Source books remain authoritative; checked output
is separate data, with completed nested instances before callers. Stable public
payloads remain four-field. Prefix APIs replay source events because cache6 does
not contain memo/output state. The earlier changed-proof prefix repair remains.

All22 original chronology observations and6let controls are exact, closing two
instance-order and three let-close differences. Original integration198 is now
198exact (its raw runner retains pass:false for14negative observed labels). Main
frontend2996 complete results and broader group196/68differences remain unchanged.
Memo8/parsed29/key61/direct40/recursion4, independentboundary104, actualbackend41,
literalexecution20, histories226, helper16/replay5 and installed/relocatedCLI42 pass
their named scopes. Historicalpublic18 remains12pass/6intentionaltransition
differences; all9stablepayload/demand rows pass. No fullconformance is claimed.

Exclusive same-sourceTS/B/C/C/B/TS: predecessor11.5706→candidate11.0570s process
(-4.44%), request10.4700→9.9567s(-4.90%);TS3.4829s, gap3.3221→3.1746×; peakRSS+0.38%.
This is a small favorable cost screen, two samples/image, identical35host files,
Base/runtime/v5/resources. No emission or generated-program speed measurement.
Source15,880physical/13,527nonblank,59modules:475fewerlines/56fewerlaws, but2more
definitions/1moretype versus installedprefix. Six reviewed files installed; all
214source/host members and75unrelatedPhase6 states verified. CLI42 passes.

Updated frontier: contextual parser stages1–3 have scoped names/calls/local-body
controls but no productionCore/loader route. Stage4 targets the original saved16
with shared pattern and flatten checkpoints, preserving real header IDs and
first-error demand. Main do diagnostics and broader grouped-pattern gaps remain.
Profile the newly installed checker before more speed changes; removing another
semantic owner matters more than renaming helpers. Preserve this release separately
from active parser work. Earlier automatic approval review still blocks remote
pushes; commits are local, without a publication claim.


## Phase20 declaration checkpoints — 2026-09-29

The [usable release](../implementation/phase20/declaration-checkpoints-release.md)
installs API `40c8f7f3`, genuine checked parent `2270973c`, on unchanged pin `b2111cf`.
One declaration module adds17 lines/one function and corrects constructor admission,
name/alias/duplicate/brace order, datatype whitespace, decorator diagnostics and
first-element match grammar. No host, runtime, cache, semantic state or profile
change. Independent review caught intermediate semicolon false acceptance; all
original source02/03 evidence remains and source04 is the sole promoted candidate.

Maintained36 is now36/36 exact; decorator24, constructor50, first-element54,
whitespace44 and original supplied39/ordered-host43 are exact. New program12 and
CLI42 pass. The entire main2996 vector is unchanged, still two do-block diagnostic
differences. Broader196 improves128→136 exact with eight gains/zero lost, retaining
60 strict differences and three failed verdicts. Its raw failure remains explicit.
Source totals15,897 physical /13,543 nonblank lines,577,003 bytes,59 modules,
1,660 definitions,719 laws and67 types. Overlapping suite counts are not summed.

Exclusive six-row identical-source timing is neutral: preceding10.9727s,
candidate10.9412s,TS3.4463s; same-window gap3.1839→3.1748×,process−0.29%,RSS+0.44%.
The observed checked build+36-control loop took34.68s, a single concurrent run,
not a controlled loop-speed measurement. No emission, kernel/GPU or fixedpoint claim.
Two audit-schema mistakes and two promotion-schema mistakes are retained; neither
promotion failure copied source. No compiler fixture or oracle was rewritten.

### Updated frontier

The [private Stage4 report](../implementation/phase19/saved-row-group-frontier.md)
retains the actual-state, row/group and alpha-binding evidence; it is uninstalled.
The unexecuted [Phase21 plan](../design/phase21/group-boundaries.md) isolates a small
first-binder range hypothesis for three observations. Grouped-comma correctness
needs preserved completed-group/error order; do not substitute a raw tag guard.
Complete durable preservation and keep remaining60/main2 visible. Publication is
still blocked by the earlier automatic approval review; local commits are not pushes.


## Phase21 local and typed-annotation origins — 2026-09-29

The [usable release](../implementation/phase21/group-range-release.md) installs
API44094e58 from genuine checkedB1 on unchanged pinb2111cf. Three existing parser
workers carry the original body cursor to the sole typed-Ann producer; Local
retains its first binder origin. Source02 adds3lines/156bytes across3files,
no definitions/laws/types, traversal, host or semantic-state change. Source01
passed narrow controls but was withheld because locating Local stopped synthetic
Ann origin attachment; complete graph review caught this and the pin30 cursor
controls validate the repair.

Broader196 improves136→139exact with3gains/0lost;57differences remain and its raw
runner stays false. Main2996 entire result payloads remain unchanged, including
two do-block diagnostics. Independent68 gains16exact, no primitive changes;
additional typederror4 preserves two exact/two inherited diagnostic differences.
Structural172 and positiveAnn30 pass;80legacy origins remain absent. Checked36
strict and installed/relocatedCLI42 pass. Program12 has exact healthy compiler
observations, but nine original per-side expected-output verdicts remain false:
#| comments omitted Nat's n suffix. No fixture/oracle rewrite or redundant rerun.
Original fixture-assumption errors and the isolated-worker audit01 failure remain.

Controlled same-sourceTS/B/C/C/B/TS: parent11.0060s→final10.9547s, TS3.4364s,
gap3.2028→3.1879×. Process−0.47%, request−0.44%, RSS−0.11% is a neutralcost screen,
not a new speedup. The observed checkedbuild+36 loop took35.17s. Source totals
15,900physical/13,546nonblank,577,159bytes,59modules/1660defs/719laws/67types.

### Updated frontier

[Comma controls](../implementation/phase21/group-comma.md) establish that a rawtag
guard loses valid nested tuples and earlier pattern errors. Adding missing
Parallel lowering alone risks false checked acceptance of raw-comma syntax.
The next semantic change needs preserved completion/failure order with actual
lexical scope. Private contextual research remains uninstalled; no second pattern
checker or location-based syntax inference. Remaining57/main2 and independent
constructor gaps stay visible. Preservation closes separately; publication remains
blocked by the earlier automatic approval review, so commits are local.


## Phase22 contextual frontend consolidation — 2026-09-29

[P22-001](phase22/P22-001-contextual-conformance.md) installs one contextual
frontend with actual scope, aliases, group completion and staged materialization.
The [release report](../implementation/phase22/contextual-conformance.md) binds
source17/build16, checkedB1 9cf01096 and guardedv5 APIade8ef02 on pinb2111cf.
Raw parsing/later-scope replay, per-term completion wrappers and98 unreachable
workers are retired. The host requires loadABI2 and corrects checkup chronology.

Final main2996 and broader196 are entirely exact, closing2 and57 differences
with zero lost matches. Audited marked114 closes43 historical differences.
Independent public176/execution36/integration198, header12/normalization12,
completion17/checkup4, strictmaintained36 and CLI42 pass. Histories226+fresh2
preserve all results except one exact prospectively pinned diagnostic correction;
unchanged standalonefrontend26 is genuinely checked independently. Counts overlap;
original raw negative statuses and failed assumptions remain visible.

The initial contextual bundle was32.77% slower. Fresh attribution led to guarded
declaration scans, direct constructor workers, a proved template-arity projection
and a constructor-only scope index preserving first-DFS winners. Two subsequent
failed cost screens (+6.48%,+5.38%) remain. The final exclusive six-row screen is
Phase21 11.0168s/final10.6991s/TS3.3833s:3.1623× TS time, process−2.88%,
request−3.22%,RSS+2.52%, exact complete observations. Only one reviewed host file
changes; this is usable-bundle checking cost, not emission or an isolated Bend
attribution. Two samples do not establish a universal speedup.

Source totals15,600physical/13,305nonblank,580,464bytes,60modules,
1691defs/638laws/68types. Physical lines fall300; bytes and helpers rise slightly.
This consolidates semantic authority without claiming the50%/75% targets.

### Updated frontier

Maintain the exact tested frontend and fast focused edit loop. Challenge new
semantic neighborhoods before another architecture change; profile the installed
image before further optimization. Kernel/GPU/platform validation and generated
program speed need separate work. The [evidence index](../implementation/phase22/context-evidence/README.md)
records preservation independently. All75 unrelated Phase6 paths remain untouched;
remote publication stays blocked by the recorded automatic approval review.

## P23 — pinned upstream migration and graph conversion (2026-09-29)

[Design](../design/phase23/upstream-graph-conversion.md),
[P23-001](phase23/P23-001-upstream-graph-conversion.md),
[P23-002](phase23/P23-002-uniform-array-atomics.md),
[P23-003](phase23/P23-003-bootstrap-profile.md), and
[report](../implementation/phase23/upstream-graph-conversion.md).

Merged29 upstream commits through0187512 after2.0.34 and added15 fixtures to the
active target. Preserved b2111cf and the old released compiler; oldTS/newTS/oldBend
were measured before edits. New upstream alone was near-neutral on ordinary
checking. Profile6 guards the changed Base dependency chain; oldprofiles1–5
retain exact replay. The current image is a derivative of a genuine checked B1,
not a new self-emitted fixed point.

Conversion reuses graph evaluation with rigid-first/full-book policies and
EQ-only post-obligation sharing. Depth32copy/shared programs formerly exhausting
1GiB now pass in1.36/1.41s under that same cap; the failed baseline cannot supply
a normal timing ratio. Added current widening/foreign/TCP/scheduler fixes and
all9arrayatomics with existing uniform arrays/RFC ownership. A surviving alias
exposed reversed native clone ordering (199versus119); final03 fixes it. Earlier
syntax, harness, missingatomic and clone failures remain preserved.

Final API5596f914 /checkedparent5f539f81: main3026 and broader196 exact, histories
226paired+2fresh exact without exceptions, focused36 and installed/relocatedCLI42
pass. Backendnew/scoped24 candidatepasses include22exact and2 Node/Bun reference
limits; retainedarrays18exact and100 multicore repetitions pass. Scanner4116,
JS TCP16 and maintainedharness114 pass. Component fixture maintenance and evidence
closure are described in the final report. Scope exclusions remain explicit:
independentkernel, GPU, arbitrarystructural/atomic races and universal equivalence.

Final exclusive ordinary check: TS3.5518s, old10.9708s, refreshed10.9199s,
final11.0135s;3.1008×TS. Final process+0.39%, request+0.52%vsold, within the
prospective3%screen. PeakRSS+7.52%vsold/−0.80%vsrefreshed. Two samples perbundle,
exact observations and unchanged identities; no generated-code performance claim.
Canonical source+148physical(+0.95%)to15,748lines, unchanged60modules/68types,
+9definitions/+2laws. This expands compatibility while reusing representations;
it is not a line-reduction phase.

**Updated frontier:** promote the pinned, validated compiler and preserve its
failed checkpoints. Profile the remaining ordinary-checking3.10× gap before new
optimization. Continue independent conformance challenges within the supported
scope, preserving exact first errors and one frontend authority. Oldmulti-hour
budgets are not renewed by this checkpoint; future work follows current user
scope and the maintained bounded-experiment workflow.


## P24 — ordinary profiles and execution boundaries (2026-09-29)

[Design](../design/phase24/profile-and-coverage.md),
[report](../implementation/phase24/profile-and-coverage.md),
[measurement review](../implementation/phase24/measurement-review.md),
[backend inventory](../implementation/phase24/backend-census.md).
Hypotheses: [profile](phase24/P24-001-ordinary-profile.md),
[local absence](phase24/P24-002-local-absence.md),
[foreign collisions](phase24/P24-003-effect-collision.md),
[membership](phase24/P24-004-membership-branch.md), and [native identity](phase24/P24-005-native-identifiers.md).

Fresh diagnostics identify source completion and repeated declaration scans,
with membership branch allocation a separate small opportunity. A negative lookup
in the existing scope index proves local absence; hits retain the original scan.
A Boolean worker removes membership closures via existing loop lowering. Direct
local-match syntax fails checked bootstrap and remains preserved. There is no new
index, cache, datatype or parser field.

The bounded execution pilot exposes two gaps despite matching frontend verdicts.
Shared emission now rejects foreign/constructor collisions before reachability;
native function IDs reuse existing scalar encoding to keep case/punctuation
identities apart. Backend81/81exact after repair; raw4check boundary failures remain
matching expected-later-error observations. Focused controls, invalid fixture
attempts and maintained native test maintenance are recorded separately.

Final API7b523bdf/checkedparente8d99da3: focused36exact, frontend3026+196exact,
histories226paired+2fresh exact. Broad reference reuse is explicitly attested,
with fresh candidate acquisitions and unchanged identities. TCP2supported-host
comparisons and8saved-program TSan executions close earlier environment gaps;
finite probes are not universal platform/race-safety claims.

Serial15samples(3/image): TS3.7370s, old11.7300s, local11.2990s,
membership11.0856s, final11.1565s. Final−4.89%process/−5.58%request with flatRSS,
2.985×TS process in this window. Final integration costs0.64%overmembership.
Native emitted identifiers grow; nat_ops C source+22.27%, no emitted runtime-speed
claim. Canonical source+28physical lines to15,776, +3helpers; modules/types/laws
unchanged. Historical large line-reduction goals remain unmet.

**Updated frontier:** keep the usable checked compiler and approximately28-second
focused loop. Expand bounded backend coverage; the inventory counts2,654execution
opportunities but only a small subset is observed here. Investigate materialization,
book walks/updates and dispatch with producer/consumer invariants before a broad
rewrite. Preserve all failed attempts and the103 unrelated starting paths; the
new evidence capsule reuses Phase23 prerequisites and records exact recovery.

## P25 — analyze emitted programs before optimizing H (2026-09-30)

[Design](../design/phase25/generated-code-analysis.md),
[report](../implementation/phase25/generated-code-analysis.md),
[reproduction](../implementation/phase25/README.md).
Hypotheses: [call lowering](phase25/P25-001-call-lowering.md),
[allocation](phase25/P25-002-runtime-allocation.md),
[JIT/scaling](phase25/P25-003-jit-and-scaling.md).

No compiler, runtime, Base or installed release changed. Twenty-three small
sources produce46 checked libraries;127 independently expected scalar points
agree on both sides. Most are mechanism analogues, not exact full compiler
components. Forty-five runtime points supply450 clean samples on CPU3/Node24;
the full cached sweep costs171.69s of child wall. A new focused paired command,
including calibration/output checks/ten samples, reproduces a numeric case in5.37s.

Full AST analysis separates copied runtimes,48 common emitted registrations and
workload owners. Direct U32 patterns expand each scalar to33 temporary constructor
values in our runtime; exact counts corroborate the hot representation overhead.
Dense pop grows to65,562bytes of matcher code versus a60-byte upstream function
and68-byte table. Selected numeric-pattern gaps are1,418–1,761×; these are tiny
generated-program ratios, not compiler-throughput or predicted optimization gains.
Other mechanisms vary widely, with string equality near parity(1.05–1.15×).

Matches interrupt saturated calls; ordinary arithmetic uses generic primitive
dispatch where upstream emits direct loops/operations. Nine paired diagnostics
(18healthy processes) establish runtime-prefix CPU73–87%, plus allocation and
exact operation evidence. Boolean-worker source is22.24× faster under upstream
lowering but1.80× slower under our emitter on one matched input: upstream-built B1
source improvements do not automatically transfer to self-emitted H.

Selected V8 steady traces show no candidate deoptimizations; observed upstream
ones belong to the diagnostic harness. Input sizes also change seeds/paths, so
no pure scaling law is inferred. Full H, native/GPU execution and a broader current
backend sweep remain outside this phase. Independent timing and dynamic reviews
retain fixture errors, the initial missing-matcher counter vocabulary, the invalid
diagnostic launcher and trace-summary parser failures. Raw artifacts and exact
recovery receipts are preserved in the evidence index.

**Updated frontier:** first isolate direct native U32 decision lowering with strict
identity/default/demand controls; next test known saturated workers and tail loops
on the frozen traversal kernels. Keep primitive inlining, Nat representation and
constructor forcing as separate ablations. Use the seconds-scale emitted-code loop
before component/full-H integration; preserve the working Phase24 release and its
conformance scope while these backend hypotheses are tested.

## P26 — native U32 decisions without linked words (2026-09-30)

[Design](../design/phase26/direct-u32-decisions.md),
[hypothesis](phase26/P26-001-direct-u32-decisions.md),
[report](../implementation/phase26/direct-u32-decisions.md),
[reproduction](../implementation/phase26/README.md).

Promoted a110-line Bend emitter rule for native U32-to-U32 ordered matcher trees
with closed numeric leaves. Native owner/constructor guards, an8192-node limit
and explicit failure preserve generic lowering outside that envelope. Recognition
precedes deep lifting. Runtime, Base, frontend, native backend and fn/call ABI are
unchanged; the source grows0.70% to15,886 lines/61modules, with no new datatype.

Installed API4c67ac04 derives from genuine checked parent818f68ca through profile6.
Focused36exact, selected upstream JS15exact, corpus23libraries/127points exact.
Paired controls2816scalar outputs per emitter plus4refusals, supplemental468points
per emitter, and independent56guard/780worker checks pass. Actual escaping
full-text/scalar controls pass. These overlap and do not renew all broader suites.

Serial CPU3/Node24 timing:90valid samples,6cases,3outputs,5fresh processes/output,
44.61seconds total including calibration/checks. Table11.80×, wide3.66×,
direct-numeric50.25× faster than old selfhost output. Remaining TS ratios122.26×,
484.26×,12.97×. Arithmetic/actual escaping controls are unchanged within the
observed window; no whole-compiler throughput or H gain is claimed.

Exact constructor counts fall8481→0,33792→0,66→0 per respective benchmark call.
Generated pop/key definitions shrink86.7%/87.0%. Generic apply/closure work remains
large in loop workloads, explaining why eliminating one representation is not
parity. The real compiler's four numeric-case helpers return String/List and do
not qualify for this rule. The emitted comparison loop gives useful evidence in
seconds without another full self-hosting build.

Retained source/expectation pilots, initial missing diagnostic-export harness and
the overly broad documentation-inclusive closure audit. Independent review finds
no blocker for checked native scalar inputs; arbitrary raw JS object coercions
and forged native flags remain outside that contract. Capsule recovery and the103
protected-path audit close preservation; release verification/CLI smoke pass.

**Updated frontier:** test constructor-arm prebinding as a separate call-lowering
ablation while preserving partial-function descriptors and argument demand.
Do not merely raise public arity. Wider numeric-result support, dense tables,
primitive inlining and tail loops remain separate candidates; prioritize changes
that transfer to real compiler components. Keep backend conformance acquisition
bounded, and retain compiler-throughput/generated-program/H distinctions.

## P27 — selected constructor-arm prebinding (2026-09-30)

[Design](../design/phase27/constructor-arm-prebinding.md),
[warmup amendment](../design/phase27/longer-warmup.md),
[shared-helper amendment](../design/phase27/shared-arm-runtime.md),
[report](../implementation/phase27/constructor-arm-prebinding.md),
[reproduction](../implementation/phase27/README.md).

Promoted the shared-runtime variant; rejected the first inline form. Both pass
scoped semantic gates and remove one fn/apply/bounce per affected match, but
inline substitution regresses20.08% in the original short window. V8 traces
motivated a prospectively defined longer-warm comparison, not discarded samples.
The final shared form preserves the same recognizer/partial descriptors and
removes that material measured penalty. Substitution remains effectively flat.

Final warmed actual compiler membership improves1.059× and Boolean traversal1.042×,
with nonoverlapping five-sample ranges. Short membership median1.026× has overlapping
ranges; other short gains are about2–6% on selected kernels. Four separate windows
retain360 samples with pinned TypeScript and Phase26 baselines. Independent audit
verifies504 total timing/calibration/check processes. The final short135-sample
screen takes66.93s; long45-sample screen63.14s. No whole-compiler/H claim.

Fresh shared gates:36 strict focused,15 upstream JS execution,23library/127point,
72 arm observations, numeric2816+468 scalar checks per emitter plus refusals,
22 actual component oracles and runtime ABI controls. Counts overlap; broader
frontend/native/device coverage is not renewed. Source adds58 Bend lines/eight
helpers/one module and11 runtime lines/one helper; no new datatype or representation.
Installed API5a89c775, checked parent25c38e3f, runtime40823818, sourcef3097523.

All failed/superseded acquisitions, original inline source, untimed ablations,
traces, checked snapshots and exact output bytes are retained with recovery
receipts. The103 unrelated paths remain unchanged; no new PR comment is posted.

**Updated frontier:** reducing one dispatch boundary yields incremental gains.
Test a private saturated worker or loop on the actual compiler helper before a
full H. Preserve evaluation/descriptor boundaries and measure both warmup regimes;
identical helper-count reductions do not guarantee identical V8 performance.

## P28 — broader existing generated programs (2026-09-30)

[Design](../design/phase28/broader-program-comparison.md),
[prospective warmup follow-up](../design/phase28/warmup-followup.md),
[report](../implementation/phase28/broader-program-comparison.md),
[reproduction](../implementation/phase28/README.md).

Measured six existing runtime algorithms at documented small inputs, four unchanged
mixed tests and the original small HVM interpreter demo. Both checked emitters
produce matching observable outputs on all11. Compiler source and installed Phase27
release remain unchanged; these runs do not renew the broad conformance inventory.

Original five-sample warmed algorithm ratios are111.39–1391.14× slower than pinned
TypeScript output: tree sorting111.39×, lexer139.32×, symbolic regression141.05×,
edit distance509.53×, ray tracing523.80× and Mandelbrot1391.14×. Tiny mixed tests
are55.35–107.32×. HVM's whole process is200.93ms versus69.21ms,2.903×. The scopes
remain separate; no production-average, native-output or compiler-throughput claim.

All four cases with repeated within-block drift receive a prospectively defined
longer-warm follow-up using identical bytes/inputs: Mandelbrot1271.44×, tree
sorting100.38×, morning60.60× and Map/Set82.37×. Residual drift remains in sorting,
Map/Set and one morning sample; neither protocol proves steady-state convergence.
All150 timed samples and56 check/calibration processes are retained and independently
audited. Original library screen816.11s; follow-up189.32s. Both rejected Nat wrappers
and the incorrect CommonJS filename remain in the capsule with their failures.

**Updated frontier:** large emitted-program gaps persist beyond diagnostic kernels.
Test saturated private workers across matches, primitive inlining and direct native
constructor/match lowering as separate ablations. Static inspection observes generic
dispatch/allocation boundaries but does not assign their shares of the slowdown.
Both outputs already have tail-jump machinery and native strings. Preserve partial
application, argument demand, forcing and stack behavior; validate on small focused
cases before repeating this more expensive algorithm suite.

## Phase29 — generated-program fast loop and guarded lowering

[Design](../design/phase29/generated-program-fast-loop.md),
[private worker amendment](../design/phase29/private-nat-worker.md),
[evening follow-up](../design/phase29/evening-warmup-followup.md),
[report](../implementation/phase29/generated-program-fast-loop.md),
[reproduction](../implementation/phase29/README.md).

Promote checked attempt04: API10510efd, checked parent37218b8a, source191df20c,
unchanged runtime40823818 and pin0187512. Two guarded JS emitter rules expose
54 native scalar operations and supported Nat countdown loops. Public partial
application, evaluation order and representations remain.

The real helper fixture improves3.65× in longer-warm confirmation. The paired
screen takes4.706s end to end; build+36focused checks33.341s and fixture emission
4.825s make a roughly43s checked edit loop before additional feature controls.
Full final three-output integration takes22.0 minutes and is reserved for this
boundary. Original algorithms improve1.24–2.94× in the original window, still
89–465× TypeScript. Longer-warm Mandelbrot improves2.695×; sorting1.063× remains
drifting. Evening regresses27.4% in the short window but improves1.167× with longer
warmup; both persist. HVM process medians196.86→198.39ms have overlapping ranges,
so no whole-process gain is claimed. Ordinary compiler throughput is not renewed.

Independent semantic controls and fresh36focused/15JS/23library127point/original
11program/component22 scopes pass; counts overlap. Independent measurement audit
passes601 processes/429 timed observations across all windows and checks summary
aggregates. Primitive/worker guards include native identity, arithmetic bounds,
partial ABI, argument demand, closures and50,000 iterations.

Failed02 source syntax,03 recognizer stack overflows, the first audit combiner's
warmup-field comparison and the first CLI smoke expectation remain in evidence.
Explicit kc branches repair eager && recursion; the small witness discriminates
old/new. All eight previously valid original emissions remain byte-identical
after repair. Canonical source16,207physical/13,839nonblank lines,64modules,
1,762defs,640laws,68types: +263lines/+36defs, two concepts, no new IR/runtime helper.

The next measured direction is a general private saturated worker across the
edit-distance record/tuple cell chain, retaining project/build/array behavior
initially. Static inspection identifies remaining generic boundaries without
assigning runtime shares. Full backend conformance and TypeScript-speed parity
remain unestablished.

## Phase30 — direct generated code (started2026-09-30 07:28 UTC)

The user authorizes at least seven hours of sustained optimization.
[Prospective design](../design/phase30/direct-generated-code.md) freezes baseline,
semantic boundaries, performance protocols and promotion gates before compiler
edits or new timings. Start at77aecb2; preserve103 unrelated files. Three agents
independently prepare a private-call prototype, semantic counterexamples and
paired generated-code inspection. Root owns the general implementation and
measurement coordination. No performance result or promotion yet.

### Phase30 first mechanism checkpoint

Private edit-row prototype confirms1.379×; live-replacement guard version1.287×,
with an explicitly narrower immutable-descriptor contract. Retain firstcold-path
ordering failure and short-window drift. Owned non-tail argument vectors confirm
1.1367× on the prior scalarfixture. Implement the latter in checkedattempt01;
36focused/120oracle/22independent ABI observations pass. Installedrelease stays
Phase29 pendingintegration. Separate exact-arm and once-per-scalar-loop dependency
guard experiments are prospective. No wholecompiler or native speed claim.

### Phase30 guarded region checkpoint

Actual checked owned-vector output confirms1.13325× on the helper fixture.
Exact constructor-arm saturation confirms1.02321× on the complete-state edit
row. The closed scalar region confirms2.679× on original Mandelbrot bench(0,0),
while per-call guards regress53.8%. Both guard frequency and eliminated-call
scope differ, so this is not a pure guard-frequency attribution. A separate
private-row V8 diagnostic profile samples43.5% in apply/force/call and2.6% in
GC; named frames are not a universal cost decomposition. Retain every window.

[General scalar-region plan](../design/phase30/scalar-region-compiler.md)
freezes compiler admission, snapshot guards, private expression nodes, unchanged
fallback and validation before implementation. Prefer existing KTerm/JS emission
over retargeting C-specific NIR. Independent reviewers cover purity, metadata,
forward references and type-preserving private lowering. Phase29 stays installed.

### Phase30 semantic correction and rejected micro-optimizations

Attempt03 passes its selected checks against Phase29, but comparison with the
pre-worker emitter finds five inherited scheduling/self-binding failures.
The corrected design admits only pure graphs, guards the recursive owner,
requires exact runtime entry and retains the original generic fallback. It
does not inherit the old loop as fallback. The exact-arm extension is withdrawn:
three enclosing-application counterexamples outweigh its small measured gain.

Long-window array-call ablation rejects per-call guards (33.7% slower on the old
row and43.2% slower after private helper lowering). Immutable native bypass saves
only about6–7%; it is not a public-ABI-preserving production candidate. A private
Number countdown gives only1.052× over BigInt with slightly overlapping ranges
and residual BigInt warmup drift; defer that representation rule.

The bootstrap error formatter previously made one source error look like a
120-second compiler timeout. A bounded structural diagnostic returns in1.836s;
eight initial and four follow-up controls pass. Successful output is byte-identical
on the checked control. Attempt04 successfully bootstraps current source, then
the provenance gate correctly refuses the changed recipe hash. Review that exact
recipe separately and preserve historical replay. No new release is installed.

### Phase30 direct lexical helpers and nested loops

Attempt07 passes the selected broad integration gates, including the retained
erased-let admission adaptation with unchanged runtime oracles. Actual helper
output confirms10.45× over Phase29, from0.394653 to0.037776ms, still22.13× pinned
TypeScript at the same128-iteration point. This is generated-program execution,
not compiler throughput.

The isolated dictionary-to-lexical helper change confirms3.757× with disjoint
ranges. Callback implementation hoisting and fusion show no meaningful warm gain;
retain their overlapping ranges and first-call observations. The profile's large
enterExact sample attribution therefore does not establish token-check cost.
Attempt08 implements lexical spelling with injective codepoint identifiers and
passes actual emission/name/ABI controls. An initial malformed synthetic name
fixture remains preserved before its corrected native-owner setup.

The nested terminal-record prototype confirms8.161× on a complete histogram
chunk and1.639× on original small Mandelbrot. Attempt09 implements that grammar
using existing state and loop emission; its actual200 histograms/129 boundaries
and independent41 admission books/88 executions pass. Instrumented chunk generic
calls fall2242→3 while the delayed record build remains. Actual output timing is
pending confirmation; isolated prototype results are not release claims.

The exact-entry method-read ablation removes redundant reflective checks and
passes scoped getter/error controls. Its initial original edit-distance screen
suggests7% but costs199s because a call lasts2.4s. Move confirmation to a row
microcase; never apply the100-call long-warm floor to that original workload.
Ordinary scalar root regions and F32 coverage remain separately frozen trials.
Installed compiler stays Phase29 until the combined promotion gates finish.


### Phase30 ordinary roots and private scalar trees

The actual lexical helper confirmation measures39.6× over Phase29,5.86× TS;
actual terminal09 measures38× on a complete chunk and1.79× on original small
Mandelbrot. Ordinary11 confirms1.375× over terminal10 on that original point.
Its admission, numeric and ordered public-boundary controls pass. A terminal
counter adapter initially selected an already-optimized baseline but expected
an old internal bounce; the unchanged failed receipt and corrected baseline run
are both retained. No source fix was needed for that harness expectation.

The strict scalar binary-tree prototype confirms15.6× over actual10 on original
small Mandelbrot, with repeated whole-point warmup drift retained explicitly.
The depth5 microcase is21.7× faster with mostly stable timed halves. A prospective
production design reuses region analysis and adds one private DFS continuation
shape, preserving public fallback and bounding its depth. Attempt12 passes all36
focused gates; actual tree controls and independent refusal tests are pending.

The F32 acyclic-root guard regresses both hit and miss microcases by2.9–7×.
The corrected exact-arm retry passes semantics but regresses28%. Both remain
out of production. Number counters confirm only5.4% lower time and remain
deferred to avoid another representation mode. Exact method-read cleanup has
an encouraging row signal but unresolved baseline drift. Installed release stays
Phase29 until the combined image, broad gates, measurement and installation.

## Phase30: actual tree confirmation and residual probes

Actual12 passes the combined focused, selected upstream, primitive/worker,
23-library, real-component and HVM gates. A fresh checked-source fixture adds
270 Bool/Nat tree points across TypeScript/actual11/actual12, 11 admission/refusal
assertions and six ordered mutation observations. Original ten libraries compile
and return exact results. Full frontend renewal and original timing remain pending.

The separate15-second-warmup original Mandelbrot comparison confirms
3.614043ms→0.267604ms for actual11→12, a13.505× gain; TypeScript is0.045645ms.
Three-process ranges are disjoint and timed halves stable in that window. Earlier
three-second drift remains retained. A tree-frame storage ablation then confirms
0.266169ms→0.244705ms (8.06% less time), cutting255 allocation pairs to8. Its
small production emitter patch is applied and awaits a fresh checked build.

Private helper const/arrow bindings show no useful screen improvement and stay
out of production. Replacing exact-entry objects with scalar runtime slots gives
a3.2% scalar gain but a4% row median regression with drift; it remains deferred.
The closed owned-row ladder passes full-state, alias and ordered host controls;
its1.52× screen gain has substantial drift and awaits confirmation. A general
local-container proof is documented, not implemented by recognizing this fixture.

### Phase 30 — settled frame, owned-row and private-Let follow-ups

The [closed owned-row ladder](phase30/P30-020-closed-owned-row.md) confirms
1.60× on its complete row32/seed17 fixture: generic 0.588137 ms versus private
row 0.367874 ms, with unchanged storage effects and full-state/alias/public
controls. TypeScript 0.008413 ms leaves a 43.7× gap there. This is a disposable
closed scalar-input experiment, not a general compiler ownership extension.

[Native calls inside the same region](phase30/P30-021-owned-native-dispatch.md)
then confirm 1.082× incrementally, 0.368370→0.340405 ms, with disjoint ranges.
Generic setup, projections, copies and force counts remain fixed; generic apply
falls 794→630. The full ladder is 1.759× generic but still 40.6× TypeScript on this
fixture. Independent review retains a real Array.prototype getter that mutates
umin inside the old standard-Array domain. The new variant rejects those hooks
at the outer boundary and matches generic behavior. No production promotion.

[Private frame reuse](phase30/P30-022-private-frame-reuse.md) is implemented in
checked13. Fresh actual-output oracles, ordered host/depth controls and repeated
traversals pass; complete module differences are restricted to intended push/pop.
Fresh frame/argument pairs fall 255→8 for original Mandelbrot. Its separate
15-second-warmup actual12→13 comparison confirms 0.263759→0.246737 ms, 6.45%
less time, with disjoint ranges and small drift. The earlier 8.06% prototype
window stays separate. A sandbox ENOSPC event prevented one oracle launch before
process creation; its receipt is retained, followed by parent-verified duplicate
temporary-file recovery and successful fresh acquisition.

[Private helper Let statements](phase30/P30-023-private-let-statements.md)
confirm 0.267175→0.237970 ms on original Mandelbrot after 15-second warmup,
10.93% less time, with disjoint ranges and less than 1% half drift. The proposed
maintained rule adds one small statement-return emitter reusing existing Let
helpers. Checked14 passes its independent actual-output structural, numeric and
public-boundary gates. The separate actual13→14 long comparison confirms
0.246549→0.215416 ms, 12.63% less time, with stable, disjoint samples; pinned
TypeScript is 0.045613 ms in that same window, leaving 4.723×. This is original
Mandelbrot execution, not a generated-program average or compiler checking cost.
The separate generic tail-Let experiment must pass its own scheduling/closure
controls and warmed measurements.

[Private helper hoisting](phase30/P30-024-hoisted-private-helpers.md) does not
survive confirmation: baseline 0.265628 versus hoisted 0.270437 ms, overlapping
ranges and 1.81% slower median. Its encouraging short screen remains in the
record. Defer the 90–160-line implementation despite smaller generated modules.

**Updated frontier:** prioritize the small confirmed private-Let implementation
and its checked-image validation, then the separately scoped general tail-Let
experiment. Keep owned local-container regions as evidence-backed research,
not benchmark-specific compiler admission. Phase29 remains installed pending
combined conformance, original-program timings, ordinary compiler-cost checks
and release. Ratios from distinct inputs/windows must not be multiplied. No
new whole-compiler throughput, full-backend conformance or fixed-point claim.

### Phase 30 — freeze the release candidate after the guard decision

The final bounded [complete-guard allocation trial](phase30/P30-025-guard-fixed-lists.md)
preserves every metadata read, predicate and live snapshot, with 67 independent
full reflection-order controls plus the retained core/helper/tree suites. Its
confirmed helper reduction is 4.33%, and original Mandelbrot reduction is 1.80%,
both with disjoint sample ranges. Before measuring, promotion required at least
5% helper or 3% whole reduction with no material opposite regression. Both
benefits fall short, so defer rather than relax the thresholds. The first
tooling-only parser failure and all short/warmed results remain retained.

**Updated frontier:** checked14's small private-Let emitter remains the release
candidate. It confirms a same-window 4.723× TypeScript gap on original small
Mandelbrot after substantial earlier improvements. Generic tail-Let expansion,
helper hoisting, guard allocation changes and closed local-array prototypes are
not part of this compiler. Freeze optimization variants and finish the original
program matrix, ordinary compiler-cost and conformance gates, evidence
preservation and installation. The installed compiler is still Phase29 until
those parent-owned steps complete.


## Phase 30 — complete matrix holds checked14 release

[P30-026](phase30/P30-026-complete-candidate-matrix.md) completes all 13 frozen
jobs in 1,631.07 seconds: ten original programs, the ordinary compiler check,
two-source checked-library costs and four scalar helper sizes. All output
checks pass. Original Mandelbrot improves 97.35× versus Phase29, but generic
edit-distance, lexer and ray-tracing paths regress approximately 20–24%. Several
small transfer cases have large warmup drift and remain explicitly unsettled.
Scalar8192 is 190.74× faster than Phase29 and 1.34× TypeScript time, while scalar0
pays 2.68× Phase29 time. These separate results expose coverage and fixed-entry
cost rather than supporting a universal average.

**Release is on hold.** The installed compiler is not replaced by this held
candidate. The next experiment uses newly checked Phase29/14 emissions of the
same complete-state row fixture and independent runtime-dispatch ablations.
Full medians, ranges, costs and limitations are in
[the batch report](../implementation/phase30/final-timing.md); the prior release
frontier is superseded by this observed regression and hold.


## Phase 30 — exact row identifies generic constructor dispatch

[P30-027](phase30/P30-027-generic-runtime-row.md) checks newly emitted Phase29
and held14 against five runtime/reference variants on the same complete-state
row. All 196 state observations and both 28/16/257 oracle/alias/boundary suites
pass. The short screen has severe opposing warmup drift; maintained confirmation
shows that restoring generic delayed constructor-field application reduces
checked14 row time from 0.606265 to 0.446850 ms (26.29% less), recovering Phase29's
0.450682 ms within overlapping ranges. Inline dispatch is null; fused prebinding
saves 2.32%; the independent method-read expression saves 9.68%.

The parent accepts the isolated generic runtime repair for checked integration.
No compound transformation is selected. The release hold remains until actual
emission, boundary and original-program transfer checks support the repaired
image. The complete comparison and its regressions remain immutable.


## Phase 30 — retire the redundant constructor-arm mechanism

[P30-028](phase30/P30-028-retired-arm-prebinding.md) separately checks the source
simplification after the isolated generic runtime repair. Checkpoint73912c3 and
checked16 remove64 maintained implementation lines, eight admission functions
and the prebinding-specific bridge. Shared arm typing and registered scalar
worker entry remain. Complete runtime/generated AST correspondence passes on
row, helper and original Mandel emissions; fresh callable-shape, partial/entry,
ordered public and actual-emitter arm controls pass. The selected15 upstream JS
gate and primitive/worker/corpus/component/HVM integration are renewed on16.

**Updated frontier:** the64-line reduction is established by source and checked
structural/public evidence. Fresh five-way confirmation now passes: row16
0.444585 ms overlaps repair15's0.448121 and29's0.448173 ranges, while held14 is
0.601983 ms. The full repair removes26.15% of held14 time; the overlapping
15/16 ranges provide no additional deletion-speed claim. Scalar14/15/16 ranges
also overlap, preserving the earlier private-worker benefit. Do not infer
complete backend conformance, full transfer recovery or installation. The held14
comparison and all intermediate failures remain in the record.
