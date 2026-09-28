# Phase10 — Index branch overhead

The bounded investigation produced one source-level candidate: express the
existing index lookup decisions as Boolean-parameter matches. The current
emitter combines the mutually tail-recursive workers into a loop, removing
per-hop branch closures and trampoline messages. The persistent trie, hashes,
collision buckets and book/cache semantics stay the same.

The isolated candidate passed its checked B1 gate and focused controls. A
concurrent component screen measured 1.77–2.21× faster complete successful
lookups across 16–4,096-entry books. These are actual compiled component
operations, **not a whole-compiler speedup**. Root owns integration, broad
validation, controlled final timing and promotion; none of those outcomes is
inferred here. No production source or distribution was edited by this task.

## Hypothesis and the rejected first formulation

[P10-004](../../experiments/phase10/P10-004-overhead.md) was written before
probes. Historical generic guarded direct/positional-call transforms had only
1.03×/1.05× whole-compilation gains, so they were not repeated. P6-002's Boolean
workers were useful precedent but not transferable evidence: the earlier pin,
artifact, workload and unresolved malformed-host-data H gate differ.

A tiny checked component tested whether the current pin permits matching a
locally computed Boolean. It still rejects that source with:

> a parameter or field scrutinee (a match cannot scrutinize a local binder: give it its own def)

The separate Boolean-parameter control checked. Both exact sources, command
arguments, input hashes, outputs and rejection are retained in
`selfhost/build/phase10/overhead-probe-01/`. This failed probe was not erased or
reclassified. These probes are upstream-checked components, not B1 artifacts.

Root's fresh final-release profile then supplied the discriminator for a narrow
index trial: two anonymous `index_find` closures account for approximately
8.256% and 2.983% of exclusive weighted samples. The profile's separate GC,
`run_loop` and `run_tail` shares are not attributed to this function; samples
are neither call counts nor allocation counts. The profile is
`selfhost/build/phase10/current-profile-01/`, against final Phase9 API
`d27968f11fa322bf3685ff0d276d9577a3b589b9cbae80784f5e4d404f7c3529`.

## Exact change and invariant

Only isolated `src/core/index.bend` changes:

- `index_find` delegates the existing absent, leaf and hash-match decisions to
  three Boolean-parameter workers. Each decision is computed at the same demand
  point as before, retaining the public argument list and result.
- `index_child_list` directly matches its existing `right` parameter after the
  same list match. It still ignores the opposite child's node contents.
- Index construction, insertion, hash computation, collision bucket traversal,
  first-wins declaration build order, replacement persistence and BookCache
  contents are unchanged.

This matters beyond replacing six branch closures per ordinary internal tree
hop: the existing upstream emitter recognizes the `index_find` / absent / leaf
mutual-tail component and emits a `for` / `switch` loop. Its generated behavior
is inspected, not patched. Full-hash collision bucket traversal retains its
existing implementation. The deliberately malformed 10,000-level tree control
checks that the reformulation does not lose stack-safe traversal.

The source cost is real: 339→375 physical lines, 298→331 nonblank lines,
9,480→10,030 bytes, and three helpers. The isolated equality API grows from
750,872 to 754,299 bytes. This is a targeted performance tradeoff, not a source
simplification or representation redesign.

## Evidence and limits

Frozen source candidate:
`selfhost/build/phase10/overhead-index-01/project/src/core/index.bend`
(`d6a80b85b6006f7750545dffe49aa0caf181fd0f555ac251be56b6c886677223`).
The manifest includes exact replacement preimages; baseline index SHA is
`c3cab805705f5dedcfe65691d4bc5c98710058bf8a62e0c39610ff398cf2872e`.

The genuine checked B1 API is
`overhead-index-01/checked-01/api.mjs`, SHA
`a71732abc6dfdfccb70240bea3b422f6ba9142cef3765ffd024136732f785c1f`.
Its validated equality derivative is
`overhead-index-01/checked-01/equality/api.mjs`, SHA
`933c3e080bbd531e450ea04e2ed8153dede5ee6cf2814f3dea4bd843c3001cbf`.
This retains the ordinary bootstrap sidecar, derivation identity, immutable
source/tool snapshot and maintained selected gate. It is not a fixed-point
claim.

The maintained gate passes 21/21 semantic observations. All 21 complete candidate
observations exactly match the existing Phase9 final gate, including diagnostic
text (`overhead-index-01/observation-preservation.json`). The same 12 exact
TypeScript diagnostic differences remain; `strictExact` remains false. This is
selected-gate preservation, not full frontend or backend conformance.

Separately, both versions' actual sources were checked by pinned upstream and
emitted with selected private exports. This component gate is not presented as
B1 evidence. Under `overhead-component-01/` it passes:

- 5,769 existing persistent-index comparisons: empty/singleton/large books,
  duplicate order, immutable historical versions, special and Unicode names,
  cached bounds, empty names, all 32 split bits, supplied hashes and collisions.
- 21 added complete outcome comparisons: arbitrary node kinds, malformed
  lists/trees, raw Boolean truthiness, invalid children skipped on absent/hash
  misses, left/right demand, empty/one/two child lists, and a malformed
  10,000-level tree. Matching thrown names/messages are retained, not reduced to
  generic rejection booleans.

The new raw controls use ordinary data and a few deliberate throwing accessors
to expose branch demand. They do not establish equivalence for arbitrary
stateful host getters, proxies or every malformed JavaScript object.

## Short operation screen

`overhead-micro-01/report.json` retains eight fresh workers in ABBA then BAAB
order on CPU3, exact Node/API/tool identities, outputs, three samples per cell,
120 ms warmup and 60 ms sample targets. Workers consume results and verify
expected checksums outside measured regions. Setup/index construction is outside
lookup timing. Other compiler jobs could run on other CPUs, so this is a
concurrent diagnostic screen, not an exclusive final benchmark.

| Book entries | Prehashed `index_find` speedup | Complete `lookup` speedup |
| ---: | ---: | ---: |
| 16 | 2.386× | 1.770× |
| 256 | 2.679× | 1.997× |
| 4,096 | 2.715× | 2.211× |

Each ratio is baseline median divided by candidate median, with each worker
contributing the median of its three samples. Keys are predetermined successful
lookups; the correctness gate also exercises misses, but this screen does not
measure them. It does not measure end-to-end checking, allocation counts, peak
RSS, native performance or the self-emitted compiler.

## Decision

Recommend root integrate this isolated source candidate and retain it only if
broad correctness and controlled whole-compiler comparisons pass. Its mechanism
has direct generated-code evidence and a positive component screen, while its
source/helper growth is explicit. Do not broaden this result into a mechanical
rewrite of every `kc` call; profile-guided branch shape and existing emitter
loop recognition are the evidence for this particular change.

Reproduction tools are `selfhost/tools/performance/phase10/overhead-{probe,
prepare,component,controls,micro}.mjs`. All compiler jobs used CPU3 and absolute
Node v24.18.0; input identities, pinned upstream revision
`b2111cf43244e65f76ddc278ee695e669f720cbf`, canonical Base path and raw failures
are preserved in their respective fresh evidence directories. No additional CPU
jobs are pending from this task.
