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
