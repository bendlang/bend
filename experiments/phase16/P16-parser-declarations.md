# P16 parser declaration eligibility

Prospective design: design/phase16/parser_declarations.md.
Baseline: immutable selfhost/build/phase16/wave4-source-02/project.
Candidate namespace: parser-declaration-source-* and parser-declaration-checked-*.
Resources: CPU3 correctness only, one child job; no timing.

Target4 fixtures/8 observations: comptime/err_dup.bend,
parse/foreign_refill.bend, parse/def_untyped_refused.bend,
parse/law_fill_arrow.bend. Expected outcome: unchanged rejection/phase/trust,
exact pinned diagnostic message and cursor. Reserved U32/import duplicates are
explicitly outside claimed gains; no keyword hard-coding or oracle edits.

Controls must cover error priority before a malformed repeated telescope,
open-law fill success versus subsequent repeat, foreign fill closure, missing
arrow cursor, real keyword rejection and fresh ordinary U32 without Base.
A single visible-book lookup moves to the header worker; existing parser fill
validation retains order. Preserve every failed candidate. Root owns full gate.

Direct injected-book controls include a native=True open-looking declaration.
The baseline raw parser may incorrectly fill it; the candidate must match the
pinned rejection. Record such direct acceptance corrections explicitly rather
than assuming baseline semantics are the oracle. Ordinary corpus axes are still
required unchanged. Successful control trees must remain metadata-erased equal.
