# Removing unused scans and duplicate range copies

The populated-range integration initially cost 10.17% more process time than
Phase15 on the same assembled source. The diagnostic profiles justified two
bounded changes; neither changes the range model or adds a compiler pass.

The [recursion-scan design](../../design/phase16/unsafe-recursion-scan.md) replaces
one strict boolean conjunction with an existing lazy branch. Safe definitions
still call `contains_self` exactly as before. Unsafe definitions immediately
return their existing zero pending-recursion count. Private instrumentation of
the genuinely checked images confirms all eight result controls: safe scan
counts remain 3/67 or 2/66 for the two body sizes, while unsafe counts become zero.
The source change adds no lines, definitions, laws or term variants.

The independently controlled range-copy change reconstructs `f_span_created`
through one KTerm pattern and constructor. It removes the intermediate
`k_with_children` object, subsequent `k_with_span` copy and redundant projections.
Conditions, child traversal, already located boundaries and metadata are identical.
All 32 complete-book, range, Base, cache, provenance and replay controls pass.
The [allocation experiment](../../experiments/phase16/P16-002D-source-span-allocation.md)
records that component separately.

`range-cost-recovery-source-01` composes exactly those two owner files onto
integration04. Its genuine checked build and unchanged v5 derivation pass all
36 focused cases with seven inherited diagnostic differences. Twelve selected
safe/unsafe recursion witnesses agree exactly with pinned TypeScript. This is an
isolated candidate; performance measurement and the final integrated corpus gate
remain required before selection.

Evidence under `selfhost/build/phase16/`:

- `unsafe-scan-baseline-02/report.json` and `unsafe-scan-candidate-01/report.json`.
- `spans-allocation-controls-01/report.json`.
- `range-cost-recovery-source-01/manifest.json`, both exact patches and selection.
- `range-cost-recovery-build-01` and `range-cost-recursion-checks-01`.

The first private probe incorrectly encoded native booleans as constructor
objects; `unsafe-scan-baseline-01` retains that setup failure. The corrected
version uses the actual checked ABI. The initial unsafe build completed checked
compilation and v5 derivation, then its older launcher rejected the valid cache4
format during focus validation. Revalidation through the candidate's own frozen
cache4-aware workflow passes in `unsafe-scan-focus-02`; the original refusal is
retained. No candidate bytes or cache guards were weakened to recover the run.

## Exclusive measurement: no useful recovery demonstrated

`range-cost-recovery-matrix-01` completes all six serial rows with every owner
compiler/probe idle. Both images check the identical integration03 assembled
source, using identical integration04 host files and independently validated
API-bound caches. Runtime and pinned Base are unchanged. Order is TS–B–C–C–B–TS,
CPU0, 4 MiB stack/4 GiB heap, fresh processes and unflushed OS caches.

The integration04 parent averages **27.8895 s** and the two-change composition
**27.7591 s**: **0.47% less process time / 0.55% less request time**, within the
observed sampling variation. TypeScript averages **2.9087 s**, giving 9.59× and
9.54× respectively. Individual Bend rows are 27.443/28.336 s for the parent and
27.608/27.910 s for the candidate. This does **not** establish a useful speedup.
Peak RSS is **1,474,444→1,713,876 KiB (+16.24%)**, requiring investigation or a
confirming comparison before selection. Fewer proven operations do not imply a
measured whole-workflow gain. The cost regression against Phase15 remains open.

The coordination record, exact empty host-delta review, raw requests/results and
complete supervision logs are retained beside this matrix. No compiler is
promoted by this experiment.
