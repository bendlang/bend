# Closed scalar regions at ordinary lambda roots

Prospective generated-JavaScript experiment, after the checked lexical-helper
candidate. This design does not change compiler or runtime sources. It tests
whether the existing scalar-region concept should also start at an ordinary
top-level lambda chain, rather than only at a Nat matcher.

## Hypothesis and target

The original Mandelbrot `rpix` definition has ten live arguments:
`U32, Nat, U32×8 → U32`. Its body calls `pix`, `bkt` and `b2u`; `pix` calls the
already proven scalar Nat countdown `mit`. The second render pass calls `rpix`
at each leaf of the existing `rcol` recursion. A closed region rooted at `rpix`
could use one entry guard for that complete scalar computation and privately
call `mit`, without changing the tree recursion, record matching or result
representation. `pix : U32, Nat → U32` is a smaller root used in both passes.

This is an admission and entry-placement experiment. Use a fresh checked
attempt08 whole-program emission, which already contains lexical private helper
spelling, as the unchanged control. Verify its checked emission receipt, source,
attempt manifest and runtime hashes before deriving any variant. Do not silently
substitute the older dictionary-helper attempt07. If the actual emitted shape
differs from the expected ordinary `fn` or private `mit` shape, preserve the
failed acquisition and amend the prospective plan before retrying.

## Frozen variants

1. Unchanged attempt08.
2. A closed ordinary region at `pix` only.
3. A closed ordinary region at `rpix` only.
4. Both ordinary roots, with the same private helper graph at each root.

The private helper spelling is lexical in every new region. Copy the exact
checked `mit` primitive expressions and loop, preserving its BigInt counter and
zero case. Rewrite only exact saturated calls to the proven helper closure.
Do not simplify arithmetic, fold constants, flatten records, convert counters,
or alter native operations. The source `Let` order and immutable aliases remain.
The first experiment does not combine this change with the terminal `hchunk`
region extension; that combination would be a separately acquired experiment.

The complete guard closure is `pix, mit, asr8, sel, sel.go, b2u` for `pix`, and
`rpix, pix, bkt, mit, asr8, sel, sel.go, b2u` for `rpix`. Capture newly compiled
ordinary helper descriptors that the old signature filter did not register.
Snapshots remain private. Existing public definitions are retained; only the
selected root callback receives the guarded fast branch.

## Public and host boundaries

Keep the original `fn` arity, ordinary function kind, partial descriptors,
argument erasure and original generic callback body. Wrap each selected callback
with the existing regular-function `exactCode` mechanism. It must consume its
unforgeable entry permission before any original slot getter is read. Read each
original callback slot once and in its original order. Only then check primitive
input representations and the complete current closure with `scalarGuard`.

All U32 inputs must be integers in `[0, 2^32−1]`; Nat inputs must be BigInts in
`[0, 2^48−1]`. The original unprojected Nat reaches the private `mit` helper:
handle zero first, then subtract one and enter the copied predecessor loop.
No eager projection or scalar coercion is added at the public boundary.

Unknown, raw, hooked, over-saturated or otherwise unprivileged invocations use
the original generic expression with the already-read original slots. Guard
failure also uses that expression. Do not reevaluate argument expressions or
recapture a callee already selected by the original path. Live `G` replacement,
descriptor mutation, slot effects, saved partials and public callback hooks
must retain their behavior. The private path has scalar inputs and a closed pure
body under the declared stable-host-intrinsics scope; it invokes no host callback
between its guard and return. It may therefore compute a scalar eagerly only on
the existing exact-entry branch. Raw callback returns retain the original bounce.

Do not root at an arbitrary scalar-looking expression. A future compiler change
must prove the complete live lambda telescope and scalar result, bounded source,
distinct unlabelled binders, no templates or effects, and the same helper closure
proof. Reuse the existing region traversal and shared budgets. No new recursion
recognizer is needed; nested `mit` must satisfy the already maintained Nat-tail
proof. F32, records, arrays, strings, erased binding support and arbitrary
recursion stay outside this initial experiment.

## Validation before timing

Derivation records exact original/replacement definitions, helper names, slot
order, guards and every output hash. Assert that all unselected public definitions
and the runtime remain byte-identical except explicit private snapshot captures.

Use an independent mathematical escape-time and palette oracle for complete
`pix` and `rpix` scalar results. Cover zero iterations, boundary indices, U32
overflow and varied palettes, plus both documented small whole-program points.
The oracle must not copy generated expression text or use the compiler's runtime.

Compare ordered host observations across all four variants: each guarded global
as a getter or proxy; code, arity, environment and bound metadata hooks; in-place
code replacement; saved partials; direct raw callback entry; attempted forged
permission; copied-vector getters, throws, reentry and mid-slot mutation;
over-saturation and deferred effects; boxed/coercible scalar inputs; and mutation
seen on the following invocation. Check original callback constructibility and
ordinary function kind. An independent reviewer should inspect the exact entry
and tail-demand boundaries before clean timing.

Collect separate administrative counters for original `bench(2,0)` and a pixel
fixture: apply, force, partial descriptors, jumps, projections and closure guards.
These instrumented modules are never timed. They explain mechanism; they are
not a complete allocation count.

## Controlled comparison and decision

After correctness and independent review, freeze short and long configurations
before asking for the parent's exclusive CPU3 timing slot. Compare all four
variants on original `bench(2,0)` and a separate dynamic `rpix` fixture. Use the
maintained rotating fresh-process protocol, exact result checks, long warmup,
sample ranges, within-process halves and outer launcher receipts. Include pinned
TypeScript for the original whole program; make any wrapper cost explicit for
the scalar fixture. Do not run the whole large application.

No speed estimate is treated as evidence. Keep a no-gain result. If the gain is
clear, the production proposal should add one ordinary-root entry into the
existing region analyzer, using the same exact-entry, input and closure guards
and original generic fallback. It should not add another private-call ABI or a
special case for `rpix`, `pix` or Mandelbrot.
