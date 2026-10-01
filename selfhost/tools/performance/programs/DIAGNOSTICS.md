# Generated-program profiles and code comparison

Use diagnostics to investigate a measured slowdown in the JavaScript emitted by
the TypeScript and Bend compilers. The [timing loop](README.md) measures execution
without a profiler. Diagnostics run afterward, or independently against the same
frozen modules, and produce CPU profiles, sampled allocation profiles and a
structural comparison of generated JavaScript. They do not rebuild either compiler.

Commands below run from the repository root. Every output directory must be new.
Linux, Python 3.9+, `taskset` and the recorded Node **24.18.0** are supported.
The analyzer uses Node's embedded **Acorn 8.16.0**, records its hash and rejects
other parser versions rather than falling back to text matching. Put Node on
`PATH`, or add `--node /absolute/path/to/node` to a command. No npm installation,
external profiler or inspector network listener is required.

## Start from an ordinary timing run

```sh
PROGRAMS=selfhost/tools/performance/programs

# Up to 20 seconds of ordinary timing, then a separate 60-second diagnostic cap.
python3 "$PROGRAMS/run.py" --budget 20 \
  --diagnostics all --diagnostic-budget 60 \
  --out selfhost/build/programs/fast-with-diagnostics-01
```

This retains the ordinary 20-second timing protocol. Diagnostics have their own
ceiling, so the combined request can take up to 80 seconds plus cleanup/reporting.
The diagnostic phase starts only after timing succeeds; its durations never
replace the unprofiled samples or become speed ratios. Add a prepared `--candidate`
to the timing command to compare all three roles. Candidate preparation stays
outside both execution budgets; see the [preparation commands](README.md#prepare-a-checked-candidate-once).

An existing successful run can be investigated without repeating its timings:

```sh
python3 "$PROGRAMS/diagnose.py" --budget 60 --mode all \
  --from-run selfhost/build/programs/fast-01 \
  --cases local-pair,local-fold \
  --out selfhost/build/programs/pair-fold-diagnostics-01
```

`--from-run` accepts the run directory or its `report.json`. It checks successful
coverage, catalog identity and the hashes of the exact copied modules that were
timed. Those modules must still be available and unchanged. The default selection
is the timing run's selection; `--cases` or `--set` may select a covered subset.
This option cannot be combined with `--baseline` or `--candidate`: the timing
receipt already fixes every role and module.

## Diagnose a bundle directly

```sh
# Inspect generated syntax without executing the analyzed JavaScript.
python3 "$PROGRAMS/diagnose.py" --budget 20 --mode static --set core \
  --out selfhost/build/programs/core-structure-01

# Collect only CPU profiles, plus the structural comparison used to map frames.
python3 "$PROGRAMS/diagnose.py" --budget 60 --mode cpu \
  --cases local-pair,local-fold \
  --out selfhost/build/programs/pair-fold-cpu-01

# Investigate allocation churn in a prepared compiler candidate.
python3 "$PROGRAMS/diagnose.py" --budget 60 --mode allocation --set fast \
  --candidate selfhost/build/programs/candidate-01/manifest.json \
  --out selfhost/build/programs/candidate-allocation-01

# Include the slowest original program, subject to the requested ceiling.
python3 "$PROGRAMS/diagnose.py" --budget 600 --mode all --set full \
  --out selfhost/build/programs/full-diagnostics-01
```

The default reference bundle contains outputs of the pinned upstream TypeScript
compiler and the Phase32 checked03 Bend compiler. `--candidate` adds a prepared
candidate; `--baseline` explicitly selects another compatible two-role reference
bundle. All selected points must be present. A manually edited JavaScript
prototype remains labeled as such; profiles do not turn it into a checked compiler.
Use `--plan` to verify inputs and inspect the selected protocol without running
generated programs or creating an output directory.

## Choose diagnostic depth

| Budget | Default set | Warmup floor | Requested profile window per point/role/kind |
| ---: | --- | ---: | ---: |
| 20 seconds | `fast` | 50 ms | 200 ms |
| 60 seconds | `core` | 150 ms | 600 ms |
| 300 seconds | `broad` | 400 ms | 1,500 ms |
| 600 seconds | `full` | 1,000 ms | 3,000 ms |

Set and budget are independent. `--cases` chooses exact IDs listed by
`python3 "$PROGRAMS/run.py" --list`. `--mode all` performs static analysis and
separate CPU and allocation runs; `cpu` and `allocation` still perform static
analysis for source attribution. `static` never imports the analyzed module.

Each profile uses a fresh Node process: import, one checked first call, at least
one warmup call and the warmup time floor, then repeated checked calls under the
profiler. CPU sampling defaults to 1,000 microseconds; allocation sampling to
32,768 bytes. Raytrace uses 262,144-byte allocation sampling for every compiler
role: its much larger allocation volume makes finer sampling expensive to retain.
The override is explicit in `plan.json` and each allocation `point.json`. This
trades sampling precision for lower profiler memory; it does not change timing.
The profiled loop stops at its requested window or 10 million calls.
Clock checks use small batches for tiny exports, while expensive exports normally
check after each call. The parent enforces the overall deadline independently.

A budget is a ceiling, not a promised completion time. Expensive first calls and
warmup consume it too; another role or full raytrace coverage may require a deeper
preset. Inputs are never silently reduced. `targetReached:false` with a completed
profile means capture and result validation succeeded but the requested depth was
not reached. Inspect the repetition cap and warnings before interpreting it.
Fewer than 20 CPU or allocation samples receive an explicit warning. A longer
budget raises preset depth; it does not make a single selected case run until
the entire budget is spent.

## Read the artifacts

Open `report.md` first. It links the structural report, side-by-side source view
and raw profiles, and lists coverage, sample counts, reached depth and the largest
self-cost owner. `report.json` retains all frames, warnings, exact identities,
resource receipts and intermediate results.

- `analysis/comparison.html` displays mapped Bend definitions beside the generated
  TypeScript-compiler and Bend-compiler JavaScript. It includes original source
  fragments, locations and normalized tokens. Candidate comparisons appear too.
- `analysis/report.md` and `analysis/report.json` contain complete-module sizes,
  AST counts, function/definition inventories, runtime/support boundaries and
  pairwise deltas. Counts cover constructs such as calls, functions, branches,
  array/object literals, BigInt conversions and recognized runtime helpers.
- `analysis/*-*.tokens.txt` preserves normalized token streams for mapped units.
  Normalization discards comments/whitespace while preserving token kinds and
  values; it does not rename variables or prove semantic equivalence.
- `profiles/CASE/ROLE-cpu/profile.cpuprofile` is the raw V8 CPU profile. Import it
  into a Chrome-compatible Performance profiler for call-tree/flame-chart views.
- `profiles/CASE/ROLE-allocation/profile.heapprofile` is the V8 sampled allocation
  profile. Use a compatible allocation-sampling viewer, such as the Chrome DevTools
  Memory panel's profile import. This is a sampling profile, not a heap snapshot.
- Each profile directory retains its point configuration, `sample.json`, process
  logs and supervisor receipt. `modules/` contains the exact copied generated
  sources; `consumed/` contains the diagnostic tools used.

CPU self cost attributes observations to the sampled leaf; inclusive cost
includes descendants. Inclusive values overlap across different frames and must
not be summed as a partition. The summary weights CPU samples by their preceding
time deltas; these are sampling estimates, not instrumented per-function durations.
Inlining and V8 attribution can put a cost at a caller or helper boundary. A hot
helper location is evidence to investigate, not proof that its guard or dispatch
instructions caused the observed cost. GC, harness and Node frames remain visible.

Allocation sampling explicitly includes objects collected by both major and minor
GC during the window. Reported bytes estimate sampled JavaScript heap allocation,
including churn; they are neither retained heap size nor exact allocation/event
counts. Native/external memory is not comprehensively measured by this profile.
Frame weights use the sum of `samples[].size`. V8 can return samples whose node is
absent from the call tree and a tree `selfSize` total that differs from the sample
total. Such samples remain explicitly unattributed; both totals and their
differences are retained without assigning an unproven cause or double-counting.
Zero samples do not prove allocation-free execution. Profiling changes execution
costs, so compare allocation structure and hotspots here and confirm speed with
the ordinary unprofiled runner. The [Node Inspector documentation](https://nodejs.org/api/inspector.html#cpu-profiler)
describes the underlying capture API.

Static counts are syntax sites, not execution frequencies or allocated bytes.
Full modules include runtime, Base and support code; their size alone does not
describe the cost of the selected export. Function-origin profile locations are
mapped to the smallest containing JavaScript AST function, then to source-owned
definitions where available. Names inferred from registrations or emitter naming
remain labeled as inferred. Unmapped frames and definitions remain visible.
This is generated-source attribution, not a Bend source map or an equivalence proof.
Anonymous functions are distinguished by file, line and column, not just name.
The JSON retains V8's zero-based line/column and display locations; JavaScript AST
offsets and columns use UTF-16 code units.

## Use the shortest useful investigation

Start with a measured slow point and a 20- or 60-second diagnostic selection.
Find a cost that appears both dynamically and structurally: for example, sampled
allocation in a record constructor beside repeated constructor/argument-array
sites. Form one concrete hypothesis and test a small saved-output prototype.
Then rerun ordinary timing for the same cases, widen to `core`/`broad`, and use
`full` when transfer to the slowest original programs matters. A profile alone
does not establish a speedup, semantic correctness or representative application
performance. Compiler throughput and broader conformance remain separate checks.

Diagnostics share the execution lock and memory supervisor with timing and
preparation. Workers run serially, with a 1,024 MiB Node heap, 1,536 MiB process-tree
RSS limit and 2,048 MiB available-memory floor by default; `--cpu`, `--rss-mib` and
`--available-mib` are explicit controls. Limits are polled and can overshoot. Keep
other compiler jobs and benchmarks stopped during measurements. Interruptions,
wrong results and exhausted budgets retain partial artifacts and return a failure
status; inspect them before starting a new output directory.
