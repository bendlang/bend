# Phase16 implementation report

Work follows the [prospective design](../../design/phase16/full_conformance.md).
Baseline is the installed Phase15 compiler `b8d658c5` at upstream `b2111cf`.
The Phase15 evidence commit `2ab7b14` is now pushed following explicit user
authorization. The 75 unrelated Phase6 paths retain their original identities.

## Fresh baseline

Installed release/checked lineage verification passes. The controlled unchanged-
release comparison completes six healthy rows: four runs of the same Bend API
(the two named variants are identical) and two pinned TypeScript runs. Pooled
process time is **24.5512 s Bend / 2.6651 s TypeScript**, a **9.2122×**
ratio. Same-image group means differ by 1.82%; that is sampling variation, not a
compiler gain. The earlier 8.35× result used another measurement window; no
compiler regression is inferred from that cross-window ratio change.

Exact records are `selfhost/build/phase16/baseline-01/report.json`,
`baseline-matrix-02/report.json` and `baseline-summary.json`. Measurement uses the
unchanged Phase15 launcher/Phase8 worker, current assembled source, CPU0, 4 MiB
stack, 4 GiB heap and separate validated Bend Base caches. All other compiler and
archive jobs stayed closed throughout the measured window. The first setup failed
before any worker launch because a hand-written identity omitted `canonicalPath`;
its original config/review and failure record remain beside the corrected inputs.

## Cause census and current work

The 459 differences split into **244 parser-origin observations** (122 fixtures,
both lanes) and **215 checker-only observations**. The latter initially split into
169 source/snippet/note rows and 46 checker-content rows; nine note rows require
coordination across those owners. These are ownership partitions, not new passes.

The three known backend differences are also diagnostics: two missing natural-
number snippets and one constructor-pattern arity message. Their exact frozen
witnesses are included in the relevant source/parser investigations.

## First combined full-corpus checkpoint

`wave1-build-02` combines parser source03 and checker source02. Its complete
2,996-observation gate reduces exact differences **459→364**, with **95 new exact
matches, zero lost matches and zero unexpected changes**. Attribution is 82
parser observations and 13 checker observations. All primitive behavior axes still
agree with the reference; the 1,001 positive accepts, 482 validation refusals and
11 exact trust refusals remain. Strict check results are 1,211 pass / 287 fail.
This is scoped progress, not full conformance and not an installed compiler.

The first composition `wave1-build-01` accidentally omitted the parser's changed
parallel module. Its successful focused build is retained but unselected. The v2
preparation tool now requires each owner's declared file set to equal its complete
actual source/tool delta. The corrected source and full gate are
`wave1-source-02/manifest.json` and `wave1-frontend-01/report.json`.

## Source-range cost experiment

The metadata-only eight-field KTerm candidate keeps every origin at zero. Its
independent controls preserve all 36 focused outcomes, raw parse projections and
all 28,780 Base terms. The Base JSON grows 3,653,389→4,516,789 bytes (+23.63%).
In the exclusive matched-source ABBA matrix, Phase15 takes **24.2841 s** and the
candidate **24.5297 s**, a **1.01% process-time increase** (1.07% request time).
Maximum RSS rises 1,384,712→1,508,412 KiB (+8.93%). TypeScript takes 2.8936 s in
this window. There are two samples per Bend image; these figures neither prove
zero overhead nor measure populated source ranges. The host ABI patch is reviewed
explicitly. Records: `spans-matrix-01/report.json`, `spans-host-review.json`.

A separate common-child rebuild helper replaces 105 repeated field projections
at 15 sites with 15 helper calls, reducing source bytes by 275 while adding seven
physical lines and one definition. Its checked build and 22 control groups pass;
its speed is unmeasured. These results justify instrumenting actual occurrence
ranges, then measuring the final combined cost before promotion.

## Work in progress

Later isolated parser and checker corrections are being combined with source
ranges. New controls also expose behavior gaps outside the inherited corpus;
those are retained as semantic failures, not reclassified as diagnostic issues.
The installed production compiler remains Phase15. No Phase16 candidate has yet
passed the final performance, full backend, history and release gates.


## First populated-range full sweep: retained regression

The isolated `spans-integration-build-02` passes its genuine checked build,
unchanged v5 derivation, 36 focused cases and 28 source/cache ownership controls.
Its targeted 169-observation checker-span group makes 141 newly exact with no
primitive changes; 28 strict differences remain in specific lowering/trace spans.

The broader `wave2-frontend-01` correctly **fails**: although 283 observations
become exact and the total difference count is 182, six formerly exact rows are
lost and 14 rows change from parse refusal to load refusal. All seven affected
fixtures have rejected partial parse books containing malformed ranges; host
validation replaces the original parse diagnostic. No other exact rows are lost.
The candidate remains unselected. `behavior-differences.json` and
`lost-exact-differences.json` retain every regression beside the raw full vector.
The next candidate must repair the producer/failed-result ownership boundary,
retain original parse error priority and rerun the complete gate. These totals
are diagnostic evidence, not an accepted improvement over the 364-difference
checkpoint.


## Populated-range performance gate

The first exclusive matched-source measurement of actual origins is slower:
**25.5882→28.1905 s** (+10.17% process / +10.61% request) versus Phase15.
TypeScript takes **2.8902 s**, so this candidate is 9.75× TS in this window
(Phase15 is 8.85× on the same final source). Peak RSS is 1,452,500→1,478,180 KiB
(+1.77%). Every timed row passes ordinary type/trust checks; this does not erase
the candidate's separate known full-corpus failures. All intentional competing
compiler/profile/archive jobs were closed for the six serial ABBA rows.

This exceeds the 3% investigation threshold and is **not approved for promotion**.
The [range-cost experiment](../../experiments/phase16/P16-range-cost.md) starts
matched-source CPU profiling and a bounded allocation/lexer investigation before
a confirming exclusive comparison. The matrix uses each frozen snapshot's cache
verifier, supporting its genuine cache2 or cache4 contract; every host delta is
reviewed explicitly. Records: `populated-span-matrix-01/report.json` and
`populated-span-host-review-01/review.json`.

Current integrated source is **15,580 lines / 13,283 nonblank / 527,431 bytes**,
1,550 definitions / 789 laws / 63 types in the same 59 maintained modules. That
is +292 lines (+1.91%), +51 definitions, −1 law and no net new types versus Phase15.
The direct range model removes structural/text matching, but the phase does not
yet reduce total source size; later work must count its helpers honestly.


## Corrected populated-range full sweep

`spans-integration-build-04` now passes the complete no-regression gate in
`wave3-frontend-01/report.json`: **459→145 exact differences**, **314 new exact
matches**, **zero lost matches**, and unchanged primitive behavior on every one
of the **2,996 observations**. The original 1,001 positive accepts, 482 validation
refusals and 11 exact trust refusals remain. All fourteen observations from the
seven failed partial-parse cases are exact again. The fix repairs the producer's
missing endpoint; the host does not interpret embedded Error tags.

The remaining 145 differences are 64 parse and 81 check: 128 parser-origin rows
(64 fixtures in both lanes) and 17 checker-only rows. The assigned 169-row span
group is now 160 exact / nine strict differences. Both targeted backend natural
literal snippets are exact. These are healthy correctness checkpoints; the
complete backend/history/release gates and performance recovery are outstanding.

CPU profiles on the same assembled source retain complete raw trees and streamed
summaries under `populated-span-profile-01` and `phase15-matched-profile-01`.
They show additional GC/front-end/host validation work; sampling is diagnostic,
not an alternate speed comparison. A bounded common-constructor allocation
experiment and an independently verified eager recursion-scan guard are underway.

## Corrected fourth wave: 51 exact differences remain

The healthy checkpoint is now `wave4-build-02` (API `833139041d474d1072365089e3b57951716ca38ee50e3653887fd2783822b35e`).
`wave4-frontend-02` passes the strengthened gate with **459→51 differences**,
**408 new exact matches**, no Phase15 losses, and **94 new matches / zero losses
relative to integration04**. All 2,996 primitive outcomes still agree with pinned
TypeScript. The remainder is 22 parse and29 check observations: 44 parser-origin
rows and seven checker-only rows. This is not full conformance or a release.

The integrated increments are parser semantic62, token-context14, literal8,
checker trace8, quiet TODO1 and template-local numbering1. The literal candidate
also preserves all32 complete-book/Base/loader/provenance controls. The token
candidate preserves all20 positive controls. Quiet TODO has one explicitly
retained mixed source-hole/open-law count gap outside the corpus.

An integration error was found and retained. The first wave4 vector has52
differences and passes the older Phase15-only gate, but loses the newly exact
bare-family observation from integration04. Its semantic-parser owner patch
accidentally removed the independently validated arity-zero predicate. The new
`frontend-gate-v2.mjs` requires an accepted previous checkpoint and forbids losing
any of its exact matches. Reaudit of the old vector correctly fails in
`wave4-adjacent-audit-01`; source02 restores the predicate and reruns the full
corpus. All eight bare-family semantic controls are exact again. The original
52-difference result is not selected or presented as monotonic progress.

The maintained59-module source is **15,616 physical lines /13,313 nonblank /
535,980 bytes**, with1,566 definitions,777 laws and63 types. Versus Phase15 this
is **+328 lines (+2.15%)**, +67 definitions, −13 laws and no net new types. The
explicit range/error model simplifies ownership but has not reduced total LOC.

## Fourth-wave performance remains a deficit

`wave4-matrix-01` compares Phase15 against the first wave4 image on identical
final wave4 source: **25.9805→29.0659 s (+11.88% process /+12.36% request)**.
TypeScript averages **2.9332 s**; ratios are8.86× and9.91× respectively. Peak RSS
is1,568,160→1,676,856 KiB (+6.93%). All six workload rows pass type/trust checks,
all intentional competing compiler jobs were closed, and the exact host delta
reuses byte-identical previously reviewed changes. This timing does not waive
that image's separate lost-family-match failure. The corrected source has not
yet received its final release comparison.

The earlier scan/copy composition shows only0.47% improvement, within variation,
and higher peak memory; it is not recovery. ASCII-width reuse removes proven
rescans (Base50,102→1,985 width calls) but likewise does not establish whole-host
recovery. The next bounded experiment reuses the existing immutable book index
for template membership; it adds no helper/type/pass. Its operation controls and
24 complete specialized-book comparisons pass; exclusive timing is pending.

Delegated agents stopped on an account usage limit after saving their checked
token/import candidates. Root completed the token/literal/trace work locally.
The import candidate makes its original14 rows exact but exposes12 remaining
boundary differences, including alias-law/type freshness; it is unselected.
Invalid-marker identity is under separate paired validation. Release/backend/
history/replay/CLI gates, final simplification and evidence recovery remain open.


## Fifth wave and measured null optimization

`kind-origin-build-01` passes `wave5-frontend-01`: **459→48 exact differences**,
411 newly exact and zero lost versus Phase15; **51→48**, three new and zero lost
versus wave4. All 2,996 primitive outcomes remain exact. The
[invalid-binder correction](unbound-binder-marker.md) preserves an existing invalid
marker until checking; the [kind-origin correction](kind-origin-fallback.md)
retains the original expression as a location fallback. Neither adds a helper,
type or valid term variant.

The [template index experiment](template-membership-index.md) is closed and
unselected: 28.8561→28.8768 seconds, effectively flat despite improved operation
counts. The [stage attribution](stage-cost-attribution.md) identifies loading
and host source validation as useful next investigations, but baseline stage
variation prevents assigning a precise causal delta or claiming recovery.
Delegated agents became available again during this continuation.

The next bounded [integration](../../design/phase16/wave6-integration.md) combines
local declaration eligibility, import diagnostics and source-module name display.
Its boundary controls expose a preexisting alias/local-binder resolution error;
that semantic gap remains explicit and under separate investigation. None of
these isolated checkpoints is installed. Final backend, histories, standalone,
CLI, performance and durable evidence recovery gates remain required.


## Sixth wave: 24 differences and all maintained backend rows exact

`wave6-build-01`, API `9fda62d7a29434b0bc3abe61a768189e68a9e571cfd41f7ad8aeda56bcf6cf24`,
passes `wave6-frontend-01`: **459→24** exact differences, 435 new exact matches and
none lost versus Phase15; **48→24**, 24 new and none lost versus wave5. All 2,996
primitive outcomes remain exact. The remaining 24 are 22 parser-origin rows
(11 fixtures in both lanes) and two checker-only rows. This is not full conformance.

The [declaration](parser_declarations.md), [import](import-diagnostics.md) and
[module-display](module-diagnostic-names.md) changes compose through an explicit
ownership merge. The integrated 93-observation control selection has 90 exact
matches, with only the retained alias-binding and annotated imported-law gaps.
`wave6-backend-01` passes **41/41 exact** with the unchanged pinned Clang16 setup
and previous selection. The three historical backend diagnostic differences are
cleared. This finite selection is not universal backend equivalence.

Maintained source is **15,759 physical / 13,436 nonblank lines / 544,617 bytes** in
59 modules, with 1,585 definitions, 776 laws and 63 types. Versus Phase15 that is
+471 physical lines (+3.08%), +86 definitions and −14 laws. One existing printer
environment type gains a separate file-context constructor. Source ownership and
error paths are more explicit, but total source has grown; there is no LOC
reduction claim. Counts are frozen in `wave6-source-counts-01.json`.

The [Base-prefix law experiment](checker-base-prefix.md) proves its scoped reuse
law but removes only 28,752 of 2,170,908 freshening visits on actual compiler
source (1.3244%). Its cache-ABI optimization is deferred. More useful evidence is
that ordinary elaboration grows about 105k alias-walk nodes into 2.17M terms.
Literal expansion and repeated pattern substitution are now under investigation;
no new complete-workflow speedup follows from these operation counts.

The installed compiler remains Phase15. Local-law parameter diagnostics, dotted
alias/local binding, imported declaration context, literal identity and checker
chronology remain active, along with final history/performance/release gates.


## Seventh wave: lexical resolution and local law order

`wave7-build-01`, API `fa08f98caf401f717ab69a71199f22bd7c4295c73d2a4694d4540b24da71bb0f`,
passes `wave7-frontend-01`: **459→18** exact differences, 441 new exact matches
and no losses versus Phase15; **24→18**, six new and none lost versus wave6.
All 2,996 primitive outcomes remain exact. The remaining 18 are 16 parser-origin
rows (eight fixtures in both lanes) and two checker-only rows. The local law
parameter fixes close four rows, and lambda binder diagnostics close two.

The [lexical alias correction](alias_lexical_bindings.md) also fixes valid programs
outside the main corpus: lexical bindings take precedence over imported aliases.
The integrated 159-observation selection has 157 exact matches; only the two
annotated imported-law wording differences remain. All16 direct lexical/alias
controls pass on the integrated image. The separate [qualified-pattern fix](qualified_pattern_bindings.md)
closes six erroneous acceptances in its focused60-observation suite; it is not
part of wave7 yet. The [integration plan](../../design/phase16/wave7-integration.md)
and immutable source manifest record complete ownership and overlap checks.

Source is **15,807 physical / 13,479 nonblank lines / 547,961 bytes** in59 modules,
1,590 definitions,776 laws and63 types. Wave7 adds48 physical lines to wave6,
and519 versus Phase15. No net reduction or new timing result is claimed.
Counts are in `wave7-source-counts-01.json`.

The [literal census](checker-compact-literal-census.md) now attributes the loader
expansion: string construction alone creates1,856,151 terms; strings, U32 and
character literals account for roughly2M raw terms before copying. A compact
literal representation is a much larger structural opportunity than Base-prefix
reuse, but correctness and complete-workflow speed remain unmeasured. The
[completion design](../../design/phase16/program-completion.md) addresses deferred
TODO reporting separately from full live-instance chronology. Contextual module
parsing, remaining first-error cases and all final promotion gates remain open.
Production stays Phase15.


## Eighth wave: final completeness and qualified pattern eligibility

`wave8-build-01`, API `f2f67a611488b39c830f61973f6705f7e2ea8bb9711850df0fe5b721f5a725a5`,
passes `wave8-frontend-01`: **459→16** exact differences,443 new exact matches
and no losses versus Phase15; **18→16**, two new and none lost versus wave7.
All2,996 primitive outcomes remain exact. All remaining main-suite differences
originate in parsing: eight fixtures in both lanes. `wave8-backend-01` again
passes the unchanged41 paired backend rows exactly with pinned Clang16.

The [program-completion entry](program_completion.md) checks live instances before
final source incompleteness and returns the materialized book through ABI2. The
[qualified-pattern fix](qualified_pattern_bindings.md) closes six erroneous
acceptances outside the main corpus. The independent [constructor-note guard](checker-constructor-note.md)
removes the false F32 suggestion while preserving the real datatype suggestion.
The integrated198-observation controls have195 exact matches; the two imported
law wording differences and one same-body instance chronology gap remain.
Integrated host10 and direct result/prefix/operation8 controls also pass.

Source is **15,842 physical / 13,509 nonblank lines / 549,933 bytes** in59 modules,
1,595 definitions,776 laws and63 types. This adds35 Bend lines to wave7. The first
wave8 preparation stopped because one valid selection used array format; the
failed source01/tool are preserved, source02 accepts both supported formats,
and only source02 was built. Counts are in `wave8-source-counts-01.json`.

The [isolated completion cost matrix](program-completion-cost.md) is flat:
wave7 takes29.2656s and program-completion01 takes29.3768s (+0.38%), with unchanged
memory; TS takes2.9708s. This is a semantic correction without a demonstrated
speedup. It does not replace final combined-image timing. Contextual module
completion and compact literals remain separately checked candidates; production
stays Phase15 and final history/release gates remain open.


## Ninth wave: contextual module parsing

`wave9-build-01`, API `d0d51f88d88f9d124bda5478844a346cc1e2f9983d6fd9c60d7b70b37dfbe0a4`,
passes `wave9-frontend-01`: **459→2** exact differences, 457 new exact matches
and none lost versus Phase15; **16→2**, fourteen new and none lost versus wave8.
All 2,996 primitive outcomes remain exact, including the original 1,001 positive
accepts, 482 validation refusals and eleven proof-trust refusals. Both remaining
rows are `check/monad_do_destructure.bend`, parse and check. This finite corpus
does not cover all semantic boundaries found by the independent controls.

The [contextual module parser](contextual-module-parsing.md) uses completed
imports and prior declarations when parsing each body. Header discovery retains
ordered imports before a later header error; a completed declaration's semantic
error takes precedence over a later top-level parse failure. It parses each
uncached physical body once and runs one graph finalizer. Standalone APIs keep
their existing result shapes. The integration checks complete owner deltas and
three-way merges against their common source ancestor.

`wave9-backend-01` passes all 41 maintained paired backend rows exactly with
pinned Clang16. Integrated controls have 197/198 exact observations, retaining
the known same-body live-instance chronology gap. The supplied-source 39 and
host-loader 43 controls pass their declared contracts, each retaining one
inherited decorator/import wording difference. All ten completion-host controls
pass. These gates validate this image, not subsequent representation changes.

Source is **16,038 physical / 13,676 nonblank lines / 561,327 bytes** in 59 modules,
1,621 definitions, 776 laws and 66 types. The module context adds 196 Bend lines,
26 definitions and three explicit records over wave8. Total growth versus Phase15
is 750 lines (4.91%); improved ownership has not reduced total source complexity.
Counts are frozen in `wave9-source-counts-01.json`.

The separate [constructor-scope correction](contextual-constructor-scope.md)
fixes local constructor shadowing of a far fillable law and alias-prefixed
constructor freshness in eight exact controls. The [compact-literal candidate](checker-compact-literals.md)
reduces the same source's freshened book from 2,171,045 to 152,620 terms while
retaining every located term. Those are structural counts, not a speed result.
Its initial union with wave9 and constructor scope passes checked construction
and the maintained 36 controls; full integration and canonical memo identity
remain under validation. No Phase16 image is installed. Final same-image
histories, CLI, performance and release gates remain required.
