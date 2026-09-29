# Phase16 import diagnostics

The integration04 full vector leaves seven import-specific fixtures (14 parse /
check observations): alias_decl, alias_shadow, alias_twice, c_suffix_module,
parent_segments, suffix_refused, and reg/import_head. Global duplicate declarations
belong to the parser owner's separate declaration-freshness work. Namespace display
inside checker terms belongs to the checker owner.

Pinned `book_load` preserves the complete trimmed import line for malformed and
repeated-alias errors, but uses the path text for extension/path errors. The marker
is a point at the matched path, or the import keyword when the header does not
match its grammar. The current token parser discards the line/expectation in those
branches. Preserve explicit error data and select the original line only while
rendering a failed header; do not reconstruct whitespace/comments from tokens.
The existing shared snippet renderer continues to display original source for
header errors. Body errors use the existing import-elided module view.

Alias ambiguity has a separate cause: `f_alias_named` knows the conflicting alias
and term but discards both in a string Error. Its explicit source cursor is the
term end (the pinned resolver checks after consuming the name or relevant form).
Carry that point and a request to observe the source character at that point;
do not search the source for another occurrence of the name. Keep the existing
loaded-scope condition and traversal order.

The raw parser cannot know whether an alias-qualified declaration names an
unfinished imported law until dependencies are loaded. Initially preserve this
boundary explicitly. Thread the existing name-token list through `f_def` and
`f_def_prior`, without adding a declaration field or allocating a second name
object, so the selected alias-name refusal can retain the precise name range.
A normal imported-law fill must remain accepted. An annotated imported-law fill
is also refused by upstream, but at the colon expectation after its telescope;
it must remain a distinct control rather than being mislabeled an alias-freshness
case. If correcting this requires dependency-stage deferral, freeze that extension
before implementing it and retain any intermediate strict difference.

Production ownership is limited to import branches in front/declarations.bend,
front/validate.bend, load/imports.bend and load/graph.bend, plus explicit failure
payload rendering in front/parser.bend. Coordinate exact hunks with the parser
owner; they own all other declaration freshness / semantic parser changes. Start
from immutable integration04, and publish patches rather than copying whole
modules over later owner changes. KTerm/source/cache ABIs stay unchanged.

Before selection require genuine checked B1, unchanged optimized helper guards,
all maintained focused cases, all 14 original observations retained, and direct
raw/indexed header controls with comments, multiple spaces, tabs, CRLF, EOF,
malformed aliases, extra tokens, extension-before-path/duplicate precedence and
repeated aliases. Independent full-loader controls include ordinary imported-law
fills, forbidden annotated fills, alias-qualified declarations and ambiguities,
with first-error ordering preserved. Check numeric source ranges and raw parser
APIs. No speed conclusion comes from concurrent correctness runs; root owns the
exclusive timing windows and final full frontend gate.
