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
   The subsequent isolated interventions attribute the regression to arm
   prebinding; they do not establish a particular V8 allocation or inlining cause.

## Candidate history and complexity

**Held14:** the ten-program integration measurement found a common roughly20–25%
regression on several generic workloads. Checked attempt14 was not released.
Its final source change is committed
at [b783a53](https://github.com/rom1504/bend/commit/b783a53), after the preceding
owned-vector, scalar-region, terminal-record, ordinary-root, tree and frame
checkpoints. The broader generic Let and fixed-list guard experiments did not
meet their promotion conditions. They remain reproducible experiments.

The seven-way row confirmation then isolated the constructor-matcher cost.
Restoring delayed arm application reduces14's0.606265 ms to0.446850 ms,26.29%
less time, overlapping Phase29's0.450682 ms range. Merely fusing the wrapper gives
2.32%; removing reflected method checks gives9.68%; moving ordinary dispatch
back into apply gives no established gain. These are independent interventions,
not additive factors. The [attribution report](generic-runtime-row-diagnosis.md)
retains all samples and the preceding unstable short screen.

Checked15 integrates only the winning runtime change at
[4e5b7fe](https://github.com/rom1504/bend/commit/4e5b7fe), with exact emitted-module
correspondence to the experiment apart from one explanatory comment. Checked16
then removes the redundant arm-prebinding recognizer and runtime bridge:64
implementation lines, eight Bend functions and one module. Independent complete
generated-AST comparisons, public callable/registration checks and retained arm
semantics pass. This simplification does not add another admission policy.

The final isolated registry experiment then finds5.57% less RLE time and5.38%
less complete-row time, with disjoint confirmation ranges and no meaningful
registered-helper/Mandelbrot regression. Checked17 integrates only its three
runtime edits: track whether any exact worker has registered, and skip the
WeakSet query while none has. The code getter still runs first; registration
and reentry preserve the original permission rules. The change adds one runtime
line and no Bend source or analysis concept. See the
[experiment](registration-dispatch.md) for the controls and measured limits.

Attempt17 is the selected candidate for final measurements and release gates.
Its API, genuine parent, assembled Bend source and Base are byte-identical16;
the runtime changes to the exactly measured flag variant. The table below
identifies17; earlier candidates keep their own immutable records and figures.
The distribution API still contains Phase29 while the working source/runtime are
under development. A verified consolidated default is not claimed until the
final installation and CLI checks complete.

| Identity | SHA256 |
| --- | --- |
| Selected API | `33545640e25beffb61639b27f4815aaeb345fda14758e1d63418cd1d0ccc0637` |
| Genuine checked parent | `60aa968ffcedb7a02a220b58a51396dd036d0d8b1f39f1b3def3f6b4248d6469` |
| Assembled compiler source | `678bafd61cff715c3ee2012ef3840ddfe99a2aeb1d81b5345fb3c6e6bfc1757e` |
| JS runtime | `6731308bcddc6faf68d0f2f9988b1299d4d62069fa091e94857f56bded44b3d6` |
| Pinned Base | `c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661` |

Canonical source counts come from the explicit `src/compiler.json` module list,
not a recursive glob that includes unused/generated source files.

| Bend compiler source | Phase29 start | Held14 | Candidate17 | Net change |
| --- | ---: | ---: | ---: | ---: |
| Physical lines | 16,207 | 16,836 | 16,778 | +571 (+3.52%) |
| Nonblank lines | 13,839 | 14,377 | 14,327 | +488 |
| Bytes | 612,128 | 649,526 | 646,310 | +34,182 |
| Definitions | 1,762 | 1,852 | 1,844 | +82 |
| Laws | 640 | 640 | 640 | 0 |
| Types | 68 | 70 | 70 | +2 |
| Manifest modules | 64 | 66 | 65 | +1 |

The two new analysis records and two modules contain the region and tree rules;
removing the old arm module leaves one net added module.
Three emitter-only KTerm labels express private slots, calls and branches; they
are not parser/checker constructs. The runtime adds fresh-vector entry, exact
invocation permission and live scalar dependency guards. Public records, arrays
and numbers keep one representation. Tools, reports, tests and the generated
runtime bundle are separate from the canonical Bend count. This is a performance
phase with a source-size increase, not a line-reduction result.

Outside that Bend count, maintained `runtime/js/core.mjs` grows from167 to234
physical lines (+67), after reaching245 in held14 and233 in16. The generated concatenated
runtime is not counted again.
The bounded bootstrap diagnostic wrapper grows from29 to58 lines, and the
checked-derivation tool from328 to338 lines. Experimental tools and evidence
are retained for reproduction rather than included in the compiler-size total.

Fresh16 integration passes the 36 build controls, 15 selected upstream JS
probes, maintained primitive/worker suites, 23 libraries / 127 points, 22 compiler
component observations and the complete HVM stdout. All ten original outputs
pass. The row, scalar helper and original Mandelbrot also have independent15→16
complete generated-AST correspondence after only the specified matcher rewrite,
with final private-worker registration retained. These scopes
overlap and are not a sum of distinct conformance tests.

The [renewed frontend](frontend-renewal.md) completes all 3,026 main and 196
broader observations with exact reference agreement. Its initial strict report
rejected the changed compiler module manifest; that failure remains preserved.
An explicit module-layout migration, independently audited against every probe,
permits only the five added JS modules relative to the historical reference.
All behavioral fields and the other input identities remain exact. Raw fixture
verdicts still include the four shared later-emission expectations; agreement
does not turn them into successful frontend checks.

The [81-row backend pilot](backend-pilot-renewal.md) also matches its complete
historical observations: 69 paired fixture passes, eight expected compile
refusals and four shared check failures. Seventeen native rows initially
reported a shared Clang EPERM under the tool sandbox. The unchanged native
selection succeeds in an approved environment outside it. Both failed attempts
remain; the result identifies an environment boundary without proving the
low-level cause of the rendered error. The optional additional811 JS fixtures
remain unexecuted, so this pilot is not full backend conformance.

The selected compiler also [emits its own complete source](bounded-self-emission.md)
in a 30.841-second checked acquisition, including verification, driver work,
emission and persistence, producing a 2,446,321-byte H module. That module passes
syntax, builds its own actual-hash Base cache, and
matches its parent on a positive and a negative small compilation. The positive
generated JavaScript is byte-identical and returns 8. This is a new usable
self-emission observation, not an H-to-H fixed point, full H conformance, or a
controlled speed comparison with a historical compiler.

## Checked16 integration window, before the final registry flag

The complete checked16 matrix passes all13 jobs in25 minutes58 seconds.
The [full timing report](final-timing-16.md) retains every sample, range, drift,
input identity and output check. Median milliseconds per original program call:

| Program | TypeScript | Phase29 | Checked16 | Checked16 / TS |
| --- | ---: | ---: | ---: | ---: |
| Mandelbrot | 0.045452 | 21.416666 | 0.214181 | 4.71× |
| Edit distance | 4.957825 | 2034.066101 | 2026.226551 | 408.69× |
| Tree bitonic | 0.273253 | 26.047441 | 26.938268 | 98.58× |
| Lexer | 1.919549 | 176.054721 | 176.159110 | 91.77× |
| Symbolic regression | 1.106572 | 106.987871 | 109.779127 | 99.21× |
| Morning | 0.003723 | 0.227457 | 0.222019 | 59.63× |
| Evening | 0.003152 | 0.286586 | 0.271041 | 85.98× |
| RLE | 0.000593 | 0.044767 | 0.049376 | 83.23× |
| Map/set | 0.023200 | 2.328559 | 2.110699 | 90.98× |
| Raytrace | 34.225803 | 10609.546586 | 10789.490798 | 315.24× |

Original Mandelbrot improves approximately100× against Phase29 in this same
window. A separate15-second-warmup comparison measures checked16 at0.209363 ms
and TypeScript at0.045581 ms, leaving4.59× overhead. Checked15 and16 ranges
overlap: source cleanup preserves the win but has no established extra speedup.
The scalar helper's8192-iteration point improves192.96× over Phase29 and costs
1.34× TypeScript time. Its zero-work point instead costs2.73× Phase29 time:
private-region admission has a fixed entry cost that larger work amortizes.

The generic repair removes held14's large regressions: edit distance, lexer and
raytrace now overlap Phase29 sample ranges. Their large absolute TypeScript gaps
remain. RLE is10.30% slower than Phase29 with disjoint ranges, and symbolic
regression is2.61% slower. Tree bitonic retains a4.15% slowdown and93.47× TS gap
in a separate15-second-warmup window. The ordinary short-window morning,
evening and map/set measurements have substantial within-sample drift; their
median changes do not establish settled performance gains. No geometric mean
is used to hide those limits or regressions.

Compiler throughput is separate. Ordinary checking of the frozen compiler
source takes10.240 seconds versus9.860 for Phase29 and2.485 for TypeScript:
3.86% more request time than Phase29,4.12× TS. Checked library generation takes
1.746 seconds for Mandelbrot and1.536 for edit distance, versus0.339 and0.307
for TypeScript. The former costs5.93% more than Phase29, while edit-distance
compilation overlaps its preceding range. Faster generated scalar programs do
not imply faster compilation.

The [small generated-compiler experiment](warmed-generated-compiler-cost.md)
compares H with the genuine TypeScript-produced parent for the **same Bend
compiler source**. Median warmed-once trial means are7.609 versus1.461 seconds,
a5.21× gap, with all18 checked outputs identical. This is a code-generation
comparison including H's real ABI adapter and ordinary cache pipeline, not H
against the handwritten upstream compiler or an attribution solely to generated
function bodies. The two timed
requests still drift in opposite directions, so it does not establish converged
steady-state throughput. It does provide a bounded request-sized target for
future generated-compiler profiling without requiring full self-emission.

## Release and evidence status

Checked17 passes its genuine build and36 focused observations in38.092 seconds.
The standard primitive runtime suite also passes in the approved execution
environment, including numeric/readback, files, channels, local TCP/UDP and Halt.
Its initial sandboxed invocation fails at socket setup and remains preserved.
Installation remains pending while actual17 output correspondence and its
renewed affected gates and complete matrix close. The
[campaign index](README.md) links intermediate outcomes, including the retained
[held14 matrix](final-timing.md). The initial pin, branch and103 protected
unrelated paths are frozen in [start-state.json](start-state.json).
