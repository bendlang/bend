# Independent review of the decorator diagnostic checkpoint

No promotion blocker was found in Phase20 source01. This was a read-only review;
no compiler source was edited and no new compiler or probe process was run.
The scope is the two existing pending-`@unsafe` failure expressions in
`front/declarations.bend`, not the separate import-after-type investigation.

The diff replaces `f_err` with the existing `fpe_error` constructor and supplies
the pinned expectation. It adds 92 bytes, zero physical lines and no definitions,
laws or types. The checked attempt is `import-diagnostic-build-01`; its guarded
API is `23c891e30fcd02e373e5257e74d3c9fc3bba4fdd5b2ad60807648d06eb3a9fd4`.
The accompanying JSON binds the source diff, genuine checked API/bootstrap record,
derived API, attempt, pin and reviewed evidence.

The current token cursor is the right diagnostic site. `f_tops` already skips
line breaks before `f_top`, while pinned `parse_word("def")` skips whitespace and
comments before failing. `fpe_error` retains the existing token line and codepoint
column; the shared renderer converts the source traversal to a UTF16 offset.
The EOF branch uses the existing source-end scan. No new coordinate conversion,
range owner or message parser is introduced.

Inspection of the actual generated `f_top` and `f_import_leading` confirms that
the structured-error call remains inside the selected failure closure. Successful
branches perform the same work as before. There is no new source or dependency
read, parse traversal or successful-path error allocation. This is a source and
generated-code demand observation, not a measured performance result.

The frozen twelve fixtures produce 24 strict exact supplied/host comparisons,
up from four exact baseline observations. They cover EOF with and without a final
newline, repeated decorators, law/type/import tokens, comments including an
astral character, a valid unsafe definition, and both dependency-order directions.
The real host read logs show that no import after the decorator is opened and
that a failing prior dependency still wins. The unchanged supplied39 and ordered
host43 reports are complete and passing with empty `strictDifferences` lists.

Two limits remain explicit. First, the `f_import_leading` unsafe fallback is
unreachable through the normal `f_top` guard; its equivalent correction was
reviewed by inspection, not exercised as a separate public route. Second, the
astral-comment fixture proves offsets before an ASCII error token. The existing
`fpe_here` deliberately preserves the legacy fallback when the offending cursor
itself contains an astral character or surrogate. This change does not close that
inherited Unicode diagnostic limitation. Decorator grammar, import-after-type,
and general parser conformance remain outside this review.
