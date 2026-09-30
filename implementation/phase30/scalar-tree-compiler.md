# A checked compiler for private scalar tree regions

Attempt12 implements the [prospective tree design](../../design/phase30/scalar-tree-compiler.md).
The generated-JavaScript prototype first confirmed a large original-program
gain; its retained warm-up drift is documented separately. This report describes
the actual compiler and does not assign the prototype's speed to its output.

The compiler recognizes precisely two saturated recursive children on the same
native Nat predecessor and a scalar combination. Both child arguments use the
original parent environment. Only their two results are available to the
combination. Existing scalar analysis proves the leaf, arguments, helpers and
combination with one shared helper cache and fuel budget. Cycles outside the
proved recursion shapes fail admission. Public entry keeps its original matcher,
partial application and generic fallback; the new path uses a private explicit
DFS stack and admits public depth at most 32. No host tree recursion is emitted.

The implementation adds one continuation shape beside the current region
emitter. It reuses `JRegion` and `JRegionBuild`, adds no KTerm tag or runtime
representation, and shares the Nat telescope predicate and lambda-body emission.
The existing countdown still requires its original self-tail-call proof.

The fresh checked build passes all 36 focused exact gates in 35.588 seconds;
checked original Mandelbrot emission takes 5.226 seconds. These are acquisition
durations, with independent work on other CPUs, not controlled compiler timings.
Against actual11, emitted output passes 74 independent scalar/original oracles,
130 ordered host observations, four depth-selection diagnostics and 20 traversal
checks. Separate independent testing passes 31 admission books and 96 executions,
including noncommutative subtraction and different left/right state updates.
Another 85 ordered metadata/prototype/copied-length observations pass on the
actual pair. Shared-header regression suites also pass: 22 scalar books/13
executions, 28 ordinary-root books/44 executions and 41 terminal books/88
executions. These counts overlap earlier controls and are not a conformance total.

On original `bench(2,0)`, separate instrumentation measures:

| Named event | Ordinary11 | Tree12 |
| --- | ---: | ---: |
| Generic applications | 6,224 | 104 |
| Function descriptors | 5,438 | 84 |
| Partial descriptors | 4,904 | 60 |
| Jumps | 535 | 25 |
| Force calls | 5,689 | 79 |
| Projections | 270 | 16 |
| Guard evaluations | 260 | 5 |
| Builds / constructors | 8 / 8 | 8 / 8 |

The tree visits 511 nodes, evaluates 256 leaves and 255 combines, with a frame
high-water mark of eight. These are named events, not total allocations or
timing shares. Actual output timings and a separate longer-warmup investigation
are next; broad original-program acquisition already passes all ten checked
results. Installation waits for the combined integration gates.

Current canonical source contains 16,815 physical / 14,359 nonblank lines,
648,564 bytes, 1,849 definitions, 640 laws, 70 types and 66 modules. Against the
Phase29 start this is +608 physical lines (3.75%), +520 nonblank lines and two
small analysis types. This phase improves performance rather than reducing
source length. Experimental tools, reports and retained evidence are counted
separately from the compiler.
