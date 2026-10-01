# Private sum traversal: preparation and static review

This record covers the prospective [private-sums design](../../design/phase35/private-sums.md),
[saved-output producer](../../selfhost/tools/performance/phase35/sum-derive-v2.mjs),
[independent controls](../../selfhost/tools/performance/phase35/sum-controls.mjs)
and [admission witness](../../selfhost/tools/performance/phase35/sum-witness.mjs).
The research agent did not execute any of them or run a compiler/performance job.
The initial preparation alone established no passing-control or speed claim.
Root's subsequent results are recorded explicitly below.

The exact pinned symreg output supplies the original complete two-scalar `cand`
callback. The producer saves an untouched module, a baseline with the same new
exact-entry registration wrapper used by the experiments, a private dataset-loop
variant retaining generic eval/esize, and the same loop with direct private
Expr eval/esize. The tagged tree representation and generic depth-five generator
remain unchanged. This deliberately separates loop saturation from recursive
ADT traversal. The public original benchmark is unchanged in all modules.

The regions agent independently inspected the producer and found no blocking
issue in its bounded local Expr scope. Its source review confirmed the operand
order/wrapping and local tree origin. It also noted that full descriptor/prototype
snapshots at each candidate entry may be expensive. These conservative guards
are an experimental boundary, not a proposed expansion of the production runtime
contract. Standard host intrinsics at initialization remain an explicit scope;
post-import dependency and named host/protocol mutations are test targets.

The independent oracle uses opcode arrays and a postfix stack evaluator, rather
than duplicating the candidate's recursive tagged-record traversal. Controls
compare all three Sel fields, complete generated trees, original tournament and
climb output, public staged calls, mutations, getters, alias trees and coercion.
The documented original `bench(6, 42)` result is an additional fixed assertion.
Only four generated modules are imported for paired controls and restored between
mutations, avoiding repeated-module accumulation.

Admission counters are isolated in diagnostic derivatives. A full original
`bench(6, 42)` should enter 96 candidates, visit 96,768 eval nodes and 6,048 size
nodes in the direct-sum variant. These are algorithm-derived expected counts,
not observations. Instrumented derivatives must never supply timing results.
Root's eventual acquisitions must retain raw failures and provenance and report
actual results separately.


## First execution exposed an inactive guard

Root's first acquisition passed 71 oracle cases and 121 public boundaries, but
`sum-witness-01/report.json` immediately found zero admissions where one was
required. Therefore those controls established fallback behavior, not correctness
of executed private sum optimization, and cannot support a speed claim.

Root identified the cause: the conservative host snapshot included `Number.NaN`,
while descriptor values were compared with `===`. An unchanged NaN is unequal to
itself, so the guard always refused entry. The original producer and failed
witness remain preserved. `sum-derive-v2.mjs` uses captured `Object.is` for
property descriptor values, also distinguishing signed zeros correctly. Both
controls and admission witness must be rerun against this new derivative before
any timing interpretation. The same copied-guard issue was reported to the
separate colf experiment before its promotion.


The vector agent also independently reviewed the local tree mechanism and found
no additional blocker: generic `force` completes the generated tree before the
private traversal, field reads and U32 operations retain left-to-right order,
and constructor metadata is private to the module. This review does not erase
the inactive-guard counterexample above or replace the v2 execution gates.

## Corrected prototype evidence

Root's `sum-controls-02/report.json` passed all 71 oracle cases and 121 paired
public boundaries. `sum-witness-02/report.json` passed separately, establishing
that the intended private loop and recursive sum consumers ran. The frozen v1
producer, v2 producer, failed witness and successful witness remain distinct.

The three-rotation CPU3 screen (`sum-screen-01/report.json`) used the unchanged
original `bench(6,42)` with expected result 2490246820. It had 350 ms warmup and
150 ms target samples, serial fresh Node processes, 1 GiB heaps and a 1.5 GiB
supervisor tree ceiling. Total wall time was 15.175 seconds.

| Saved output | Median ms/call | Observed min–max ms |
|---|---:|---:|
| Untouched selfhost original | 109.263 | 107.854–111.342 |
| Matched exact-entry wrapper baseline | 110.844 | 110.202–112.174 |
| Private dataset loop only | 110.485 | 108.612–110.523 |
| Loop plus direct Expr eval/size | 20.223 | 19.867–20.311 |
| Pinned TypeScript | 1.111 | 1.109–1.116 |

The sum traversal experiment is 5.40× faster than the untouched output, while
loop saturation alone changes little. It still takes 18.20× the TypeScript time.
This supports replacing repeated generic sum elimination/call machinery inside
the closed local graph. It does not establish a compiler release improvement or
the representative corpus average. Some original samples show 13–19% half drift;
this short screen chose the next experiment, not a final precision claim.

## Compiler translation and independent review

`private-sums.patch` introduces a bounded structural fold planner/emitter and
shares the separate `j_pure_type`/`j_pure_graph` proof for generic local producers.
The public tagged representation remains unchanged. The compiler uses an explicit
postorder stack rather than the prototype's recursive JS evaluator, so promotion
does not assume a depth-five tree. Children are demanded once in source order,
extra scalar arguments remain unchanged, and the rewritten U32 combiner passes
the existing typed expression planner. See the [design](../../design/phase35/private-sums.md)
for the exact admitted grammar and limits.

The regions and vectors agents independently inspected this implementation and
found no blocking issue under fully materialized local-tree assumptions. Both
requested an explicit host-guard requirement for every JFold, including future
paths without a residual producer; this was added. Research then identified an
absent frame-array slot read and inherited numeric prototype hooks as additional
observability risks. Root's checked09 image avoids absent-slot lookup and
rejects changed Array/Object prototype own-name lists before the region starts.
The owner controls include numeric getter/setter/mutation cases; review alone
does not mark those runtime controls passed.

Root's checked09 output contains an optimized ordinary `cand` root and two private
fold helpers while retaining public eval/floop callbacks. Its initial combined
60-second screen reported symreg medians of 123.336 ms baseline, 17.403 ms candidate
and 1.268 ms TypeScript: 7.09× improvement, still 13.72× TypeScript. This is a
combined compiler screen, not isolated attribution to folds. Longer confirmation
and final-API owner controls were pending when that initial screen finished;
their completed results are recorded below.

The owner gate is `fold-final-controls.py ATTEMPT NEW_OUT`. It checks independently
modeled U32 outcomes against actual baseline/candidate/TypeScript emissions,
then candidate-only depth 50,000, actual admission witnesses, public boundaries,
and synthetic recognition refusals. Every producer and checked API is hashed.
No gate uses the hand-edited prototype as the compiler candidate.

## Final checked09 owner evidence

The final owner group passed against checked API SHA256
`467bc7dec2751a94cb677c5eb2da22a8fb69ee3522c6e164cb2bfcc147a78d82`.
The [independent provenance audit](fold-final-provenance-audit.json) rehashed the
selected API, attempt, frozen source, candidate emission and control inputs;
the compiled control's module hash matches the checked emission, and the
synthetic recognizer controls point directly to that same final API.

- 25 small fixture points × 9 exports × 3 compiler variants: 675 independently
  modeled scalar/record result comparisons.
- Two further candidate-only local-tree depths, 4,096 and 50,000, returned the
  expected 8,216 and 100,024 without a native-stack failure.
- 57 paired public-boundary observations passed, including 12 inherited numeric
  Array/Object prototype getter/setter/mutation controls.
- 24 synthetic recognizer cases passed, covering both admission and conservative
  refusals. An initial synthetic book omission was corrected before execution;
  its exact producer is retained as `fold-guards-v1.mjs`.
- Four diagnostic entry witnesses each recorded one executed private fold:
  ordinary deep tree, shared tree, wrapped multiplication and flat-record root.

Receipts are under `selfhost/build/phase35/final-plan-09/owner/recursive-folds/`.
All 15 final owner groups subsequently closed on this API. The owner retry
preserved a TypeScript acquisition failure caused by sandbox `spawnSync git
EPERM`, retained the first nine successful commands, and reran only the failed
and downstream commands with explicit output/collector paths. That environmental
failure is not converted into a semantic pass or omitted from preservation.

The complete 600-second-budget generated-program confirmation finished all 15
selected points in 518.338 seconds. Symreg medians were 106.609 ms baseline,
15.529 ms checked09 and 1.108 ms TypeScript: **6.87× faster than baseline, still
14.02× TypeScript**. This supersedes the short-screen point estimate; it remains
a combined phase result, not isolated fold attribution. Final profiles put only
9.41% of candidate CPU sample weight under eval/size, versus 64.33% under the
remaining generic tree producer. See [profile findings](profile-findings.md).
Broader conformance and release admission were separate root-owned gates. They
subsequently closed on this same API: all 15 postinstall groups, including all
42 ordinary/relocated CLI checks, passed. The [independent release assessment](release-assessment.md)
records that installed closure and the accepted compiler-cost tradeoff; the
owner and timing results alone were not sufficient for that decision.
