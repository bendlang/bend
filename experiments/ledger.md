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
claimed. S2 design is next;50%/75% goals are still unachieved.

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
all raw evidence preserved. S3 design is next;50%/75% targets remain unmet.

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
14,977 physical /12,779 nonblank lines across59 modules, still9.28% below the
original16,509-line baseline. Generated API shrinks27.80%. No new50%/75% claim or
unchecked generic rewrite is promoted.

P8-001's unchanged-source operation comparison improves1.45–1.52×. P8-003's
separate controlled full-source **checking** comparison records205.26s Bend versus
2.80s TypeScript,73.20× process wall; it does not measure full compilation.
A coarse profile locates most time in checking. The measured checked-build plus
focused loop is about27s. All samples, failed attempts, exact identities and
archived byte objects remain linked from the [preservation index](PRESERVATION.md).
The checked release is not relabeled a fresh self-hosted fixed point.
