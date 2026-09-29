# R1 correction: locate the generated typed annotation at its producer

The first R1 candidate is withheld. It improves the saved196 suite by three
exact observations and the independent68 by16, without changing their primitive
outcomes. However, assigning an existing range to `Local` makes `f_locate` skip
`f_span_created`. The previously synthetic typed-local `Ann` then stays at0/0.
Its original whole-group range was also inaccurate, but deleting it is not an
acceptable way to select the local-binder correction. Preserve source01/build01
and its complete graph reports unchanged.

Pinned `parse_body` records `beg` before the first pattern expression, and builds
`Ann(parse_term(p), T, parse_span(p, beg))`. `parse_term_ops` skips whitespace
and comments before returning. Therefore the exact annotation range starts at
the body cursor and ends at the returned, spaced cursor before the semicolon or
next body token. The RHS term's own range cannot supply either endpoint in
general: a completed group retains the inner term's origin, and a parenthesized
binder has an origin after the original body cursor.

## Candidate02

Keep R1's successful-Local range correction. Pass the existing body start from
`f_body_at` through `f_statement` and `f_typed_let_try` to `f_let_ann`. The erased
local route already has the original start and passes that same value. Add a
single U32 parameter to each of those three existing workers; update their
existing signatures/laws and sole relevant calls. Do not add a worker or type.

Construct the existing `Ann` using `kt_span` with that explicit start and
`f_begin(f_space(ts))` from the returned RHS parser cursor. This reuses the
existing whitespace worker and indexed token positions; no source search,
pattern classifier, scope change, subtree traversal or host change is needed.
Unindexed tokens preserve0/0. Existing branch choices and child-error demand
remain unchanged. No parallel-binding or comma change belongs to this candidate.

Freeze independent exact-coordinate controls before preparing source02. They
must include a bare and parenthesized binder, erased/marked cases, grouped RHS,
spaces/comments/newlines before the boundary and astral UTF16 offsets. Compare
the new raw and lowered annotation endpoints to actual pinned terms, including
the original binder and RHS child ranges. Preserve any invalid fixture's actual
outcome; do not silently replace its expected oracle.

Repeat the unchanged maintained36 and independent68 controls, the original102
structural observations, and saved196. Apart from justified origin changes,
complete graphs and behavior remain strict. Proceed to the main2996, actual
execution and exclusive cost screen only if this bounded producer correction
passes independent review. Stop if another semantic traversal or pattern
eligibility rule becomes necessary. Count actual lines and bytes from source02.
