# P15-002: parser caret rendering

Prospective plan under the [phase design](../../design/phase15/parser_conformance_and_speed.md).
Hypothesis: one shared renderer can correct the missing parser caret row in up to
66fixtures/132observations while preserving parsing/error order. The132figure is
an opportunity ceiling, not a promised pass count. Use existing token/source
coordinates; do not guess a span or alter the exact oracle.

Inspect checker renderer reuse and pinned parser/error contracts before edits.
Freeze direct Unicode/tab/EOF/multiline/token-width and precedence controls. Build
a genuine checked B1, run26focused cases and the strict target family. Separate
remaining origin errors from rendering. Count removed/added code and concepts.
Owner: caret agent, isolated carets-* work, CPU1 after exclusive profiling. Root
composes overlapping parser hunks and validates/promotes the combined compiler.
