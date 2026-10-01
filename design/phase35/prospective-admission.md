# Final compiler admission for Phase35

Select one checked compiler only after the mechanism experiments. Every selected
source change must appear in that compiler's frozen snapshot; every final runtime,
conformance and owner control must use that exact API. Earlier checked attempts
and handwritten output prototypes remain useful evidence, but cannot discharge a
final-image gate. This design does not expand the backend conformance claim.

`selfhost/tools/performance/phase35/final-integration-plan.py ATTEMPT NEW_OUT`
creates immutable tools, identities, configuration and commands without executing
anything. The optional repeated `--added-module` argument supports only
`src/back/js/jpure.bend` immediately after `local.bend`, and
`src/back/js/fold.bend` immediately after `region.bend`. All original 66 modules
must remain in their original order; all other compiler.json fields are identical.
The complete selected 66–68 entry list is frozen. This is an explicit layout
migration, never a general exception to manifest equality.

Root executes commands serially. Each command has a ready `supervisedCommand`
using the existing process-tree supervisor and shared execution lock. Parent and
child CPU affinity is 3; every Node child has at most a 1024 MiB heap. The outer
process tree is capped at 2048 MiB with a 2048 MiB host-available-memory floor.
Existing test deadlines, selected fixtures, expectations and oracle bodies remain.
Timing never overlaps code acquisition, controls, profiles or other benchmarks.
An incomplete, killed or failed run stays failed; a retry gets a new directory.

## Correctness gates

The plan reuses the Phase32 final frontend/backend assertion bodies and their
resource limits. Only structured candidate/output bindings, explicitly frozen
module layout, and old launcher CPU values change.

| Gate | Required result |
| --- | --- |
| Checked build | Equality-derived API, strict exact focused 36 probes, no differences |
| Full selected frontend | 3026 exact outcomes; healthy single worker, no timeout/failure |
| Broader frontend | 196 exact outcomes, same checks |
| Selected backend | All 81 exact historical observations: 69 passes, 8 N/A, 4 shared check failures |
| Primitive controls | 56205 scalar checks |
| Worker controls | 3759 scalar checks |
| Nested controls | 144 checks |
| Primitive refusal guards | 1129 guards |
| Upstream selected JS | 15 exact probes |
| Generated corpus | 23 libraries and 127 points |
| Worker admission | 40 refusal guards plus two execution witnesses |
| Compiler component | 22 independent observations |
| Whole HVM demo | Exact complete 42-byte stdout, empty stderr |
| Release smoke | 42 ordinary and relocated CLI assertions, selected installed API |

Backend comparison keeps complete reference/candidate observations and their
verdicts, including the four shared check failures. Neither shared failure nor N/A
becomes a pass. No result is replaced with an earlier compiler's result. Native
execution-environment failures remain visible; any separate retry must preserve
that failure and satisfy the same exact row admission. GPU and broad backend
coverage are not implied by these 81 observations.

Owner controls are additionally mandatory for the final compiler: pair, fold,
argument/read order, parallel scope, vector types/values, aliases, nested vector
loops, counter admission/refusal, counter Number hooks, expanded regions, finite
Nat guards and ray tracing. A selected `jpure.bend` requires the pure-graph owner
group; a selected `fold.bend` also requires recursive-fold owner controls. Include
actual fast-path witnesses so a passing generic fallback cannot certify the new
optimization. For emitted code, preserve independent complete results, ordered
storage/callback events and negative witnesses where the existing owner tools
provide them. Counter tests near 2^48 execute bounded transitions, never a full
huge loop.

The owner aggregate at `NEW_OUT/owner/report.json` records selected `attempt` and
`api` identities and a `cases` array. Each case has the exact name from the frozen
plan's `ownerGates`, `returncode: 0`, and either one identity-bearing `report` or
several `reports`. Every report must be complete and passing. Its hashed provenance
graph must reach the final checked API and final attempt through recorded inputs
or checked emission/cohort receipts. An unrelated final API added to the aggregate
cannot make an old report valid. Keep cohort transformation receipts connected
from the controls' inputs when a wrapper surrounds the raw checked output.

The audit script preserves Phase32's focused/frontend/backend/inherited/corpus/
component/HVM assertions, strengthens owner provenance, and requires canonical
source equality with the selected snapshot. Run
`final-gate-audit.py PLAN_DIR NEW_AUDIT --require-closed` before installation.
Missing or invalid reports remain explicitly incomplete. After installation and
release verification, use a fresh audit directory and add `--post-install` to
require all 42 CLI checks and the installed API identity. The audit executes no
gates and makes no performance-admission decision.

## Generated program performance

Measure the selected compiler's emitted programs through the maintained Phase34
catalog, source identities, reference modules and exact expected answers. Start
with the focused 60-second screen, then confirm accepted effects on the relevant
300/600-second suites. Report each workload's same-window baseline, candidate and
TypeScript medians plus spread and raw samples. Include unchanged scalar zero,
long scalar, pair, fold, Mandelbrot, edit distance, ray, RLE and the slower recursive
workloads as applicable to the changed proof. Keep mechanism ablations separate
from broad generated-program metrics; never divide numbers from unrelated runs.

Profiles and syntax analysis are diagnostic artifacts outside timing. Compare
allocations, dominant functions, helper calls, closure/vector creation and emitted
bytes on the same source. A transformed but inactive guarded path is a failed
optimization experiment even when outputs agree. Broad correctness, code-size and
compile-time costs constrain promotion alongside generated execution time.

## Normal checked compiler cost is a separate measurement

Measure complete normal checked-library requests for (1) pair and Mandelbrot,
then (2) symreg and ray, on identical source with TypeScript, the Phase32 baseline
and the selected checked compiler. Use each compiler's normal validated Base
pipeline/cache; do not time only emission or manufacture a new frontend shortcut.
Bind API, runtime, Base, driver, Node, upstream pin, source and expected emitted
output identities. Verify every produced output byte against its independently
acquired checked module before accepting a timing sample.

Use three rotated samples with a fresh process for each compiler/request, CPU3,
1024 MiB heap, 4 MiB stack, 180-second child deadline and the same outer memory
supervisor. Record cold import/setup, complete request wall time, peak process-tree
RSS and generated bytes where available. Report all four costs separately from
runtime improvements; a slower compiler can be acceptable only as an explicit
tradeoff, never hidden inside a generated-program speedup. Reuse the maintained
Phase30 library-cost worker/assertions with a structured final-candidate case plan
when ready. These compiler-cost jobs are requested and reviewed separately from
the correctness planner and do not run as an accidental side effect of it.

After these gates, root installs/verifies the selected release, runs the 42 CLI
checks, documents accepted and rejected experiments, updates the repository usage
links, commits the exact selected source/tools/design/report and pushes. No PR
comment is posted without a new explicit user instruction.

## Concrete execution sequence

The planner accepts `--prepared PATH/manifest.json` to reuse a complete maintained
candidate bundle from the same selected API/runtime/Base. It verifies those
identities before creating owner commands; all new source fixtures are freshly
emitted. The owner schedule is concrete and includes cohort adapters, current and
legacy controls, Number-hook pairs, proof recognizers, Hit/partial-tree controls,
colf transfer, and the recursive-fold suite when its module is selected. The
final owner collector writes the aggregate required by the audit.

For a selected 68-module attempt with an already prepared bundle, root runs:

```sh
python3 selfhost/tools/performance/phase35/final-integration-plan.py ATTEMPT NEW_PLAN \
  --added-module src/back/js/jpure.bend --added-module src/back/js/fold.bend \
  --prepared PREPARED/manifest.json
python3 selfhost/tools/performance/phase35/final-integration-run.py NEW_PLAN \
  --stage preinstall --out NEW_LAUNCH
python3 selfhost/tools/performance/phase35/final-gate-audit.py NEW_PLAN NEW_AUDIT \
  --require-closed
```

`preinstall` runs owner groups first, then broad gates, and stops at the first
failure. `--stage owner` can run just those cheap gates first; `--start NAME` is an
explicit resume point, with every prior output preserved. Acquisition helpers
that already own `ExecutionGuard` run directly; other commands use the outer
supervisor, avoiding a nested lock. The root runner only orchestrates these serial
children. A later repair creates a new plan/output directory and retains the
original failure. No automatic install occurs during either stage.

After separate performance admission, `--stage postinstall` executes the frozen
install/verify/42-CLI commands. A fresh audit with `--post-install` verifies those
receipts and the installed API.

For normal compiler cost, use the standalone preparation and run tools:

```sh
python3 selfhost/tools/performance/phase35/compiler-cost-plan.py \
  ATTEMPT PREPARED/manifest.json NEW_COST_PLAN --cases local-pair,mandelbrot
python3 selfhost/tools/performance/phase35/compiler-cost-run.py \
  NEW_COST_PLAN/config.json NEW_COST_RUN
```

Repeat in fresh directories for `--cases symreg,raytrace`, or omit `--cases` to run
all four. Optional `--baseline-preparation` and `--typescript-preparation` accept
fresh maintained bundles when exact historical output is unavailable. The default
uses the identity-verified portable Phase34 reference modules and requires the
Phase32 baseline API/runtime/Base/driver hashes to agree. Both the new emission
receipt schema and checked attempt identity are verified explicitly. The worker
bytes remain SHA256 `f0dea569…`, unchanged from Phase30; the new runner changes only
bindings, role names, CPU, heap and memory supervision around that worker.
