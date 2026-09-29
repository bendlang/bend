# Phase16: one pinned JSON encoding for template identity and growth

The literal prototype restores missing value identity, but exposes the old size
approximation:10/20 frozen literal-size boundary observations disagree with the
pinned32768UTF16 limit. Repeated F32.neg applications also retain the inherited
source-token-ID memo duplication. The prior grow_double experiment rejected a
shorter custom encoding because it moved the first refusal from grow~9 to grow~10.

Use one canonical JSON string matching pinned
`term_key(term_lower(argument))`. It supplies both memo identity and the existing
32768 guard, including one newline between multiple arguments. Do not keep a
second shorter memo serialization or a differently approximated count. Reuse the
existing UTF16 width helper for the completed JSON text; escaped control
characters count as their ASCII escape bytes, astral characters as two code units.
The comparator limit and depth64 limit remain unchanged.

A dedicated Lambda variant carries explicit optional-quantity presence, owned by
the representation agent. This is necessary: the checked literal05 source maps
`&x:Type -> Type` and `Exists(Type, x => Type)` to identical Lambda nodes while the
pinned keys differ by17units. Core ordinary fields and quantity meanings remain
unchanged. The encoder consumes `k_quantity_present(t)` and never guesses presence
from names, ranges or quantities.

The encoder owns only the memo helpers and guard in check/specialize.bend. It
preserves pinned field order, names, optional Ref offload flag, ADT removed
constructors, quantities, interpreted literals, and optional Lambda quantity.
It uses the existing KPName environment to map globally fresh binder IDs to
lexical indices and binder names just as term_lower opens binders. Renamed
lambda binders remain different keys; same-spelling terms at different source
positions share keys. No normalization beyond the pinned force/substitution
boundary is introduced. Variable value cells expose their value; annotations
remain explicit. Parallel let values use the outer environment and the body uses
all new binders together. There is one semantic constructor visitor covering the
pinned TermOf alternatives, plus small JSON/string/list helpers, replacing the old
length-prefixed key visitor. Invalid internal-only tags cannot arise after the
existing closed-argument check; explicit defensive handling must not silently
merge them.

JSON quoting is separate from JS source quoting: JSON.stringify uses short
escapes for backspace/tab/newline/formfeed/return, escapes other controls as
\\u00xx, and does not use the JS-only\\x00 spelling. Scalar strings preserve raw
astral characters; surrogate code units must use canonical\\uXXXX if reachable
through a direct API. Literal F32 values are unsigned bits, so positive/negative
zero remain distinct. The source language spells numeric negation F32.neg rather
than a negative literal token; the rejected ~(-0.0) fixture is retained as an
invalid preliminary control.

Freeze an isolated union after the Lambda transport candidate is genuinely
checked. Validate exact key bytes for all semantic constructors, both Lambda
presence states, lexical/shadowed/parallel-let binders, flags, quantities,
literal kinds, Unicode/control quoting and argument separators. Re-run the saved
key controls and actual pinned instance counts, exact grow/grow_double boundaries,
all20size controls, original checker55+84 selection where applicable, literal176,
maintained36, backend41, and root full frontend before promotion. Keep chronology
and unsupported cases explicit; changing key identity is not a replacement for
on-demand checker specialization. Measure source growth and whole-host cost in
separate controlled gates.

## Direct factory boundary

Pinned source parsing writes reference offload `b` only as absent or `true`
(`parse_term_call`, bend.ts:2028); structural reconstruction propagates that
value. The Bend core likewise represents the parsed absent/true alternatives,
and the direct suite checks both. The exported TypeScript `Ref` factory can also
construct an explicit `false` property, whose JSON retains that property; no
source parser or checked-language producer creates it. This artificial factory
state is outside the parsed-source memo equivalence claim. We will not invent
an overloaded quantity encoding for it. Negative free-variable sentinel `-1`,
all five short JSON escapes, NUL, U+001F, valid astral text, and isolated high/low
surrogate direct strings are explicit encoder boundary controls.
