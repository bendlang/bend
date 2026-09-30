# Phase30: direct generated code through measured, small transformations

Agent-generated design. Frozen starting plan, 2026-09-30 07:28 UTC. The user
requests at least seven hours of sustained work, through 14:28 UTC, to make the
compiler's generated programs fast. Commit/push to the existing fork branch is
authorized. No new PR comment is authorized. Amendments will be separate dated
files or clearly prospective sections; raw protocols and failed trials persist.

## Baseline and objective

Start at commit `77aecb2855345ade00a5f63f297e991ea5298e57` on
`selfhost/bootstrap`. Installed checked derivative API is `10510efd`, checked
parent `37218b8a`, source `191df20c`, runtime `40823818`; upstream remains pinned to
`018751270e800bc222a93dad7f257083ee53a5f7`. Exact identities and the 103 unrelated
dirty files are in `implementation/phase30/start-state.json`. Preserve all of them.
Never edit human-written `bend2/bend.ts` or historical pinned checkouts.

Phase29 improves selected generated programs but leaves original algorithm
costs 89–465 times TypeScript output in its original observation window. Those
numbers are historical, scoped observations, not a universal slowdown. Its
current helper screen is 4.706 seconds, checked edit budget roughly 43 seconds
before added semantic controls, while full integration timing costs 22 minutes.
Compiler throughput, developer-loop latency, generated-program execution,
startup, memory and source complexity remain separate measures.

The objective is a usable checked compiler with general speed improvements,
backed by scoped semantics and repeatable comparisons. Neither a fast manually
edited program nor a nicer intermediate representation alone fulfills it.

## Questions and ranked hypotheses

1. **P30-001 direct entry:** repeated generic application, partial descriptors
   and copied argument vectors dominate useful work in some inner helpers.
   Replace only private full entries/transfers; keep public descriptors,
   arithmetic, array access, projection and constructor scheduling fixed.
2. **P30-002 general loops:** a compact description of parameter/match entry and
   control flow permits safe private loops beyond scalar Nat countdowns.
   Keep representation and direct-call policy fixed while testing loop lowering.
3. **P30-003 data overhead:** after call overhead is reduced, generic projection,
   constructor scheduling and array operations may dominate. Measure them
   independently; prefer eliminating temporary records or specializing proven
   native operations over changing the whole runtime representation.
4. **P30-004 compiler cost:** newly computed entry facts should be bounded and
   reused, not rediscovered by large repeated core traversals at every call.
   Measure emission cost and ordinary compilation separately before promotion.

Static JS differences locate opportunities; they do not quantify runtime shares.
A repeated counter reduction without a corresponding clean timing gain refutes
that mechanism as the priority for the observed workload. No speedup factor is
assumed. Keep regressions, failed controls, and invalid/contaminated timing.

## Phase A: compare and discriminate without compiler edits

Use identical saved checked Phase29 and pinned TypeScript emissions. Separate
runtime scaffolding from program functions, align corresponding helpers, and
record direct/generic call, matcher, construction, array and loop shapes. Hash
all inputs and tools. Compare edit distance, Mandelbrot, ray tracing and lexer;
transfer claims require more than the tiny mechanism fixture.

Start with one edit-distance row/cell pipeline. The prototype owner will freeze
an exact derivation and oracle before execution. Initial intended selection is
row length32/seed17 for timing, and lengths0,1,2,7,16,32,64 with seeds0,1,17,
0xffffffff for complete-state correctness. If admission requires changing the
fixture, preserve the original attempt and explain the new scope before timing.

Disposable JS variants must identify themselves as prototypes and preserve the
public G definitions. A direct cell/f1/f2/f3/f4 chain can enter after the row has
already evaluated its arguments. Match projection, field snapshot and fallback
behavior require independent review, including malformed/foreign field vectors.
Run operation counters separately from uninstrumented performance. Add a second
small fixture only when it discriminates a remaining plausible mechanism.

## Phase B: implement the smallest general checked rule

First prove a profitable mechanism with the saved-output intervention. Then
introduce only enough backend structure to express it safely. A compact
per-function entry/control plan can record bound variables, argument-demand
boundaries, matches, returns and tail transfers. Keep parser/checker/core and
the existing fallback. Do not materialize a complete new book for every tiny
pass. Prefer explicitly specified small transformations with an inspectable
contract; a well-formed plan is not a semantic preservation proof.

Separate worker formation from tail-loop lowering and from data/array changes.
Admit known complete calls only when earlier applications still happen before
later effectful arguments, or when a restricted purity/atomic-argument proof
permits the schedule. A saturated call alone is not that proof. Public partial
application must continue to use its existing arity/descriptor behavior.

Workers must preserve erasure, native identity, argument and field evaluation,
errors, mutation/ownership, escaped closure captures and bounded tail stack.
Retain `project` and its field-copy schedule initially; foreign getters/custom
slice results and mismatched field vectors need exact fallback. A native name
alone does not prove identity. Fresh loop aliases protect escaping closures;
parallel next-argument temporaries protect evaluation order. Explicit `kc`
branches fence recognizer recursion because Bend `&&` is eager. Analysis work
must have explicit bounds and unsupported shapes must select the old path.

If a representation is added, count its source cost and identify old duplicated
logic it replaces. Do not claim simplification from fewer characters or from
moving complexity into an uncounted generator/runtime.

## Phase C: controlled performance and correctness

Reuse Phase29's maintained comparator: Node24.18.0, serial rotated fresh
processes, CPU3, 4MiB stack, 1GiB heap, sanitized BEND/NODE environment. Freeze
exact source/API/runtime/Base/tool/harness/Node/config identities. Keep first
call and import separate. A short screen uses three samples/output, at least
8 calls AND100ms warmup,150ms timed target; confirm survivors with five samples,
at least100 calls AND3000ms warmup,300ms timed target. Original transfer uses
five samples, at least3 calls AND1000ms warmup,300ms target. Every result is
checked and all timed halves retained. Calibration uses separate processes.

Only the lead grants the measurement slot; pause all our builds, generated
executions, counters and CPU-heavy diagnostics during clean timing. Static
reading/documentation may continue. Parallel development/acquisition costs
are descriptive, not comparative throughput. Five samples and small half drift
do not prove convergence; prospectively follow up drift and retain both windows.
Do not repeat until a favorable result appears.

Correctness ladder: complete independent fixture outputs; public ABI/effect/
error/ownership adversarial controls; genuinely checked B1 build with36focused
observations; relevant emitter/runtime controls;23library/127point and15upstream
JS scopes; unchanged original algorithms and HVM at integration. Broaden backend
coverage where a changed rule reaches additional shapes. Full frontend and
self-reproduction are justified integration gates, not the inner loop. Do not
sum overlapping checks into a unique conformance count.

## Phase D: integration and publication

Promote only compiler-produced wins after independent semantic and measurement
review. Time original programs against both Phase29 and pinned TS, including
cold costs and observed regressions. Verify ordinary compilation/emission cost
for surviving structural changes; do not infer whole-compiler speed from a
helper. Preserve old release bytes and exact checked lineage. Install and run
CLI checks on the final artifact, update README/compiler/backend documentation,
record code size/concepts, archive raw successful and rejected evidence with
an independently checked per-file receipt, and commit/push the concrete result.

Review priorities after every decisive experiment or unproductive wave. Use the
seven-hour window for useful successive optimizations and integration; do not
spend it rerunning already settled gates. Each checkpoint reports what changed,
what the measurements establish, failures, limitations and the next question.
The final report must state actual work interval and remaining performance gap.
