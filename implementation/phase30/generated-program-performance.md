# Phase30 compiler performance campaign

Agent-generated report. This report is being consolidated while final candidate
selection and release validation are in progress. The campaign began on
2026-09-30 at 07:28 UTC, with at least seven hours authorized. No PR comment is
part of this work. The target remains upstream
`018751270e800bc222a93dad7f257083ee53a5f7`, after Bend 2.0.34.

## What changed and why

Comparing the two compilers' JavaScript was useful because the investigated hot
paths differed substantially in administrative work around the same algorithm. The Bend-written
backend represented calls, partial applications and matches with descriptors,
copied argument vectors and trampoline messages. The upstream emitter used
direct local functions and control flow at many corresponding points. Counting
those differences identified hypotheses; isolated interventions established
which differences actually cost time.

The resulting compiler recognizes bounded closed scalar regions and keeps
their internal calls private. One checked entry guards a complete helper graph,
then the generated code uses lexical functions, native scalar expressions and
proved countdown loops. A strict two-child scalar tree can use an explicit
depth-bounded DFS stack with reusable frames. A terminal flat record retains
the existing delayed construction and field representation. Tail Let chains in
ordinary private helpers become statements with preserved parallel RHS scope.

This avoids paying generic public-call overhead for each scalar operation. It
does not make every function private or assume that all typed code is pure.
Live public bindings, partial descriptors, raw callbacks, foreign objects and
unsupported shapes retain their generic behavior. Exact entry permission is
single-use and consumed before argument access can reenter. The new controls
also caught and repaired five inherited scheduling/self-binding counterexamples
in the preceding Nat-loop optimization.

The [performance guide](../../docs/BEND-IN-BEND-PERFORMANCE.md) describes the
implementation and supported boundary. The [decision table](decisions.md)
collects promoted, rejected and deferred experiments without multiplying their
separate speedup factors.

## Measurement boundaries

Final generated-program comparison uses all ten original selected programs,
unchanged inputs and complete expected outputs. Pinned TypeScript, Phase29 and
the final compiler run in rotating fresh Node24.18.0 processes on CPU3, with
4 MiB stack and 1 GiB heap. The retained transfer protocol uses five samples per
side, at least three warmup calls and one second, then a 300 ms timed target.
Module import, first call and warmed execution are kept separate. These selected
program points do not define a production-workload average.

For small mechanisms, a short paired screen normally takes seconds. A surviving
compiler edit requires a genuine checked bootstrap, its 36 focused observations,
fresh fixture emission and feature-specific controls. Builds in this campaign
took roughly 35–40 seconds and small original-library emission roughly five
seconds. These are observed acquisition durations, not controlled compiler
throughput. Full original-program measurement belongs at integration time.

Warmup remains a material part of the evidence. The campaign preserves cases
where short-window rankings reverse. Separate 15-second-warmup protocols resolve
specific questions; they do not replace earlier runs or establish convergence
for every workload. Every timed result is checked. Instrumented counters and
profiles are diagnostic observations, never used as uninstrumented timings.

Ordinary compiler checking and checked-library compilation have their own
frozen workloads and timing boundaries. Neither is inferred from the speed of
generated Mandelbrot code. The installed compiler remains a guarded derivative
of a genuine checked B1; this campaign makes no new self-hosted fixed-point claim.

## Main lessons

1. A complete private region matters more than removing one public call layer.
   Per-call guards can cost more than the work they protect; one guard around
   many operations permits useful direct execution.
2. JavaScript representation matters even after generic calls are removed.
   Lexical helper calls and constant native shifts produced further large gains
   in the isolated scalar loop. Reused frames and statement emission changed
   allocation/closure patterns and produced smaller measured gains. These
   interventions do not quantify runtime allocation or CPU shares.
3. Broader syntax needs broader correctness arguments. Arrays and record fields
   introduce aliasing and deferred mutation; a scalar result type alone does not
   prove a private computation is safe. The owned edit-row ladder remains a
   separately validated prototype while its general locality/demand proof is
   developed.
4. Failed and null experiments save future work. Hoisting shared helpers did
   not improve the settled whole-program measurement, guarded F32 leaf entries
   regressed, and a correct constructor-arm retry was slower. None justified
   additional maintained compiler machinery.
5. A shared runtime edit needs a cheap generic regression case alongside the
   scalar improvement case. The final14 matrix caught similar slowdowns in edit
   distance, lexer and ray tracing after the scalar helper had improved sharply.
   Keeping one complete-state edit-distance row in the inner loop would expose
   that class of cost without waiting for the full original-program matrix.
   This is a methodological lesson from the held candidate, not yet a causal
   attribution to one dispatch operation.

## Frozen candidate and complexity

**Release hold:** the ten-program integration measurement found a common
roughly20–25% regression on several generic workloads. Checked attempt14 remains
the frozen measurement candidate, not an approved release. Phase29 remains the
installed default. Separate runtime ablations are investigating ordinary exact
dispatch and registered constructor matchers before any installation decision.
Its final source change is committed
at [b783a53](https://github.com/rom1504/bend/commit/b783a53), after the preceding
owned-vector, scalar-region, terminal-record, ordinary-root, tree and frame
checkpoints. The broader generic Let and fixed-list guard experiments did not
meet their promotion conditions. They remain reproducible experiments.

| Identity | SHA256 |
| --- | --- |
| Selected API | `ade96ba48b05ba116430f57e433d8fbdbd76646b61f5e9d53cf34a4c4a9da76d` |
| Genuine checked parent | `cb2a5555e8ad6afc51e3bc778242e26334f11c40b720028650b8b4c0525f2deb` |
| Assembled compiler source | `223331981f58cc412f5c4bbc120dd3e8322bac1cfa2b3047536317ad15e43f55` |
| JS runtime | `a3547a8854b45c65fd804f106868dc28540118b611d85fe99ba0e3d199c66ef0` |
| Pinned Base | `c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661` |
| Guarded profile6 derivation | `3af1a57e86cb1813638dc615dbca69dbcab7c0efc807ca70046a8ecef705e1fa` |

Canonical source counts come from the explicit `src/compiler.json` module list,
not a recursive glob that includes unused/generated source files.

| Bend compiler source | Phase29 start | Attempt14 | Change |
| --- | ---: | ---: | ---: |
| Physical lines | 16,207 | 16,836 | +629 (+3.88%) |
| Nonblank lines | 13,839 | 14,377 | +538 |
| Bytes | 612,128 | 649,526 | +37,398 |
| Definitions | 1,762 | 1,852 | +90 |
| Laws | 640 | 640 | 0 |
| Types | 68 | 70 | +2 |
| Manifest modules | 64 | 66 | +2 |

The two new analysis records and two modules contain the region and tree rules.
Three emitter-only KTerm labels express private slots, calls and branches; they
are not parser/checker constructs. The runtime adds fresh-vector entry, exact
invocation permission and live scalar dependency guards. Public records, arrays
and numbers keep one representation. Tools, reports, tests and the generated
runtime bundle are separate from the canonical Bend count. This is a performance
phase with a source-size increase, not a line-reduction result.

Outside that Bend count, maintained `runtime/js/core.mjs` grows from167 to245
physical lines (+78); the generated concatenated runtime is not counted again.
The bounded bootstrap diagnostic wrapper grows from29 to58 lines, and the
checked-derivation tool from328 to338 lines. Experimental tools and evidence
are retained for reproduction rather than included in the compiler-size total.

Fresh final14 integration passes the 36 build controls, 15 selected upstream JS
probes, maintained primitive/worker suites, 23 libraries / 127 points, 22 compiler
component observations and the complete HVM stdout. All ten original outputs
pass; nine emitted modules are byte-identical to13, while Mandelbrot contains
only the independently reconstructed private-helper changes. These scopes
overlap and are not a sum of distinct conformance tests.

## Release and evidence status

The in-progress transfer window already establishes that the scalar result is
not representative of all generated code. Original Mandelbrot measures
21.473750 ms with Phase29 versus0.220591 ms with14, a97.35-fold improvement;
pinned TypeScript measures0.045687 ms, leaving4.83-fold overhead. In the same
transfer protocol, edit distance goes2029.575→2435.481 ms, lexer
175.07393→210.84747 ms and tree-bitonic26.097304→31.865055 ms. These regressions
are release blockers, not averaged away by Mandelbrot's gain. Bitonic's Phase29
samples still show material half-window drift, so its exact ratio is provisional.
The complete batch and diagnostic controls are retained in
[final-timing.md](final-timing.md). Later repaired candidates will have their own
identities and measurements; these observations will not be relabelled.
Ray tracing independently completes at10527.867→13027.830 ms,23.75% slower;
its one-call timed samples do not provide a useful half-window drift statistic.

Final measured tables, installed-image identity, renewed frontend/backend scopes,
source/runtime complexity, relocation checks and durable capsule references will
be attached here when their runs close. Intermediate observations remain in the
[campaign index](README.md); the initial pin, branch and 103 protected unrelated
paths are frozen in [start-state.json](start-state.json).
