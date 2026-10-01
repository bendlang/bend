# Phase36 generated-program profiles and the next experiments

Phase36 removes two measured bottlenecks: symreg's private tree construction and
raytrace's repeated guards. The remaining largest selected gaps are **lexer
(89.38× TypeScript) and tree-bitonic (80.62×)**. Their generated program bodies
did not change in this phase, and their profiles still show substantial generic
application, closure and thunk traffic. Further work should test ways to remove
that traffic from proved private operations rather than repeat the rejected
exact-entry reflection shortcut.

## Clean execution establishes the gains

These are medians from the separate unchanged fifteen-point execution run,
not profiler elapsed times. Baseline is Phase35 checked09; candidate is Phase36
checked03, API `93e55ad7ee456eebb5fa3dd9606c2cf262ea386c6f66bfd891ffe187d8f50a75`.
TypeScript is pinned at `018751270e800bc222a93dad7f257083ee53a5f7`.

| Fixed point | Phase35 ms | Phase36 ms | TypeScript ms | Gain vs Phase35 | Phase36 / TS |
| --- | ---: | ---: | ---: | ---: | ---: |
| symreg, size 6 / seed 42 | 15.581745 | 4.265036 | 1.112363 | 3.6534× | 3.8342× |
| raytrace, row 80 / seed 0 | 1,859.589096 | 801.893428 | 34.161730 | 2.3190× | 23.4734× |
| lexer, size 8 / seed 0 | 170.428825 | 172.053661 | 1.924985 | 0.9906× | 89.3792× |
| tree-bitonic, depth 8 / seed 0 | 23.072350 | 22.684449 | 0.281382 | 1.0171× | 80.6181× |

Symreg and ray baseline/candidate ranges are disjoint; lexer and tree-bitonic
ranges overlap. The [complete table](execution-table.md) retains every point
and its observed ranges. These are specific dynamic inputs, not an estimate of
average application speed. Other observations, including the map/set follow-up,
remain in [execution findings](execution-findings.md).

## What the profiles measure

The final diagnostic run completes **24 separate CPU/allocation profiles** in
**76.666 seconds**: these four points × three compiler roles × two profile kinds.
Every profile validates the same input/result as clean execution and uses
byte-identical generated modules. Runs are serial on CPU3 under the existing
memory supervisor. There is no profile instrumentation in the clean timing
samples.

CPU sampling uses a 1,000 μs interval. Source ownership comes from the retained
JavaScript AST mapping. For a named owner or group, the extractor walks each
sample's ancestor chain and counts its weight once if any matching frame occurs.
That prevents recursive/nested inclusive-frame double counting. Groups can
overlap and must not be added. A frame's **self** percentage instead measures
samples directly at that frame. In particular, nearly all execution being below
an outer `apply` frame does not mean nearly all time is spent executing `apply`.

The `producer` ancestry group matches source names `gen`, `gen.leaf` and `node`;
it is a profile grouping, not a compiler-admission test. Lexer also has a function
named `gen`, but did not receive Phase36's producer lowering. Actual optimized
entry is established by the separate [producer controls](private-producers.md).

## Symreg: construction is no longer the dominant region

| CPU ancestry union | Phase35 | Phase36 | TypeScript |
| --- | ---: | ---: | ---: |
| `gen` / `gen.leaf` / `node` | 63.92% | 12.30% | 12.62% |
| `eval` / `esize` | 9.18% | 26.27% | 79.05% |
| Guard helpers | 12.24% | 35.58% | 0% |

The independent ordered-child traversal and private selector lowering remove
most of the former producer-region traffic. In the candidate, `gen` accounts
for 10.50% CPU self samples, `eval` for 23.49%, `regionHostGuard` for 20.58% and
`scalarGuard` for 10.83%. Guard checks and evaluation are now more useful targets
than another general rewrite of tree generation. A rising share of a much faster
program does not establish an increase in that operation's absolute cost.

Candidate allocation samples put 26.88% of estimated bytes at
`getOwnPropertyDescriptor`, 22.65% at `eval`, 17.12% at `gen`, 6.48% at
`scalarGuard`, 6.36% at `getOwnPropertyNames` and 4.52% at `ctor`. This supports
investigating guard boundaries and remaining construction work, with separate
clean timings to establish any actual benefit.

## Raytrace: the guard bottleneck moved to generic call traffic

The guard ancestry union falls from **50.12% to 0.44%**. Baseline CPU self samples
were led by `regionHostGuard` at 28.97% and `scalarGuard` at 15.34%. Candidate
self samples are now led by `apply` at **31.53%**, `enterExact` at **9.76%**,
`invokeExact` at 5.80% and `callOwned` at 4.92%. Source-mapped `nearest` and
`trace` account for 7.08% and 6.12% self respectively. The dynamic proof did its
intended job; the large remaining gap is not explained by those repeated guards.

Allocation samples now put 24.55% at `apply`, 20.34% at `trace`, 12.15% at `colf`,
8.46% at `nearest` and 4.94% at `project`. The observed pattern supports testing
direct private operations on the existing tagged geometry/results and reducing
temporary call/continuation records. It does not prove that every such operation
can safely bypass the generic runtime.

The additional reflection experiment already tested one tempting shortcut.
Although its semantic controls passed, its five-round clean median was
792.012→793.867 ms, with overlapping samples. It was
[rejected](guard-exact-report.md), with no source patch in checked03. The new
profiles do not justify relabeling that negative result as a prospective win.

## Lexer and tree-bitonic: broader coverage is the largest open gap

Lexer candidate CPU self samples include `apply` **25.45%**, `force` **12.85%**,
`callOwned` 7.80% and `invokeExact` 6.95%. The union below `lex` is 46.45%, and
below `gen` 39.55%; these are separate regions to isolate, not an additive cost
partition. The source uses linked strings, finite `Slot`/`Cls`/`Mode` sums and a
`Mode & U32` state. Both compiler variants process the same Bend data structures;
the TypeScript comparison is not a switch to a byte-string lexer.

Tree-bitonic candidate CPU self samples include `apply` **23.77%**,
`invokeExact` **9.58%**, `callOwned` 7.74%, `force` 7.45% and source-mapped `warp`
14.23%. Allocation owners include `warp` 25.34%, `warp_zip` 11.69%, `apply`
11.19%, `warp_leaf.go` 10.80% and `callOwned` 10.24%. The source repeatedly
matches and rebuilds `Leaf`/`Node` trees. It requires tree-to-tree operations and
multiple matches; the scalar-input producer recognized in this phase does not
cover that whole workload.

Neither point has evidence of a Phase36 execution gain. Their complete emitted
program suffixes are byte-identical to Phase35; only the shared runtime prefix
changed. Existing guard helpers contribute zero sampled ancestry in both, so
another guard-only optimization would not address the measured hot paths here.

## Allocation estimates, with their limits

Decimal MB per validated profiled call, calculated from the retained
`samples[].size` weights. These include harness/inspector allocation and are not
retained heap, peak memory or execution-speed ratios.

| Point | Phase35 MB/call | Phase36 MB/call | TypeScript MB/call | Candidate / TS |
| --- | ---: | ---: | ---: | ---: |
| symreg | 19.187 | 4.247 | 0.449 | 9.46× |
| raytrace | 1,676.187 | 722.034 | 8.291 | 87.08× |
| lexer | 220.067 | 220.975 | 3.973 | 55.62× |
| tree-bitonic | 33.664 | 33.508 | 1.374 | 24.39× |

The symreg estimate falls 77.86% and ray's 56.92%. Sampling intervals are
32,768 bytes except ray at 262,144 bytes. Ray has only **one baseline and two
candidate profiled calls**, versus 43 TypeScript calls; its numerical allocation
ratio is especially coarse. Lexer has six calls in each Bend role. These
estimates suggest allocation mechanisms to investigate; small differences for
unchanged lexer/tree code are not improvements or regressions.

Every allocation profile retains both sample-based and tree-based estimates,
their discrepancies and any unmapped samples. Those totals differ, with no
established cause. Unattributed samples remain unattributed; they are not
silently assigned a convenient source owner. All candidate profiles have zero
unattributed samples, while the raw baseline/TypeScript warnings remain in the
evidence. Each kind/role has one diagnostic run, not repeated statistical trials.

## Generated syntax explains coverage, not dynamic frequency

These counts describe the parser's program section, excluding its runtime/support
section. They count static sites, including retained generic fallbacks. They are
not the complete suffix sizes used by the separate byte-equality audit.

| Point | Program bytes: Phase35→Phase36 | TS program bytes | Phase36 trampoline call sites | Phase36 closure-helper sites | TS sites of either kind |
| --- | ---: | ---: | ---: | ---: | ---: |
| symreg | 44,087→45,527 | 6,728 | 127 | 144 | 0 |
| raytrace | 71,681→71,867 | 21,214 | 370 | 153 | 0 |
| lexer | 31,284→31,284 | 7,560 | 112 | 160 | 0 |
| tree-bitonic | 27,448→27,448 | 5,016 | 90 | 133 | 0 |

Symreg's whole program grows despite running 3.65× faster: new direct private
paths coexist with the generic paths required for public/refused cases. Byte or
AST counts alone cannot predict which path runs. The controls prove actual
entry, while clean timings and profiles establish its value. See
[compilation cost](compiler-cost.md) for the source/latency tradeoff.

## Next falsifiable experiments

These are proposals, not implemented changes or promised gains.

1. **Private finite sums and tree-to-tree operations.** Start with one actual
   lexer operation such as `step.at`, or bitonic's `warp_leaf.go`/`warp_zip`, in a
   saved-output ablation. Preserve tagged representations, field demand and
   evaluation order. Compare direct pattern dispatch with the original generic
   path, and count which path executes. If complete outputs, alias behavior and
   callback/refusal controls pass and clean timing improves, extend the existing
   private lowering proof only to that demonstrated shape. Reject the idea if
   moving one operation removes little traffic; do not first build a new IR for
   the entire compiler.
2. **Amortize the remaining symreg guards at a proved enclosing boundary.**
   Count actual guard entries and identify the smallest enclosing call chain
   whose complete original graph satisfies the purity proof. Test one guarded
   private scope; retain mutable dependencies, public/refused entry and Error
   reentry behavior. A rising guard percentage is a reason to measure, not
   permission to weaken admission or reuse proofs across callbacks.
3. **Lower ray's remaining private result/geometry calls.** Isolate one
   frequently called finite tagged-result operation and compare direct calls
   with the current `apply`/continuation route. Use existing full-row results
   and public mutation/overflow controls, plus nearby ray inputs that actually
   exercise each case. Require reduced dynamic call/allocation counts and a
   clean timing gain before generalizing. This targets the newly observed
   bottleneck rather than retesting the rejected reflection shortcut.
4. **Inline only proved nonnative constructor creation.** The private symreg
   helpers still use `ctor` for closed tagged constructors. A narrowly proved
   direct object/field-array construction may remove residual helper work while
   retaining the ABI. Its source/field/alias conditions must be explicit, and a
   prototype must beat its unchanged control. With only 4.52% of candidate
   allocation samples at `ctor`, this is a smaller secondary experiment, not an
   explanation of the 80–89× lexer/tree execution gap.

Use the maintained single-case loop first, with a checked compiler build only
after a saved-output hypothesis survives. Counters/profiles are diagnostic
artifacts; speed acceptance must use fresh clean modules and the unchanged
measurement protocol. Recheck all fifteen catalog points and normal compilation
cost only for a surviving integrated candidate. Keeping one mechanism per
experiment preserves useful negative results and limits complexity growth.

## Evidence

[Final results](final-results.json) bind the selected and baseline APIs, clean
timings, all module identities, normal costs, AST data and raw CPU/allocation
profiles. [The extractor](result-summary.py) is read-only and computes sample
unions explicitly. The final profile report is
[`selfhost/build/phase36/profiles03/report.json`](../../selfhost/build/phase36/profiles03/report.json),
SHA-256 `7d3325274459f62e4e972d64bc27905f2f8c93edca4995d55a22efdb175773a3`.
The [AST report](../../selfhost/build/phase36/profiles03/analysis/report.json)
has SHA-256 `641de91df5761a29cfba94d9e3b2e8caeb711619e3652f17d0ae6ca4a8688856`.
Raw evidence is retained through the [phase capsule](evidence/README.md).
