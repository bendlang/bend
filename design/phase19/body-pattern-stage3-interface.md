# Stage3 interface refinement

Root approved the ordinary-local slice in body-pattern-checkpoints.md and asked
that temporary parser stages share a result type. This addendum freezes that
choice before controls or source.

Rename the private FNamesResult union to `FContextSyntax`, with
`FContextParsed{term,rest}`, `FContextError{error,rest}` and
`FContextUnsupported{feature,rest}`. Rename the private expression export to
`f_context_term(input,seed)` and add `f_context_body_syntax(input,seed,outer)`.
There are no aliases for the old experimental name. The new snapshot's tests
explicitly bind the renamed API and union. The entry defines whether success
contains a names-stage expression or a scoped Body; neither entry returns Core.
Stage1's distinct fixed state-observation protocol remains a test-only root.
All public raw parser/loader exports retain their names, stages and behavior.

Freeze a new ordinary-local oracle before implementation. Pinned parse_tele
supplies parameters/next and parse_body supplies the actual body, final state or
selected error. The same fixtures run against the predecessor's raw f_body as
an independently retained baseline. Include both computed-pattern/continuation
orders, a bad RHS, valid locals and shadow restoration, successive locals,
empty-call eligibility, constructor-spelled binders, underscore, and ambiguity
which first arises at the pattern checkpoint even though a dotted bound name
skipped parse_var's alias lookup. Unsupported owners are explicit controls.

The pattern checkpoint's cursor is the real cursor after RHS whitespace and an
optional consumed semicolon. Its alias diagnostic uses that cursor, while a
constructor/computed-pattern diagnostic uses the original pattern range. An
error may fall between tokens (after a semicolon/name and before whitespace).
Preserve that authoritative producer cursor using the existing synthetic point
token technique already used by fpe_word, only in a returned Error rest. Do not
change the lexer, guess from rendered diagnostics, or put a point token into a
successful parser stream. Add whitespace/semicolon controls for this boundary.

The shared Var eligibility helper accepts the original written node and the
already selected constructor record. Its canonical lookup occurs at the pattern
owner, before allocating the new binder. The computed-pattern helper accepts an
already materialized observation. Existing raw validation still supplies its
legacy scoped observation; contextual parsing uses the existing freshener with
one FName fallback leaf. No second recursive validator or scoper is introduced
for this first Var/computed-pattern slice. Constructor syntax remains explicitly
unsupported until the reviewed recursive-pattern extension.

Keep newline tokens available to the body owner inside the grammar. The private
result boundary may normalize trailing whitespace for its observable returned
cursor, but f_grow must not erase the newline before f_statement decides whether
a following name starts a parallel binding. This reuses the existing token list
and does not add a second mutable cursor or a line-position inference.
