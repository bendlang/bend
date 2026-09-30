# A closed F32 chain under one ordinary scalar entry

Freeze before deriving or executing the experiment. This tests F32 profitability
independently of the ordinary-root prototype that contains a nested Nat loop.
Use checked attempt08's original raytrace output:
`selfhost/build/phase30/transfer-08/raytrace/candidate.mjs`, SHA-256
`fc22762988a5f28ffced35a47abc124d5716061e8a737caeabc8d10fe8b360a5`.
No compiler or maintained runtime changes are authorized by this experiment.

## Exactly one public root

Optimize `isect5`, preserving its ten-argument public descriptor, callback slot
read order, partial application behavior and original generic fallback. Its
complete ordinary dependency closure is `isect5`, `isect.go`, `isect.go2`,
`isect.t`, `isect.t2`, and `fl`. The two Boolean decision helpers become private
ternaries; all other private functions preserve their original leading scalar
arguments. No scene selectors, ray loops, record projections, arrays or tracing
functions are changed.

Reuse the ordinary-root entry framing from
`prototype-lambda-region-derive.py`: register a fresh ordinary callback with
`exactCode`; consume permission before reading its argument vector; retain each
original slot read once; require primitive F32 inputs; then guard all six
original descriptors before calling private helpers. Definitions are captured
when constructed, never on first use. The owner is included in the closure.
Missing captures, replaced/accessor descriptors, call hooks and primitive
prototype hooks select the unchanged generic body.

Use the existing input predicate `typeof x === "number" &&
(Math.fround(x) === x || Number.isNaN(x))`. It accepts signed zero, subnormals,
infinities and NaN, and rejects boxed/coercive values without coercing them.
Stable host intrinsics, including Math and reflection functions, remain the
current experiment contract. The runtime's public descriptor/prototype mutation
fallback remains supported within that contract.

Parse only exact saved generated shapes. Copy primitive expressions, IIFE let
bindings, all `Math.fround` calls and comparisons byte for byte. Replace only
saturated calls to the five known helpers. Translate the two complete native
Boolean match pairs to conditional expressions, preserving the chosen branch's
expression and polarity. Assert no generic global call remains in the private
closure. Preserve the ordinary public helper descriptors and all public callback
function shape properties. Do not reassociate arithmetic or specialize the
input coordinates.

## Controls before timing

Build a separate scalar reference for the ray/sphere intersection formula using
explicit per-operation F32 rounding. Compare every output with `Object.is`
semantics (NaN equals NaN; negative zero remains distinct). Cover hit/miss,
tangent and near-epsilon branches; ordinary finite coordinates; subnormals;
signed zero; NaN and infinities; and rounding boundaries. Both unchanged and
derived output must match. A deterministic family of scalar points is preferable
to a single checksum.

Challenge all six live bindings and metadata fields, Proxy replacement,
`code.call`, partials saved before mutation, raw callbacks and constructed
callbacks, outer overapplication, argument getter ordering and same-vector
reentry. Boxed Number, coercive object, throwing coercion and Proxy scalar inputs
must fall back with unchanged value/error/transcript. Include primitive
`request`/`bounce`/`build`/`code` prototype hooks and a getter that mutates a helper
between slot reads and the guard. Preserve failures and exact error messages.
Use independently reviewed entry controls from the ordinary-root utility where
their assumptions match; do not attribute those earlier executions to this new
module.

Also execute the unchanged original raytrace adapter at its previously retained
point and compare with the known result. This establishes transfer correctness,
not a performance gain.

## Measurement

After controls and independent static review, prepare a cheap leaf adapter that
invokes the unmodified public `isect5` with a deterministic scalar input and
returns its complete scalar result. Both variants use the same adapter and input.
Use the standard paired screen and longer-warm confirmation only for this small
point, under the parent's exclusive timing grant.

The original raytrace adapter is a separate transfer measurement. Calibrate its
cost and use the original-program transfer protocol with an explicit small call
budget; never apply a microbenchmark's 100-call minimum blindly. A helper win
does not imply a whole-raytrace win. A guard-per-root loss is a useful reason to
defer F32 production admission until a larger closed region can amortize it.

Retain source/tool/design/output hashes, full oracle and host-boundary receipts,
first-call and warm observations, both timing windows, and the distinction
between generated-JS experimentation and actual checked compiler output.
