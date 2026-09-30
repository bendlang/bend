# Recheck the private countdown after lexical helper lowering

Prospective generated-JavaScript experiment. The earlier private Number counter
gave only a 1.052× improvement with dictionary helpers and dynamic shifts. The
current helper has lexical functions and constant shift lowering, so its cost
distribution has changed. The earlier ratio does not answer whether the same
representation change is worthwhile now.

Use the checked attempt08 Mandelbrot helper emission at
`selfhost/build/phase30/fixture-region-08/candidate.mjs`, SHA-256
`fa9cc6361f7d11e5e340d487f0ac918fd51212b82611b2a8baf247c847787da3`.
Its checked emission receipt is part of the acquisition. This is deliberately
the isolated helper fixture, rather than a later whole-program output that also
changes terminal records or the number of region entries.

Keep exactly two timed variants: the unchanged module and a module changing
only the admitted private loop's countdown. Insert `Number($s0)` after all
existing exact-entry, scalar-input and live-descriptor guards succeed; change
only the private zero comparison and decrement from BigInt to Number. Preserve
every helper, primitive expression, public descriptor, callback, slot read,
fallback, guard and runtime byte outside that loop edit. Do not combine this
with a smaller guard, entry-wrapper change or helper inlining.

The derivative must reject an unexpected shape. The original predecessor alias
must occur only at its immutable binding and as the first self-tail argument.
The saved next counter must occur only at its binding, zero test and decrement.
No arithmetic, helper, result, another state slot or deferred closure may observe
the Number representation. The existing predecessor guard is native BigInt in
`[0, 2^48-1)`. Every admitted initial value and every decrement is an exact
integer under Number. The original successor callback still executes one body
before the zero test; do not change its off-by-one convention or the Zero arm.

Validate the maintained independent fixture points, a 50,000-iteration point,
saved partials and all current same-runtime ABI, entry, mutation, coercion and
prototype controls. Add representability checks at 0, 1, the 32-bit boundary,
the 48-bit boundary and deterministic samples. Separate diagnostic copies may
replace only the already-guarded private body and cold body with entry sentinels
to test huge counters without running huge loops. They must observe the actual
conversion and decrement in their respective variants, preserve slot reads and
guards, and never enter the timing set. Test admitted maximum predecessor and
the next rejected value, Number/boxed/coercible/raw inputs, and guard failure.

Freeze identities, change counts, controls and screen/confirmation configs before
execution. Start with the existing `[128, 524800]` helper point and independent
expected result 128 under the maintained exclusive CPU3 protocol. Report ranges,
drift and lifecycle separately. No compiler edit is authorized by this output
experiment. Only a material confirmed gain justifies a subsequent minimal
induction-variable liveness check in the compiler; a small gain leaves BigInt
as the simpler implementation.
