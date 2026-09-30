# Shared private helper experiment

The isolated actual12 hoist/deduplication passes its semantic gates, but the
long whole-program comparison shows no speed benefit. Defer production sharing.
No compiler or maintained runtime source changed.

`review-hoist-private.mjs` uses the pinned Node's embedded Acorn 8.16.0 and
records its exact source. It requires identical complete declarations for every
duplicate name, resolves helper-local lexical scopes, permits only collected
private helpers and Math/Number/BigInt as free names, and rejects escaping or
non-saturated uses. Only declaration spans move; all call sites, bodies, guards
and public callbacks remain unchanged. Exact inverse edits reconstruct each
original checked module.

| Actual12 module | Original declarations | Unique declarations | Original bytes | Hoisted bytes |
| --- | ---: | ---: | ---: | ---: |
| Scalar helper fixture | 14 | 5 | 82,259 | 79,875 |
| Original Mandelbrot | 31 | 8 | 110,405 | 102,556 |

The checked receipts and complete edit manifests are in
`review-hoist-{helper,whole}-01`. This tests module sharing and optimization
feedback together, separately from the earlier constant-binding experiment.

Passing reviewer receipts:

- `review-hoist-helper-controls-01`: 146 ordered ABI/prototype observations and
  72 scalar oracles; `review-hoist-helper-entry-01`: nine exact/raw/reentry cases.
- `review-hoist-tree-controls-01`: 74 tree/original-program points, 130 ordered
  boundaries and four depth sentinels; `review-hoist-tree-boundaries-01`: 85
  additional prototype/metadata/copied-length observations.
- `review-hoist-initialization-01`: all helper entry counters are zero after
  import, forward private references execute successfully, and aggregate call
  counts per original helper name agree across the four diagnostic modules.

The analysis agent independently completed `inspection-hoist-scope-01`, proving
that actual enclosing scopes do not shadow Math/Number/BigInt, each public
private-call site is inside the direct argument callback of exactCode, and no
new top-level name collision or private export occurs. This closes assumptions
of the first audit without changing its already consumed inputs.

Only unchanged uninstrumented modules enter the gated
`review-hoist-plan-01/{screen,confirm,long_warmup}.json` configurations. The long
warmup configuration uses the previously frozen long runner and whole-program
point only. It is not combined with the attempt13 frame-pool change. Allocation
counts and smaller source do not themselves imply faster execution.

The conditional production proposal is
`design/phase30/shared-private-helper-emission.md`: explicit emitted-global
results and helper collection, without string postprocessing or a second
analysis pass. Timing and complexity determine whether to implement it.

The initial `hoist-screen-01` was still warming: helper medians were
0.007584/0.007452 ms, while the whole-program medians were 0.409472/0.387097 ms
(baseline/hoisted). Timed-half changes reached approximately 15%, so the screen
does not establish a speedup. `hoist-long-confirm-01` uses the frozen longer
warmup runner on the complete original Mandelbrot point:

| Side | Median ms | Sample minimum–maximum ms |
| --- | ---: | ---: |
| Actual12 baseline | 0.265628475 | 0.262733701–0.271493486 |
| Hoisted private helpers | 0.270436688 | 0.266507347–0.273590072 |

The ranges overlap and the hoisted median is 1.81% slower. Baseline timed-half
changes were +0.118%, +2.540%, and −0.525%; hoisted changes were +0.557%,
+4.506%, and −1.103%. This does not justify the additional explicit collection
state and estimated 90–160 implementation lines, despite saving 7,849 emitted
bytes. Retain the experiment as evidence; do not combine its source-size result
with the separately measured frame-pool gain.
