# S0 report: hypothesis validation without implementation changes

Status: complete, 2026-09-26. Baseline `fc509f4`.
[Phase design](../../design/phase7/s0_hypothesis_validation.md) ·
[Overall design](../../design/phase7/compiler_simplification.md).

The first reduction has a concrete, reviewed implementation path: **548 physical
lines, 460 nonblank lines and 14,980 bytes** of unreachable private declarations
can be removed, projecting **15,961 lines**. S1's 16,000-line ceiling is supported
by an exact deletion inventory. No implementation has changed during S0.

The proposed multi-thousand-line allocations for S2 and later phases are **not
validated**. Named deletion pools are much smaller and require replacement code.
The 50% and 75% goals remain objectives, not forecasts or completed achievements.

## Baseline identity and environment

The existing source recount confirms all 59 production modules are byte-identical
to `a6459af`: 16,509 physical lines, 13,803 nonblank lines, 509,937 bytes, 1,526
definitions, 1,280 laws and 66 datatypes. The upstream checkout is clean at
`6018e28ecc67cf1fffc0c20c64b11023474c2df8`.
[Baseline identities and file counts](s0-evidence/baseline.json) record this scope.

The installed release's complete manifest hash check finds no mismatch. Its
existing release verifier, including equality derivation replay, passes:

```sh
# Working directory: selfhost/
/home/ai/.nvm/versions/node/v24.18.0/bin/node \
  tools/development/release.mjs --verify
```

It reports `complete:true`, `artifact:equality-derived-b1`, `newBootstrap:false`,
API `e2b5463678a26558e8fea1d585782e0863f1046067949a374f0469080281b15a`, source
`e3b927d13dc2645e19171b72de60c49dd5bc5e5059863937153b957e2ce0ec1d`.
This verifies the identified release; it is not a new conformance or timing run.

The initial `node`/`npm` shell invocations failed with exit 127 because they are
not on this environment's default PATH. Existing Node 24.18.0 was located under
NVM and used by absolute path; no installation or source change was needed.
Clang/clang-19 are absent from PATH and `/usr/lib/llvm*`; GCC is available. Native
execution gates must establish their toolchain before running. There are eight
available logical CPUs. Historical timings are not reinterpreted as fresh timings
on this environment.

The prior 919 positive passes, 318 strict check failures, 444 exact live differences
and 6.03x full-source TS ratio retain their original artifact/workload scope.
No new full-suite, self-reproduction or performance claim is made by S0.

## Hypothesis ledger and non-overlapping budgets

| Phase/hypothesis | Current evidence | Net saving credited now | Decision / first falsifier |
| --- | --- | ---: | --- |
| S1 obsolete implementations | Exact 53 functions, 35 laws and five exclusive types; all remaining-production and external reference searches empty | 548 proposed compiler lines; no replacement | Supported for implementation. Any actual root, checked-build error or generated-output difference rejects an affected deletion. |
| S2 explicit term access/provenance | 675 gross lines identified before replacement; 65 constructed core/administrative tags need representation policy | None | Bounded trial only. New variants/metadata/bridges must remove more code and rules than they add. |
| S3 authoritative checker failure | Existing isolated candidate removes 140 Bend lines and adds two host lines; exact 459-negative observations and accepted/late-error timings retained | 140 candidate Bend lines, 138 across required languages; not promoted | Supported narrow candidate, but combined current-source validation still required. Preserve first error and public detailed-result shape. |
| S3 retained type facts | `annotate.bend` is 400 lines total; `KChecked` already retains local term/type/uses. Specialized books/binders differ from chronological checking | None; 400 is a gross module size, not a deletion estimate | Unresolved. Dependent substitutions, templates and consumer facts must survive without stale-book reuse. |
| S4 frontend/loader plumbing | 214 gross lines after overlap correction: 52 duplicate selectors/length, 92 legacy-loader declarations, 70 duplicate error traversal | None; conditional net estimate requires reallocation after S1 | Bounded trial only. Public fallback loader and first-error behavior must remain correct. |
| S5 binding model | Active explicit-stack freshening, normalization sharing and template binder shifts have distinct obligations | None | Unresolved. Capture/stack/sharing counterexamples decide; obsolete S1 freshening is not counted again. |
| S6 backend semantic planning | Backends total 4,011 lines but their target models differ; TS already implements additional native optimization | None | Unresolved. Show identical decisions and actual net deletion before introducing a shared plan. |
| S7 residual traversal/control | No exact residual inventory exists before earlier migrations | None | Unresolved. No general visitor/metacompiler budget can be credited in advance. |

The source-level identified gross pools of S1, S2, annotation and S4 total 1,837
lines, even before replacement. Adding the separately measured 140-line error
candidate gives 1,977, subject to rechecking cross-phase interactions. This does
not explain the 8,255 lines needed for 50% or 12,382 needed for 75%. In particular,
after S1, deleting all 675 S2 lines with no replacement would leave 15,286 lines,
still 1,786 above the provisional S2 ceiling of 13,500. S0 rejects that ceiling
as an evidence-backed forecast; it remains a planning goal requiring a new budget.

S1 review correction: the original S0 summary at `83c8ebc` counted the ten-line
`f_dv` accessor in both S1 and S4. It is assigned to S1 only; S4's selector pool
is 52, not 62 lines. The original raw S0 audit retains its stated estimate and this
erratum makes the correction explicit. The exact S1 deletion inventory and its
548-line total were unaffected.

## Concrete findings

The [retirement audit](s0-evidence/retirement-audit.md) and
[exact declarations](s0-evidence/retirement.json) identify eight affected modules.
They retire old recursive freshening, old recursive/non-graph normalization and
comparison, unused native flat-layout packing, unused native traversals and
isolated frontend helpers. The active lazy graph evaluator, work frames,
`norm_rebind`, native word types, supported loader/origin APIs and all selected
compiler roots remain. Root independently verified every block/source hash and
performed the proposed deletion in memory: zero remaining production references,
exactly 15,961 / 13,343 / 494,957 projected lines/nonblank/bytes. No candidate tree
or compiler image was created during this audit.

The [representation audit](s0-evidence/representation-audit.md) shows why a simple
translation to explicit variants is not yet a size reduction. The source-location
experiments also provide counterevidence: earlier provenance versions exceeded
the accepted-workload cost guard. The compact ABI2 candidate adds 292 Bend and 52
required host/workflow lines while retaining origin fallback; its accepted-cost
gate is pending. It cannot be counted as either a completed simplification or an
established performance improvement.

For checked facts, [prior attribution](s0-evidence/phase6-typed-facts.txt) found zero repeated
exact annotation-type or spine inputs. A generic type cache is therefore not the
retention design. `check/annotate.bend` reconstructs types after specialization;
`check/specialize.bend` keeps source templates for conversion. Retaining facts must
transform their dependent context rather than reuse them by name or term shape.
The [structured-error result](s0-evidence/phase6-structured-checker.txt) is a separate,
narrower candidate whose existing evidence is stronger.

## Review-context baseline

Whole-file context sets are explicit, conservative review proxies. They are not
minimal theoretical contexts or measurements of human effort. Use the same tasks
and selection policy after each phase; do not improve the metric by dropping tests.

| Fixed task | Files | Physical lines | Bytes |
| --- | ---: | ---: | ---: |
| Parser first-error choice | 30 | 5,716 | 198,816 |
| Dependent application check | 9 | 3,156 | 106,647 |
| Constructor lowering across JS/native | 15 | 3,397 | 126,336 |

[Parser context](s0-evidence/parser-context.json) and
[checker/backend contexts](s0-evidence/contexts-root.json) retain exact paths,
hashes and inclusion rationale. Task sets overlap and must not be summed as a
whole-compiler context count.

## Decision and next phase

S0's read-only requirement is met. Only plans, reports and audit evidence were
written; no production compiler, host, runtime, harness, configuration or
instrumentation changed. The initial pending-work inventory and prior steering
are retained in [the audit evidence](s0-evidence/worktree-at-audit.txt) and
[the steering snapshot](s0-evidence/phase6-steering-at-start.txt).

Proceed to S1 with the exact 548-line retirement as its design. Require genuine
checked compilation, root/output comparison and existing component/selected
controls. Retain the working release until those gates succeed. Before S2, use
S1's measured result to write a bounded implementation design and revise its
unsupported intermediate allocation openly; no phase can claim completion with
more code or more conceptual machinery. The final 50% and 75% milestones remain
unachieved and must not be reported as inevitable.
