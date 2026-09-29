# Phase15: profile-directed source lookup workers

The isolated source candidate uses **3.49%less full-source checking time** and
passes its checked build, focused and boundary controls, and both exact saved
histories. It changes one module by **22lines,332bytes and two definitions**,
with no maintained JS/helper/runtime changes. Recommend integration of this
small measured tradeoff, subject to root's combined release gates.

The [profile plan](../../experiments/phase15/P15-003-checker-speed.md) preceded
profiling. The [lookup plan](../../experiments/phase15/P15-003-lookup-workers.md)
selected this one operation after profiling and before any candidate edit/probe.
Root granted profiling at00:01:44UTC on2026-09-29; the initial feasibility
deadline remains01:31:44UTC. Previous seed/branch counterexamples remain excluded.

## Fresh released-image profile

The unchanged Phase9 profiler checks released Phase14 combined-01, API
`9136be92928eda4b3b8e9c99e4e35d62504a825b458ff237c514d4e99f21206b`,
on its exact original full source. Upstream remains
`b2111cf43244e65f76ddc278ee695e669f720cbf`. Node24.18.0,CPU0,
10,000us sampling,4MiBstack/4GiBheap, separately validated existing Base cache.
Other intentional compiler/archive jobs were paused.

`selfhost/build/phase15/speed-profile-01/report.json` completes at00:02:37UTC.
All launch, signal, deadline, overflow, ordinary-result and identity checks pass.
Its27.097s instrumented process is excluded from speed ratios. The48,508,246byte
raw profile has SHA256
`eec2546174eb8c9d826edfe7375a19ca2ce3b6e5467cf75c65d41ce9e7ff34fc`.

| Lexical owner | Exclusive weighted sample share |
| --- | ---: |
| Garbage collection | 14.10% |
| run_loop | 12.21% |
| lookup | 4.37% |
| index_find | 3.79% |
| norm_match | 3.03% |
| subst | 2.75% |
| check_node | 2.09% |

There are2,551samples. Lexical ownership is neither caller attribution nor an
estimate of recoverable gain. Runtime and GC shares remain separate. Lookup
ranks above the larger checker tag chain while requiring only two workers.

## Candidate and emitted mechanism

`selfhost/build/phase15/speed-source-01` retains the baseline module, exact
replacement, prospective bindings, copied project and preparation tool. Only
`src/core/term.bend:lookup` changes. After the same Nil/head/tail observations,
`lookup_cached` matches the already-computed BookCache test; its false branch
computes the ordinary name test and calls `lookup_named`. That worker returns
the first matching declaration or resumes the unchanged list search.

Pinned upstream fuses the three decisions into a **three-state mutual-tail
loop**, emitted at each of its three function entries. There is no branch
closure, Unit or trampoline-message allocation in that family. This
is verified both in separately checked components and the actual checked B1
derivative. It preserves first-match order, cache-sentinel priority, malformed
input demand and the original hash/index implementation. No new data protocol,
index, compiler API or generated-JavaScript transformation is introduced.

Genuine checked B1:
`5640eb42b0fa431b5cf4384742250d933c3da2c69ab579be83f3ae184c7a0d6a`.
Unchanged equality-v5 derivative:
`78ee67ddaa4ea131cf6f4fc0c3dbf67d3eae37fe9e111ad113024064b09b6d0e`.
Attempt:`selfhost/build/phase15/speed-checked-01`. This is checked-B1 provenance,
not a new self-emitted fixed point.

## Correctness and demand

The candidate passes all26maintained focused cases with the same12exact
TypeScript differences. `speed-analysis-01/report.json` compares every complete
result to Phase14, permitting only explicitly checked sourceFile/files snapshot
relocations. Every other field is exact. The strict diagnostic mismatches remain.

`speed-component-01` builds actual baseline/candidate core components using
pinned upstream. `speed-controls-01/report.json` passes68tailored paired controls
and5,769existing persistent-index assertions. These cover empty/ordinary/cached
books, hits/misses, first-win duplicates, empty and Unicode names, full-hash
collisions, unusual kinds, cache markers mid-list, cache priority over its own
name, missing/malformed heads/tails and exact observable getter/error order.
Both10,000-declaration missing/final-hit lists finish under the original limits.
The finite getter tests do not prove equivalence for arbitrary stateful host
objects; the deep list does not establish universal stack safety.

`speed-history-01/report.json` uses the unchanged generic Phase14 paired-history
runner on the genuine Phase14 and candidate attempts with identical current
hosts. Fresh6,000-character strings pass. The original53and60request histories
then pass all226paired complete observations, including every predecessor,
under4MiBstack/4GiBheap. Request order, worker generation/index and resource
limits stay exact; no recycling, launch error, timeout or identity drift occurs.
Historical Phase12 host/diagnostic differences remain recorded by the runner.

## Operation counts

`speed-counts-02/report.json` instruments separate copies, never timed images.
The same valid two-module graphs contain4,16or64definitions per module; loaded
books and checker results are exactly equal. Loading these graphs never enters
lookup and its operation counts remain unchanged.

| Definitions per module | Baseline check dispatches | Candidate | Closures removed | Units removed |
| --- | ---: | ---: | ---: | ---: |
| 4 | 1,358 | 1,249 | 71 | 113 |
| 16 | 7,280 | 6,091 | 659 | 1,205 |
| 64 | 56,090 | 39,061 | 8,771 | 17,093 |

At64definitions,17,029message objects and argument arrays disappear; consumed
argument slots fall66,033→40,746. These counts expose removed work, not allocated
bytes or a full-source speed forecast. The synthetic book's list/index mix is
different from the complete compiler workload.

The first counter attempt mistakenly required an improvement in loading despite
zero lookup entries. It remains failed at `speed-counts-01`; its original tool
is unchanged. The v2 tool explicitly requires exact loading counts and positive
checking reductions, retaining all observed results in a new attempt.

## Complexity and current boundary

`speed-cost-01.json` audits all59ordered source modules. Only term.bend changes:
436→458physical lines,373→393nonblank,9,187→9,519bytes,49→51definitions;
its10laws stay unchanged. The equality helper and existing tests are byte-exact.
The independently runnable component/demand/control wrapper adds77research-test
lines/10,803bytes, reusing the existing persistent-index tests. Total new source
plus that runnable test bundle is99lines/11,135bytes. The complete nine-file
research tool set, including the failed count version, is423lines/41,245bytes;
these are experimental launch/audit tools, not production compiler dependencies.

The generated API grows772,643→775,373bytes (+2,730bytes). Upstream duplicates
the loop body for each function entry, initializing the state to0,1or2. Source and generated-code
costs are reported separately. No line-count reduction is claimed.

## Controlled full-source pilot

`speed-pilot-01/report.json` records the root-authorized exclusive CPU0 ABBA
window00:11:54→00:13:44UTC. Other intentional compiler/archive jobs were paused.
Both verified images use the identical unchanged Phase14 assembled compiler
source, Node24.18.0,4MiBstack/4GiBheap, byte-identical current host/runtime/Base,
and separately validated API-specific Base caches. Preparation and counters are
outside timing; OS caches are not flushed. The unchanged Phase8 worker measures
request time around adapter.probe including lazy API loading, and process wall
including startup, identity verification and output capture.

| Variant | Process seconds (two samples) | Mean process | Mean request | Maximum RSS KiB |
| --- | --- | ---: | ---: | ---: |
| Released Phase14 | 24.9747,25.1710 | 25.0728s | 23.8452s | 1,417,288 |
| Source lookup workers | 24.1273,24.2686 | 24.1980s | 22.8650s | 1,402,788 |

Process time decreases3.49% (1.0362×baseline/candidate), request time4.11%.
Maximum observed RSS is14,500KiB lower, but two samples establish neither a
general memory improvement nor a confidence interval. All four complete ordinary
results are exact, including compiler-source type acceptance and its expected
proof-trust refusal/unsafe-definition report. Every process exits cleanly, with
no signal, launch error, deadline/overflow or consumed-input drift.

These observations are consistent with removing the lookup dispatch work, but
do not assign the profile's GC/runtime samples to this function. There is no
new isolated TypeScript measurement and historical ratios are not multiplied.
No generated-program runtime gain is measured.

## Decision and integration boundary

Recommend integration: the3.49%screening gain justifies two small source workers
and332B without any maintained JS machinery. The bounded feasibility stage
finishes in about12minutes, well before its90-minute cap. Do not broaden this
result into other dispatch families or repeat the rejected seed/branch changes.

Root independently reviewed the source and generated three-state loop and
accepted the isolated result for integration. The conformance-only versus
combined checked history ablation, full frontend/backend gates, final same-source
TypeScript comparison and installed release checks remain separate. Those are not implied by this isolated
pilot. All owned jobs have closed; source snapshots and consumed tools are
frozen for preservation. No production/default source edit, commit or push was
performed by this owner.


## Combined validation follow-through

The [integration validation report](integration-validation.md) now completes
the conformance-only versus combined history ablation and41-row backend gate
for conformance-02/APIc4c90831 andcombined-02/APIb8d658c5. All226paired saved
history observations and both fresh strings pass; all41backend rows pass with
three retained exact diagnostic differences and no lost exact matches. This
owner performs no additional optimization or performance run. Root's final
frontend, TypeScript matrix and installed release checks remain separate.
