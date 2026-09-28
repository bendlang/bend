# Phase14: Boolean-parameter normalizer dispatch

P14-003 investigates only `norm_eval_node`. The owner started at 22:05:48 UTC on
2026-09-28, with an initial feasibility deadline of 23:35:48 UTC. The
[frozen plan](../../experiments/phase14/P14-003-source-dispatch.md) precedes the
source change and measurements. The isolated candidate completes its scoped
gates and uses **9.03% less complete-source checking time**. It is recommended
for final integration, subject to the combined release gates owned by root.
No production installation or broad conformance result is inferred here.

## Candidate and mechanism

The isolated source is
`selfhost/build/phase14/dispatch-source-01/project/src/core/normalize.bend`.
Its six existing outer tag decisions become Boolean-parameter match workers,
called in exactly the original App, Ann, Let, Ref, Min, Rwt order. The nested
Rwt proof decision retains its `kc` and both selected body arrows. `norm_eval`,
`wnf` and the fallback seed allocation remain byte-identical. The original
book, term, arguments, remaining arity and fallback flow through the workers.
No selector condition or branch body is evaluated earlier in the source.

Pinned upstream emits direct `if` statements and direct calls between these
workers. It does **not** form the Phase10 index's mutual-tail loop: recursion
still crosses the unchanged `kc` in `norm_eval`. Static inspection of the real
checked derivative shows 14→2 branch arrows, 7→1 Unit literals and 7→1
`run_tail` sites within this owner family. The direct false-branch call chain
also changes native stack depth, making the saved-history gate essential.
This is neither the rejected local-Boolean-match source nor generated-JS
branch inlining. No JS rewrite/helper or runtime is added.

## Checked provenance and semantic observations

The genuine checked B1 is
`selfhost/build/phase14/dispatch-source-01/checked-01/api.mjs`, SHA256
`ba8d8d28a302255f8e66102966304df406625e1f4a2f528265120555be881ee2`.
Its unchanged guarded equality-v5 derivative is `equality/api.mjs`, SHA256
`77ba97c64f9001f7dd211ee6835557caf94c01d4c43e1ace20cf1b8a47b338de`.
The baseline remains released Phase12 API `0975a4a8…`, pinned upstream
`b2111cf43244e65f76ddc278ee695e669f720cbf`, Node24.18.0, unchanged Base/runtime.
The checked source snapshot and original bootstrap sidecar remain available;
this does not establish a fixed point or general compiler soundness.

The maintained focused gate passes 22/22 semantic observations with the same
12 exact TypeScript differences. Comparing its complete results to the earlier
Phase12 gate identifies only expected snapshot relocations in `sourceFile` and
`files` fields. Every other field, including exact diagnostics, is unchanged.
The static/focused report records each relocation instead of calling those
original complete JSON objects byte-identical:
`selfhost/build/phase14/dispatch-analysis-02/report.json`.

Independently compiled, upstream-checked normalizer components pass 41 paired
controls in `selfhost/build/phase14/dispatch-controls-01/report.json`: all tag
branches and default dispatch, beta reduction, annotation/let/reference handling,
minimum kinds, successful/stuck rewriting, lambda arguments, ex-falso fallback,
condition-read ordering, unused throwing fields, selected malformed inputs,
and 5,000 nested annotations/applications. Matching thrown names/messages are
retained. These finite raw-data/getter controls do not establish equivalence for
arbitrary stateful host objects. Component builds are not presented as B1 gates.

## Saved resource histories

`selfhost/build/phase14/dispatch-history-01/report.json` passes for both actual
checked derivatives under Node24.18.0, 4 MiB stack and 4 GiB heap. A fresh
6,000-character string checks successfully. Both exact retained 53-request and
60-request histories then pass: all 226 paired observations, including every
predecessor, exactly match the successful released Phase12 results. Worker
generation and index remain unchanged; there is no recycling, error, timeout or
artifact drift. The successful Phase12 oracle is retained separately from the
original failed Phase12 seed candidate's historical target digest.

These are bounded operational controls, not a proof of stack safety for every
program or process history. The gate ran as correctness work on CPU3; its wall
time is excluded from all performance claims.

## Actual operation counts

`selfhost/build/phase14/dispatch-counts-02/report.json` instruments copies of
both verified checked derivatives, never the timed images. For each of 4, 16
and 64 definitions **per module**, a two-module graph loads and checks with
exactly equal results. Load work is unchanged. At 64 definitions per module,
checking removes 4,254 selected closures, Unit objects, trampoline messages,
argument arrays and dispatch iterations each. Total dispatches fall
60,344→56,090; consumed argument slots fall 70,287→66,033. The smaller graphs
remove 294 and 1,086 of each respectively.

These counters show eliminated work rather than closure syntax moved into
capture arrays. They do not measure allocation bytes or predict elapsed speed.
The original Phase13 structural reader is an instrumentation dependency only;
no new parser/helper is needed by the candidate compiler.

## Complexity

Only `core/normalize.bend` changes in the source snapshot:

| Measure | Baseline | Candidate | Change |
| --- | ---: | ---: | ---: |
| Physical source lines | 535 | 626 | +91 |
| Nonblank source lines | 466 | 550 | +84 |
| Source bytes | 17,989 | 19,460 | +1,471 |
| Definitions | 44 | 50 | +6 |
| Laws | 31 | 31 | 0 |

The maintained equality helper and its existing tests are byte-identical.
The six helpers represent the original six decisions explicitly; no new data
representation, state protocol or dependency enters the production compiler.
The paired normalizer control tool adds 48 physical lines / 5,234 bytes for 41
cases; its usable component-build wrapper adds another 24 lines / 2,663 bytes.
The full paired-test bundle is therefore 72 lines / 7,897 bytes, bringing the
source-plus-test-bundle increase to **163 lines / 9,368 bytes**, with no
maintained-JS-helper or existing-test change. The generated API grows by 782
bytes (766,097→766,879). Experimental assembly, instrumentation, replay, timing
and audits are separate research harness costs.
`selfhost/build/phase14/dispatch-cost-04/report.json` lists all 816 physical
research-tool lines / 78,032 bytes, including failed versions and the generic
integration replay tools. These are not claimed to be production dependencies.
All 59 declared source modules were audited; only the normalizer differs.
No reduction in line count is claimed. The benefit under investigation is efficient source expressing the
existing decisions without a new maintained JS transformation mechanism.

## Preserved failures

- `dispatch-component-01`: the initial requested export list included `ann`,
  which is not a source definition. Pinned upstream rejected the setup; no
  candidate result or timing is inferred. `dispatch-component-v2.mjs` removes
  that invalid export, and both checked components pass in attempt02.
- `dispatch-counts-01`: the initial instrumentation lookup used un-mangled names
  against the structural reader's `$name$` map, and refused before running a
  graph. `dispatch-counts-v2.mjs` fixes that lookup; attempt02 is complete.
- `dispatch-analysis-01`: the first focused-result audit accounted for
  `sourceFile` relocation but missed the same recorded relocation in `files`.
  It failed rather than labeling those results exact. Attempt02 records both
  explicitly, checks the expected prefix mapping, and requires every remaining
  result field to be exactly equal.

All original consumed tools and failed reports remain retained. Process launch,
signal, timeout and output failures are checked in addition to exit status.
Correctness jobs on CPU3 can overlap other correctness work and their wall
figures are not performance measurements. The exclusive performance pilot is
reported separately below.


## Controlled checking pilot

`selfhost/build/phase14/dispatch-pilot-01/report.json` records the root-authorized
exclusive CPU0 ABBA run from 22:16:31 to 22:18:27 UTC. All other intentional
compiler, Node and archive jobs were paused. Each sample is a fresh process
using Node24.18.0, 4 MiB stack, 4 GiB heap, the unchanged Phase8 checking worker,
and its separately validated API-specific Base cache. Both APIs check the exact
same frozen complete Phase12 compiler source; no cache preparation, source build,
transformation or operation counters are inside the measurement. OS caches are
not flushed. Process wall includes startup, identity checks and output capture;
request wall includes the adapter probe and lazy API loading.

| Variant | Process seconds (two samples) | Mean process seconds | Mean request seconds | Maximum RSS KiB |
| --- | --- | ---: | ---: | ---: |
| Released Phase12 | 27.4666, 27.4862 | 27.4764 | 26.2463 | 1,342,276 |
| Boolean-parameter source | 24.9902, 24.9988 | 24.9945 | 23.7495 | 1,369,968 |

Process time decreases **9.03%** (1.0993× baseline/candidate); request time
falls **9.51%**. The candidate's maximum observed RSS is 27,692 KiB higher
(2.06%); these two samples do not establish a general memory regression or a
confidence interval. All four complete ordinary results are exactly equal,
including accepted types and the expected proof-trust refusal for the compiler's
unsafe definitions. All launch, signal, deadline and identity checks pass.
There is no new TypeScript measurement in this isolated pilot, and historical
ratios are not multiplied into a claimed new ratio.

## Review, decision and integration boundary

The independent
[root source review](../../selfhost/build/phase14/dispatch-root-review-01.json)
confirms the original condition order, demand, nested Rwt decision and unchanged
fallback. It also identifies the direct-call-depth risk rather than inferring
stack safety from source appearance. The saved-history controls provide the
bounded operational evidence required by the plan.

Recommend this narrow source patch for root's final integration: the observed
9% checking gain removes measured work with six explicit decisions in Bend and
no additional maintained JS rewriter. Its real source/test growth is disclosed;
it is a performance tradeoff, not a line-count reduction. The feasibility phase
finished its candidate measurement in about 13 minutes, within the 90-minute cap.
Do not expand the owner family or change `norm_eval` to force a loop from this
result. Full frontend, applicable backend/CLI and the final paired TypeScript
comparison remain root release gates. The combined saved-history gate below
has now completed.

For the combined conformance patches, `dispatch-paired-history.mjs` and
`dispatch-paired-inputs.mjs` accept a JSON binding with `baselineAttempt` and
`candidateAttempt` paths. Both must be verified checked B1/equality-v5 attempts
with identical current host/runtime/Base. The baseline contains the conformance
fixes; the candidate adds this dispatch patch. Every original request, ordering
and resource limit is retained. Complete paired results must match at every
predecessor; original and Phase12 differences are explicitly recorded because
accepted conformance fixes may legitimately change their diagnostics. This
runner passes the concrete combined gate below; that result does not replace
root's full conformance or release gates.


## Combined conformance-plus-dispatch history gate

Root's verified `conformance-01` (API
`9bdcc1200cf9b0e6b91f3744a86b681e949ff61b4cc4c39aa04917e10f87765f`)
and `combined-01` (API
`9136be92928eda4b3b8e9c99e4e35d62504a825b458ff237c514d4e99f21206b`)
each complete the 26-case focused gate before this run. Their current host,
runtime and Base are identical; the dispatch ablation is the difference between
these two checked compilers. CPU3 is explicitly allocated for correctness only.

`selfhost/build/phase14/dispatch-combined-history-01/report.json` completes at
22:33:03 UTC on 2026-09-28. The fresh 6,000-character string and both exact
53/60-request histories pass at 4 MiB stack / 4 GiB heap. All **226 paired history
observations** match completely, including every predecessor and result field;
there is no worker recycling, process error, timeout or input/artifact drift.

All 113 historical requests per variant have a changed `hostProvenance` because
the shared Phase14 typed driver changed. Beyond that provenance change, the
53-request history has one changed diagnostic (`kind_none_lone_binder`), and the
60-request history has seven (`fits_adt_param_invariant`, `fits_domain_swap`,
`forward_reference_scope`, `json_number_format`, `parser_lexer_kit`,
`partial_self_call_stuck`, `rand_bag_ops`). No other result fields change from the
retained successful Phase12 observations. The exact indices, lanes and field
classification are in
`selfhost/build/phase14/dispatch-combined-history-summary-01/report.json`;
full old/current objects remain in the original gate report. Classification does
not strip fields from the actual paired comparison.

The dispatch workstream is closed with this additional integration control.
All owned jobs have ended; source snapshots, tools and this report are frozen
for root's final preservation and release decision. No production installation,
commit or push was performed by this owner.
