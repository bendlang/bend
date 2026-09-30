# Phase28 mixed tests and complete application

These five programs broaden the generated-code comparison beyond diagnostic
kernels. They do not form a statistical sample of production programs. The four
mixed tests use their original tiny, fixed inputs; the HVM demo is a complete
parser/interpreter application running its original embedded example. No compiler
source or application algorithm was changed for this acquisition.

## Exact source provenance

Every fixture is a byte-for-byte copy of its file in upstream commit
`018751270e800bc222a93dad7f257083ee53a5f7`. There are no appended wrappers or
rewritten functions in these five fixtures. The
[application manifest](../../selfhost/tools/performance/phase28/application-cases.json)
records source paths, hashes, origins, execution boundaries and complete expected
values. Both compilers receive the same copied source bytes.

The four tests are present in the sparse pinned checkout. The HVM demo is absent
from that working tree because of its sparse selection, but exists in the pinned
Git object. `git show <pin>:demos/pure_hvm5_mini/main.bend` yields the same bytes
as the repository's demo, with SHA-256
`7e7205fd672770e522d9bc76403145203f83f7dce941e269b1370ec3caced63d`.
This is a fixture from the pinned upstream, not a newer application imported into
an older compiler comparison.

Library acquisition reuses the checked upstream emitter and the immutable
Phase27 `attempt-02` selfhost emitter. The full program emitter likewise verifies
the checked attempt and records its API, runtime, Base and driver identities.
Emission durations are descriptive acquisition costs, not controlled compiler
throughput measurements.

## Original mixed tests

Each library run invokes the unchanged exported `main.out()` with no arguments.
The measured boundary includes the computation that constructs the complete
original output value, and excludes the original `IO.print` call. The harness
compares that entire value on every invocation. It does not introduce a new
lossy digest of a larger result.

| Original upstream source | Input and computation | Complete expected value |
| --- | --- | --- |
| `tests/run/morning_program.bend` | Two-entry map; split the eight-character string `a,bb,ccc` into three parts and rejoin; arithmetic, number formatting, comparison and a three-element list | `a-bb-ccc 8 1877 42 lo hello 3` |
| `tests/run/evening_program.bend` | Two-cell floating-point array; two-element set; one-entry map; number parsing and reused tuple | `81111` |
| `tests/run/rle_roundtrip.bend` | Encode the six-element list `[7,7,7,2,9,9]` into three runs and expand it; execute the original test's two checks | `11` |
| `tests/run/map_set_ops.bend` | Three-entry map, two two-entry maps for union, and small sets; original get/delete/pop/union/order/set checks | `11111` |

The goldens come directly from the upstream `#|` lines. All eight checked
emissions and all eight first-call value comparisons passed. The RLE and map/set
outputs are the upstream tests' own encoded assertions, not full dumps of all
internal collections; their equality is scoped to those original observations.

These cases must remain labeled **tiny mixed tests**. Repeating them gives a
useful measurement of those exact computations after warmup, but does not make
their data sets larger. Constant inputs, short traversals and host boundary costs
can influence their ratios differently from larger programs.

The generated exports do not memoize `main.out()`: upstream `run_lib` calls the
function on each invocation, and selfhost `get` evaluates a nullary function
descriptor on each access. Repetition therefore requests the original
computation again. This source-level observation does not claim that V8 performs
no constant propagation, inlining or other optimization inside the generated
programs.

## Complete HVM mini application

The unchanged 1,916-line `demos/pure_hvm5_mini/main.bend` includes a parser,
interaction-calculus evaluator, normalization and output formatting. Its original
embedded program uses Church numerals and shared Boolean negation, applies four
negations to both Boolean inputs, and normalizes the result. Each process builds
the application's original 65,536-cell environment and runs through `main`.

Both checked emissions produce exactly these stdout bytes, including the final
newline, with exit code zero and empty stderr:

```text
&S{#0{()},#1{()}}
- Itrs: 79 interactions
```

The normal form agrees with the embedded program's stated behavior. The exact
interaction count of 79 is a **differential oracle**: it was observed to agree
between the two generated programs. It was not independently established with a
C reference evaluator or a separate formal derivation. Full stdout agreement
does not establish correctness for other HVM source inputs.

### Preserved module-host failure

The initial acquisition named both complete programs `.mjs`. The upstream
`js_book` output uses CommonJS `require`, so Node rejected that output under the
ES module host with `ReferenceError: require is not defined in ES module scope`.
The failure, its complete stderr and its original generated bytes remain in
`selfhost/build/phase28/applications-01/app-pure-hvm5-mini/`.

The corrected acquisition copies those exact upstream bytes to `upstream.cjs`.
The selfhost program stays `selfhost.mjs`, because its runtime uses ES modules.
Both copied files are hash-verified against the original emitted modules; no
generated statement or application function is patched. The complete pair then
passes in `selfhost/build/phase28/application-host-02/`. The initial failure is a
launcher packaging error, not evidence of an application semantic mismatch.

### Process timing boundary

The [application measurement launcher](../../selfhost/tools/performance/phase28/measure-application.py)
measures five fresh complete processes per side with alternating order, pinned
to CPU3 under the same Node24 executable, 4MiB stack and 1GiB heap. Its deadline
is 120 seconds per process. It verifies the full stdout, empty stderr and exit
status for every sample; any failed sample remains an outcome.

The measured interval starts before process creation and ends after complete
stdout/stderr collection and process exit. It includes Node startup, loading,
the original computation and printing; it excludes compilation. There is no
reused warm process. The upstream CommonJS loader and selfhost ES module loader
are therefore part of their respective observed process costs. This comparison
does not isolate evaluator execution time or establish a warmed in-process HVM
throughput ratio.

The launcher uses pipe collection with `communicate(timeout=...)` to avoid the
coarse polling increments of a timeout-based wait on file-backed output. It
records both high-resolution elapsed time and epoch start/end intervals for a
serialization audit. Both sides inherit the same environment after removing all
`BEND_*` variables, `NODE_OPTIONS` and `NODE_PATH`. Raw output, commands, source
and module identities, and the complete expected output are retained with the
Phase28 evidence.

Process timing for this application must be reported separately from warmed
library calls. In particular, its ratio cannot be combined with the tiny tests'
ratios into an unqualified claim about typical generated-program speed.

## Acquisition and reproduction tools

- [Source manifest](../../selfhost/tools/performance/phase28/application-cases.json)
- [Acquisition launcher](../../selfhost/tools/performance/phase28/acquire-applications.py)
- [Full test-value checker](../../selfhost/tools/performance/phase28/check-application.mjs)
- [Checked full-program emitter](../../selfhost/tools/performance/phase28/emit-program.mjs)
- [Recorded module-host correction](../../selfhost/tools/performance/phase28/check-program-host.py)
- [Complete-process measurement](../../selfhost/tools/performance/phase28/measure-application.py)

The acquisition launcher deliberately retains the initial packaging attempt;
the host-correction launcher is the explicit, separately recorded next step.
The main Phase28 report provides the final controlled timings and evidence
recovery instructions. Acquisition times in the raw launch records are not
substitutes for those measurements.
