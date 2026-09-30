# Remaining hypotheses after checked16

This is a static prioritization from retained Phase30 experiments. Final16's
full timing matrix and the warmed H comparison are still pending. It proposes
no additional source change or execution in the current clean timing window.
The [decision index](decisions.md) separates earlier measurement windows.

| Priority | Evidence and next discriminator | Admission/correctness boundary |
|---|---|---|
| 1. Larger closed regions containing local records and arrays | The [complete local-row ladder](closed-owned-row.md) improves1.60× while preserving storage; the separate [native-call ladder](closed-owned-native-calls.md) reaches1.759× versus its own generic baseline, yet remains40.6× TS. First rebind that small fixture to16, then remove generic gen/init setup in one separate generated-JS ablation. Its scalar-input/scalar-result `pair` is the likely original-program entry. | Reuse bounded first-order dependency analysis. Prove local production of every container and finish all private deferred work before return. Preserve aliases, zero-row swaps, writes and complete forcing order. This is locality, not unique ownership. The [existing proof outline](../../design/phase30/closed-local-graph-proof.md) identifies the required record-prefix and demand rules. |
| 2. Separate record administration from native Array dispatch | The native-call ladder removes160 Array call applications and four allocations' dispatch at row32, but still executes258 projections,384 copied field slots,33 builds/34 constructors and600 forces. Those are operation counts, not CPU shares. After the locality boundary passes, compare retaining exact objects while eliminating one private match/field-copy chain; only later test a distinct private flat representation. | Keep public records and callbacks unchanged. Immutable field snapshots can coexist with mutable aliased Array handles; do not eliminate or move Array.set. A representation experiment needs full-state/alias/deferred-write oracles and a second structurally different source fixture. |
| 3. Broader F32 work, not tiny guarded leaves | The [isect5 experiment](f32-ordinary-root.md) regresses2.87×/6.99× on hit/miss because its root is too small. The retained raytrace inventory identifies `nearest.t`/`nearest` chains and recursive `colf`/`rowf`; F32 signature admission alone misses their Nat selectors, residual Bool matches and Hit record boundaries. First statically classify one complete chain, then preserve existing rounded arithmetic in an isolated region experiment. | Reuse scalar provenance and exact entry, with complete helper snapshots. Keep every existing F32 rounding point and NaN/signed-zero behavior. Do not promote based on the number of eligible signatures or assume tree lowering covers these residual matches. |
| 4. Attribute generated-compiler H cost before changing its adapter | [P30-029](../../experiments/phase30/P30-029-bounded-generated-compiler.md) proves H can check Base and compile a small request. The pending clean comparison is against the genuine TS-produced parent of the same Bend compiler. If it exposes a material gap, acquire separate per-export encode/invoke/decode timings and existing ABI counts on that exact request, followed by a larger source point. | `compiler-abi.mjs` already uses cached read-only Proxy views and unwraps them back to original graphs; it does not eagerly copy every compiler result. Host-owned inputs still use fresh encoding because they may mutate. Do not remove those rules based on an assumed whole-book conversion cost. Profiling/counters belong in separate untimed copies. |

For H, the useful first split is **host/cache/ABI work versus generated compiler
execution**. Existing `BEND_TYPED_TRACE` phase events and ABI counters expose
encode/invoke/decode boundaries without inventing a second compiler pipeline.
If invocation dominates, inspect the responsible generated functions for repeated
generic apply, record matching and construction; the local-container work above
is then a plausible reusable direction. If adaptation dominates, isolate repeated
encoding of host-owned Base/source inputs versus lazy view accesses before
considering an immutable-input fast path. No current measurement assigns either
cause a fraction of H's time, and one warmed request is not a steady-state claim.

The common-runtime lesson is also a constraint: restoring generic delayed arm
application removed the observed row regression and allowed64 implementation
lines to be deleted. Per-call descriptor checks, a native bypass at each call,
callback fusion, helper hoisting and scalar permission slots did not establish a
large transferable benefit. Repeating those broad changes is lower priority than
a bounded private region that removes an entire chain while retaining the public
ABI and a simple generic fallback. No gains from different windows should be
multiplied into a forecast.
