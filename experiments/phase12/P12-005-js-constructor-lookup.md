# P12-005 — Reuse checked ADT identity during JS emission

Prospective extension, authorized after P12-004's baseline counter screen.
Owner and baseline are the same as [P12-004](P12-004-known-structure.md).
No lookup candidate or lookup-specific counter probe has run yet.
Outcome: [known_structure.md](../../implementation/phase12/known_structure.md).

## Evidence and hypothesis

The original screen finds 22,272 / 72,384 / 522,000 / 1,991,952 `j_find_ctor`
entries for actual checked Nat patterns at depths 8/16/32/64. JS constructor
emission and lifted-function traversal each hold the checked expected type but
search every definition for the constructor telescope. Pinned `comp.ts` uses
the checked constructor/ADT tables. Phase10 already introduced `j_layout_ctor`
for layout validation, using the normalized ADT's local constructor list and
retaining the general search when that observation is unavailable.

Replace only the three same-shape constructor telescope lookups in
`j_constructor_mode`, `j_constructor_literal` and `j_l_children` with that existing
helper. Keep recognizer-only, lookup-only and combined checked ablations.
No fresh cache, index, IR tag, ownership rule or helper is needed. The candidate
normalizes the expected type for the local lookup; the existing specialization
still receives its arguments. Match-arm lookup is outside this first change.

## Contract and falsifiers

The valid domain is checked annotated source with unique constructor ownership,
complete type context and immutable definitions. Read the existing Phase10
duplicate-constructor/raw-book controls: a forged book whose wrong earlier owner
shares a constructor name can intentionally differ. Preserve that counterexample
instead of claiming arbitrary raw-JS equality. Unknown/non-ADT type shape and
missing local constructor must retain the old general fallback.

Compare exact checked observations, exact generated JS bytes and actual output
for the Nat/String ladder, user-owned constructor names, erased fields, metatype
constructors, aliases and imported ADTs. Retain dynamic-tail open-Array refusal
and actual error order for live versus erased failing fields. Direct controls
compare the original and local constructor selection on valid/fallback books and
record forged-owner differences. If valid output, refusal phase or selected
exports change, stop promotion and retain the failed attempt.

Count constructor-search entries separately from literal recognizers. Use CPU1,
Node24.18.0, 4MiB stack/4GiB heap, 30s small children, fresh files and checked B1
builds. Concurrent counters are mechanism evidence only. Any public JS-emission
timing is a bounded opposite-order screen with exact output guards; it cannot
claim a full-source checking gain. Root owns final integration and exclusive
measurements. Historical P6 scalar-field and broad compact-string proposals stay
deferred in this investigation.
