# Source spans and module display

Follow-up to `source-spans-instrumentation.md`. Independent nested-note controls
now locate the exact inner binder, but expose a presentation difference: pinned
`book_load` empties leading import lines before parsing a module, while retaining
each newline. Import-discovery errors instead refer to the original file text.

Keep numeric ranges bound to immutable original source bytes. Compute the target
line, indentation and caret width using those raw coordinates. For checker
module diagnostics, pass an import-elided line view to the existing snippet line
renderer: preserve blank/comment lines, replace each leading import line with an
empty string, and stop at the first other line. No source-offset translation,
new span variant, term matching or normal-path collection is needed.

The generic `dg_snippet` and raw parser/import diagnostic paths remain unchanged.
Parser-body module presentation needs its own explicit call boundary; changing
`f_parse_indexed` error strings implicitly would violate the currently checked
raw/legacy invariance contract. This follow-up initially covers checker output.

Check the existing nested-note witness, a leading import immediately adjacent to
a failing declaration, comments/blank lines between imports, a valid imported
module failure, and a foreign import inside a declaration which must remain
visible. Preserve the first malformed imported-origin fixture and its observed
parse refusal; fixture set02 supplies the corrected import syntax.
