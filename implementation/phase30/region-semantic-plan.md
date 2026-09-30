# Independent review: closed scalar execution regions

This is a prospective semantic analysis, not a timing or correctness result.
The proposed optimization validates a closed set of ordinary function bindings
once, then runs private direct code without repeating a guard at every call.

## Smallest first experiment

Use the existing, fully entered Mandelbrot `mit` successor callback. Phase29
already lowers it to a local loop with one Nat and six U32 state values. Its
remaining scalar helper closure consists of `asr8`, `sel`, `sel.go` and `b2u`.
The helper graph is acyclic; the only repeated state transition already has a
bounded-stack loop. This is a substantially smaller proof boundary than an
entire exported benchmark or a record/array-carrying region.

Preserve the original seven callback-vector reads into local state slots in
their existing order. Check those locals and the four helper bindings once.
If accepted, run the same loop/BigInt arithmetic with private scalar helper
bodies. Otherwise enter the original loop body. Do not read the original
callback vector a second time; a raw host invocation can supply accessor slots.
Preserve the public Nat matcher, partial descriptor, callback arity, state
aliases and all forcing outside that callback.

The small helper bodies use scalar comparisons and existing inline U32
operations, including Math.imul and bounded shift conversion. There is no
foreign operation, higher-order callback, array access, record projection or
constructor allocation inside this first candidate region. The Boolean
matcher inputs arise from scalar comparisons. Those facts avoid a large
provenance analysis in the first experiment.

## Admission and guard obligations

1. The actual runtime state values must have the native scalar representation.
   A checked Bend type does not validate arbitrary raw JavaScript arguments.
   Nat must be a BigInt in the checked nonnegative range; each U32 must be an
   integer Number in its range. Type checks precede comparisons/conversions so
   invalid host objects cannot execute coercion hooks during validation.
2. Inspect each reachable G entry as an own data property, then compare it with
   the module's original descriptor. Never invoke a G getter while validating.
   A replacement or accessor selects the original loop fallback.
3. Verify the original function descriptor's own data properties for arity,
   code, env and bound, its expected prototype, and empty original bound vector.
   Detect io/typeName paths and inherited changes that affect generic apply.
   Verify that the code function has no added own `call` hook and still uses
   its original ordinary function prototype/call behavior.
4. The emitted helper analysis must prove the complete executable dependency
   closure. Source references alone are insufficient if a native helper's
   runtime implementation calls additional G entries or host callbacks.
5. Require standard built-in functions and relevant prototype behavior. For
   example, the old Boolean matcher checks `x?.request`; a host getter installed
   on Boolean.prototype or Object.prototype can make that observable even when
   x is a primitive. A prototype may state this exclusion; a broader public
   guarantee requires an appropriate entry guard or retained runtime operation.
6. Preserve the original body and use it on every failed guard. Do not perform
   any optimized projection, effect or partial evaluation before deciding to
   fall back. The guard itself uses observation-free descriptor inspection on
   known ordinary objects under the stated intrinsic assumptions.

The guard should use the already read callback locals. General direct calls
need a different staging argument: lookup and leading arguments precede the
prefix application, whereas the final matched argument follows it. The existing
fully entered scalar callback deliberately avoids crossing that boundary.

## Why one guard can suffice

After admission, every input and intermediate value in this first region is a
primitive scalar. Every reachable helper is fixed and has a known scalar body;
the helper graph is acyclic. There are no foreign calls, callbacks, getters on
input objects, computed impure globals, runtime re-entry or shared-memory inputs.
The synchronous computation therefore has no admitted operation that could
mutate a guarded G binding or descriptor between the guard and the last helper
use. Ordinary JavaScript event handlers cannot interleave with that synchronous
activation. This is a noninterference argument with stated host assumptions,
not a proof that arbitrary JavaScript functions are pure.

Changing G between invocations remains observable: the next guard fails and
the original loop performs its original lookups. A saved partial function also
retains its captured callback; its guard checks current helper bindings when
the partial is finally saturated.

## Counterexamples that define the boundary

| Tempting relaxation | Distinguishing behavior |
| --- | --- |
| Trust static U32 type at a JS entry | A host object has valueOf that changes G.sel or records an effect. |
| Guard descriptor identity only | Mutating its code, bound vector, typeName, io or code.call changes generic invocation. |
| Read G entries normally in the guard | A getter for an unselected branch runs earlier or unnecessarily. |
| Guard only source-level callees | A whitelisted native helper calls an unguarded G helper or foreign callback. |
| Admit host records/arrays | A field/index getter mutates a helper binding after entry validation. |
| Admit a callback-valued argument | The callback changes G while the private region continues with stale bodies. |
| Admit a computed zero-arity global | Resolving a reference runs an initializer which changes state or throws. |
| Read callback arguments again for validation | Proxy/accessor slots see extra reads or return different values. |
| Directly recurse through a helper cycle | Tail recursion begins consuming the JavaScript stack. |
| Replace a public bounce-returning body eagerly | Caller overapplication can read its copied-vector length before the old bounce would run. |
| Assume primitive matching never reads properties | A prototype request getter makes the old native Boolean match observable. |

The public-bounce counterexample is particularly relevant to a future whole
function region. The existing `mit` callback already executes its scalar loop
before returning, so replacing its interior does not create that eager boundary.

## Later expansion

A region with records or arrays needs a provenance invariant: every object is
created inside the region by a trusted constructor/native allocator from region
values, never receives a foreign accessor/proxy/prototype, never escapes to a
callback or global before region completion, and is not shared with another
thread. Array operations and native helpers need independent ownership and
effect audits. Scalar-only public inputs and result help establish that boundary
but do not prove it alone.

A whole-program first-order region also needs a complete call graph and proper
loop/SCC lowering before it can replace trampoline tail calls. Those are later
experiments. The small existing scalar loop can test guard amortization without
introducing those concepts or changing its arithmetic/representation.

## Discriminating controls

Require scalar oracle equality across many counts and boundary values; preserve
the public partial and final output behavior. Vary G entries between calls,
install entry getters and zero-arity initializers, mutate descriptor fields and
code.call, and retain invalid scalar/coercion witnesses showing fallback. Test
that the entry guard occurs once per region, not per iteration. Verify generated
markers or counters so fallback execution cannot masquerade as fast-path
coverage. Run 50,000 iterations to retain stack behavior. Count dispatch and
allocation separately, then time the same immutable outputs without counters.
