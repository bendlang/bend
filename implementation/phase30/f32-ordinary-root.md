# Closed F32 ordinary-root experiment

The generated-JavaScript `isect5` prototype passes 425 independent rounded
scalar points, 238 paired public/host observations, and the original raytrace
result on both variants. The clean short screen regresses both leaf points:
about 2.87× on a hit and 6.99× on a miss. This per-root guard is not recommended
for promotion. No maintained compiler or runtime source was changed.

The [prospective design](../../design/phase30/f32-ordinary-root-ablation.md)
tests a small closed floating-point chain separately from the ordinary-root
experiment that encloses a nested Nat loop. Eight plausible raytrace roots were
identified in the [coverage analysis](../../design/phase30/next-scalar-coverage.md);
this probe changes only one. Coverage does not establish profitability.

## Exact scope

The root `isect5` retains its public arity10 descriptor and original callback
slot reads. A registered exact callback admits only native primitive F32 values,
then guards the root and its complete five-helper closure: `isect.go`,
`isect.go2`, `isect.t`, `isect.t2`, and `fl`. Captures happen during definition
construction, before any experiment calls. Private lexical helpers eliminate
public helper application; the two complete native Boolean matches become
ternaries with their original polarity. All original primitive expressions,
`Math.fround` operations, comparisons and IIFE binding order are copied.

The unchanged generic body remains the fallback for raw or overapplied entry,
coercible/non-F32 inputs, mutated descriptors and relevant prototype hooks. The
experiment retains the existing stable host-intrinsic contract. Function source
text is not an identity promise. No scene selection, array, record projection,
ray loop or arithmetic algorithm changes.

| Output | SHA-256 | Bytes |
| --- | --- | ---: |
| Checked attempt08 original raytrace | `fc22762988a5f28ffced35a47abc124d5716061e8a737caeabc8d10fe8b360a5` | 101364 |
| Guarded F32 root | `1f343805f0b64dd8c608151036f624db002e8eafa77d603a5fabf34f711acd1f` | 104172 |
| Unchanged leaf adapter | `74d6a9f8f676bb20f4010dfc4255fa3f6de0492f6921867943b7b631947c19f1` | 101532 |
| Guarded leaf adapter | `c9f165702e431519405b5c7eb38a52eef618d0b8e8e27276dc3c5826f001175d` | 104340 |

`inspection-f32-root-01/derive.json` records the exact checked emission receipt,
source/design/parser/framing-tool hashes, original and private helper bodies,
root replacement and identical leaf adapter. The generator checks the expected
source identity, leading/public arities, Boolean match shape, saturation and
absence of residual generic global calls in the private chain.

## Correctness and review

Evidence directories below are under `selfhost/build/phase30/`:

| Receipt | Observation |
| --- | --- |
| `inspection-f32-root-controls-01` | 425 scalar points and 238 paired host observations pass |
| `inspection-f32-root-original-01` | Both unchanged and derived original `bench(80,0)` return 402971 |
| `inspection-f32-root-counts-01` | Four instrumented leaf observations match complete scalar results |

The independent scalar reference uses separate explicitly rounded add, subtract
and multiply operations, rather than copied generated JavaScript. It checks hit,
miss, tangent, inside/behind, near-epsilon and deterministic finite points, plus
each input position with signed zeros, subnormals, extreme finite values, NaNs,
infinities and rounding boundaries. Comparisons use `Object.is` to preserve NaN
and signed-zero distinctions. Valid finite intersection results below the
positive epsilon become the sentinel, so separate live-helper replacement
controls explicitly verify returned positive and negative zero through fallback.

The host observations cover all six live bindings and descriptor fields,
replacement Proxies, custom call hooks, saved partials, raw/forged/constructed
callbacks, slot getters and same-vector reentry, mutation between slot reads,
overapplication with changing/throwing length, boxed/coercive/proxy inputs,
non-F32 numbers and other primitive types, and primitive prototype hooks,
including a hook that removes itself. Values, errors and event order are paired.

An independent static reviewer found no blocker in the closure capture,
Boolean polarity, exact-entry framing or copied floating-point expressions.
That review is distinct from the owner-executed controls reported here.

## Mechanism counts and measurement

Separate instrumented copies count one leaf invocation, resetting after module
initialization and snapshotting before any later work:

| Point | Variant | apply | fn | partial | jump | force | guard |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Hit: `(5,0) -> 4` | Original | 10 | 4 | 0 | 5 | 5 | 0 |
| Hit | Guarded root | 1 | 0 | 0 | 0 | 1 | 1 |
| Miss: `(5,3) -> 1e9` | Original | 4 | 1 | 0 | 2 | 2 | 0 |
| Miss | Guarded root | 1 | 0 | 0 | 0 | 1 | 1 |

The candidate pays the same six-descriptor guard for both branches; the miss
removes fewer calls. These are named event counts, not total allocations or
runtime-cost percentages. The instrumented modules are excluded from timing.

The clean three-sample screen is retained at `f32-root-screen-01/report.json`.
The timing coordinator acquired it in the exclusive CPU3 window; the outer
launcher took8.63 seconds. All timed outputs pass.

| Frozen point | Original median ms [range] | Guarded root median ms [range] | Candidate/original |
| --- | ---: | ---: | ---: |
| Hit `(5,0)` | 0.00180505 [0.00179239–0.00188124] | 0.00517952 [0.00514769–0.00526318] | 2.87× |
| Miss `(5,3)` | 0.000741189 [0.000734346–0.000743311] | 0.00517756 [0.00513338–0.00537074] | 6.99× |

Candidate second halves are10.5–18.6% faster than first halves, so this is not
a settled steady-state effect estimate. The completely separated ranges and
large regression on both branches nevertheless support declining this isolated
promotion. A confirmation config was frozen but has not been run. The guard
cost is almost identical on both branches, consistent with the named mechanism
counts: removing a handful of public calls does not amortize six descriptor
checks. This does not reject F32 lowering inside a larger already guarded loop.

The original raytrace comparison remains correctness-only. An earlier checked
invocation took13.8 seconds; further whole-program timing is not justified by
this leaf result. No whole-program speed claim follows from the screen.

Tools are `inspect-f32-root.py`, `inspect-f32-root-controls.mjs`,
`inspect-f32-root-counts.mjs` and `inspect-f32-root-plan.py`. The generated parser
and ordinary-root framing come from the earlier independently reviewed Phase30
experiment tools. All modules, consumed tools and receipts are retained.
