# Phase35 current frontier

User authorization covers research, compiler experiments, implementation,
design/report and commit/push to `rom1504/bend`, branch `selfhost/bootstrap`.
No PR comments without an explicit request. Older timed campaigns are historical.
The 103 unrelated starting files remain unchanged and unstaged; preserve them.

## Installed decision

**Phase35 checked09 is installed and verified.** All 42 ordinary/relocated CLI
checks and all 15 postinstall audit groups pass; 225 canonical files match.
API: `467bc7dec2751a94cb677c5eb2da22a8fb69ee3522c6e164cb2bfcc147a78d82`.
Upstream remains `018751270e800bc222a93dad7f257083ee53a5f7`.
This is a checked B1 derivative, not a new self-emitted fixed point.
[Report](../implementation/phase35/README.md),
[release](../implementation/phase35/release-09.md),
[admission](../implementation/phase35/performance-admission.md),
[literature](../design/phase35/literature.md).

Retained changes: selective vector inlining/scalar state, captured private Number
countdowns, direct private get/set, finite Nat/F32 decisions, final-Bool loops,
independent bounded purity proof and closed iterative structural folds. Broad
scalar inlining was rejected. Source is frozen at `selfhost/build/phase35/checked09`.
The prior Phase32 installed release is preserved in release history.

## Measured results and costs

The unchanged 15-point maintained suite completes in 518.338s. Gains versus
same-run Phase32: pair **1.324×**, fold **2.360×**, original edit distance
**1.278×**, symreg **6.865×**, raytrace **5.475×**. Remaining TS gaps respectively
**3.058×, 3.497×, 3.259×, 14.021×, 54.781×**. No candidate beats TS in this
final set; fixed inputs do not define average application speed.

Generic-row's full-run median is 9.52% slower with overlapping bimodal samples;
a separate five-round check is 0.323% slower with overlap. Preserve both, do not
claim a fix. Normal checked compilation costs +0.72% pair (overlap), +8.17%
Mandelbrot, +30.09% symreg and +34.40% ray (disjoint ranges; ray baseline drifts).
These are accepted costs, not compiler-throughput wins. Compiler source grows by
979 physical Bend lines (5.73%) to **18,050 lines / 68 modules / 2,008 definitions**.
Generated modules also grow. No simplification claim.

## Next experiments

Use [final profiles](../implementation/phase35/profile-findings.md) to choose the
next small ablation. Do not begin a large optimizer or rerun the full suite blindly.

1. Amortize ray's repeated guards across a proved private region. Guard ancestry
   is 47.24% of candidate CPU; preserve mutation/callback/reentry boundaries.
2. Lower symreg's pure producer. Generator ancestry is now 64.33% of CPU, while
   eval/size falls to 9.41%; more consumer work misses the dominant cost.
3. Carry private array/index facts farther in pair/fold's surviving hot loops.
4. Audit unused private helper declarations for size, retaining guard dependencies.
5. Avoid unproductive analysis to recover compile latency, particularly Mandelbrot.

These are hypotheses, not measured future gains. Pair/fold allocation samples
are already lower than TS while execution is slower; allocation is not the only cost.

## Reproduction and preserved scope

Use the [maintained execution loop](../selfhost/tools/performance/programs/README.md)
with 20/60/300/600-second ceilings and independent `--set`/`--cases` coverage.
Checked09 plus Focus36 took 42.506s; `local-pair,local-fold,symreg` screen took 22.961s.
Profiles run separately. The [phase tools guide](../selfhost/tools/performance/phase35/README.md)
separates actual compiler gates from saved-output experiments.

Raw full run: `combined-full-confirm-01`; focused follow-up: `generic-row-confirm-01`;
profiles: `combined-profiles-01`; costs: `compiler-cost-run09`, under `selfhost/build/phase35`.
Final audit uses **final-gate-audit-v2.py** and explicit owner retry aggregate
`final-owner-retry09-01/owner-report.json`. The original audit's historical-path
error and sandbox acquisition failure remain preserved; no assertion was weakened.

**3,026 main + 196 broader** frontend observations agree exactly. Raw main
verdicts remain 2,525 pass / 497 observed / 4 shared failures. Backend81 remains
69 pass / 8 N/A / 4 shared failures.
Keep scopes separate; no full backend/GPU or independent kernel claim.

The [verified capsule](../implementation/phase35/evidence/README.md) retains 24,717
files in two volumes (52,475,156 compressed bytes), including failed/superseded
attempts. Final protection audit verifies all 103 unrelated files. Only root runs
heavy jobs, serially under a shared lock, CPU3, explicit heaps, RSS/deadline limits
and 2GiB available-memory floor. Do not write into the closed raw Phase35 tree.
