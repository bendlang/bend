# Reproduce Phase26

The [design](../../design/phase26/direct-u32-decisions.md) freezes the support and
measurement boundaries. The [report](direct-u32-decisions.md) records outcomes.
All commands below start at repository root. Use Node24.18.0; set `PHASE25_NODE`
for the Python launchers if that binary is elsewhere. Their timing CPU is3.

## Checked candidate and semantic controls

Create a fresh configuration with absolute pinned upstream path, `jobs:1`,
`cpu:"3"`, `profile:"equality"` and `strictExact:true`, then:

```sh
node --stack-size=4096 --max-old-space-size=4096 \
  selfhost/tools/development/workflow.mjs run CONFIG.json NEW_ATTEMPT
```

The attempt contains the genuine checked bootstrap, guarded derivative, frozen
source/host/runtime and36 paired focused observations. For emitted-output controls,
create a JSON config with `cpu:"6"` and `candidate:{api,runtime,base,driver}` using
`attempt.json`'s `.api.file`, `.runtime.file`, `.base.file`, and
`.snapshot.root + "/tools/typed-driver.mjs"`:

```sh
node selfhost/tools/performance/phase26/controls.mjs CONTROLS.json NEW_CONTROLS
```

The [control notes](controls-design.md) document independent expected outputs,
exact fixture/refusal scope and preserved failed source/expectation pilots.

## Frozen corpus and runtime comparison

Restore the Phase25 `corpus-01` directory using its
[evidence instructions](../phase25/README.md), or generate a fresh baseline with
the original Phase24 compiler. Do not use the old identity-guarded campaign tool
to label new emissions as Phase25. The new acquisition verifies a completed
immutable candidate attempt, the original corpus inputs and baseline receipts:

```sh
python3 selfhost/tools/performance/phase26/corpus.py \
  NEW_ATTEMPT PHASE25_CORPUS NEW_CORPUS
```

This emits all23 libraries and checks127 independent scalar points. A separate
single-source emission command is:

```sh
node --stack-size=4096 --max-old-space-size=1024 \
  selfhost/tools/performance/phase26/emit.mjs NEW_ATTEMPT INPUT.bend OUTPUT.mjs
```

Timing config: `{"cases":[{"id":"NAME","point":{"size":256,"seed":18,
"expected":24132},"modules":{"upstream":"ABS_TS.mjs","old":"ABS_OLD.mjs",
"candidate":"ABS_NEW.mjs"}}]}`. All paths must identify the same checked source.
Hash/provenance acquisition and runtime measurement are separate gates. Stop
other benchmark/build work before running:

```sh
python3 selfhost/tools/performance/phase26/measure.py TIMING.json NEW_TIMING
```

Five fresh processes per output run serially in rotating order. Unchanged Phase25
execution code performs independent scalar checks, at least100ms/eight-call
warmup and side-specific calibration targeting150ms (maximum1M calls). Raw samples
include startup/import/warmup and RSS separately from execution; the compared
number is execution time per call. This is generated-program performance.

The exact compiler escape component has a separate full-text oracle:

```sh
node selfhost/tools/performance/phase26/compiler-escape-oracle.mjs OUTPUT.mjs
```

It deliberately remains outside the initial U32-result optimization. Its wrapper
also constructs strings and checksums output; it is not a whole-compiler benchmark.

Run guarded counters and AST analysis after clean timing:

```sh
node --stack-size=4096 --max-old-space-size=1024 \
  selfhost/tools/performance/phase26/analyze.mjs TIMING.json NEW_ANALYSIS
```

The [evidence capsule](evidence/README.md) preserves all completed and failed
attempts. For the recognizer's direct synthetic guards, copy the consumed config
from `guards-02/config.json`, update its immutable candidate paths and run
`node selfhost/src/back/js/test-u32.mjs CONFIG.json NEW_OUTPUT` with the documented
Node stack/heap flags. These unit controls expose unchanged internal functions
only in a diagnostic copy; ordinary library exports are unchanged.
