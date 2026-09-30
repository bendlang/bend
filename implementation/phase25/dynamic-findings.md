# Phase25: dynamic costs of the unchanged emitted programs

The healthy final diagnostic acquisition is `selfhost/build/phase25/diagnostics-02`: **18/18 processes exit0 and report pass**, covering nine kernels through both unchanged emitters. Every measured result matches the previously checked scalar result; every counter acquisition passes its exact tiny controls. No compiler or runtime was modified. Counter copies remain separately identified diagnostics.

The central observation is repeated generic runtime work in the selfhost output, plus especially expensive numeric-pattern expansion. This is **emitted-program execution**, not compilation time. Source-level improvements that benefit upstream-built B1 do not necessarily benefit code produced by our emitter. No current full self-emitted compiler H was built or timed here.

## Provenance, scope and the retained first attempt

Both compiler sides use upstream pin018751270e800bc222a93dad7f257083ee53a5f7. Original modules and checked sources are frozen in `selfhost/build/phase25/corpus-01`; ordinary performance observations are in `timing-01`. The diagnostic plan binds the corpus, timing, frozen tool and launcher hashes before acquisition.

Attempt01 profiles completed, but its `node -e` launcher accidentally made the imported diagnostic module look like the CLI entrypoint. The CLI guard set exit code2; these are retained **launcher-invalid observations**, not clean process passes. Attempt02 adds a distinct leading launcher argument and reruns all18 modules. The frozen diagnostic tool is unchanged. The standalone emission/timing CLIs were not affected. This report uses only healthy attempt02 profiles and counters.

CPU and allocation profiling are separate passes over the original emissions after side-specific warmup counts selected from the measurements. The allocation pass follows the CPU pass when both are enabled, so its execution history includes those additional calls. The interval is1,000µs for CPU and262,144bytes for allocation, with collected objects included. Exact counter runs use **10 calls per module**, independent of the different CPU/allocation repetition counts. Tables below divide counters by10, never by profiler repetitions.

CPU percentages use the sum of all retained sample time deltas. Allocation percentages use the total sampled self-size; they are statistical allocation estimates, including collected objects, not retained memory or peak RSS. Profiler/host overhead remains included. V8 can attribute inlined work to a caller: an export-wrapper frame does not prove that the wrapper itself owns the cost. Zero sampled body allocations do not prove allocation freedom.

## Exact dynamic operations per benchmark call

All rows use seed18; size is shown. Counts include the entire benchmark, including data construction, exported-call boundary and result preparation, rather than only a named inner helper. `fn` means the actual `{arity,code,env,bound}` function record. A staged matcher call is not necessarily a partial application: partial/overapplication count only their explicit `apply` branches.

| Kernel | Size | `fn` records | `apply` | Partial | Overapplied | Tail messages | Constructor calls |
|---|---:|---:|---:|---:|---:|---:|---:|
| scalar-arithmetic | 1024 | 3,073 | 9,220 | 1,024 | 0 | 3,073 | 1,024 |
| boolean-choice | 1024 | 3,073 | 8,196 | 1,024 | 0 | 4,097 | 1,024 |
| boolean-worker | 1024 | 4,609 | 10,756 | 1,024 | 0 | 4,609 | 0 |
| match-remaining-args | 256 | 1,795 | 3,591 | 769 | 0 | 1,793 | 257 |
| string-scan | 1024 | 144,386 | 339,977 | 23,553 | 0 | 142,338 | 1,025 |
| string-equality | 1024 | 5,123 | 9,233 | 3,074 | 0 | 3,076 | 3 |
| term-substitution | 256 | 6,650 | 9,913 | 1,686 | 0 | 7,214 | 2,235 |
| pinned-u32-table | 256 | 5,309 | 6,338 | 241 | 1,893 | 5,566 | 8,481 |
| pinned-u32-wide | 1024 | 12,801 | 17,926 | 3,073 | 3,071 | 11,777 | 33,792 |

For these kernels the `apply` count also equals the count of its argument-copy arrays (`slice` or bound-argument `concat`). Overapplication allocates two additional slices per overapplication. These counters omit other emitted array literals and JS arrows and do not measure allocation bytes. Tail argument slots count observed lengths, not unique arrays.

Upstream has zero observed `run_tail` messages, `run_clo` creations and `run_loop` jump steps for scalar, Boolean-worker, match-remaining-args, U32-table and U32-wide; each has one library entry and one `run_loop` entry per benchmark. This does not mean zero calls or all allocation: direct generated calls, loops and inline jump construction are outside those counters. Boolean-choice has1,024 messages and2,048 closure creations per benchmark; string-scan1/2, string-equality3/6, and term-substitution239/478.

## Profiles corroborate execution of the machinery

The runtime-prefix column classifies exclusive frames whose emitted-module URL and starting line lie inside the exact493-line common selfhost runtime. It includes anonymous runtime closures, and excludes generated definitions/export wrappers and URL-less native frames. It is not a perfect causal allocation owner or an Amdahl speed ceiling. The `apply+force+call` column is a subset of that prefix, not an additional share.

| Kernel | Selfhost CPU samples | Runtime-prefix CPU | `apply+force+call` CPU | `apply` sampled allocations | Selfhost profiled calls | Upstream profiled calls |
|---|---:|---:|---:|---:|---:|---:|
| scalar-arithmetic | 448 | 81.27% | 55.01% | 26.23% | 271 | 51,778 |
| boolean-choice | 426 | 83.29% | 69.29% | 26.00% | 311 | 4,011 |
| boolean-worker | 1,243 | 75.29% | 46.23% | 24.14% | 173 | 89,210 |
| match-remaining-args | 453 | 77.71% | 64.77% | 22.04% | 598 | 77,115 |
| string-scan | 440 | 74.40% | 54.26% | 25.29% | 7 | 844 |
| string-equality | 456 | 87.01% | 67.95% | 38.10% | 224 | 235 |
| term-substitution | 424 | 73.64% | 62.04% | 19.23% | 125 | 7,074 |
| pinned-u32-table | 366 | 73.32% | 28.18% | 13.07% | 183 | 258,982 |
| pinned-u32-wide | 407 | 77.81% | 43.93% | 15.42% | 87 | 137,373 |

Allocation totals must be normalized by these very different call counts. The following descriptive estimates include harness/inspector allocations; they are not exact heap-byte accounting and are not benchmark time:

| Kernel | Selfhost sampled bytes / call | Upstream sampled bytes / call |
|---|---:|---:|
| scalar-arithmetic | 2,068,611 | 5,630 |
| boolean-choice | 1,981,304 | 701,070 |
| boolean-worker | 2,617,580 | 65 (host-only samples) |
| match-remaining-args | 940,979 | 12,307 |
| string-scan | 82,628,111 | 563,455 |
| string-equality | 1,987,608 | 4,550,700 |
| term-substitution | 3,696,469 | 255,382 |
| pinned-u32-table | 3,418,601 | 70 (host-only samples) |
| pinned-u32-wide | 8,950,886 | 76 (host-only samples) |

The extremely small upstream totals for Boolean-worker and the two U32 cases have no sampled emitted-body allocation. Treat them as sampling/host floors, not exact tiny allocation budgets, and do not advertise enormous allocation ratios from them. GC-event counts from a time-bounded trace likewise require normalization by actual work; a much faster program may trigger more events simply because it executes many more benchmark calls.

## Findings with distinct causal boundaries

### 1. Matches interrupt otherwise saturated calls

**Observed:** the scalar recurrence is an ordinary numeric `for (;;)` in upstream, with `Math.imul`, shifts and unsigned arithmetic directly emitted. Selfhost instead starts `G["spin"]` with a `matcher("Zero", ...)`, reconstructs a function for the chosen arm, and recurs through this form:

```js
jump(call(get(G,"spin"),[rest]),[nextAccumulator])
```

`match-remaining-args` similarly emits `call(call(call(get(G,"walk"),[tail]),[scale]),[offset])` where upstream calls a three-argument `$walk$`. Its loop body also dispatches U32 primitives through `get(G,...)`/`call`. Exact counters establish thousands of entered generic operations per benchmark; sampled runtime frames establish that this machinery is hot.

**Inference:** carrying the known remaining arity through a match and generating saturated private workers could remove much of this work. It is not yet an implemented causal ablation. Scalar cost also differs in primitive inlining and Nat representation: selfhost uses BigInt Nat and constructor views, while upstream uses checked JS numbers. The191.36× scalar timing ratio on size1,024 cannot be attributed solely to call currying or the trampoline.

Source anchors: `corpus-01/scalar-arithmetic/{selfhost,upstream}.mjs` lines597/178, and `corpus-01/match-remaining-args/{selfhost,upstream}.mjs` lines597/207. These are frozen generated files, not maintained compiler source.

### 2. A source rewrite helps B1 lowering but hurts our emitted code

**Observed:** the two Boolean kernels implement the same tested recurrence with thunk-choice versus a Boolean worker. At size1,024/seed18, the uninstrumented upstream median falls0.124683→0.005605ms/call (22.24× faster). Selfhost rises1.611686→2.902458ms/call (1.80× slower). Upstream turns the worker version into a two-state `for/switch` loop and eliminates the1,024 jump messages and2,048 closures observed for its choice version. Our worker version raises `apply` calls8,196→10,756 and function records3,073→4,609 per benchmark.

**Inference:** the Boolean-worker technique used to speed the upstream-built compiler image depends on upstream lowering. Repeating that source technique alone is not a plan for fast self-emitted H. The backend needs to retain/directly lower those known calls and tail cycles. This is a mechanism result on two analogues, not a measurement of the full current compiler H.

### 3. U32 matching expands a scalar into33 temporary constructors

**Observed:** `project("U32", x)` calls `word(x)`. That runtime helper creates one `WNil` plus32 `WCon` nodes. The table benchmark executes257 numeric matches and exactly8,481 constructor calls per benchmark (**33×257**); the wide-key benchmark executes1,024 matches and exactly33,792 constructor calls (**33×1,024**).

Upstream instead emits `TAB_0[Math.min(n,16)]` for the table and direct numeric equality/bit tests for wide keys. Structure analysis separately records the expanded matcher/function syntax. In healthy profiles, `word` receives26.44% of table sampled allocations; `project` receives41.75% for wide matching. Inlining can move attribution between these frames, so these percentages are not additive estimates of a hypothetical optimization.

**Inference:** direct U32 decision lowering is the most sharply isolated next prototype. It attacks work whose exact count is explained by the representation expansion, without first changing all calling conventions or Nat/public ABI. The1,417.89× table and1,593.94× wide timing gaps at these selected sizes include traversal/call costs too and are not promised gains from that prototype.

Source anchors: common runtime `word` at `selfhost/src/runtime.mjs:250`; generated U32-table upstream `pop` at162, selfhost `pop` at664; U32-wide upstream `key` at162, selfhost `key` at614.

### 4. String equality is a necessary counterexample

**Observed:** size1,024 string equality is only1.047× slower in selfhost (2.236434 versus2.136415ms/call), despite9,233 `apply` calls and3,074 partial applications per benchmark. The selfhost runtime supplies `String.eq` via its guarded native-string helper. Upstream routes equality through `String.order`, `String.cmp` and a recursive compare/rebuild path. Its compare bodies dominate its CPU profile and sampled allocation. Selfhost samples about1.99MB allocated/call versus4.55MB upstream for this exact diagnostic input.

**Inference:** efficient primitive implementation can offset a less efficient calling convention. Neither “all slowdown is dispatch” nor “copy all upstream lowering/primitive choices” fits the evidence. Keep the successful exact string primitive while testing narrower improvements. This observation does not establish universal string equality speed, especially for malformed UTF-16 or different mismatch positions.

### 5. Tree/substitution work has an additional constructor-forcing cost

**Observed:** at size256 the term analogue enters `force`2,699 times, emits1,484 deferred constructor-build messages and makes7,214 tail messages per benchmark. `force` receives29.71% exclusive CPU and11.58% sampled allocation, alongside `apply`23.37% CPU. The list-building match case shows the same mechanism.

**Inference:** after scalar pattern/call fixes, constructor-continuation construction and forcing deserve a separate measured ablation. Direct eager construction cannot simply replace deferred work: demand/error order and deep-stack handling are part of the current runtime contract. The analogue is not the complete production term representation or compiler.

## Minimal next experiment and correctness obligations

1. **Direct primitive U32 pattern decisions first.** Add a narrowly recognized lowering of fully typed native U32 match trees into numeric tests/table lookup, retaining the generic path otherwise. Preserve row/default priority, unsigned32-bit wrapping, full-width constants, type/constructor identity, duplicate/overlapping patterns and evaluation/error order. Refuse a native scalar shortcut for user-defined constructors with the same spelling. Validate exhaustive feasible small domains plus boundaries0,2³¹,3,000,000,000,2³²−1, randomized words, capture/argument demand and exact fallback behavior. Rerun the two frozen witnesses and nearby mixed patterns before any broad gate. No speed estimate is established until this ablation exists.
2. **Known saturated workers across matcher boundaries next.** Start with one checked family and direct recursive calls, preserving the public closure/library ABI. Keep generic partial/overapplication and higher-order escape paths. Do not evaluate later arguments before the matcher or an earlier error. Validate closure captures, recursive/cyclic tail groups, exact argument order and deep-stack behavior. Primitive inlining and Nat representation should be separate ablations so a combined result remains explainable.
3. **Preserve the allocation and string counterexamples.** Require counter decreases, exact output and warmed uninstrumented timing, but do not promote on counters alone. Boolean-source transformations must be tested under both emitters. Keep the existing String.eq semantics instead of replacing a demonstrated good primitive as collateral cleanup.

No optimization is implemented or promoted by this report. Current H throughput, arbitrary generated programs, native C and GPU execution remain outside this acquisition.

## Recomputing these summaries

For each `diagnostics-02/<kernel>-<side>/report.json`: divide `counters.counts` by `counters.results.calls` (10); divide `allocation.sampledBytesFromNodes` by `allocation.results.calls`; sum selected `cpu.exclusiveFrames[].microseconds` and divide by the sum over all frames. The runtime-prefix classification additionally requires the original module URL and zero-based frame line<493. Direct named allocation fractions sum `allocation.exclusiveFrames[].sampledBytes` for matching module URL/function name and divide by `sampledBytesFromNodes`. This preserves V8 frame attribution rather than redistributing inlined/native costs.

Final acquisition status: `diagnostics-02/results.json`, SHA256`90c2a53cad9fcd570eb486d83bbb891a40a5b3197b15fa91cd6c6ee705518208`. Timing source: `timing-01/report.json`, SHA256`b083635a4f7eb85c9ad795f5ab2e38a25772d39b8df8a03155cb13047799a0a6`. Raw generated modules, profiles, guards, controls, original attempt01 and launcher correction are retained for the root-owned evidence capsule.
