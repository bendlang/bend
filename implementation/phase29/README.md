# Reproduce the generated-program fast loop

Start with the [design](../../design/phase29/generated-program-fast-loop.md),
[worker amendment](../../design/phase29/private-nat-worker.md),
[report](generated-program-fast-loop.md) and
[independent semantic review](semantic-review.md). Commands run at repository root.
The commands require Node 24.18.0 on `PATH`; the pinned TypeScript compiler is
`018751270e800bc222a93dad7f257083ee53a5f7`. No upstream source is modified.

## Separate the three loops

1. **Mechanism experiment:** reuse checked emitted modules, derive a separately
   named disposable JavaScript variant, validate its results and public boundaries,
   then compare saved bytes. No compiler rebuild is necessary. A manual prototype
   is evidence about a mechanism, not a compiler release.
2. **Compiler change:** build a checked immutable attempt, emit the small fixture,
   run independent scalar/ABI controls and compare its output. Keep the previous
   attempt and outputs. Source changes require a new attempt directory.
3. **Integration:** run the existing library corpus, upstream JS controls and
   unchanged real programs once a candidate survives the focused loop. Run the
   expensive complete program comparison at this boundary, not on every edit.

The tiny fixture preserves the Mandelbrot helper definitions from the pinned
program and adds parameterized wrappers. Its Python oracle supplies 120 points.
The prototype report preserves arithmetic-only, worker-only and combined effects,
including the short-window warmup artifact. Counters run separately from timings.

## Build and acquire

Use the maintained checked development workflow with a config naming this
`selfhost` project, the pinned upstream checkout, `profile: "equality"`,
`strictExact: true`, one job and a CPU outside the timing slot:

```sh
node --stack-size=4096 --max-old-space-size=4096 \
  selfhost/tools/development/workflow.mjs run BUILD_CONFIG.json NEW_ATTEMPT
node --stack-size=4096 --max-old-space-size=1024 \
  selfhost/tools/performance/phase26/emit.mjs NEW_ATTEMPT \
  selfhost/tools/performance/phase29/fixture-mandelbrot.bend NEW_OUTPUT.mjs
node selfhost/tools/performance/phase29/prototype-check.mjs NEW_OUTPUT.mjs \
  selfhost/tools/performance/phase29/fixture-points.json
```

The checked emitter verifies the attempt's API/runtime/Base/driver lineage and
records input/output identities. The production emitter must itself generate the
optimization; do not substitute a manually edited module in the compiler column.
Arithmetic and worker controls under `selfhost/tools/performance/phase29/` cover
identity refusals, numeric boundaries, evaluation order and public descriptors.
Read their argument lists and preserved launch records before replaying.

## Clean focused timing

Stop other builds, generated-program executions and diagnostics. `compare.py`
executes serially on CPU 3 with 4 MiB stack, 1 GiB heap and a sanitized environment.
Its config accepts two or more immutable modules and complete expected results:

```json
{
  "protocol": "screen",
  "inputs": [],
  "cases": [{
    "id": "mandelbrot-inner",
    "point": {"args": [128, 524800], "expected": 128},
    "modules": {"old": "/absolute/old.mjs", "candidate": "/absolute/new.mjs"}
  }]
}
```

Populate `inputs` with `{file, sha256, bytes}` identities for source, checked
emission receipts and oracles. The runner hashes its config, harness, Node and
all modules itself. It verifies all inputs before and after the campaign.

```sh
python3 selfhost/tools/performance/phase29/compare.py CONFIG.json NEW_TIMING
```

The screen uses 3 samples/side, at least 8 calls AND 100 ms warmup and a 150 ms timed
target. Confirmation uses 5 samples, at least 100 calls AND 3000 ms warmup and 300 ms
timing. The original-program transfer protocol uses 5 samples, at least 3 calls
AND 1000 ms warmup and 300 ms timing. These are minimum floors, not convergence claims.
Calibration uses separate fresh processes; side order rotates. Every timed result
is checked. Preserve first calls, both timed halves, actual durations, memory and
failed processes. Do not report a survivor-only aggregate.

## Integration and interpretation

`acquire.py ATTEMPT SELECTION.json NEW_OUTPUT` reuses the exact Phase 28 programs
and checked baseline/TypeScript modules, emits each new candidate and validates
its complete result. The selection is a JSON array of Phase 28 case IDs. It requires
the recovered Phase 28 evidence at the recorded paths and produces a ready timing
config only if every selected acquisition passes. Acquisition durations include
lineage verification and are not comparative compiler timings.

The 23-library corpus runner and 15 upstream JS selection retain the prior scopes.
The actual compiler membership component has its separate 22-point oracle. The
HVM application is timed as a whole process and is never pooled with warmed
library-call costs. Neither small kernels nor the broader algorithms define a
production average. No new self-hosted fixed point, whole-compiler throughput,
native C speed or device coverage is inferred from these JS measurements.

## Evidence recovery

The [capsule](evidence/README.md) preserves failed and successful attempts,
emitted modules, frozen configs, raw processes, consumed tools and audit receipts.
Phase 27 and Phase 28 capsules supply explicitly linked immutable prerequisites.
Recovery and measurement audit are separate operations. Historical receipts keep
their original paths and identities; a replay on another host needs new configs
and records new measurements instead of rewriting historical evidence.
