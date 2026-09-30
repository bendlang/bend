# Closed local-array row investigation

This is a disposable generated-output investigation, not a production compiler
change. The checked fixture, complete-state/alias/public-boundary controls and
mechanism counts pass. Independent exact-code review and additional boundary
controls also pass. Performance plans are frozen and await a coordinated clean
timing grant.

The broader proposal is
[closed-owned-edit-distance-region.md](../../design/phase30/closed-owned-edit-distance-region.md),
and the bounded first ladder is
[closed-owned-row-first-ladder.md](../../design/phase30/closed-owned-row-first-ladder.md).
The latter freezes a checked scalar-input row creator, private cell/scalar
helpers and an optional private BigInt row loop. Array calls, record and Tuple
representations, projection/copies, build/force and public helper definitions
remain unchanged.

Static inspection of actual12 confirms that original editdist still uses the
generic five-function cell chain and opaque-state trampolines. Its scalar-input
`pair` creates every array inside and eventually returns a scalar, making it a
possible future outer region boundary. The current probe exposes the complete
resulting Dp solely for state and alias oracles. It does not establish a general
compiler rule for escaping container results.

Independent review supports this scope with an explicit requirement: the local
closure proof must cover deferred field work through complete public forcing.
The admitted exact probe therefore forces its private expression completely
before returning. Raw, constructor and oversaturated invocations retain the
original generic expression and its deferred result. This prevents a private
Array.set field thunk from escaping the guard and later bypassing a changed
global binding.

The important proof is locality, not unique ownership. Array.get returns the
same array handle, source Dp values share handles, and even a zero-cell row swaps
prev/cur roles. The prepared controls compare all four complete arrays, distinct
fresh allocations, old handle identity after another public row, and a subsequent
Array.set observed through saved aliases. They also retain public mutation,
getter, copied-vector, raw-entry and primitive-marker controls.

The first source acquisition is `prototype-owned-source-01`, with a separate
outer receipt. It copies the canonical editdist source verbatim and appends
`row.probe(n: U32, seed: U32) -> Dp`. The checked probe creates four 128-slot
arrays, generate two n-symbol sequences, initialize the first n+1 previous-row
entries and run one row. Admitted private sizes are at most 64. Source n and seed
remain dynamic inputs, and every timed invocation will include allocation,
initialization and complete-state observation.

Maintained tools currently prepared under `selfhost/tools/performance/phase30/`
are `prototype-owned-fixture.py`, `prototype-owned-derive.py`,
`prototype-owned-controls.mjs`, `prototype-owned-counts.mjs` and
`prototype-owned-plan.py`.

## Checked acquisition and semantic gates

The exact source passed actual12 checked emission in 5.125 seconds and pinned
TypeScript checked emission in 0.767 seconds. Those are acquisition durations,
not compiler throughput measurements. Both module receipts record the same
input-source hash. `prototype-owned-01` retains five separately hashed modules:
baseline, private cell, private scalar helpers, private row loop and TypeScript.
The public row/cell/minimum/Bool definitions remain byte-identical in each
candidate-runtime module; only the probe can enter the private path.

`prototype-owned-controls-01/report.json` passes:

- **28 full-array oracle points across all five variants**, including zero and
  multiple cells, U32 extreme seeds, complete input arrays and all 128 slots of
  both working arrays.
- **16 alias observations:** four distinct array handles and backing arrays,
  fresh storage between calls, preserved zero-row swap, a subsequent public row,
  and a write visible through all saved aliases of the same handle.
- **257 paired ordered host observations** across four candidate-runtime
  variants, including all 16 captured targets, mutation before first invocation,
  saved partials, raw/new/forged entry, slot/environment reentry, oversaturated
  copied-length effects, primitive runtime marker hooks and a foreign public row.
- **15 post-guard admission sentinels:** each private variant accepts n0/n64,
  rejects n65 and boxed scalar inputs, and keeps its generic body independently.

All native snapshots occur once during module initialization, after their original
creation and before any exported call. The private callback forces every local
build before returning. Independent exact-code review finds no blocker within
the frozen standard-intrinsic, scalar-root scope. Its separate
`review-owned-row-controls-01` passes **27 additional paired observations**:
raw/forged/constructed results retained before later native/cell mutation and
forcing, repeated forcing of a saved bounce, later alias writes, fully aliased
public row handles/shared backing storage, proxy arrays, getters and Object
prototype marker hooks. These controls are evidence, not a general ownership
proof.

## Mechanism counts

Separate instrumented copies pass 16 runs in
`prototype-owned-counts-01/report.json`. For n32, seed17:

| Operation | Baseline | Private cell | Plus scalar helpers | Plus row loop |
| --- | ---: | ---: | ---: | ---: |
| Generic apply | 1,723 | 1,243 | 954 | 794 |
| Function descriptor | 944 | 624 | 495 | 367 |
| Partial application | 360 | 360 | 360 | 264 |
| Jump | 709 | 421 | 292 | 227 |
| Force | 1,014 | 855 | 695 | 600 |
| Projection | 355 | 355 | 290 | 258 |
| Closure guard | 0 | 1 | 1 | 1 |
| Array reads / writes | 128 / 129 | 128 / 129 | 128 / 129 | 128 / 129 |
| Array allocation | 4 | 4 | 4 | 4 |
| Build / constructor | 33 / 34 | 33 / 34 | 33 / 34 | 33 / 34 |

Every private variant still copies 384 projected field slots; the cell step
retains projection and build work. The scalar step removes only primitive
minimum/Bool boundaries. The row step removes repeated Nat administration while
retaining an original public zero-row call for the final swap. The counts show
the intended removed operations and unchanged storage effects. They are not
time shares or a speed estimate. Generic gen/init setup and native Array calls
remain substantial work in this complete fixture.

## Controlled timing

Frozen comparisons are `prototype-owned-plan-01/{screen,confirm}.json`.
Corresponding source/emission/derivation/control/counter/plan outer receipts
retain complete process outputs and exact consumed sources. All timings used
the exclusive CPU3 window with other agents' acquisitions paused. The fixture
includes local allocation, generic gen/init setup and complete four-array
serialization; these numbers are not an isolated inner-cell rate.

The retained `owned-row-screen-01` completed in 9.53 seconds. Its median times
were 0.833818 ms generic, 0.783122 ms private cell, 0.696593 ms plus scalar
helpers, 0.547825 ms plus private row and 0.009228 ms pinned TypeScript. Large
within-process changes, up to roughly 48%, made this screening evidence only.
The prescribed maintained confirmation was run unchanged.

`owned-row-confirm-01` completed in 105.72 seconds with every output check
passing:

| Variant | Median ms | Sample range ms |
| --- | ---: | ---: |
| Generic checked12 | 0.588137 | 0.575187–0.623766 |
| Private cell chain | 0.520346 | 0.518463–0.529447 |
| Plus scalar minimum/Bool helpers | 0.456687 | 0.451875–0.471843 |
| Plus private BigInt row | 0.367874 | 0.367393–0.379354 |
| Pinned TypeScript | 0.008413 | 0.008361–0.008665 |

Each ladder step has disjoint sample ranges. The full ladder is **1.60× faster**
than the generic baseline on this point, while remaining **43.7× slower** than
the pinned TypeScript output. The ratios are scoped to this complete local-array
fixture. Within-process changes were much smaller than in the screen: generic
−4.04% to +1.90%, cell −1.97% to −0.86%, scalar −1.42% to −0.01%, private row
−2.42% to −0.06%, TypeScript −1.53% to +5.54%. Keep these residual changes and
the full sample ranges when interpreting the magnitude.

The evidence supports removing closed private call plumbing while preserving
the current storage and forcing behavior. It does not yet justify a production
owned-region extension. The general locality proof is outlined separately in
`design/phase30/closed-local-graph-proof.md`. The subsequent
[native-call experiment](closed-owned-native-calls.md) isolates native Array
dispatch inside the same region, leaving generic gen/init unchanged. Its
separate confirmation shows another 7.59% reduction in time, with an additional
outer Array.prototype marker refusal required by its broader hook controls.
Use that report's directly measured full-ladder comparison; do not multiply
ratios from the two windows. The earlier variants retain their explicit
standard-Array scope.
