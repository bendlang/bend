# Phase25: explain the cost of emitted programs

## Objective and scope

Build a reusable, fast investigation loop for programs emitted by the compiler
written in Bend. Compare the installed Phase24 emitter with the pinned upstream
TypeScript emitter on identical source, then connect recurring generated-code
patterns to execution time and allocation. This is an analysis phase: no compiler
or runtime change, new release, upstream migration, or full self-reproduction is
required. A small diagnostic transformation is permissible only on a separately
identified copy. No diagnostic copy becomes the installed compiler.

The baseline is repository commit5350b2fec8f6f8484c7a689e915b359d7ce86847,
upstream018751270e800bc222a93dad7f257083ee53a5f7, installed guarded B1
API7b523bdffc0acde702dda1005a5e8201f7b65b2e432d1be95b07f2cfcc0346fa.
This API is a derivative of a genuinely checked upstream-built compiler. Its
output is self-emitted user code; neither that output nor this experiment is a
new compiler fixed point. Historical compiler-throughput ratios are separate.

Read experiments/README.md and retain all attempts. Preserve the103 unrelated
starting paths recorded by Phase24, taking a fresh byte inventory before work.

## Questions and discriminating observations

1. **Call lowering:** do matches interrupt saturated calls, producing generic
   dispatch and partial applications where upstream uses direct workers?
   Disproof: the pattern is absent, rarely executed, or not associated with cost.
2. **Allocation:** do closures, argument arrays and trampoline messages account
   for substantial executed work? Count these independently. Phase13 reduced
   closures but increased capture slots and made checking slower; no structural
   count is a speed measurement. Disproof: allocation/counters do not corroborate
   the proposed cost, or a simpler output is equally slow.
3. **Host optimization:** are residual gaps associated with hot runtime helpers,
   unstable JIT optimization, or missed loop lowering? CPU/allocation samples and
   selected V8 traces distinguish these from mere source-size differences.

Each question has a frozen hypothesis record under experiments/phase25. A null
result, unsupported pattern, wrong result, stack failure or timeout remains a
result. An association is not proof of the gain from an unimplemented change.

## Sequential phases

### 1. Freeze identities and build a paired corpus

Create roughly20–40 small cases across recursion/membership, match followed by
arguments, persistent structures, strings/Unicode, substitution/tree walks,
shared terms and arithmetic/constructor controls. Start with a manageable pilot.
Distinguish exact compiler helpers, mechanism analogues and upstream fixture
adaptations; do not imply analogues exercise the complete real compiler.

Prefer `bench(size: U32, seed: U32) -> U32` library exports with dynamic inputs
and a fully consumed scalar checksum. Keep repeated work inside Bend where
practical. Use a common library boundary; measure a trivial control to expose
host-call overhead. Retain independent expected checksums where available and
paired results at multiple sizes/seeds. Both sides must type-check before a
timing qualifies. Preserve source and emitted hashes and complete failures.

Use the installed release and unmodified pinned upstream APIs. Freeze runtime,
Base, host, compiler source and tool identities. Capture compilation separately;
compilation elapsed times in this acquisition are descriptive, not benchmark
results. Artifact reuse eliminates repeated compilation from the timing loop.

### 2. Inventory generated structure

Parse emitted JavaScript with an identified full parser where available; any
fallback recognizer must declare its restricted grammar and refuse unknown
syntax. Separate runtime, generated definitions and export/entry wrappers.
Report body bytes, functions/arities, calls, closures, arrays, matches, direct
workers and trampoline-related sites per source owner. Counts are syntax sites,
not allocation counts or claims of unnecessary work.

Normalize incidental variable names to group recurring shapes while retaining
control flow and call structure. Keep example source ranges. Count common runtime
once separately rather than inflating corpus totals. Static shape equivalence
does not establish semantic equivalence or permit automatic rewriting.

### 3. Measure execution and diagnose the largest gaps

Use the same Node24 binary, core3 affinity, 4MiB stack and 1GiB heap for both
outputs. Run serially with clean NODE_OPTIONS and no other campaign workload on
that core. Preserve startup/import latency separately from warmed exported-call
execution. Perform a pilot to select bounded repetitions, freeze that schedule,
then take at least five fresh-process samples per side in alternating order.
Keep all samples; do not silently discard outliers. Report distributions and
paired ratios, without treating the selected corpus as a universal speed factor.

Workloads should last long enough to exceed timer noise while remaining small:
target roughly50–250ms per sample, with a15second child deadline. Calibration
is not a comparative sample. Runtime inputs must be used and every result checked.
Record warmup and repetitions exactly. Very small cases are boundary controls,
not convincing measurements of inner-loop performance.

On selected slow/diverse cases run separate CPU sampling and sampled allocation
passes, including collected objects. Join samples to generated ranges and pattern
families. Add exact guarded counters on diagnostic copies for dispatch,
under/overapplication, closures, messages and argument slots if supported by the
current runtime. Validate counter accounting on a known tiny execution and demand
unchanged output. Counter runs and profiles never enter timing summaries.

Use V8 optimization/deoptimization and GC traces for selected unexplained gaps.
Record those as diagnostic evidence, not performance measurements. Native C,
Clang optimization remarks, perf and llvm-mca are a later extension after this JS
pilot; tool availability alone does not establish host permissions or correctness.

### 4. Rank explanations and review

Produce pattern → affected cases → static sites → dynamic/profile evidence →
upstream shape → minimal witness → correctness obligation → next experiment.
Candidate changes must preserve demand/error order, partial/overapplication,
capture/ownership behavior and deep-stack handling. Do not assume saturating a
call across a match can safely evaluate later arguments early.

Have an independent reviewer challenge workload equivalence, output checks,
sampling boundaries, runtime de-duplication, evidence preservation and attribution.
The report must state what is observed, inferred and still unmeasured. Stage2
speed, complete backend conformance and universal equivalence remain unmeasured.

## Outputs and bounds

Design: this file. Code and corpus: selfhost/tools/performance/phase25/. Durable
results, raw samples, profiles/counter summaries and reproduction instructions:
implementation/phase25/. Large generated modules may use a verified compressed
archive with per-file hashes; ignored local artifacts alone are not preservation.
Update the compiler guide, experiment ledger and steering; link the guide/report
from the README. Commit and push the finished, reviewed phase to the existing fork
branch under the user's standing authorization.

Initial acquisition budget: at most200MiB of new artifacts,15seconds per runtime
child and120seconds per emission child. Stop a failing family to diagnose it before
expanding volume. Short prospective amendments may refine corpus or measurement
details before the affected runs; retain original plans and failed pilots.
