# Phase16: source-independent template memo identity

Prospective bounded correction after the separate per-template ordinal wave.
The six frozen direct controls in `checker-name-direct-03` complete: source04
has two exact instance-name sets, source05 has five. Repeating the same `Zero{}`
argument at a different text position still creates an extra instance in both.
The paired `prior-repeated-instance` diagnostic reports `bad~2` where pinned
TypeScript reports `bad~1`. This is an inherited identity bug exposed by the
required negative control, not a new numbering regression.

## Cause and exact upstream contract

`term_key` currently serializes all KTerm fields, including `ix`. Ref/ADT/Ctr
nodes use that field for lexer position, whereas Var/All/Lam/Bind use it for
binding identity. The same source expression at two positions therefore misses
the memo. Globally fresh binder IDs likewise distinguish repeated lambdas.
`norm_exact` intentionally compares these raw fields and is unsuitable as the
memo equivalence relation; do not weaken normalization or diagnostic identity.

Pinned `term_key` is JSON of `term_lower`, excluding `s`. `term_lower` rebases
bound IDs to lexical depth, retains binder names, and does not normalize terms
by definitional equality. Consequently `(n => n)` at two positions shares an
instance, while the alpha-equivalent `(m => m)` remains a distinct key because
its spelling differs. The controls must preserve that distinction. Source
ranges, file names, lexer offsets and globally allocated binder numbers must
not determine identity.

## Small candidate, preserving unknown data

Retain the existing unambiguous length-prefixed serialization and size guard.
Add a scoped key worker with the existing core readback binding environment
(KPName) and an explicit lexical depth. The public local `term_key` starts with
an empty environment at depth zero; every closed argument resets independently.

- Rebase Var through the environment; an unknown/free ID remains unchanged.
- Serialize Lam/All binder IDs as the current depth. All domains use the outer
  environment, bodies use the newly bound environment.
- Handle parallel Let bindings explicitly: each value uses the same outer
  environment/depth; only the body sees all freshly numbered binders.
- Zero only known source-position IDs on Ref, ADT, Ctr and residual Literal.
  Preserve tag, name, quantity, children and removed-constructor lists. Other
  IDs remain conservative until their semantics are established.
- Never read begin/end range fields. Never mutate the term, book, semantic
  checker or normalizer. Reuse existing memo, first-error handling and ordinal.

This removes false distinctions; it does not broaden memoization to arbitrary
beta/eta or alpha equivalence. Numeric/character/string payloads and quantities
must remain distinct. In this core LitNat stores its value in `qt`, and U32/F32
payloads are constructor word trees; their children and quantities are retained.
Future or backend-only tags retain their IDs rather than being silently erased.

The current key encoding is not byte-identical to TypeScript JSON, and older
literal lowering already erases some spelling distinctions. Those are inherited
boundaries, not claims fixed by this candidate. The existing key-size and depth
growth controls must retain the pinned first refusal; if they change, preserve
the attempt and investigate the boundary before promotion. A complete upstream
JSON encoder or a new literal-origin representation is outside this bounded edit.

## Frozen controls and gates

Before execution, extend direct materialized-name controls with repeated same
spelling lambdas at different positions, differently named alpha-equivalent
lambdas, nested shadowing/outer capture, repeated parallel-let bodies, different
constructor/Nat/U32 values, and different lambda quantities. Reuse two templates,
interleaved ordinals, nested calls, decreasing recursive memo reuse, erased
calls, active cross-instance cycles, depth growth and key growth. Where the
parser/checker cannot reach a semantic witness, keep that setup failure and
replace it prospectively rather than weakening its assertion.

Run genuine checked B1, 36 maintained cases, previous 84 paired observations,
all original naming controls, and the extended direct controls against baseline,
ordinal-only source05 and the key candidate. Inspect actual instance-name sets,
not just successful final output. Require zero lost strict rows and no unexpected
primitive changes. Record duplicate-instance reduction as an operation count;
root owns whole-host time/RSS comparison. New source must be isolated source06;
source05 and every earlier artifact remain immutable.
