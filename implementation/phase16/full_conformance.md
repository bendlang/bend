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
