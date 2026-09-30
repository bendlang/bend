# Phase28 workload scope and input accounting

This document describes the six complete algorithm workloads before interpreting
any timings. They broaden the earlier diagnostic kernels across rendering,
arrays, sorting, tokenization and expression interpretation. They remain a small,
purposeful benchmark selection, not a statistical sample of production programs.
The upstream suite itself describes some entries as representation or dispatch
stress cases.

## Source and execution boundary

Every fixture begins with the exact bytes of its original
`bench/runtime/<name>/main.bend` Git blob at upstream commit
`018751270e800bc222a93dad7f257083ee53a5f7`. The original definitions, comments and
large-input `main` remain present. The only addition is a pure
`bench(size: U32, seed: U32) -> U32` wrapper calling the existing algorithm at its
published small parameters. No algorithm body was rewritten or replaced with a
host implementation.

The [initial six-case manifest](../../selfhost/tools/performance/phase28/six-cases.json)
records each Git blob, source length and SHA256, complete appended wrapper,
fixture SHA256 and input. For raytrace, the accepted wrapper is the separately
recorded [typed-call correction](../../selfhost/tools/performance/phase28/raytrace-typed-retry.json).
The original source prefix is unchanged across all three raytrace attempts.

Both compilers consume the same fixture bytes and expose the same scalar entry.
Wrappers use ordinary calls, with no added parallel `!` annotation. They execute
as sequential JavaScript libraries; this comparison does not measure Bend's
native CPU parallelism, GPU execution or process-level output. The original
large-input `main` is retained as a library root but never invoked by this
benchmark entry. Input generation, algorithm execution, verification folds and
checksum calculation are included in each call. Module import and compilation
are separate boundaries.

`size` is a real runtime parameter: a tree/batch depth for five entries and image
width for raytrace. `seed` is the starting index for editdist and lexer, the root
index for bitonic and the population seed for symreg; it is unused for Mandelbrot
and raytrace. These measurements select one published small point per algorithm,
not a distribution of sizes or random seeds.

## Exact small inputs

The work counts below follow the source algorithms. They are not counts of host
instructions, generated closures or allocations; a compiler may optimize or
represent those operations differently.

| Program | Wrapper input `(size, seed)` | Source-level work per call | Expected U32 checksum |
| --- | --- | --- | ---: |
| Mandelbrot | `(2, 0)` | Four histogram chunks of 64 pixels; 256 recolor pixels; each pixel evaluation runs 7 fixed iterations in each pass | 887240761 |
| Raytrace | `(80, 0)` | 64 rows × 16,384 column probes; 5,120 active pixels × 4 primary rays | 402971 |
| Edit distance | `(2, 0)` | Four independent 256 × 256 distance grids: 262,144 DP cells | 2065873279 |
| Tree bitonic | `(8, 0)` | 256 keyed leaves; 4,608 leaf compare-and-swap operations; full 511-node verification scan | 971629740 |
| Lexer | `(8, 0)` | 256 generated lines; 20 tokens per line: 5,120 tokens | 1822208108 |
| Symbolic regression | `(6, 42)` | 64 initial candidates plus 32 mutation candidates; 16 data points per candidate | 2490246820 |

### Mandelbrot

[Fixture](../../selfhost/tools/performance/phase28/corpus/mandelbrot.bend).
The wrapper calls `rend(U32.to_nat(size), 7n)`. With histogram depth 2,
`hfold` visits 4 leaves, each calling `hchunk` for 64 pixels. The second pass has
depth `hd + 6 = 8` and revisits 256 pixels after the histogram-to-LUT conversion.
The two passes therefore make 512 pixel evaluations and 3,584 iterations of the
fixed seven-step arithmetic loop. The loop freezes its state after escape but
continues the remaining iterations.

This is **the first 256 pixels of the original 4096 × 4096 viewport**, with indices
0 through 255, all in the first row. It is not a 256-pixel downsample covering the
whole fractal. That restricted geometry limits how well it represents a complete
render, even though both histogram and recoloring passes execute. Increasing
histogram depth changes the covered part of the fixed viewport as well as work
volume; the original large input also raises the iteration count from 7 to 51.
A small-input ratio should not be extrapolated directly to the full render.

### Raytrace

[Accepted fixture](../../selfhost/tools/performance/phase28/corpus/raytrace-typed.bend).
The wrapper preserves the original main's camera setup, replacing its row count
with 6 and supplying width 80 dynamically. There are `2^6 = 64` rows. Crucially,
`rowf` always invokes a column tree of depth 14, even for a narrow image. Each row
therefore visits 16,384 column leaves. Multiplication by an odd constant followed
by masking permutes those column indices; exactly 80 satisfy `xx < width` and
trace an actual pixel.

One call makes **1,048,576 column probes for 5,120 active pixels**. The other
1,043,456 probes return zero after the width test. Four supersamples per active
pixel produce 20,480 primary rays. Each nearest-hit fold tests the fixed nine
spheres. A ray can perform up to five surface-hit steps, with actual continuation
and shadow work depending on the scene and misses.

Consequently, this small case includes substantial tree traversal and bounds
checking in addition to floating-point geometry. It is not a pure floating-point
throughput test. Its width 80 activates about 0.49% of the fixed column positions;
the original width 6000 activates about 36.62%. The large input also uses 4096 rows.
Different widths change the balance between traversal and ray intersection work,
so this ratio cannot be treated as the general cost of rendering.

### Edit distance

[Fixture](../../selfhost/tools/performance/phase28/corpus/editdist.bend).
`batch(2n, 0)` evaluates pair indices 0 through 3. Each pair generates two 256-symbol
arrays over a four-symbol alphabet, then computes a 256 × 256 Levenshtein grid using
two rolling 512-slot rows. Across four pairs this generates 2,048 input symbols,
performs 1,024 DP rows and updates 262,144 cells.

Every cell performs four array reads and one write through the source's staged
pair/record operations. Row initialization, sequence generation, row swaps and
final checksum mixing also execute within the call. The large benchmark increases
the batch depth, retaining the 256-symbol sequence length. These measurements
therefore concern many modest grids, not the cache behavior of a single much
larger grid.

### Tree bitonic sort

[Fixture](../../selfhost/tools/performance/phase28/corpus/tree-bitonic.bend).
`bsort(8n, False{}, 0)` builds and sorts a tree of 256 pseudo-random U32 keys.
The depth-eight bitonic network performs
`(256 / 2) × (8 × 9 / 2) = 4,608` leaf compare-and-swap operations. Structural
merging and rebuilding surround those comparisons; they are part of the workload.

The following `scan` visits all 256 leaves and 255 internal nodes, propagating
minimum, maximum, sortedness and an order-sensitive mix. `stat_out` combines those
fields into the final checksum. The test is therefore build, sort **and verify**,
not an isolated comparison loop. Depth 8 is small relative to the published large
depth 23. Allocation, garbage collection and locality may scale differently at
that larger tree size.

### Lexer

[Fixture](../../selfhost/tools/performance/phase28/corpus/lexer.bend).
`batch(8n, 0)` generates and tokenizes lines indexed 0 through 255. Each line expands
the same 39-character template: four identifier placeholders, three number
placeholders, five operator placeholders, eight literal punctuation characters
and 19 spaces. Identifier lengths range 1–8 and number lengths 1–6, so expanded lines
range 39–82 characters. The exact character total depends on the deterministic
per-index random stream; it was not separately counted in this acquisition.

Every line yields four identifier tokens, three number tokens and 13 operator or
punctuation tokens: 20 total, hence 5,120 tokens across the batch. Generation,
xorshift arithmetic, character classification, token payload hashing and checksum
mixing all execute. The fixture tests many short generated lines rather than a
complete source file, a large string, Unicode input or arbitrary lexical syntax.
The published large input raises the number of lines while retaining this same
template distribution.

### Symbolic regression

[Fixture](../../selfhost/tools/performance/phase28/corpus/symreg.bend).
The wrapper calls `run(6n, 42, 32n, 16n)`: 64 tournament candidates, followed by 32
sequential mutation candidates, each evaluated on the 16 points 0 through 15.
Every candidate constructs a full depth-five arithmetic expression tree with 63
nodes, including 32 leaves. The source-level total is 96 candidate trees containing
6,048 nodes, 1,536 complete expression evaluations and 96 node-count penalty scans.
The complete evaluations visit 96,768 expression nodes; the penalty scans visit
another 6,048.

The workload includes random-tree construction, arithmetic interpretation,
fitness calculation, winner selection, hill climbing and final checksum mixing.
It intentionally stresses constructor dispatch, as its upstream description
states. The large input changes both population depth 6→18 and data points 16→110;
its fixed 32-round climb becomes a much smaller fraction of total work. This small
case is useful as a complete program but is not a representative average for all
interpreters or symbolic systems.

## Checksum evidence and preserved wrapper failures

All six accepted wrappers produce the documented small checksum through both
compilers. The expected values came from the pinned Bend source before emission;
the source comments say they were checked against a C twin or earlier Bend C run.
This phase did **not** rerun those independent C implementations. Agreement with
a fixed 32-bit checksum is a useful regression oracle, not proof that every
intermediate array, image, sorted tree or candidate is identical. There is no
claim of universal backend conformance or correctness across all inputs.

Two raytrace acquisitions were rejected before the accepted variant:

1. `runtime-01/raytrace`, [original wrapper](../../selfhost/tools/performance/phase28/corpus/raytrace.bend):
   both compilers rejected the added `+rr = 6n` local because they could not infer
   its type.
2. `runtime-02-raytrace/raytrace`, [annotated wrapper](../../selfhost/tools/performance/phase28/corpus/raytrace-annotated.bend):
   both also rejected `+rr = (6n : Nat)` at that local. Its fixture and manifest
   remain separate from the first attempt.

The accepted `runtime-03-raytrace/raytrace` uses the typed call
`+rr = U32.to_nat(6)`. Only the appended wrapper changed; the original source,
row count, width, camera setup and expected checksum did not. These are retained
harness construction failures, not evidence that either compiler rejects the
original raytrace program. Both emission failures, commands, stderr and complete
selfhost diagnostics are retained. The successful five other algorithms remain
in `runtime-01`; the selection index records the exact accepted pair for every
algorithm.

No input was silently reduced to obtain a successful result. Timings and their
warmup/startup boundaries belong in the main Phase28 comparison report; this
workload accounting alone supports neither a typical-program average nor
large-input performance extrapolation.
