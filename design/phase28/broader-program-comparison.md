# Phase28: measure a broader set of emitted programs

The user asks for clear numbers on existing Bend programs beyond the diagnostic
kernels. This phase measures, without changing compiler source or installed
release. Baseline is commit9be96e4, installed Phase27 API5a89c775/runtime40823818,
genuine checked attempt `selfhost/build/phase27/attempt-02`, and pinned upstream
018751270e800bc222a93dad7f257083ee53a5f7. Preserve the103 unrelated starting files.
Existing authorization covers reports, commits and pushes; no new PR comments.

## Frozen selection and acquisition

Use six existing runtime programs at their documented small inputs: Mandelbrot,
ray tracing, edit distance, tree bitonic sorting, lexer and symbolic regression.
Their algorithm bodies remain byte-identical to pinned Git blobs. Append only
an exported scalar benchmark wrapper; retain original main but do not invoke its
large input. Freeze exact parameters and published small checksums in metadata
before compilation. Compare the same wrapped Bend bytes through both compilers.
Handwritten C/TS counterparts are potential independent oracles, not the primary
performance baseline.

Also acquire four unchanged mixed tests through their full `main.out` values:
morning_program, evening_program, rle_roundtrip, map_set_ops. They are tiny
integration inputs and must be labeled separately from scaled algorithms. Attempt
the full HVM mini parser/interpreter application with its embedded program and
complete stdout; first qualify its execution boundary, without replacing its
algorithm. Never silently substitute another workload for a failure.

Emission uses the existing checked upstream library launcher and immutable
attempt emitter. Node24.18.0, stack4MiB, heap1GiB; acquisition may use separate
CPUs concurrently. Preserve commands, exits, source/API/runtime/Base/host/module
identities, stderr and complete output. Per-emission deadline120s and first
execution deadline60s. Every failure remains a named outcome. If a documented
small case cannot run, report it before designing a separately labeled smaller
input; do not promote a surviving-subset aggregate as the whole set.

## Prospective clean measurement

Freeze supported executable pairs and expected complete values before timing.
No compiler builds, diagnostic runs or other agent executions during clean
measurement. Use CPU3, the same Node24 binary, stack4MiB and heap1GiB for both.
Five fresh processes per side and input; alternate side order. Compilation is
excluded, import/startup separately recorded. Check the exact result every call.

Each sample records its first useful call, then warms for at least3 further
calls AND1000ms. This is a practical common protocol for whole algorithms, not
a claim of universal JIT convergence. Do not require200 whole-program calls.
Separate calibration targets300ms of measured work, repetitions fixed per side
across five samples and capped at1M. A timed call may itself exceed the target.
Sample deadline120s; a failure is retained without survivor-only success claims.
Report realized warmup and timed durations. Where feasible, record halves of the
timed block to flag within-sample drift; do not drop inconvenient observations.

For an application requiring process-level I/O execution, use five fresh complete
program processes per side instead and label its startup-including boundary
separately. Do not merge that ratio with library execution medians. Preserve
timeouts, compile failures and wrong results as coverage outcomes, not speed.

## Report and closure

Produce per-program absolute medians, observed ranges, selfhost/upstream ratios,
input sizes and correctness status. Distinguish first-call and warmed execution,
small tests and algorithm workloads. A broader corpus is still not a statistical
sample of production programs; avoid an unqualified typical-speed average.
Publish a chart and raw evidence with independent timing review and byte recovery.
Verify installed release and protected files unchanged, document findings and
reproduction, commit and push. No optimization is bundled into this comparison.
