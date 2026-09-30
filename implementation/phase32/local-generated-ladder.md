# Local-data statement and tuple experiments

The [prospective ladder](../../design/phase32/local-generated-ladder.md) starts
from the installed Phase31 checked07 output. Separate saved-output derivatives
test return-position field statements, canonical Array.get producer/consumer
fusion, and their combination. A freshly checked production statement compiler
is a distinct fourth candidate; public runtime and fallback behavior remain
unchanged. This report does not claim an actual fusion implementation yet.

The statement derivative finds 22 return-position field-unpacking arrows in the
full pair module and three in the independent fold. It captures the original
field vector outside a fresh nested binding scope, then reads fields in order
and returns the original arm. Initial-zero rebinding arrows remain intact.
Every edit has a verified exact inverse. Generated module size increases by
978 bytes for the pair and108 bytes for the fold; this transformation is not a
line-count reduction in those emitted artifacts.

The fusion derivative finds six consumer shapes in each of the pair and batch
private closures, plus one fold consumer. It retains each ordinary consumer,
adds a private clone accepting handle/value fields, and uses a private bridge
to evaluate prefixes/handle/index once and perform the original backing read
before entering the clone. The scalar read reuses `arraydata`, `Number(index)`
and modulo indexing. Pair/fold output grows by4033/444 bytes. This first prototype
has a separate bridge and clone; a production emitter may combine them if its
typed proof establishes the same evaluation order.

`local-01` preserves all derived bytes, exact edits/inverses, consumed deriver and
Node's embedded Acorn8.16 parser identity. `local-actual-01` adds root's checked
statement compiler from `emission-01`, rebinding only the existing pair benchmark
export. The production emitter recursively handles nested return arms and lets;
its results are measured separately from the narrower JavaScript prototype.

## Correctness before timing

All five selfhost variants plus pinned TypeScript pass six complete pair outputs
against the independent BigInt oracle. Each selfhost variant also preserves all
four physical arrays and the exact328,966 allocation/read/write events, including
the newly scalar read sites. Seventeen public mutation/raw/forged/constructed/
saved-partial controls agree. Raw receipts are `local-pair-controls-actual01`.

The separate one-array fold passes41 oracle points, including n4096/seed17 with
result2339999928. Twenty full state/native-event checks cover initial zero,
one step and wraparound sizes130/257 across the five variants. Seven public
mutation boundaries and the retained delayed-write negative witnesses pass
(`local-fold-controls-actual01`).

`local-order-controls-01` reuses the exact preserved fusion bridge and scalar-read
body in ten order witnesses: earlier argument writes, handle/index evaluation
once, consumer writes before scalar use, aliasing, wraparound, ignored values
and repeated reads around a write. A deferred-read implementation returns99
where the captured original value is7. The exact preserved deriver also refuses
an unknown producer and a record-vector consumer substituted for canonical
tuple shape. These are additional diagnostic controls, not public ABI changes.

The new Bend scope fixture exercises scalar prefixes, nested unpacking, repeated
source names and initial/loop-to-zero paths. Both checked07 and actual01 agree
with40 BigInt recurrence points (`a' = 3a + 27` modulo2³²) and three public
mutation cases. Two failed preparations remain: the first acquisition omitted
its output directory; the second source put a scalar let before a parameter
match, which Bend's parser refuses. The rejected source is retained as
`local-scope-02/failed-source.bend`. The corrected source unpacks parameter and
field first, then introduces the shadowing scalar lets; both emissions pass.

The frozen six-role/two-case timing plan is `local-plan-01`. It binds47 exact
input identities and retains the unchanged pair p0 and fold n4096/seed17 checks.
Correctness acquisition times above are not throughput measurements.

## First controlled screen

The root granted an exclusive CPU3 window; it closed in23.41 seconds.
`local-screen-01/report.json` contains three fresh rotating samples with the
existing100ms warmup/150ms target screen. Medians in milliseconds:

| Variant | Full pair p0 | Independent fold n4096 |
| --- | ---: | ---: |
| Checked07 | 17.7161 | 0.56503 |
| Statement derivative | 10.1847 | 0.46870 |
| Actual checked statement compiler01 | 9.0836 | 0.40227 |
| Fusion derivative | 12.1565 | 0.43365 |
| Combined derivative | 8.9422 | 0.42153 |
| Pinned TypeScript | 1.26034 | 0.06305 |

Every candidate has disjoint faster ranges than07 on both fixtures. On the
complete pair, statement-only output saves42.51%, actual recursive statement
lowering saves48.73%, fusion-only saves31.38% and the combined derivative
saves49.53%. The statements therefore have a substantial generated-program
effect despite adding a small number of bytes. Timing alone does not establish
whether avoided closure allocation, inlining or another V8 mechanism causes it.

This is selection evidence, not a completed confirmation. Fold halves slow
by9–20% under the short warmup; the actual statement compiler also beats the
combined narrower derivative on that fixture. The prospective next step is a
real checked compiler that combines recursive statement lowering with typed
tuple fusion, followed by unchanged order/state controls and a longer paired
confirmation. Older Phase31 numbers are not substituted into these comparisons.
