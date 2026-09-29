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

Independent owners have prospective family plans and isolated preparations.
No Phase16 source is installed and no conformance improvement is claimed yet.
