# P16 parser origins: prospective staged experiment

Frozen before any compiler probe of this change. Parent is the immutable
`spans-shared-migration-01/project`: parser05 plus checker03, migrated to eight
KTerm fields. The metadata cost experiment already passed the root's guard.

The hypothesis is that actual parse cursors can retain upstream source ranges
without recovering them from binder identifiers, rendered terms, or a second
source scanner. This experiment changes no oracle and intentionally makes no
semantic correction to the Empty desugaring (owned separately by root).

1. Extend FToken with U32 `begin`, `end`, `previousEnd`. Thread an optional
   positive UTF16 cursor through the existing lexer workers. Zero disables
   metadata and preserves the legacy token sequence. Only indexed lexing adds
   a terminal `<eof>` cursor, with historical EOF line/column zero. Newlines
   and comments advance the cursor but do not replace the previous significant
   token end. Preserve all historical text/kind/line/column projections.
2. Add `f_parse_indexed(start, source)` and attach ranges at actual parser
   construction sites through `k_with_span`/`kt_span`. Parentheses preserve an
   existing inner range. Calls and constructors end at their closing token;
   lambda ranges cover their binder; binary ranges follow pinned parse_term_ops
   whitespace consumption; angle datatype ranges stop after the first argument,
   as pinned upstream does. Synthetic split tokens get exact subranges.
3. Compare legacy and indexed results after erasing only origin fields, including
   complete errors, books, imports, EOF and indentation. Compare selected actual
   ranges with pinned TypeScript terms and explicit UTF16 expected positions for
   comments, tabs, astral characters, quoted newlines, nested operators, binders,
   constructors, calls, and split delimiters. Preserve every failed attempt.
4. Hand off exact owner-file patches to the span owner for lowering/host binding.
   Run selected parser controls and genuine checked compilation on CPU3. Root
   owns full-corpus correctness, histories, backend, and performance promotion.

Owner files are front/lexer.bend, front/parser.bend, front/declarations.bend,
parser construction sites in front/sugar.bend, front/parallel.bend and
front/validate.bend. A mechanical FToken pattern-arity update in
diagnostic/frontend.bend is included in the handoff and must be composed with
that file's span-owner changes. No live production files are edited.

The first independent range controls identify five constructor omissions.
The bounded followup additionally owns parse construction in
`front/literals_arrays.bend`: f_array_depth, f_index and f_index_value. The span
owner retains namespace/literal-lowering changes in that file. A generated-tree
range fill is limited to list/tuple/existential/matcher sugar and stops at every
already located child; it never scans an existing parsed subtree. Binary
operator references retain the actual operator token range separately from the
full application range. These changes were specified to the span owner before
source03's checked probe.

A subsequent shared-span census motivates three additional exact producer
boundaries: do headers own implicit quantities, individual do statements own
bind/pure calls, and law existential references own the declared binder token.
The do parser will carry one located monad KTerm instead of separate name and
type-list parameters; raw output after erasing metadata must remain identical.
Whole Match ranges use the actual match start and parser continuation cursor;
erased local binder ranges include their leading minus. Direct upstream term
comparisons and the existing whole-Base invariance suite gate this followup.

The root's independent full gate exposed seven partial ASTs whose embedded Error
left no consumed endpoint for a composite wrapper. The correction leaves the
wrapper unlocated when end<begin and retains the original partial tree/error.
All seven become explicit controls; this is not an oracle change or exclusion.
