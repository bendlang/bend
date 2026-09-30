# Prospective ablation: exact constructor arms through the existing helper

Agent-generated2026-09-30, before candidate derivation or compiler change.
The existing `matcher1p(name,count,arity,make)` runtime helper already handles
exact copied-field saturation, short and long copied vectors, and mismatched
source vectors. The compiler's `j_arm_sizes` admits only `0 < count < arity`.
This experiment extends the same rule to `count == arity`.

Keep the existing live telescope, literal unlifted lambda, constructor identity,
nonzero field-count and selected single-constructor conditions. Use identical
`j_lambda_code`. Public matcher arity remains1. The original arm descriptor is
no longer allocated on the ordinary exact-size case, and its immediate jump/apply
boundary disappears. Its body can still return a jump/build and is not eagerly
forced beyond the existing boundary. No global lookup or mutable G contract is
changed. Erased/eta-short/lifted/zero-field cases still decline.

First derive an immutable edit-distance row variant replacing only its5cell
record/tuple exact-arm prefixes with matcher1p(name,count,count,make); preserve
all call sites and operations. Compare original/private/identityguard/exactarm
and TS separately, not a combined variant. Independent controls must cover
project/copy/length ordering, zero/short/long vectors, customslice/proxies,
partial/oversaturated results, function-valued fields and escaping closures.
The earlier private prototype's cold-order bug illustrates why the original
arm body must remain unchanged here. Marker or source identity checks ensure
actual selection, not passing through an unchanged fallback.

Use the same frozen row32/seed17 point, screen/confirmation protocols, immutable
oracles and exclusive CPU3 timing as the main design. If profitable, production
requires only widening the count comparison and documenting the admitted case;
run a checked B1 and updated exact-arm controls before broad transfer. Existing
`test-arm` expected refusal for equal arity is a former admission boundary, not
a semantic requirement; preserve historical test bytes and report the expansion.
