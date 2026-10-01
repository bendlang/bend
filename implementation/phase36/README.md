# Phase36: amortize guards and lower private tree production

The selected candidate is checked03, API
`93e55ad7ee456eebb5fa3dd9606c2cf262ea386c6f66bfd891ffe187d8f50a75`.
**It is installed and verified**, with all 42 ordinary/relocated CLI checks and
all 15 postinstall audit groups passing. All 226 canonical source files match.
See the [release record](release-03.md) and [gate closure](final-conformance/gates.md).

[Prospective campaign](../../design/phase36/campaign.md) ·
[Experiment records](../../experiments/phase36/) ·
[Tools](../../selfhost/tools/performance/phase36/README.md) ·
[Architecture](../../selfhost/docs/ARCHITECTURE.md)

## Retained mechanisms

**Scoped guard reuse.** An exact scalar-input tree entry first performs its normal
input, host and dependency checks. A separate proof of the entire original
source call graph excludes callbacks during private execution. A small private
dictionary then lets covered nested calls reuse those checks until `finally`
restores the previous scope. Error construction explicitly suspends the proof
because mutable host Error hooks can reenter. Native array graphs are refused.
The [guard report](guard-report.md) records the callback counterexamples,
actual source controls and saved-output measurements.

**Private tree production.** A scalar-input producer with two independent,
ordered recursive children uses existing continuation frames, preserving original
tagged values, parent scalars and shared children. Existing Bool/finite-Nat
selectors gain trailing-argument handling inside this independently proved
producer context. Direct constructors keep inert/primitive fields; general calls
inside delayed fields retain generic construction. There is no benchmark-name,
constant-depth or seed specialization. See the [producer report](private-producers.md)
and [selector design](../../design/phase36/producer-selectors.md).

## Measurements

All fifteen unchanged points pass in **401.551 seconds / 219 fresh timing
processes**. The incremental baseline is Phase35 checked09; pinned TypeScript
remains at `018751270e800bc222a93dad7f257083ee53a5f7`.

| Program | Phase35 ms | Phase36 ms | TypeScript ms | Gain vs Phase35 | Phase36 / TS |
| --- | ---: | ---: | ---: | ---: | ---: |
| Symbolic regression | 15.5817 | 4.2650 | 1.1124 | **3.653×** | **3.834×** |
| Ray tracing | 1,859.5891 | 801.8934 | 34.1617 | **2.319×** | **23.473×** |

These two gains have disjoint observed ranges. The other thirteen points overlap;
their complete program suffixes are byte-identical after verified runtime
prefixes. Map/set's full-run 3.190% slowdown prompted an unchanged-protocol
follow-up: 0.523% faster with overlap. Both observations remain. No source change
occurred between them and no regression fix is claimed. Every candidate still
trails same-run TypeScript output; lexer and tree-bitonic retain **89.379×** and
**80.618×** gaps. These fixed inputs do not estimate an application population.

Read the [execution findings](execution-findings.md), [complete table](execution-table.md)
and [bound data](final-results.json). Screens and saved-output ablations retain
their mechanism scope and are not substituted for the final checked-output run.

All **36 normal checked compilation requests** pass exact output checks in
254.736 seconds. Request medians change −1.56% pair, +0.42% Mandelbrot,
**+4.50% symreg and +4.02% ray**, with overlapping three-sample ranges. The
[compiler-cost report](compiler-cost.md) separates imports, request, process wall,
RSS and bytes. The [admission](performance-admission.md) accepts these possible
costs and source growth for the execution gains; it does not claim faster
compiler throughput.

All **24 separate CPU/allocation profiles** pass in 76.666 seconds, with exact
module and point bindings plus generated-JavaScript AST comparisons. Ray guard
ancestry falls **50.12→0.44%**; symreg producer ancestry falls **63.92→12.30%**.
The [profile findings](profile-findings.md) explain the remaining costs. Profiles
are diagnostic: overlapping ancestry groups cannot be summed or used as clean
execution ratios.

## Correctness and provenance

All seven new owner groups pass on checked03 and close through exact emission
receipts in `selfhost/build/phase36/owner-close03/report.json`:

| Group | Observations |
| --- | --- |
| Actual ray traversal and public boundaries | 57 oracle rows, 200 boundaries |
| Dynamic proof scope and cleanup | 10 observations |
| Nat constructor overflow and Error reentry | 16 oracle rows, 4 boundaries |
| Mixed-array proof refusal and callbacks | 16 oracle rows, 4 boundaries |
| Producer numerical transfer and refusals | 175 oracle rows, 5 admission checks |
| Complete trees, aliases and real private entry | 108 trees, 36 alias rows, 9 entries, 27 boundaries |
| Trailing selectors and context/field refusal | 243 oracle rows, 10 admission checks, 6 live mutations |

Counts overlap and are not a total conformance score. Complete-tree controls
include depth twelve and shared child object identity. Entry counters establish
that the optimized path actually runs; mutation controls require live callbacks.
The [owner closure protocol](owner-closure-protocol.md) binds every group to the
selected API rather than accepting a prior prototype's pass flag. All 38 inherited
preinstall steps pass, and the corrected 14-group audit matches 226 canonical
source files. Its frontend results agree exactly on 3,026 main + 196 broader
observations. Backend81 retains 69 pass / 8 N/A / 4 shared failures; inherited
15 owner groups, execution, library, components and complete HVM output pass.
All 42 installed/relocated CLI checks also pass. Counts and remaining proof/platform
limits are documented in [conformance](../../selfhost/CONFORMANCE.md).

## Rejected and repaired attempts

| Experiment or attempt | Outcome |
| --- | --- |
| Initial baseline adapter | Missing separate receipt for the complete-row observer; retained failure, exact observer replay in baseline02 |
| Cost-only checked01 | Ten synthetic controls, fifteen byte-identical modules and 36 checked requests pass; rejected for only 1–2% scalar compile gains and an overlapping apparent pair regression |
| Guard proof v1 | Mutable Error construction could reenter while proof was active; rejected |
| Guard proof v2 | One pure residual did not prove the complete directly lowered graph pure; native array hooks exposed the gap; replaced by full-root proof v3 |
| First scope witness | Nearest-tree mutation never executed for the chosen ray; retained failure and corrected active center-pixel witness |
| Checked02 | Generator-only producer and corrected scoped guard; checked build and focused controls pass |
| Original array fixture | Computed tuple scrutinee is invalid source syntax; corrected using a named helper parameter |
| Original producer fixture | Repeated values needed unrestricted bindings; corrected v2 sources preserve the alias assertions |
| First TypeScript fixture acquisition | Sandbox blocked a read-only git subprocess; retained failure and same bounded acquisition rerun in the approved execution context |
| Checked03 | Complete producer selectors plus scoped guard; selected for final integration |
| Additional exact-entry reflection shortcut | Semantic controls pass, but five-round median is 0.234% slower with overlap; rejected, no production patch |

The [cost report](cost-report.md) and [reflection report](guard-exact-report.md)
retain negative results. Every retry uses a new directory. No original failure
was replaced by a successful successor.

## Complexity and iteration cost

Compiler source grows from 18,050 to **18,174 physical Bend lines** (+124, 0.687%),
15,436 to **15,545 nonblank lines**, 2,008 to **2,024 definitions**, and 68 to
**69 modules**. The 71 types and 640 laws are unchanged. Runtime JavaScript grows
by 25 lines and 1,005 bytes. These counts exclude generated images and experiment
tools. This is an execution-speed improvement with a small source cost, not a
line-count reduction.

Checked03 plus the strict 36 focused checks takes **42.288 seconds** and peaks at
**1,127,624,704 process-tree bytes**. The one-case actual symreg screen takes
8.028 seconds. The saved-output producer ablation takes 10.753 seconds, and the
five-round full-ray guard ablation takes 96.502 seconds. These are different
loops: prototype quickly, acquire a checked compiler only for a surviving idea,
and reserve broad integration for the selected image. Normal compiler request
latency is measured separately, rather than inferred from build wall time.

All heavy work is serial on CPU3 with Node24.18.0, explicit Node heaps at most
1 GiB, a process-tree RSS cap at most 2 GiB and a 2 GiB available-memory floor.
Root coordinates execution; agents inspect code, challenge proofs and prepare
controls/reports. The [evidence capsule](evidence/README.md) is captured only
after all raw writers close. The 103 unrelated starting files remain protected.
No PR comment is authorized or posted.
