# Phase36 installed compiler

**Checked03 is installed and verified. All 42 ordinary/relocated CLI checks and
all 15 postinstall audit groups pass.** The final audit matches 226 canonical
source files. Seven new Phase36 owner groups separately close on the same API;
the inherited 15 Phase35 owner groups also pass. The
[phase report](README.md), [admission](performance-admission.md) and
[gate table](final-conformance/gates.md) keep execution speed, compilation cost
and semantic scope separate.

## Installed identities

| Artifact | SHA256 |
| --- | --- |
| Installed API | `93e55ad7ee456eebb5fa3dd9606c2cf262ea386c6f66bfd891ffe187d8f50a75` |
| Genuine checked parent | `2abe5b2f86e70f554a9daf07168c8a10247d9f185e0c0961bc718ec7213acbd7` |
| Assembled Bend source | `3a17f92d036ee64230d358de26be85722315ce7f41d0fe63a92ce150722bf3d4` |
| Embedded runtime | `c1a75ed096e77cfa50ab66279b513b8cdb5aa2e273f1f56b82f8cbdde40e19fa` |
| Base | `c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661` |

The active upstream remains `018751270e800bc222a93dad7f257083ee53a5f7`.
The [manifest](../../selfhost/dist/release.json) and
[installation receipt](release-installation.json) bind six installed artifacts,
125 checkout files and the original checked lineage. Ordinary compilation runs
the Bend implementation without a TypeScript fallback. This is a checked B1
derivative, not a new self-emitted fixed point. The previous Phase35 release is
preserved under `selfhost/dist/release-history/467bc7dec2751a94cb677c5eb2da22a8fb69ee3522c6e164cb2bfcc147a78d82/`.

## Decision and validation

All fifteen unchanged execution points pass. Symbolic regression is **3.653×**
faster and ray tracing **2.319×** faster than same-run Phase35, with disjoint
observed ranges. Their remaining TypeScript gaps are **3.834×** and **23.473×**.
The other thirteen points overlap; a 3.190% map/set slowdown did not reproduce
in a same-protocol follow-up, which measured 0.523% faster with overlap. Both
observations remain in the [execution report](execution-findings.md).

Root accepts possible compiler costs: symreg and ray request medians increase
4.50% and 4.02%, with overlapping three-sample ranges. Pair changes −1.56% and
Mandelbrot +0.42%. All 36 checked requests match independent output bytes.
Source grows by 124 physical Bend lines to 18,174 lines in 69 modules; types
and laws are unchanged. This phase improves execution with a small source cost.

Fresh frontend execution agrees exactly on 3,026 main and 196 broader retained
reference observations. Main outcomes remain 2,525 pass / 497 observed / 4 shared
failures; broader remains 195 pass / 1 observed. The 81-row backend pilot retains
69 pass / 8 N/A / 4 shared failures. Reference acquisitions are verified and
reused, not presented as fresh TypeScript execution. Inherited primitive, worker,
library, component and HVM gates pass. The [CLI receipts](release-cli.json) include
JS and native CPU execution, plus a relocated copy without an upstream checkout.

The [independent review](independent-review.md) checks source identity and the
proof's callback boundaries. Error callbacks suspend scoped proof; whole-root
purity excludes array callbacks. Complete-tree, alias, partial, raw, changed-host
and refusal controls include actual optimized-entry witnesses. These finite
scopes do not prove arbitrary JavaScript-host equivalence, full backend/GPU
conformance or independent proof validity. `--verdict` remains unsupported.

## Iteration and preservation

Checked acquisition plus Focus36 takes 42.288 seconds with a 1,127,624,704-byte
process-tree peak; the actual symreg screen takes 8.028 seconds. Final full
execution takes 401.551 seconds, compiler-cost acquisition 254.736 seconds and
the separate 24-profile acquisition 76.666 seconds. Profiles identify future
private tagged-data and guard-boundary experiments; see [findings](profile-findings.md).

The [resource summary](resource-summary.json) records 529 successful bounded
receipts, five completed failures, zero resource stops and zero unfinished
receipts. Its largest observed process tree is 1,128,304,640 bytes. Counts overlap
nested supervision; they are not unique tests. All successful receipts remain
within their configured RSS bounds and above the free-memory floor. Root runs
heavy jobs serially on CPU3, with Node heaps at most 1 GiB and process-tree bounds
at most 2 GiB. Failures and rejected ideas remain preserved.

The [evidence index](evidence/README.md) records closed-tree capture and independent
reopening. The [protection audit](protected-files-final.json) verifies all 103
unrelated starting files unchanged. Commit/push is authorized; no PR comment is
posted as part of this phase.
