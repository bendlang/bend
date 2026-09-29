# Contextual module parsing

Freeze before implementation. Parent: local-law-source-01/project, which contains
accepted wave6 and the separately checked local-law cursor/parameter correction.
Pinned reference remains b2111cf43244e65f76ddc278ee695e669f720cbf. Existing failed
import/header experiments and all unrelated Phase6 files remain unchanged.

## Required behavior and ordering

A module header is inspected before its body. Its valid import prefix loads in
source order, each dependency completing its own body before the next sibling IO
request. Then a later header error is reported, or this module's body is parsed
once against the loaded prior declarations. Never collect all dependency IO first:
an earlier dependency's body error must beat a later sibling ENOENT or cycle.
The host owns IO; Bend continues to own header syntax, namespace resolution,
declaration eligibility, alias rules, elaboration and final graph validation.

Use one shared Bend completion operation both from the pure supplied-source graph
loader and the normal host's ordered IO traversal. The latter must finalize its
accumulated graph directly, rather than loading/elaborating the graph again.
The new path must not allocate a host-visible token graph or reparse successful
module bodies. Header scanning is limited to leading import/comment/blank lines
and the first body line. Body lexing keeps the original UTF16 interval and physical
line; error display keeps the complete original source.

## Explicit data and API

Add FHeader{imports,error,body,line,offset}: imports are the valid prefix in source
order, error is the selected header diagnostic, body is the unconsumed source tail,
line is its physical first line, and offset is its UTF16 offset in original text.
Reuse the existing import parser on the isolated prefix, so header grammar/error
ordering remains one implementation. The complete original text renders errors.

Add a private immutable FParseScope containing the prior declaration book/index,
module namespace, resolved aliases and an explicit contextual-mode flag. Thread
it through declaration workers, not checker or arbitrary term traversal. The
local parser book remains separate; imported definitions are never copied into
it. Use the existing index operations for prior declaration lookup. Legacy entry
points supply an empty noncontextual scope. Known imported law fills retain the
existing ImportLaw/ImportFill compatibility lowering after eligibility is checked;
there is no guessed imported-law classification or new definition representation.

Add FCompletion{graph,parsed}. It returns the updated existing FGraph plus the raw
module parse result for the host's existing per-module span validation, source
snapshot retention and foreign-path discovery. This avoids validating a fully
expanded graph or rescanning immutable cached Base. These are small module-level
records; KTerm and persistent Base-cache layouts remain unchanged.

Expose f_source_header and f_complete_source plus the existing graph finalizer
through the checked API. An explicit compiler_load_abi capability identifies the
new lifecycle. Host support must reject an unknown present capability. ABI field
adapters add only the new module records and existing FGraph transport; they do
not perform language semantics. Exact host/source changes receive separate review
before a performance comparison or integration.

## Declaration rules

At a def header resolve the actual prior declaration, then apply the existing
fillable-law, native/foreign/completed-definition and parameter rules before later
syntax. A contextual missing alias-qualified declaration is refused at its name;
an existing fillable imported law follows the same colon/plain-parameter path as
a local law. Laws, datatypes and constructors apply freshness against the actual
prior scope and current local events, with separate constructor namespace rules.
Keep the new root local-law checks intact. Preserve source spelling for diagnostics
and canonical names for dependency lookup. No error-string selection is allowed.

## Compatibility and cache boundaries

f_parse and f_parse_indexed retain standalone signatures and noncontextual behavior.
FParsedSource remains a trusted already-parsed input; completion reuses its exact
result and never reparses it. Its caller therefore owns parse-context suitability;
new contextual exactness applies to raw sources and the normal CLI. Preserve all
source getters, wrappers, provenance/replay and raw/parsed/seeded loader APIs.
Dependencies still load before a supplied parser failure is surfaced. This corrects
the same dependency-order boundary without manufacturing a different parsed result.

Base injection remains lazy at Base's actual dependency position and requires its
existing path/text/compiler/interval identity. No unconditional Base validation or
parse is introduced per request. The normal host keeps immutable Base metadata and
validates newly returned raw module books against canonical source intervals;
imported-law source references may legitimately belong to the dependency interval.
No cross-request source interval or mutable global parser context is introduced.

## Sequential checkpoints

1. Implement header splitting, private declaration scope, shared module completion
   and supplied-source graph integration. Keep host discovery on the old path.
   Check genuine B1/current v5, exact legacy parser projections and complete Base,
   direct contextual supplied-source results, raw/parsed/seeded parity and header
   ordering. Record any incomplete capability separately; do not promote it.
2. Change host IO DFS to header→children→shared completion, preserve immediate
   child failures before later sibling IO, capture exact parsed sources, validate
   new raw books, then finalize once. Review capability/ABI/host delta explicitly.
   Check canonical aliases/cycles, missing files, foreign paths, imports after
   decorators/declarations, cache identities and source-range boundaries.
3. Root composes later alias-binding and local-law overlays, runs full adjacent
   frontend/backend/history gates and serial performance comparison. An operation
   counter must establish one body parse per uncached physical module, zero Base
   body parses on a valid seed, and no repeated normal graph completion.

Estimate: approximately180–300 initial net lines, around29 threaded declaration
workers and three small module/scope records. This is an estimate to audit against
the final diff. No speedup is assumed; successful-path cost remains a measured gate.

## Frozen refinement: earlier completed declarations on parser failure

Root approved this refinement after checkpoint B's first controls. TypeScript
flattens each completed def body before advancing to the next declaration; a
later top-level syntax error must not erase an earlier completed body's semantic
parse error. FResult already retains the completed declaration prefix on failure.
Run that prefix through the same module completion path once, only on the failed
parser path. Prefer its first structured frontend Error; when there is none,
preserve the original parser diagnostic exactly. Do not inspect diagnostic text,
compare source spans to choose, or add a successful-body traversal.

Freeze witnesses in both orders: an earlier completed invalid match followed by
later syntax must select the match; an earlier valid completed body followed by
the same syntax must preserve that syntax; earlier syntax must still win over a
later bad body. Include pinned framed_cell_capture. Unfinished bodies within the
same declaration require a separate parser-owner proposal and are outside this
refinement.
