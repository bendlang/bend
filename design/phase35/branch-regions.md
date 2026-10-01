# Preserve public stages while looping across the final Boolean match

This prospective experiment targets the original raytrace `nearest.t`, beginning
with a frozen saved-output ablation. It is not a compiler implementation or a
new conformance claim. Parent compiler changes remain separate. The
[literature review](literature.md) motivates direct saturated regions and join
points, while this design fixes the observable boundary at which a region starts.

## Hypothesis and rejected alternative

The original function matches its Nat first, then accepts eight scalar values
in the zero case or nine arguments (including the predecessor) in the successor
case. It subsequently returns a Boolean matcher. Each recursive transfer crosses
that sequence again. Eliminating the repeated transfer should improve execution
even while sphere selectors and intersection helpers retain generic calls.

A new public callback accepting the whole argument list would change the public
partial-application stages. Reusing the existing generic fallback would also
return the final matcher without applying the already consumed Boolean. That
naive architecture was rejected before implementation. This experiment instead
replaces only the successor's final Boolean callback, preserving the outer Nat
matcher, zero branch, leading `fn(9)` and prefix slot reads exactly.

## Prototype transformation

[branch-derive.mjs](../../selfhost/tools/performance/phase35/branch-derive.mjs)
accepts only the canonical Phase33 raytrace output, SHA256
`3d1bc9a29878c1c079fdafcad3e6733037194323edc9a099efd940d811b3b367`.
Acorn verifies the expected top-level assignment, constructor names, prefix
arity/slot reads, final False/True matcher and identical intersection expression
in both arms. Source slices retain the complete original fallback and intersection
calculation; only references to the predecessor change inside that calculation.
This is explicitly fixture-specific mechanism evidence, not name-based general
code generation.

The new final descriptor is `fn(1, exactCode(inner, true))`. The public callback
is therefore still an arrow of length one, although its private inner function
also receives the runtime's unforgeable exact-entry permission. It destructures
the Boolean argument once at the same stage as the original matcher. Only then
does it inspect canonical scalar values and guards. A descriptor-only numeric
intrinsic check precedes the `Math.fround`/`Number.isNaN` input tests, so replaced
Math/Number globals or relevant methods cannot execute extra guard callbacks.

On valid guarded entry, a local loop selects the previous best distance, evaluates
the unchanged intersection expression, and either returns the selected minimum
at predecessor zero or updates the predecessor/pending/best/flag slots. The
F32 operation order inside intersection and the strict comparison remain. The
source's initial Nat zero arm is unchanged, including selected signed zeros or
NaNs. No runtime continuation closure is allocated per iteration.

## Why scalarGuard alone is insufficient here

The first ablation deliberately retains generic `isect5`, `sx`, `sy`, `sz` and
`sr` calls. Their statically discovered transitive definition graph includes all
live helpers such as `fl` and comparison helpers. Each is captured with the
existing descriptor snapshot mechanism. Replacing or accessor-wrapping any of
those definitions after import must reject private entry. This prevents an
arbitrary helper callback from changing the recursion target mid-loop.

Generic calls also use Array protocols. A changed iterator can run user code
during argument destructuring, and `scalarGuard` itself iterates over arrays.
The prototype therefore first checks property descriptors for:

- Array iteration and iterator `next`/inherited `return`, including relevant
  iterator prototype links;
- Array `concat`, `slice`, constructor/species and concat spreadability;
- Array `every`, which is used by the later scalar guard.

The preliminary guard uses indexed loops and descriptor inspection, avoiding
invoking those hooks merely to decide to fall back. It runs after the one original
Boolean destructuring, so a hook there has its normal chance to run and mutate
dependencies. Existing `localGuard` then checks marker hooks and the captured
closed definition graph. Guards are once per entered nearest search, not once
per sphere.

This experiment assumes standard, stable host intrinsics at module initialization,
as do the existing guarded experiments. It captures their initial identities;
it is not a defense against arbitrary JavaScript environment modification before
import. Post-import hooks named above and descriptor mutations are explicit
counterexample controls. This scope must remain in any result description.

## Correctness and measurement

[branch-controls-v2.mjs](../../selfhost/tools/performance/phase35/branch-controls-v2.mjs)
contains an independent sphere/intersection/minimum oracle with one rounding per
F32 operation. It compares both emitted variants and the oracle for multiple
depths, both initial Boolean choices, different rays, subnormals, signed zero,
NaN and infinities. A 4,096-step control checks stack behavior separately.

Paired public observations cover saved prefixes and callback shape, helper
replacement/accessor mutation between stages, raw and forged callback entry,
oversaturation, nonconstructibility, iterator-triggered mutation/reentry/errors,
Array protocol hooks, Math method/global replacement and getters, primitive
marker hooks and noncanonical scalar inputs.
They retain ordered events and errors, not only final checksums. Version two
normalizes only V8's embedded callback-source text in the explicit nonconstructor
probe; raw errors remain in evidence. The original tool and failed first
acquisition remain preserved. A semantic boundary failure invalidates the
candidate rather than becoming an excluded sample.

The new benchmark wrapper performs 1,000 complete `nearest.t` calls across five
ray origins. An independently computed sum of F32 bit patterns is checked. Both
variants keep the original full raytrace wrapper as `raytraceBench`; this allows
later transfer confirmation without changing the original algorithm or input.
The new small workload is a diagnostic, not a replacement representative corpus.

Root alone runs derivation/controls and timing serially under existing limits.
Use the maintained prototype-bundle preparation and 20/60-second timing screens,
then longer confirmation only if correct and faster. Check code size and memory;
the guard's cost may exceed the transfer work for short searches. Instrumented
profiles are separate from uninstrumented timing. A useful result would justify
an ABI-preserving compiler plan that routes private statements through branches;
it would not authorize installing this hand-written output transformation.
