# Reproduce Phase27

Read the [main design](../../design/phase27/constructor-arm-prebinding.md),
[warmup amendment](../../design/phase27/longer-warmup.md),
[shared-helper amendment](../../design/phase27/shared-arm-runtime.md) and
[report](constructor-arm-prebinding.md). The experiment compares generated
program execution. It does not measure complete compiler throughput or a new H.

Commands start at repository root. Use Node24.18.0; the Python launchers accept
`PHASE25_NODE` if its binary is elsewhere. Timing uses CPU3, 4MiB stack and
1GiB heap. Stop other builds, diagnostics and benchmarks during timing.

## Checked acquisition

Use an absolute pinned upstream path to commit018751270e800bc222a93dad7f257083ee53a5f7
in a config with `jobs:1`, `cpu:"3"`, `profile:"equality"`, `strictExact:true`:

```sh
node --stack-size=4096 --max-old-space-size=4096 \
  selfhost/tools/development/workflow.mjs run CONFIG.json NEW_ATTEMPT
```

This produces a genuine checked bootstrap, guarded derivative, frozen source,
runtime and host, and36 standard paired observations. Attempt01 is the original
inline candidate; attempt02 is the shared runtime variant. Each keeps its own
API/runtime identities. Never combine a candidate emitter with an old runtime.
The capsule retains both snapshots and the original inline source patch.

Restore the Phase25 corpus using its [capsule instructions](../phase25/README.md).
Its receipts provide unchanged source/oracle identities. Reuse the maintained
acquisition tools with a new output directory:

```sh
python3 selfhost/tools/performance/phase26/corpus.py \
  NEW_ATTEMPT PHASE25_CORPUS NEW_CORPUS
node --stack-size=4096 --max-old-space-size=1024 \
  selfhost/tools/performance/phase26/emit.mjs NEW_ATTEMPT \
  selfhost/tools/performance/phase27/component-membership.bend COMPONENT.mjs
node selfhost/tools/performance/phase27/component-membership-oracle.mjs COMPONENT.mjs
```

The corpus checks23 libraries/127 scalar points. Its `oldModule` field identifies
the original Phase25 receipt, **not** Phase27's timing baseline. Phase27 times the
Phase26 `corpus-01/*/candidate.mjs` as `old`, Phase25's pinned `upstream.mjs`, and
the new Phase27 output as `candidate`. Restore Phase26 from its separate capsule.
The actual compiler component uses aligned `component-baseline-02` and the
unchanged `component-upstream-01`. Its22 independent oracles include direct
membership and complete wrapper results; timing includes list construction.

See [semantic controls](controls-design.md) for `test-arm.mjs` configuration and
the72 descriptor/effect/ownership observations. Phase26's control harness and
bit supplement protect the numeric optimization. The shared runtime also runs
`node selfhost/src/runtime/js/test-apply.mjs`.

## Two separately reported timing protocols

Use the preserved `timing-shared-config.json` schema: `cases` with `id`,
`point:{size,seed,expected}` and `modules:{upstream,old,candidate}` absolute paths;
top-level `runtimes:{old,candidate}` holds their matching runtime paths. Every
module has an adjacent checked emission receipt. Validate lineage first:

```sh
python3 selfhost/tools/performance/phase27/check-inputs.py CONFIG.json PROVENANCE.json
python3 selfhost/tools/performance/phase26/measure.py CONFIG.json NEW_SHORT_TIMING
```

The original protocol uses at least100ms/eight calls warmup, side-specific150ms
calibration target, and five fresh processes per output in rotating serial order.
Nine cases give135 samples. Expected outputs are checked on every measured call.

The longer-warm configuration contains exactly `term-substitution`,
`compiler-membership`, `boolean-worker` in that order, with `warmup:200` and
`warmupMs:500` on every point. Run:

```sh
python3 selfhost/tools/performance/phase27/measure-warm.py WARM_CONFIG.json NEW_WARM_TIMING
```

This records a mechanically derived launcher using the original measurement
machinery, with a500ms calibration target. Warmup enforces both floors; measured
duration is a target, not a minimum. Calibration still caps at1M calls. It gives
45 fresh samples. Keep both protocols and all samples; never pool them or replace
an unfavorable short-window result with a longer-warm value.

## Diagnostics and recovery

Only after clean timing, run counters and AST analysis:

```sh
node --stack-size=4096 --max-old-space-size=1024 \
  selfhost/tools/performance/phase27/diagnose.mjs CONFIG.json NEW_ANALYSIS
python3 selfhost/tools/performance/phase27/summarize.py \
  selfhost/build/phase27 RESULTS.json
```

The summary expects all four campaign windows. Counters use each variant's
exact runtime, verified against its module prefix. Generic `apply` partial/copy
counters exclude the new helper's equivalent copy and final partial descriptor;
function-record counts include both. Do not treat moved operations as eliminated
allocations. The original inline diagnostic launcher is preserved with its run.

[Evidence recovery](evidence/README.md) preserves raw acquisitions, failures,
traces, unexecuted ablations, all timing windows and both immutable builds.
Absolute historical paths in receipts describe the acquisition host; extracting
at a different path does not renew historical build provenance. Use fresh
checked acquisition or relative installed-release verification as appropriate.
