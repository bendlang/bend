# First-element guard composition

Compose the accepted declaration source02 with only two guards from the independently
checked contextual experiment's first-element-only.patch. Preserve the original
f_match_heads and f_case_pats bodies byte-for-byte inside their wrappers, including
List<FToken>, f_body_context and f_case_body. Do not import FInput, contextual
flattening, parser wrappers or new declarations. On an empty accumulator and an
initial colon/comma, call the existing fpe_error with expectation `a term`.

Use List.is_empty, not a full length traversal. The pinned parse_terms always parses
one term before testing the colon or optional separator. A bound head with zero
rows remains valid; an empty pattern row is a distinct rejection. Preserve normal
multiple terms with optional commas and retain trailing/doubled-comma rejection.

Before source mutation, freeze eighteen independent fixtures: empty head, empty
pattern row, leading head/pattern comma, one head, multiple comma/space/mixed
separators, trailing and doubled head/pattern commas, newline before each empty
colon, head/pattern EOF, a bound head with zero rows, and a comment/newline before
the first head. Compare raw parsing and both supplied/actual ordered-host loading
(54 observations), including complete pinned diagnostics, acceptance and exact
one-file read lists. Frozen baseline strings remain the candidate oracle.

Build source03 as a fresh genuine checked B1. Require default36, decorator24,
constructor raw30/loaded20, original supplied39/host43 and all54 independent first
element observations. Preserve source01/source02 and their reports unchanged.
Root runs broader frontend2996 and original group196 before any installation.
Count the full one-file Phase19 delta honestly; no timing or speedup claim is made.
