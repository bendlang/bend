# Stage4 result and regression contract

The private complete-block entry returns scoped LTerm syntax, not final Core.
Its successful semantics are compared modulo alpha-renaming of generated bound
identifiers. Preserve complete raw candidate graphs and pinned LTerm graphs.
Header IDs, lexical environment, source spans, cursor and next counter remain
exact observations. The existing ff_fields reserves IDs at 2^31+next for generated
fields, whereas pinned flattening uses next directly. No counter is fabricated
and no extra production traversal is introduced to match those numbers.

The positive nested-field fallthrough fixture must retain a generated field
binder and its use in the final graph. A simple nested pattern that completely
consumes its synthetic field is insufficient evidence. Record both numeric IDs;
check binder/use links with an independent lexical walk on the retained graph,
keeping free identities fixed. Ordinary lexical IDs in these actual-source
seeds and test bodies are below 2^31. Generated IDs must be disjoint from all
ordinary binders and the subsequent fresh interval, with their `_next` spelling
and returned next counter agreeing with the pinned event. State this bounded
precondition rather than claiming an unbounded U32 allocation proof. Do not
normalize a free/captured variable into a Ref and call that alpha-equivalence.

The actual complete-block term has no free lexical variables after its opened
header binders are represented or consumed; unbound ordinary source names carry
FName's explicit canonical Ref alternative. The test converter consumes that
alternative deliberately at the value boundary, without invoking the Bend
freshener first. A Var without an enclosing binder is a test failure. Then pinned
term_higher/term_lower canonicalizes only the already validated binding graph;
compare every constructor, occurrence span, name, quantity and resulting binder
relationship. The raw graph is retained beside this canonical observation.
FComputedHead must be absent from every successful complete-block graph.

The Stage3 body40 and Stage2 names46 controls stay byte-for-byte unchanged. Their
pinned oracles already recorded all outcomes, including the previously excluded
owners. Four body controls become admitted: match, constructor local, grouped
local, and grouped RHS before later alias error. Four names controls become
admitted: group, constructor, literal, and nested group. New probe versions must
compare these against the existing pinned outcomes; the old Unsupported label
is a stage-domain assertion, not a language expectation. Every other old admitted
control keeps its exact expectation. Remaining excluded owners must still return
Unsupported and are never counted as conformance. Body-level Match head syntax
comparison omits only the pinned ordinary unbound Var's fallback Ref, because
that match-only occurrence is explicitly the syntax view; retain actual ID/span.
No value occurrence or free identity is erased by this projection.

The shared parser first-element correction is independently extractable. Pinned
parse_terms always parses its first expression before accepting ':' or taking
an optional comma. Both f_match_heads and f_case_pats must reject ':' or ',' when
the accumulator is empty. The frozen boundaries include zero heads, zero row
patterns, leading head/pattern commas, and a valid bound head with no rows. Keep
this two-expression declaration patch separate from the private contextual route
so production adoption can be validated independently.
