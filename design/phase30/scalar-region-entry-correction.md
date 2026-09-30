# Preserve generic callback entry and self-binding semantics

Prospective correction after the five actual-emitter counterexamples in
`review-nat-loop-scheduling-01`. The Phase29 Nat worker already ran later
iterations before observable oversaturation checks and skipped mutable self
bindings. Phase30's original-loop fallback inherits those defects. Passing
against Phase29 alone was insufficient; the pre-worker compiler discriminates
them. Do not promote attempt03 as a completed compiler version.

Only a completely admitted pure scalar graph may use a local loop, including a
primitive-only graph with no helper definitions. The owner itself joins the
definition-time snapshot and entry guard. Unknown/effectful bodies keep ordinary
emission. Failed scalar/descriptor guards use the original generic successor
body, rather than the previously optimized Nat loop.

The remaining distinction is actual invocation. Optimize only when the runtime
enters the successor callback through apply's **exact saturation** branch. That
branch returns immediately after the callback; it has no later length or arity
reads that a whole loop could overtake. Partial, oversaturated and raw callback
invocations keep the generic body. A callback merely running somewhere beneath
force is not sufficient evidence.

Use a private runtime entry record tied to both callback identity and argument
vector identity. A registered anonymous code wrapper consumes the record at its
first instruction, before any vector getter can reenter the same callback. It
passes the resulting private Boolean to the compiler's inner implementation.
The inner implementation reads the original slots once. If all guards succeed,
it loops; otherwise it binds the ordinary source variables to those captured
slots and emits the original tail expression. No raw caller can forge or reuse
the private permission by passing an extra argument.

In exact apply, read code once at the original point. An unregistered code uses
the original `.call(env,args)` path. A registered ordinary function may receive
an entry record only after getter-free verification of its ordinary callable
prototype and unchanged Function.prototype.call. Preserve the original `.call`
then environment evaluation order. A scoped record is installed only after
environment evaluation, and restored with finally even when code throws.
Oversaturation is untouched. Standard intrinsic behavior remains the existing
backend assumption; no public descriptor fields or flags are added.

Capture the owner matcher at definition construction, and guard its own G data
binding plus original arity/code/env/bound just like helper descriptors. This
rejects self replacement, metadata accessors and code changes before entry.
Purity then establishes that no admitted operation can change those bindings
during the optimized loop.

Validation must reproduce all five earlier failures and compare against the
pre-worker compiler, test exact versus overapplication, raw borrowed callbacks,
same-vector reentrancy, environment and `.call` hooks, saved partials, owner
replacement and throwing guards. Then repeat the actual checked scalar fixtures,
existing worker controls, broad integration and clean performance comparison.
The cost of the new runtime dispatch branch and entry record must be measured
on unrelated workloads. Preserve attempt03 and the failed counterexamples.

## Raw host TypeError wording boundary

Before attempt04, direct runtime controls found one identifier-only diagnostic
difference on a malformed callback whose `.call` getter returns `null`. Capturing
the callback once changes the engine's message from `f.code.call is not a function`
to `code.call is not a function`; getter order and `TypeError` class agree. Retain
the raw comparison and its `pass: false` status. The experimental candidate may
proceed to further evaluation while this boundary receives an independent scope
decision. Do not normalize messages or add allocations to every normal invocation
to hide the difference. Any future preserving fallback must retain the single
callback read, `.call`-before-environment order and unregistered Proxy behavior.
