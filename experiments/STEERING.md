# Phase36 current frontier

User authorization covers compiler experiments, implementation, design/report
and commit/push to `rom1504/bend`, branch `selfhost/bootstrap`. No PR comments
without an explicit request. Older timed campaigns are historical. Preserve the
103 unrelated starting files and the closed Phase35 and Phase36 raw trees.

## Installed result

**Phase36 checked03 is installed and verified.** All 42 ordinary/relocated CLI
checks and all 15 inherited postinstall audit groups pass; 226 canonical files
match. Seven new owner groups separately close on the same API:
`93e55ad7ee456eebb5fa3dd9606c2cf262ea386c6f66bfd891ffe187d8f50a75`.
Upstream remains `018751270e800bc222a93dad7f257083ee53a5f7`. This is a checked B1
derivative, not a new self-emitted fixed point. The previous Phase35 release is
preserved in release history.

[Report](../implementation/phase36/README.md) ·
[Release](../implementation/phase36/release-03.md) ·
[Admission](../implementation/phase36/performance-admission.md) ·
[Profiles](../implementation/phase36/profile-findings.md)

Retained changes: scoped guard reuse under whole-root purity and private ordered
tree production with finite Nat/Bool selectors. Error construction suspends proof
through callbacks; native-array graphs are refused. Original tagged storage,
sharing, public stages and fallback remain. No new types or laws were needed.
The source is frozen at `selfhost/build/phase36/checked03`.

## Measurements and costs

The unchanged fifteen-point comparison takes 401.551 seconds. Versus fresh
same-run Phase35, symreg is **3.653×** and raytrace **2.319×** faster, with disjoint
observed ranges. Remaining TS gaps are **3.834×** and **23.473×**. Other points
have overlapping ranges; all fifteen remain slower than TS. Lexer and tree-bitonic
retain **89.379×** and **80.618×** gaps. Do not average these fixed-input ratios.

Map/set shows +3.190% in the full run and −0.523% in a same-protocol focused
follow-up; both overlap and remain evidence. Thirteen complete program suffixes
are byte-identical, with a common runtime increase of 1,005 bytes. Normal checked
request medians change −1.56% pair, +0.42% Mandelbrot, +4.50% symreg and +4.02% ray,
all overlapping across three samples. Accept these possible costs explicitly;
no compiler-throughput improvement is established.

Source grows 124 physical lines (0.687%) to **18,174 Bend lines / 69 modules /
2,024 definitions**, with 15,545 nonblank lines, 71 types and 640 laws. Generated
program sections grow 1,440 bytes for symreg and 186 for ray. This phase improves
execution, not source simplicity.

## Next experiments

1. Test one private finite-sum or tree-to-tree operation from lexer or bitonic,
   such as `step.at`, `warp_leaf.go` or `warp_zip`. Their hot generic application,
   forcing and closures remain, and guard-only work will not cover these paths.
2. Find a proved enclosing boundary for symreg's remaining guards: its producer
   ancestry falls 63.92→12.30%, while guards now occupy 35.58% of sampled ancestry.
3. Lower one remaining ray geometry/tagged-result call. Guards fall 50.12→0.44%;
   `apply` now accounts for 31.53% of self samples. Keep the complete-row oracle.
4. Consider narrowly proved direct nonnative constructor creation only as a
   secondary ablation; `ctor` is 4.52% of symreg allocation samples.

These are unimplemented hypotheses without gain promises. Start with a clean
saved-output ablation and complete local oracles; require actual path entry,
mutation/reentry and refusal controls before a checked compiler change. Do not
repeat the rejected extra reflection shortcut or compiler-analysis preflight
without overcoming their recorded lack of material benefit. Do not build a new
optimizer IR before a narrow mechanism establishes its value.

## Reproduction and closure

Use the maintained 20/60/300/600-second execution ceilings with independent
`--set`/`--cases`. The default portable baseline remains Phase32; Phase36 uses the
explicit `baseline02/manifest.json` containing Phase35 checked output. See the
[phase tools guide](../selfhost/tools/performance/phase36/README.md). Checked03
plus Focus36 takes 42.288 seconds; the actual symreg screen takes 8.028 seconds.
Profiles are separate: all 24 pass in 76.666 seconds. Clean final run is
`full-confirm03`; follow-up `map-set-confirm03`; cost `compiler-cost-run03`;
profiles `profiles03`, all under `selfhost/build/phase36`.

Frontend agrees exactly on 3,026 main + 196 broader observations. Raw main
verdicts remain 2,525 pass / 497 observed / 4 shared failures; backend81 remains
69 pass / 8 N/A / 4 shared failures. Counts overlap and no full backend/GPU or
independent proof-kernel result follows.

The [capsule](../implementation/phase36/evidence/README.md) preserves failures and
successes with independent reopening/source verification. Resource receipts show
zero resource stops and zero unfinished jobs; all 103 protected files remain
unchanged. Root alone runs heavy jobs serially, CPU3, heap at most 1 GiB, process
tree at most 2 GiB, and a 2 GiB free-memory floor. Agents inspect and prepare
controls/docs without concurrent compiler or benchmark jobs.
