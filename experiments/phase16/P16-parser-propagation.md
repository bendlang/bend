# P16 parser propagation — stage 2 prospective supplement

Frozen before parser-source-02 is built or probed. Stage1 source and all attempts
remain immutable. Stage2 starts from its accepted range implementation.

Hypothesis: parser failures already carry the required cursor, but continuations
discard them. Use two explicit continuations for expression/body parsing after
`f_expect`; preserve an earlier error node. General punctuation expectations use
the existing structured error producer. Match pinned parser sequencing for
parallel-let `=`, failed speculative typed-let annotation, the opening matcher
brace, and trailing computed marker. End-of-input locations are rendered from
the original source only when an explicit `<eof>` parser token has no position.
The first observed UTF16 unit is produced for supplementary and surrogate point
errors, matching TypeScript's string indexing. Successful tokenization/term ABI
is unchanged.

Files: front/parser.bend, declarations.bend, parallel.bend, validate.bend. No
lexer/type-layout/host/checker/render edits. No parsing of legacy error strings.
The narrow semantic risk is changed earlier-error choice, so direct competing
errors and all122 paired parser fixtures are required. The inherited EOF, Unicode
and parallel-binding direct witnesses must improve exactly without losing any
existing exact control. Genuine checked build and36 focused controls precede
the direct and census comparisons. Root full-corpus integration is still needed
to rule out losses outside this selection.

Any new acceptance difference or unsupported normal-path effect rejects the
candidate; preserve the full failed attempt before correction. No timing claim.
