# Phase30 compiler performance campaign

Agent-generated report. Checked17 is installed, release verification passes,
and all 42 ordinary/relocated CLI checks pass. The campaign began on
2026-09-30 at 07:28 UTC and completed release/evidence validation after 15:59 UTC,
exceeding eight and a half hours. No PR comment is
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
6. A large kernel win need not accelerate the compiler itself. The complete AST
   audit proves that the generated H compiler has no actual private-worker
   registrations; its two quoted registration strings are generator templates.
   The present scalar-region rules therefore do not cover its central structured
   data flow. Local records/arrays and precise host/ABI attribution are more
   promising next targets than repeatedly tuning the already fast scalar loop.

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

Attempt17 is the installed compiler after final measurements and release gates.
Its API, genuine parent, assembled Bend source and Base are byte-identical16;
the runtime changes to the exactly measured flag variant. The table below
identifies17; earlier candidates keep their own immutable records and figures.
The distribution now contains this verified API with its matching runtime,
source and checked-bootstrap lineage. The previous Phase29 default is retained
in release history.

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

Fresh17 integration passes the36 build controls,15 selected upstream JS
probes, maintained primitive/worker suites, 23 libraries / 127 points, 22 compiler
component observations and the complete HVM stdout. All ten original outputs
pass. The row, scalar helper and original Mandelbrot also have independent15→16
complete generated-AST correspondence after only the specified matcher rewrite,
with final private-worker registration retained. Four actual17 modules also
match the experimentally timed flag derivatives byte for byte. The independent
[17 validation report](registration-flag-actual-review.md) records renewed
transition, ABI, entry, primitive, worker, guard and admission controls. These scopes
overlap and are not a sum of distinct conformance tests.

The [renewed16 frontend](frontend-renewal.md) completes all3,026 main and196
broader observations with exact reference agreement. Its initial strict report
rejected the changed compiler module manifest; that failure remains preserved.
An explicit module-layout migration, independently audited against every probe,
permits only the five added JS modules relative to the historical reference.
All behavioral fields and the other input identities remain exact. Raw fixture
verdicts still include the four shared later-emission expectations; agreement
does not turn them into successful frontend checks. A strict identity audit
permits reuse on17 because its complete frontend source/API/Base/host inputs are
unchanged; these observations are not relabelled as a fresh17 frontend run.

The [81-row backend pilot](backend-pilot-renewal-17.md) also matches its complete
historical observations: 69 paired fixture passes, eight expected compile
refusals and four shared check failures. Seventeen native rows initially
reported a shared Clang EPERM under the tool sandbox. The unchanged native
selection succeeds in an approved environment outside it. Both failed attempts
remain; the result identifies an environment boundary without proving the
low-level cause of the rendered error. The final17 pilot freshly acquires all28
interpreter and26 JS rows; only its four check and23 native rows reuse16 after
the identity audit. The optional additional811 JS fixtures
remain unexecuted, so this pilot is not full backend conformance.

The selected compiler also [emits its own complete source](registration-checked-integration.md)
in a31.076-second checked acquisition, including verification, driver work,
emission and persistence, producing a2,446,379-byte H module exactly matching
the independently tested flag variant. Fresh17 preparation validates Base under
the actual H hash, matches the genuine parent on a positive small compilation,
and executes its emitted JavaScript to8. The earlier positive/negative functional
gate retains its original16 runtime-input scope. Neither result establishes an
H-to-H fixed point, full H conformance or historical self-emission speedup.

## Final17 controlled results

All ten original-program measurements pass their exact public outputs. The
[complete17 timing report](final-timing-17.md) retains every sample, range, drift,
input identity and output check. Median milliseconds per original program call:

| Original point | TypeScript | Phase29 | Checked17 | Time change vs29 | Checked17 / TS |
| --- | ---: | ---: | ---: | ---: | ---: |
| Mandelbrot | 0.045950 | 21.379050 | 0.212798 | −99.00% | 4.63× |
| Edit distance | 4.924144 | 2043.843405 | 1927.977556 | −5.67% | 391.54× |
| Tree bitonic | 0.273753 | 26.139551 | 25.255092 | −3.38% | 92.26× |
| Lexer | 1.912223 | 176.105372 | 172.992868 | −1.77% | 90.47× |
| Symbolic regression | 1.101039 | 106.122892 | 103.629737 | −2.35% | 94.12× |
| Morning program | 0.003708 | 0.211189 | 0.203379 | −3.70% | 54.85× |
| Evening program | 0.003161 | 0.346974 | 0.203409 | −41.38% | 64.35× |
| RLE round trip | 0.000592 | 0.044830 | 0.046043 | +2.70% | 77.75× |
| Map/set operations | 0.022467 | 2.224335 | 2.141633 | −3.72% | 95.32× |
| Raytrace | 34.115672 | 10564.198488 | 10202.864968 | −3.42% | 299.07× |

Original Mandelbrot improves **100.47×** against Phase29 in the same window and
costs **4.63× TypeScript time**. Candidate halves stay within1% drift. Its actual
module also equals the flag variant whose separate15-second-warmup negative
control overlaps16; no incremental scalar gain from the flag is claimed.

Edit distance takes **5.67% less time** and ray tracing **3.42% less time** than
Phase29, with disjoint ranges. They still cost391.54× and299.07× TypeScript time.
These generic improvements transfer the small-runtime investigation to larger
original programs while leaving their much larger gap unresolved. Their slow
samples contain only one call, so within-sample half drift is unavailable.

RLE retains a **2.70% slowdown** against Phase29 with disjoint ranges; the earlier
16 matrix's10.30% loss is preserved separately. Symbolic-regression ranges
narrowly overlap. Tree bitonic, morning, evening and map/set have substantial
within-sample drift, and lexer consistently slows7–8% between halves. The
especially large apparent evening gain is not a settled performance result.
The separately frozen 15-second-warmup tree-bitonic comparison now passes:
22.783611 ms for checked17 versus 22.886438 for Phase29 and 0.258705 for
TypeScript. The 0.45% improvement has overlapping ranges, so no material change
against Phase29 is established; the remaining ratio is 88.07× TypeScript.
Candidate half drift stays within 1.4%. This new-image window neither replaces
the short transfer samples nor rewrites checked16's earlier long-warmup loss.
No overall average hides these limits or the remaining RLE regression.

Compiler throughput remains separate. Checking the frozen compiler source takes
**10.331 seconds**, versus9.853 for Phase29 and2.450 for upstream TypeScript:
4.86% more request time than Phase29 and4.22× TS. Whole-process medians are
11.494,11.021 and3.577 seconds; maximum observed RSS is696240,758200 and478116 KiB,
respectively.17's compiler API is byte-identical16, so cross-window differences
between16 and17 do not establish a compiler-throughput effect of the runtime flag.
Compiling the Mandelbrot library takes 1.771 seconds versus 1.631 for Phase29
and 0.346 for TypeScript: 8.56% more than Phase29, with disjoint ranges. The
edit-distance library request takes 1.550 seconds versus 1.547 and 0.306;
the Phase29/current ranges overlap. These measure compilation, not execution.

The registered scalar helper at 8,192 iterations takes **0.136689 ms**, versus
25.477501 for Phase29 and 0.099372 for TypeScript: **186.39× faster than Phase29
and 1.376× TypeScript time**. Candidate halves still improve 3.35–4.21%, so this
is an observed ratio, not a perfectly settled asymptote. At zero iterations,
the checked entry costs 2.70× Phase29; the optimization amortizes that cost over
a larger private computation. All four sizes and twelve output checks pass.
The complete frozen 13-job matrix closes in 25 minutes 30 seconds.

The [current generated-compiler comparison](warmed-generated-compiler17.md)
uses actual H17 and the genuine TypeScript-produced parent for the **same Bend
compiler source**, including H's real ABI adapter and ordinary cache pipeline.
Fresh preparation validates both actual-hash caches and positive output8.
Its separate clean timing passes: median trial means are **7,405.986 ms for H17
versus 1,480.712 ms for its genuine parent**, a **5.002×** ratio. All eighteen
output hashes match. Both sides still warm within trials: H improves 7.66–9.88%
and its parent 10.12–13.37% from the first to second timed request. This is a
fixed warmed-once protocol, not converged throughput. The [original16 H
result](warmed-generated-compiler-cost.md), 5.21×, remains a separate historical
window. Neither ratio compares H with the handwritten upstream TypeScript
compiler, and neither is multiplied by the ordinary compiler-check ratio.

The [checked16 matrix](final-timing-16.md), its long follow-ups and the
[held14 regression](final-timing.md) remain separate historical windows. Their
samples are neither replaced nor pooled into the final17 numbers.

## Release and evidence status

Checked17 passes its genuine build and36 focused observations in38.092 seconds.
The standard primitive runtime suite also passes in the approved execution
environment, including numeric/readback, files, channels, local TCP/UDP and Halt.
Its initial sandboxed invocation fails at socket setup and remains preserved.
Actual17 output correspondence, the affected correctness gates and the complete
13-job matrix have passed. All separately frozen timing windows are also closed. Installation, maintained
release verification and all 42 ordinary/relocated CLI checks pass. The
[release report](release-17.md) records the exact commands, native environment
and retained previous default; [CLI observations](release-cli.json) are preserved
verbatim. [Final diagrams](final17-figures/report.md) include exact plotted data.
The verified [evidence capsule](evidence/README.md) preserves 39,272 regular
files, with complete per-member recovery checks and exact chunk transport. All
103 unrelated starting files remain byte-identical. The
[campaign index](README.md) links intermediate outcomes, including the retained
[held14 matrix](final-timing.md). The initial pin, branch and103 protected
unrelated paths are frozen in [start-state.json](start-state.json).
