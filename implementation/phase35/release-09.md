# Phase35 installed compiler and release closure

**Checked09 is installed and verified. All 14 preinstall gate groups, all 42
ordinary/relocated CLI checks, and the final 15-group postinstall audit pass.**
All 225 canonical snapshot files match. The [independent release review](release-assessment.md)
checks final receipts and artifact identities separately from root's admission.
The [phase report](README.md) contains the experiments, full timing table and next
hypotheses; [performance admission](performance-admission.md) records the costs.

## Artifact identity

| Item | SHA256 |
|---|---|
| Installed API | `467bc7dec2751a94cb677c5eb2da22a8fb69ee3522c6e164cb2bfcc147a78d82` |
| Genuine checked parent | `f4c42dffb7e7ce015ef402ddbb9569d9d1539c284c3bce4ca394563d22da54cb` |
| Assembled Bend source | `e0764b71474eae9a46de637c6dc16e2dd32f29ba51c6eb93be18c3f5b4a9e088` |
| Embedded runtime | `af2a3ae8a3c42fc0cb206ec7671960b82501944bf5619ec7893847460447a961` |
| Base | `c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661` |

Upstream remains `018751270e800bc222a93dad7f257083ee53a5f7`, after Bend 2.0.34.
The API is the maintained equality-derived B1 from the genuine checked parent
of the same source. The [release manifest](../../selfhost/dist/release.json) and
[installation receipt](release-installation.json) bind six installed artifacts,
124 checkout files and original lineage. Ordinary compilation executes Bend code
without TypeScript fallback. No new H image or self-emitted fixed point is claimed.
The prior Phase32 release is preserved under
`selfhost/dist/release-history/8be506d811f627fe6346a5eaba07050c36db70e2704608adcfd781b85a3a7f92/`.

## Why promote this version

Five unchanged generated programs improve by more than 5%, with disjoint observed
ranges in the same final run: pair **1.324×**, fold **2.360×**, original edit
distance **1.278×**, symreg **6.865×**, and raytrace **5.475×**. All fifteen points
complete with exact expected results. No workload is faster than the same-run
TypeScript compiler's output. Remaining gaps range from 1.406× on the long scalar
control to 89.150× on lexer; fixed-input ratios do not define a production average.

The main finding is that eliminating temporary representation and generic dispatch
inside a proved private region matters much more than copying arbitrary helper
code. Selective vector inlining and scalar loop state remove allocations; captured
Number countdowns and direct array calls remove local wrappers; finite decisions,
F32/final-Bool loops, separately proved pure residuals and closed structural folds
make broader regions useful. Public stages/data, demand order, mutation guards
and generic fallback remain. Broad scalar inlining was rejected after regressions.

The full-run generic-row median was 9.52% slower with overlapping bimodal ranges.
Its required focused recheck records 0.323% slowdown with overlapping ranges;
executed functions are unchanged. Both observations remain, and no corrective
source change or established regression fix is claimed. Other overlapping median
changes are not promoted as wins. Clean timing is separate from all profiles.

Promotion explicitly accepts **compiler and size costs**. Three rotated normal
checked-library requests per role/source, 36/36 byte-verified outputs, show:

| Source | Phase32 request ms | Phase35 request ms | Change | Phase35 / TS request |
|---|---:|---:|---:|---:|
| Pair | 1,669.819 | 1,681.841 | +0.72%, overlap | 5.393× |
| Mandelbrot | 1,709.781 | 1,849.441 | +8.17% | 5.417× |
| Symreg | 1,531.111 | 1,991.764 | +30.09% | 6.650× |
| Raytrace | 1,992.469 | 2,677.918 | +34.40% | 6.184× |

The last three request ranges are disjoint. Ray's baseline samples drift upward;
three samples are limited evidence and the report preserves them all. Imports,
verification and supervised whole-process duration are separate boundaries.
At these fixed inputs, symreg's extra 461 ms request cost is recovered in about
six complete calls; ray's extra 685 ms is smaller than one call's 8.4-second saving.
Mandelbrot has no corresponding measured execution benefit. This is an accepted
regression and a target for avoiding unproductive analysis, not a throughput win.
See [normal compiler cost](compiler-cost.md) and the pre-install
[root decision](admission-decision.json).

Source grows by **979 physical Bend lines (5.73%)**, 124 definitions, two modules
and one proof-state type, reaching 18,050 lines / 68 modules. Generated program
sections grow 10–57% on the four profiled points. These costs are accepted for
the measured gains; the phase is not a simplification. The new analysis remains
bounded and reuses the existing private-region/public-ABI architecture.

## Exact semantic and release scope

The [final audit](final-conformance/gates.json) keeps every gate and reference
identity; its [readable table](final-conformance/gates.md) separates the scopes.
Fresh candidate frontend execution matches all **3,026 main and 196 broader**
reference observations. Main raw verdicts remain 2,525 pass / 497 observed /
4 shared failures; broader remains 195 pass / 1 observed. These reference
acquisitions were retained and revalidated, not rerun and represented as fresh TS.

The fresh backend pilot preserves **81 exact historical outcomes: 69 pass,
8 not applicable and 4 shared failures**. It runs in the approved native CPU
execution context without a backend retry. Known shared failures and unavailable
lanes remain visible. These counts do not establish full backend or GPU conformance.

All 15 final owner groups pass on checked09, including complete pair/fold state,
328,966 ordered native events, aliases/nesting, argument order, counter precision
and hooks, finite Nat/F32/branch controls, delayed records, partial regions,
whole-graph purity refusals and iterative structural folds. Separate witnesses
establish that the intended private paths ran. Structural-fold controls include
675 small comparisons, two deep points up to 50,000 nodes, 57 boundaries and
24 recognizer cases. These overlapping finite scopes are not a proof of arbitrary
program or arbitrary modified JavaScript-host equivalence.

Fresh inherited gates pass 56,205 primitive checks, 3,759 worker checks, 144
nested checks, 1,129 primitive guards, 15 selected upstream probes, 23 libraries/
127 points, 40 worker guards/two witnesses, 22 compiler-component observations
and the complete 42-byte HVM stdout with empty stderr. The optional 811-case JS
expansion and independent proof-kernel/GPU campaigns remain outside this release.

The initial owner launch stopped during read-only Git verification with sandbox
EPERM; the explicit retry retains that failure and all earlier passes. Two
collector report pointers were repaired without changing oracle assertions.
The initial final audit then rejected a historical reference runtime path as if
it were a live dependency. The [audit successor](provenance-audit-repair.md)
resolves only the exact pinned reference through its archived modules and frozen
Phase32 snapshot. All candidate edges and canonical-source checks remain strict.
The original failed audits and acquisitions remain preserved.

The [42 CLI receipts](release-cli.json) cover ordinary and relocated checking,
interpretation, JS emission/execution, native CPU emission/build/run and integrity.
Native checks use Clang16. The relocated copy has no upstream checkout; historical
absolute provenance paths are metadata, not a claim of OS isolation. These are
fresh checks on the installed API, not results attributed from an earlier release.

## Resource bounds and evidence

One heavy job runs at a time under the shared lock, with one compiler worker,
CPU3, explicit Node heaps no larger than 1 GiB, process-tree RSS/deadline bounds
and a 2 GiB available-memory floor. The selected checked build plus Focus36 takes
42.506 seconds and peaks at **1,129,676,800 bytes**. Node heap and process-tree RSS
are distinct; sampled RSS sums can double-count shared pages.

The [resource snapshot](resource-summary.json) includes **772 successful bounded
receipts, 13 completed failures, zero resource stops and zero unfinished receipts**.
Counts overlap nested acquisitions and are not unique tests. Every successful
receipt stays within its configured RSS budget and free-memory floor. Parser,
fixture, inactive-witness and environment failures remain in the raw tree.
The full maintained benchmark takes 518.338 seconds; the three-case screen takes
22.961 seconds. Separate final profiling completes 24/24 in 149.020 seconds,
peaking at 532,652,032 bytes. These are measured acquisition costs, not guarantees.

The [evidence capsule](evidence/README.md) preserves all closed Phase35 raw
experiments, including failed/superseded attempts. Capture and fresh independent source/archive verification both pass:
24,717 files / 395,912,134 logical bytes in 52,475,156 compressed bytes across
two volumes. Capture takes 25.199 seconds and peaks at 65.6 MiB RSS. Exact
volume/member hashes and resource receipts are linked from the capsule index.
The [final protection audit](protected-files-final.json) verifies all 103
unrelated starting files unchanged. Commit and push
are publication actions, separate from installation or audit success. No PR
comment is posted as part of this phase.
