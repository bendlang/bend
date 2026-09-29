# R1 typed annotation cursor supplement

Source01 failed origin review despite complete nonrange graph equality: grouped
typed local Ann lost its inherited range. Before the root chooses a repair,
record actual pinned Ann start/end and complete raw/lowered parent graphs for
bare, grouped, nested-grouped, erased and marked binders; simple, grouped and
local-bodied RHS terms; spaces, comments, newlines and astral source prefixes.
Keep the typed constructor rejection as a negative neighbor.

Pin parse_body saves beg before the first expression, after its erased-marker
handling. parse_term_ops skips trailing whitespace/comments before returning,
so parse_span after parsing RHS includes that returned cursor. Neither the
semantic binder's own range nor the semantic RHS range is assumed to recover
these consumed source boundaries. In particular parentheses can already have
been erased from those child origins. This is a producer/cursor question; no
source search, guessed extent, new origin traversal or pattern classifier.

Use the unchanged frozen group-range-structure-run.mjs and retain full small
graphs and pinned terms, then enumerate actual coordinate differences. Existing
source01 and its rejection report remain immutable. This supplement permits no
compiler source edits by the structural reviewer.
