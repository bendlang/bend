# Phase25 emitted-JavaScript diagnostics

`selfhost/tools/performance/phase25/diagnostics.mjs` profiles an **already emitted**
library with a deterministic `bench(size: U32, seed: U32) -> U32` export. It does
not compile Bend, change any compiler/runtime source, or measure compiler startup.
The normal default export object (`default.bench`), a named `bench`, and a default
function are accepted. Every observed return must be the same valid U32; callers
can additionally provide an independently established `expectedResult`.

```sh
node --stack-size=4096 --max-old-space-size=1024 \
  selfhost/tools/performance/phase25/diagnostics.mjs \
  EMITTED.mjs SIZE SEED REPETITIONS FRESH_OUTPUT_DIRECTORY
```

The module exports `runDiagnostic(config, out)`. Required fields are `module`,
`size` and `seed`; `repetitions` defaults to10, `warmup` to3, `exportName` to`bench`,
`samplingIntervalUs` to1000 and `sampleIntervalBytes` to1048576. Optional
`counterRepetitions` defaults to `repetitions`; a small independent value bounds
counter work when CPU/allocation sampling needs many calls. Each mode records
its actual call count. Optional `modes`
selects any distinct subset of `cpu`, `allocation`, `counters`; all three run by
default. `counterRuntime` can identify an exact frozen copy of the candidate's
runtime. It defaults to the repository's current `selfhost/src/runtime.mjs`.
The caller supplies a fresh output path whose parent already exists and enforces
its own subprocess resource/deadline/affinity policy. The tool never overwrites
an existing observation directory. Inputs, Node executable, tool and counter
copy have recorded hashes; the tool and original module are rechecked at closure.

## Separate diagnostic passes

1. Import the original emission, establish/check its result, and warm its exported
   function. This occurs before either profiler starts.
2. Run a CPU sampling pass over repeated calls. Retain the complete inspector
   profile as `cpu.cpuprofile.gz` and an exclusive-frame summary. Microseconds
   are sample time deltas, not instrumented call counts or a causal speed bound.
3. Run a separate heap-allocation sampling pass with both
   `includeObjectsCollectedByMajorGC` and `includeObjectsCollectedByMinorGC` enabled.
   This follows the CPU pass when both are selected, so it has that additional
   execution history. Retain every node and parent relationship in
   `allocation-nodes.ndjson`, every sample in `allocation-samples.ndjson`, and
   profile metadata. Iterative traversal avoids the earlier campaign's deeply
   nested JSON serialization failure. The aggregate is a sampled allocation-size
   estimate, including collected objects, **not retained memory or peak RSS**.
4. Load a separately instrumented copy for operation counters. Tiny runtime
   controls must first produce exact expected values and counters. Warm the
   copied benchmark, reset counters, then acquire its repeated calls. Every result
   must equal the original. All source edits and both artifact identities are
   preserved in `counter-guard.json`.

The loop preallocates result storage outside each profiler, then retains a histogram of
all numeric results, its total call count and a wrapping checksum after stopping
it. Every call is checked immediately against the expected value; repeated
identical outputs are summarized instead of stored redundantly. Inspector, wrapper and
loop overhead are still present. Profiles with too few samples or zero sampled
allocations are weak/insufficient evidence, not proof of zero cost. V8 trace flags
and uninstrumented elapsed-time measurements belong to a separate launcher.
Counter instrumentation changes generated-code shape and JIT behavior; its running
time must never be compared with an uninstrumented benchmark sample.

## Counter coverage and guards

The current selfhost emission uses public runtime `fn` records with
`{arity, code, env, bound}`; it has no `PrivateFunction` class. The emitted module
must start with the complete exact supplied runtime. Every replacement also
requires one exact matching helper. Counters cover:

- Function-record construction; generic application, partial and overapplication.
- `apply` argument-copy arrays from `slice`/`concat`, plus separate overapplication
  prefix/suffix slices. These do not count all generated argument-array literals.
- Tail messages, their observed argument-slot count, forced bounce steps, and
  `call`/`force` entry. Argument slots are not allocations or unique arrays.
- Unary/binary matcher construction and entry, constructor/project calls, and
  deferred constructor-build messages.

Upstream instrumentation requires exact unique bodies of `run_tail`, `run_clo`,
`run_loop` and `run_lib`. It counts their messages, wrapper/closure creation and
entry, partial applications and consumed jumps. It does **not** count every direct
call, compiled loop, inline `$JMP` allocation, arrow closure or program array.
A `run_loop` jump-step does count an inline jump if that helper consumes it.
The two counter dictionaries describe different mechanisms and must not be
summed or interpreted as equivalent total allocation counts.

Both modes refuse unknown helper shapes and an existing `__p25` identifier.
Instrumentation is scoped to the pure standalone benchmark corpus; helper
controls and value equality do not prove equivalence for malformed private
runtime values, arbitrary foreign imports or path-sensitive IO. The copied
artifact has a different path and prepended counter declarations, so its line
numbers and source hash differ from the production emission. Ordinary CPU and
allocation profiles use the unchanged original artifact.

## Tool-level validation

Initial tiny smoke observations at `/tmp/phase25-diagnostics-selfcheck-01/`
use the actual current candidate runtime prefix and the exact current upstream
run-helper text, followed by a hand-authored addition export. They are **tool
controls, not compiler-emitted corpus evidence**. Both return15 for inputs7/8
across all stages; original and instrumented results agree. Candidate controls
pass7/7: exact application, partial application, overapplication, three tail
jumps, unary matching, a binary match and its default. Upstream controls pass3/3:
one jump, a closure with three jumps, and a partial library wrapper. CPU sampling
and collected-object allocation sampling operate under Node24.18.0. The tiny
addition has zero sampled allocation at a1MiB interval; no allocation conclusion
is drawn. Syntax validation also passes.

The later actual-corpus diagnostic acquisitions, frozen tool identities and
preservation status belong to the root-owned Phase25 report. No long diagnostic
run or compiler source modification is made by this tooling workstream.
