# Phase 29: checked emitted-program integration

Final candidate **attempt 04** passes the existing 23-library corpus at all 127
correctness points, all 15 selected upstream JavaScript execution probes with
exact agreement, 22 actual compiler-component observations, and the complete HVM
demo's stdout check. These are selected emitted-program gates, not a renewal of
the full frontend/native/device conformance inventory. Their counts overlap and
must not be summed into a new conformance denominator.

The candidate identity is:

| Artifact | SHA-256 |
| --- | --- |
| Selected guarded API | `10510efda268bac1f31cc8fed87a9315e8f9edfa15aad6b90b0d96756c217b11` |
| Genuine checked parent | `37218b8a6f954bd4478502e79359080994c620b66f99d5e324627c8e740b1ea2` |
| Runtime, unchanged | `40823818afd57a6c37e055272dc332f461955a7cd225f67d66194f0d43ec823f` |

The maintained workflow verifies the immutable checked attempt and its guarded
derivation before and after acquisition/validation. The selected API is a
`derived-b1` artifact with an identified checked parent; it is not reported as a
new self-reproduced compiler fixed point or an independent kernel proof.

## Existing corpus and upstream execution

The corpus runner reuses Phase 25's frozen source metadata, 127 expected points and
paired original/upstream module receipts. All 23 sources are freshly emitted by
attempt 04 and their actual exported library functions execute. Coverage includes
host boundaries, scalar arithmetic, Boolean choices/workers, membership,
list reverse/map/fold, remaining arguments after matching, partial application,
closure capture, strings, trees, term substitution/freshening/normalization,
index traversal, Nat reconstruction, and pinned U32 tables/wide matches.

The original Phase 26 runner and Phase 25 campaign helper are copied and retained.
The [integration launcher](../../selfhost/tools/performance/phase29/integration-corpus.py)
derives copies with only CPU 3→CPU 6 and explicit original-path bindings changed.
Sources, expectations, timeouts and execution logic are unchanged. It verifies
the frozen metadata/source hashes and both saved baseline/reference receipts.
All derived/original launcher bytes and exact transformations are preserved.

The 15 upstream cases use the unchanged Phase 26 selection, now
[tracked under Phase 29](../../selfhost/tools/performance/phase29/integration-upstream-selection.json)
with SHA-256 `e9660d1fb35883349e5e13ce4b0b7fff5cd950a54b40e9c9e702721907fecf0c`.
They cover literal/table/bit-variable/wide U32, word matching/sharing/contraction,
ternary selection, F32 literals, defaults, absurd tails, closure matching, shared
constructors, erased match arms and Nat widening. Both pinned upstream and the
candidate report 15 **checked runtime executions**, all passing, with zero exact
differences, zero discrepancies and healthy workers. These are `js` lanes,
not parse/check-only observations. The workflow uses CPU 4, the attempt's 4 GiB
phase/runtime heap and 4 MiB stack; the corpus uses CPU 6, 1 GiB heap and 4 MiB stack.

| Attempt | Corpus | Upstream JS | Descriptive validation wall time |
| --- | --- | --- | --- |
| Superseded 03 | 23 libraries / 127 points pass | 15/15 exact | 116.18 s corpus; 40.80 s upstream selection |
| Final 04 | 23 libraries / 127 points pass | 15/15 exact | 116.52 s corpus; 39.54 s upstream selection |

The earlier 03 passes are retained. Broader acquisition subsequently found
emission failures for symbolic regression and ray tracing, so that passing
subset did not qualify 03 for release. Attempt 04 adds the reviewed rejection
fences/bounds and is freshly revalidated here. The parent phase report and
semantic review explain those retained counterexamples and their fix; this
report does not hide them behind a successful subset.

These wall times are acquisition/validation observations with other work on
separate CPUs. They are not controlled compiler-throughput or generated-program
speed measurements.

## Actual compiler component and whole application

The checked candidate freshly emits the unchanged Phase 27 extraction of
`has_name`/`has_name_next` from the compiler. The existing oracle rechecks the
extracted source fragment and tests 12 direct membership inputs plus 10 wrapper
inputs: empty lists, first/middle/last hits, misses, duplicates, Unicode, embedded
NUL, case sensitivity, multiple sizes/seeds and U32 wrapping. All 22 observations
pass. The positional host-list adaptation is explicit; the measured wrapper also
constructs its list and reduces Bool to U32, as documented by the existing oracle.

Component module SHA-256:
`b7f5e36ce94707a915812932a3b4d0cf0b4672c8e59166e715e015dbb976f629`
(67,129 bytes). Its checked emission and oracle execution take 4.67 s and 0.12 s
respectively as descriptive acquisition costs.

The HVM demo source remains the exact pinned original used in Phase 28, with its
original embedded program and inputs. Attempt 04's complete emitted ESM program
executes successfully with empty stderr and exact stdout:

```text
&S{#0{()},#1{()}}
- Itrs: 79 interactions
```

The printed normal form agrees with the source comment and prior executions;
the 79-interaction count is a differential oracle, not an independently established
golden. Candidate program SHA-256:
`e0d1a3d4111649c282f3343dc44792ab10146f7ab47ab0c5f22fb6a561df92c7`
(224,510 bytes). Its 7.13 s emission and 0.22 s first complete process are descriptive
acquisition costs, not comparative performance results.

The prepared whole-process timing configuration contains the exact saved
TypeScript CommonJS program, old Phase 27 ESM program and new candidate ESM program,
with all source/compiler/program receipts. It requires the three-output timing
runner; the unchanged Phase 28 runner accepts only two outputs. Any later timings
belong to the parent report's clean campaign, separate from this acquisition.

## Compiler-produced mechanism check

The final emitted Mandelbrot fixture is separately instrumented using the same
frozen counter transformation as the disposable prototypes. The launcher verifies
the checked emission receipt, original module hash and exact runtime 40823818
prefix. It writes distinct instrumented bytes; the original measured module is
unchanged. Ten calls to `bench(128,524800)` all return 128.

| Runtime operation, ten calls | Disposable prototype A+B | Compiler-produced final 04 |
| --- | ---: | ---: |
| `apply` | 27,030 | 26,970 |
| `fn` descriptors | 7,750 | 7,750 |
| Bound `fn` descriptors | 60 | 60 |
| `call` | 19,330 | 19,270 |
| `jump` | 7,700 | 7,700 |
| `apply` argument-array copies | 27,030 | 26,970 |
| Copied `apply` argument slots | 46,500 | 46,390 |

The compiler reproduces the intended descriptor reduction. Its six fewer
`apply`/`call` operations per invocation also have a visible source explanation:
the compiler inlines the wrapper's two `and`, two `sub`, one `shrn` and one
`to_nat` operation, while prototype A deliberately transforms only the inner
helpers. The compiled fixture still performs 2,697 `apply` operations and creates
775 descriptors per 128-iteration invocation.

This accounting measures named runtime operations only. It excludes argument
literals, projection arrays, arbitrary closures, BigInts, allocation bytes and
JIT/GC behavior. Instrumented times are not speed evidence; matching counters do
not by themselves prove equal performance or complete semantic equivalence.

## Reproduction and evidence

Commands run from the repository root after restoring the recorded immutable
attempt and earlier Phase 25/27/28 prerequisites. Output directories must be new;
coordinate CPUs 4/6 and finish all execution before comparative timing.

```sh
python3 selfhost/tools/performance/phase29/integration-corpus.py \
  selfhost/build/phase29/attempt-04 selfhost/build/phase25/corpus-01 \
  selfhost/build/phase29/corpus-04
python3 selfhost/tools/performance/phase29/integration-upstream.py \
  selfhost/build/phase29/attempt-04 selfhost/build/phase29/upstream-js-04
python3 selfhost/tools/performance/phase29/integration-acquire.py \
  selfhost/build/phase29/attempt-04 \
  selfhost/build/phase29/component-candidate-04 \
  selfhost/build/phase29/application-candidate-04
python3 selfhost/tools/performance/phase29/integration-counters.py \
  selfhost/build/phase29/fixture-candidate-04/candidate.mjs \
  selfhost/build/phase29/fixture-counters-04
```

Raw reports are under `selfhost/build/phase29/` and included by the parent
phase's preservation workflow: `corpus-01`, `corpus-04`, `upstream-js-01`,
`upstream-js-04`, their launcher directories, `component-candidate-04`,
`application-candidate-04` and `fixture-counters-04`. Source/output/tool identities,
commands, process status, complete stdout/stderr and oracle observations are
retained. Each acquisition checks inputs again at completion. No additional
comparative timings were executed by these integration tools.
