# Generated-program execution loop

Use this suite when optimizing **the JavaScript produced by the compiler**.
It compares freshly executed outputs from the frozen Phase32 checked03 compiler,
the pinned upstream TypeScript compiler and, optionally, a prepared candidate.
Compilation is a separate preparation step. The ordinary timing command never
builds or imports a compiler.

The checked-in [reference bundle](baseline/manifest.json), compressed modules,
[catalog](catalog.json) and [Bend fixtures](fixtures/) work from a normal clone.
Running the reference does not require ignored historical experiment directories,
an installed compiler or an upstream checkout. Linux, Python 3.9+, `taskset` and
Node 24+ are required. Put Node on `PATH`, or pass `--node /absolute/path/to/node`.
Run the commands below from the repository root; every output directory must be
new. Old, failed and interrupted observations are retained.

## Choose a depth and workload

| Wall-time budget | Default set | Points | Fresh rounds per point/role | Minimum warmup | Target timed block |
| ---: | --- | ---: | ---: | --- | ---: |
| 20 seconds | `fast` | 5 | 3 | 3 calls and 100 ms | 50 ms |
| 60 seconds | `core` | 8 | 3 | 3 calls and 350 ms | 150 ms |
| 300 seconds | `broad` | 14 | 5 | 3 calls and 600 ms | 250 ms |
| 600 seconds | `full` | 15 | 5, except raytrace: 3 | 3 calls and 1,000 ms | 300 ms |

The [validation run](../../../../implementation/phase33/README.md) completed these
presets in **16.4 / 56.7 / 259.4 / 351.1 seconds** on its recorded host. The first
three included TypeScript, baseline and candidate; the full run used TypeScript
and baseline. These are observed totals, not portable runtime promises.

Raytrace uses one warmup call **and** the preset's warmup milliseconds because a
single complete call is expensive. It still executes its unchanged input. The
budget includes verification, extraction, process startup, imports, first calls,
warmup, calibration and timed blocks. It is a **maximum**, not a request to pad a
short run. Changing hardware or adding a candidate can exhaust it before all
rounds finish. Cleanup and report writing may add a small overrun, reported
explicitly. No input is silently reduced and no unfinished case receives a ratio.

- `fast`: one complete edit-distance pair, array fold, scalar zero/8,192-iteration
  canaries, and a complete generic row with serialized state.
- `core`: `fast` plus original Mandelbrot, four-pair edit distance and RLE.
- `broad`: `fast` plus nine original programs; excludes expensive raytrace.
- `full`: all 15 points, including raytrace.

```sh
PROGRAMS=selfhost/tools/performance/programs
python3 "$PROGRAMS/run.py" --list
python3 "$PROGRAMS/run.py" --budget 20 --plan
python3 "$PROGRAMS/run.py" --budget 20 --out selfhost/build/programs/fast-01
python3 "$PROGRAMS/run.py" --budget 60 --out selfhost/build/programs/core-01
python3 "$PROGRAMS/run.py" --budget 300 --out selfhost/build/programs/broad-01
python3 "$PROGRAMS/run.py" --budget 600 --out selfhost/build/programs/full-01
```

Budget and workload selection are independent. Spend more time confirming a
small hypothesis, or select exact catalog IDs. `--cases` overrides the set;
it does not change inputs or expected results. `--plan` verifies the selected
sources and bundles, prints the protocol, and executes no generated program.

```sh
python3 "$PROGRAMS/run.py" --budget 300 --set fast --out selfhost/build/programs/fast-confirm-01
python3 "$PROGRAMS/run.py" --budget 60 --cases local-pair,local-fold --out selfhost/build/programs/pair-fold-01
```

Use 20 seconds for a quick rejection screen, 60 seconds for early transfer,
300 seconds for broader confirmation, and 600 seconds for the slowest transfer
cases. Release admission still requires the relevant semantic gates.
These protocols do not guarantee stabilized V8 performance; even the 600-second
preset has only a one-second warmup floor. Selecting one case with that budget
does not extend its warmup to use all 600 seconds. Inspect drift and
rerun the relevant selection with a deeper preset before accepting a small gain.
These are new protocols: historical Phase28–32 medians are context, never a
denominator for a current comparison.

## Prepare a checked candidate once

Acquire only the set needed for the next experiment. Preparation verifies the
installed release or the supplied checked development attempt, checks the Bend
source, emits each distinct source once, and freezes module/source/compiler
identities. It runs serially outside the 20/60/300/600-second execution budget.
Changing compiler source requires a new checked attempt; preparation does not
build it automatically. See the [checked development workflow](../../../../docs/PHASE5_DEVELOPMENT.md).

```sh
# Installed, verified compiler; no compiler build here.
python3 "$PROGRAMS/prepare.py" --set core --out selfhost/build/programs/candidate-01

# Alternatively, a newly built checked attempt.
python3 "$PROGRAMS/prepare.py" --attempt selfhost/build/my-checked-attempt \
  --set core --out selfhost/build/programs/candidate-02

python3 "$PROGRAMS/run.py" --budget 60 --set core \
  --candidate selfhost/build/programs/candidate-02/manifest.json \
  --out selfhost/build/programs/compare-02
```

The candidate must contain every selected point. Prepare `--set full` if several
selections will reuse it. Preparation also accepts `--cases`; it refuses a changed
catalog fixture, a different compiler target or a compiler that changes during
acquisition. The report preserves the candidate's checked provenance and compares
all three roles in the same run. It never substitutes an old timing for a role.

## Screen a manual generated-JavaScript experiment

A small saved-output transformation can test an optimization before implementing
it in Bend. Supply a complete standalone module with the same catalog export,
arguments and returned result. The generic-row point includes its full-state
serialization adapter; preserve that work in a replacement module.

```sh
python3 "$PROGRAMS/prototype.py" \
  --replace local-pair=/tmp/pair-experiment.mjs \
  --out selfhost/build/programs/prototype-01
python3 "$PROGRAMS/run.py" --budget 20 --cases local-pair \
  --candidate selfhost/build/programs/prototype-01/manifest.json \
  --out selfhost/build/programs/prototype-screen-01
```

`prototype.py` copies the verified reference by default. `--from PATH/manifest.json`
can instead start from a prepared candidate. Repeat `--replace CASE=FILE` to change
several points. The module and its original are hashed and retained; the candidate
is explicitly labeled **Manual JavaScript prototype**, `checked:false`.
Packaging performs no execution or compiler check. Even a successful timing
screen establishes agreement only on the selected fixed results. Promote an idea
through compiler implementation, checked acquisition and relevant semantic controls.

## Read the results

Each output has `plan.json`, `report.json`, `report.md`, copied measured modules,
consumed worker/supervisor sources, and per-process logs and sample receipts.

- `measured` and exit code 0 mean every requested role and round completed and
  returned the exact catalog result. `failed`, `interrupted` and `budget-exhausted`
  retain partial evidence and exit nonzero.
- A fresh Node process performs import, one first call, warmup, calibration and a
  timed block. Reported milliseconds per call exclude import and first-call time;
  these are recorded separately. Timed work includes the exported computation,
  result validation, checksum bookkeeping and the row observer where applicable.
- Roles rotate serially between rounds. Only complete paired rotations contribute
  to statistics. Ratios require **all** requested rounds for that case. Partial,
  failed and unmatched samples remain visible; they cannot become a favorable
  comparison by disappearing.
- Medians, ranges, individual samples, first-call/import costs and half-to-half
  drift are retained. `candidate/typescript` is the current slowdown;
  `baseline/candidate` is the current gain. No overall average claims typical
  production-program speed.

The [15 points use 13 sources](catalog.json). Ten are the existing original
algorithms or mixed tests, at their documented small fixed inputs; five are
diagnostics/canaries. Pair and row share a source, as do the two scalar points.
Mandelbrot covers a narrow strip, RLE uses six elements, and raytrace performs
many inactive column probes. Read the original
[workload accounting](../../../../implementation/phase28/workloads.md) and
[mixed-test scope](../../../../implementation/phase28/applications.md).
This suite measures sequential generated JavaScript. It does not measure compiler
throughput, whole-compiler self-hosting speed, native C/GPU performance or the HVM
application, and it is not a replacement for conformance gates.

## Resource controls and maintenance

Preparation and execution share Phase32's execution lock. One job owns it and
children run serially on an allowed CPU; `--cpu N` selects one explicitly.
Execution uses 1,024 MiB Node heaps, a 1,536 MiB process-tree RSS limit and a
2,048 MiB available-memory floor by default. Preparation defaults to 1,024 MiB
heaps, 1,600 MiB tree RSS and a 180-second timeout per source. `--rss-mib` and
`--available-mib` are explicit overrides; preparation additionally exposes
`--heap-mib` and `--timeout`.

The supervisor samples descendants, stops work on deadline/RSS/host-headroom
failure, and cleans up on SIGINT/SIGTERM. Limits are polled, so they can overshoot;
they are not a kernel-enforced memory reservation or proof against every host OOM.
Do not run unrelated builds or benchmarks alongside a measurement. After an
interruption, inspect its saved status before selecting a new output directory.

The frozen reference is an artifact, not a cache silently refreshed by timing.
Maintainers can create a new one explicitly after agreeing on compiler/source
identities. The TypeScript checkout must be clean at the catalog pin.

```sh
python3 "$PROGRAMS/prepare.py" --role baseline --set full \
  --out selfhost/build/programs/reference-bend-NEW
python3 "$PROGRAMS/prepare.py" --role typescript --set full \
  --upstream selfhost/.bootstrap/upstream-phase23 \
  --out selfhost/build/programs/reference-ts-NEW
python3 "$PROGRAMS/freeze-reference.py" \
  --baseline selfhost/build/programs/reference-bend-NEW \
  --typescript selfhost/build/programs/reference-ts-NEW \
  --out selfhost/build/programs/reference-bundle-NEW
```

The packer retains checked emissions, adapters, receipts, logs and consumed tools;
it reopens the gzip and verifies every archived byte. The resulting manifest uses
relative module paths. Historical absolute paths in acquisition receipts are
provenance, not runtime dependencies. The generated Bend modules also retain
lazy Base foreign-function path strings; none of these pure catalog entry points
invokes them. The reference is portable for these entry points, not for arbitrary
IO exports from the same modules. Review a new bundle before replacing the
committed `baseline/`; a different upstream pin also needs a new catalog and
reference, rather than relaxing identity checks.

Run harness controls serially, separately from measurements:

```sh
node "$PROGRAMS/execute.test.mjs"
python3 -m unittest discover -s "$PROGRAMS/tests" -p 'test_*.py'
```

The tests use small synthetic modules to check result failures, timeouts,
provenance rejection, pairing and resource cleanup. They do not benchmark Bend or
replace the real-corpus runs. With Node outside `PATH`, set
`PROGRAMS_TEST_NODE=/absolute/path/to/node` for the Python tests.
