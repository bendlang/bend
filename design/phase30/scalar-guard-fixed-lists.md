# Remove repeated fixed-list allocation from the complete scalar guard

The earlier residual-cost experiment bypassed the complete guard or outlined
the fallback; neither tested its internal fixed-list allocation. The current
actual14 guard constructs a combined prototype list, repeated marker/key lists,
and a four-descriptor array plus callback for each dependency check. These are
source-level allocation opportunities, not established material heap costs:
the host may already eliminate some of them.

Freeze one disposable actual14 variant that changes only `scalarGuard` and
adds private fixed lists next to it. Keep public generated code, scalarCapture,
snapshots, exact entry, all dependency names and every guard predicate unchanged.
Hoist the fixed prototype sequence Object, Boolean, Number, BigInt and the fixed
key sequences request/bounce/build/code and io/typeName into private module
constants. Preserve iteration order and every early return.

Replace only the guard's `[a,c,e,b].every(d => Object.hasOwn(d,'value'))` with
four ordered explicit own-data checks. The existing statements still acquire
all four metadata descriptors in their original arity/code/env/bound order
before any of these checks; absent descriptors still short-circuit at the same
point. Keep the later value, environment, bound identity and length checks in
exact order. Do not alter the similar one-time capture check. Do not cache an
acceptance result, skip revalidation, freeze public objects or add an alternate
representation. All fixed lists remain private and are never handed to host
callbacks.

This uses the existing standard-intrinsic contract: replacing Array iterators,
Array.prototype.every, Object.hasOwn or reflection functions is outside scope.
Hoisting would otherwise move observable iterator/method reads. Preserve the
supported metadata/prototype accessor and mutation behavior: guard validation
must still refuse hooks without invoking them, and generic fallback must still
observe the original effects. No broader sandbox or arbitrary monkeypatch
equivalence claim follows.

Before measurement, retain exact checked actual14 helper and original Mandelbrot
emissions, runtime/attempt/source receipts, and derive exact baseline/candidate
copies. Prove the whole modules differ only by this runtime helper replacement
and private constants. Run inherited scalarGuard direct controls, actual helper
numeric and ordered ABI/entry controls, original/tree oracles and supplemental
public boundaries against both copies. Use separate diagnostic instrumentation
only if needed; do not confuse source allocation counts with measured heap
allocations. Any changed accepted/refused result or ordered observation stops
promotion.

Freeze two paired cases: the established helper point(128, 524800), expected128,
and original Mandelbrot bench(2,0), expected887240761. Keep all source/control
identities and normal CPU3 rotating-process screen settings. Whole-program
follow-up, if warranted, uses the already established separately frozen
15-second-warmup protocol; the helper can use the maintained confirmation.
Execution requires the parent's next clean timing grant. A small or absent
gain favors keeping the current runtime; final compiler release has priority
over expanding this experiment.

Freeze the decision threshold before the first screen: require at least a 5%
stable reduction in time on the 128-iteration helper, or at least a 3% reduction
on the original whole-program point, with no confirmed regression above 3% on
the other. Both fixed-list hoisting and explicit four-descriptor checks form
one temporary-allocation variant. Do not attribute a gain separately to either
subchange without another ablation. Promotion still requires fresh actual
compiler/runtime validation and a final compiler-produced timing comparison.
