# Next scalar coverage, grounded in saved outputs

Static investigation after checked attempt08, before any new implementation or
timing. Compare the saved Phase29 `transfer-04` outputs with Phase30
`transfer-08`, and reuse the checked definition summaries in
`inspection-region-coverage-01` and `inspection-region-coverage-02`. The latter
explicitly identifies the previously documented typed raytrace wrapper. These
are site counts and semantic constraints, not estimates of runtime contribution.

## What the correction removed

Across the ten original-program outputs, Phase29 emits private Nat loops only in
Mandelbrot `mit` and symbolic regression `climb`. Attempt08 retains `mit` as a
guarded pure region; `climb` is generic. The other eight outputs have no such
site in either image. Raytrace did not lose a loop.

The lost `climb` site is a deliberate consequence of correcting the old worker's
scheduling and live-binding defects. Its signature is scalar, but its body calls
`cand`, obtains a `Sel` record, and invokes public projections and helpers. It
cannot safely inherit the old purity assumption. Restoring this site requires a
different transfer proof, not merely widening the scalar type list.

Comparison identities:

| Program | Phase29 output SHA-256 | Attempt08 output SHA-256 |
| --- | --- | --- |
| symreg | `d252d573449d06ab88d88243c0a18b237e3643de94b4cbd75141086b9f57661e` | `439cb0ecd6781d6a44a9001d8624e25a1e550c35e05a8b20dcdfe16652366973` |
| raytrace | `52a93a16fe13e01b7e6cbce350d0f22d7fe0c7581ed649482a5002bfa7d3454c` | `fc22762988a5f28ffced35a47abc124d5716061e8a737caeabc8d10fe8b360a5` |

## First: native F32 in closed ordinary scalar roots

Pair F32 admission with the separately investigated ordinary leading-lambda root
rule. F32 alone enables **zero additional Nat-loop entries** in attempt08. With
that root rule, raytrace contains eight plausible closed roots:

| Full leading-lambda root | Public emitted arity |
| --- | ---: |
| `fl` | 2 |
| `isect.t` | 1 |
| `isect.go` | 2 |
| `isect5` | 10 |
| `fmax0` | 1 |
| `shade` | 3 |
| `clamp01.hi` | 1 |
| `clamp01` | 1 |

Their closure contains five more scalar definitions: `isect.t2`, `isect.go2`,
`fmax0.go`, `clamp01.hi.go`, and `clamp01.go`. These have a residual Boolean
parameter match, so their public leading arity is shorter than their checked
telescope. They are private helper candidates through existing Boolean `JIf`
lowering, rather than eight-plus-five independently eligible public roots.
The total closure therefore contains thirteen distinct definitions. `fl` has no
ordinary helper call to remove, so it is coverage evidence rather than a
promising standalone performance target.

The changes should reuse native identity/type checks, primitive emission,
private scalar calls, Boolean lowering, exact entry and the existing closure
guard. Admit native F32 types/literals and reuse the current F32 input predicate.
Do not reassociate arithmetic, remove `Math.fround`, fold NaNs, change signed
zero, or bypass native primitive semantics. Preserve all existing refusal gates.
No new IR, control-flow representation or runtime helper is necessary.

Start with generated-JS copies of `isect5` and `clamp01`; they exercise different
closed chains and the existing Boolean lowering. Verify finite values, negative
zero, NaN, infinities, smallest subnormals and halfway rounding cases against the
unchanged output. Guard failures must preserve traces for boxed Numbers,
coercion objects, scalar proxies, descriptor replacements and primitive prototype
hooks. Include raw callbacks, saved partials, enclosing overapplication and
argument getters. Keep standalone helper timings separate from original raytrace
transfer: scalar helpers can remain a small share of the complete program.

This is the smallest new semantic extension after the ordinary-root mechanism
survives its own controls and measurement. Coverage alone does not predict a
speedup or justify installing it.

## Second: a measured generic-body transfer, without a purity claim

`climb` is one proven lost site, with four scalar state parameters and an exact
self call on the predecessor. Retain all body calls, projections and let order.
The following is a conservative first generated-JS ablation; it is not a compiler
implementation proposal until a benefit survives controls and timing.

Its recursive tail is curried. The original order is approximately:

```js
const selected = callOwned(get(G, "climb"), [p]);
const nextBs = callOwned(get(G, "sel"), [w, bs, callOwned(get(G, "Sel.seed"), [cn])]);
const withBs = callOwned(selected, [nextBs]);
const nextBf = callOwned(get(G, "sel"), [w, bf, ff]);
const withBf = callOwned(withBs, [nextBf]);
return jump(withBf, [pts]);
```

Capturing the root lookup, evaluating all arguments, and falling back to
`jump(root, allArguments)` is invalid: replaced roots can observe execution before
either `sel`, and the earlier partial application precedes the second `sel`.

For the first ablation, retain all those prefix applications and argument
evaluations. Enter the private loop only from the registered exact callback, with
scalar entry slots. Capture the root at its original lookup point; a side-effect
free guard can identify the original owner before executing its prefix. Only a
positive primitive Nat predecessor and the original successor selection are
eligible. Preserve that fresh selected callback's identity. After the original
prefixes and next arguments, inspect the final selected continuation's ordinary
data metadata, its expected callback identity, scalar slots and prototype
boundary. On failure return the original `jump(withBf, [pts])`. Never reconstruct
the tail from a later root lookup or an aggregate argument vector.

On success, bypass only the final bounce/application and enter the already
selected successor body locally. A root mutation during an argument must not
replace that selected body; it applies to the next recursive root lookup. It is
acceptable for a conservative late owner guard to choose generic fallback in
that case, provided fallback uses `withBf`. Keep the terminal Zero selection and
call generic in this first variant. Keep malformed host state on the generic
path. Stable host intrinsics are the existing experiment contract; public
descriptor/prototype hooks still need the ordinary fallback.

This retains most prefix overhead and introduces a guard per iteration. It may
lose, like the measured live-binding record-loop experiment. That result would
be useful evidence against a broad effectful-loop compiler extension. Eliding
the prefixes is a separate ablation with a larger scheduling proof, not an
automatic follow-up.

Required controls include the five retained pre-worker scheduling witnesses;
root getter/replacement/accessor metadata; mutations during each argument;
partial selection before later arguments; changes to `code.call` and primitive
prototype hooks; raw invocation; outer overapplication with changing or throwing
`copied.length`; boxed or coercive next state; and deep countdown stack behavior.
Compare with the corrected pre-worker emitter, never the old eager Phase29 loop
as the semantic oracle. Measure a small unchanged `climb` workload and original
symreg separately; candidate generation and expression evaluation can dominate.

## Third: finite Nat selectors, then residual Boolean loop columns

Raytrace has five finite Nat-to-F32 selectors: `sx`, `sy`, `sz`, `sr`, `skr`.
Each distinguishes 0 through 7 and an `8 + predecessor` default whose predecessor
is unused. Their leaves are scalar expressions and calls to `fl`. The four scene
geometry selectors are required to close `nearest` and `nearest.t` around
`isect5`; `skr` participates later in tracing.

Neither existing two-arm countdown recognition nor Boolean private lowering
directly admits these finite Nat trees. A bounded native-Nat decision lowering
can reuse checked case structure, original primitive BigInt representation and
the existing helper graph budgets, but is a new admission case. Do not encode
predecessor offsets in unrelated slot fields or normalize emitter-only nodes.
Begin with a single selector and require exact checks at 0–9, larger bounded
Nats, raw malformed inputs, live helper replacement, and default-case arithmetic.

Closing the selectors still does not enable either nearest loop: both have a
residual Boolean parameter match after their leading lambda prefix, with a
self-tail call in each arm. That requires preserving/analyzing both branches
under shared state and budgets. `nearest.t` returns F32 and is the smaller next
loop. `nearest` returns `Hit`; its terminal fields include comparisons, so the
initial variable/literal-only terminal-record admission also refuses it.

Further raytrace roots remain outside this proposal: `trace` carries a `Hit`
record, `pixel` calls `F32.to_u32` (absent from the current primitive whitelist),
and `colf`/`rowf` fork recursively. Count these blockers explicitly; adding F32
does not turn the complete raytracer into one private scalar region.

Prefer the first extension for minimal conceptual cost. Treat the second as a
bounded attribution probe, and the third as a staged opportunity only after
helper-level evidence shows enough value. No speed estimate follows from these
static site counts.
