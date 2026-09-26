# Source-aware diagnostic path

One chronological checker produces the verdict and original diagnostic together.
`check_book` retains its String API by projecting that result's error: an empty
string means acceptance. Diagnostic formatting and source lookup never change
that decision or relax a check. Full-book and exact-prefix checking share the
same event worker and retain the original `KChecked` failure through definition
and template checking.

The kernel's `check` and `infer` wrappers attach context and an ancestor trail only
when a result already contains an error. Fifteen existing failure sites preserve
expected/observed values that were previously discarded. Metadata occupies the
existing failed `KChecked.term` payload; the `KTerm`, `KDef`, `KEnv`, and `KChecked`
type layouts are unchanged.

## APIs

- `compiler_check_result_abi() -> U32` returns 1 for the authoritative-result API.
- `check_book_diagnostic(book, origins) -> DResult` returns the authoritative
  error, book and original structured failure from one check.
- `check_book_diagnostic_from_exact_prefix(book, validated, origins) -> DResult`
  skips an exactly matching, previously validated prefix. A mismatch, including
  a prefix longer than the book, falls back to checking the full book.
- `diagnostic_render(result) -> String` produces the complete `Error:` output.
  Unsupported declaration/TODO paths retain the original legacy output.
- `f_load_origins_for(main, sources, definition) -> FProvenance` loads through the
  actual frontend and returns origins only for the requested definition.
- `f_loaded_origins_for(trace, definition) -> FProvenance` reuses a successful
  load trace to collect those origins without loading again.
- `diagnostic_result_locate(result, origins) -> DResult` attaches source locations
  without repeating checking.
- `f_load_origins(main, sources)` provides the unfiltered provenance map for tests
  and tools that need it. Filtering avoids tracing every Base declaration.

When the capability is exactly version 1, the driver calls the detailed full-book
or exact-prefix API once with an empty origin list. On rejection it reuses that
result, collects origins for the failed definition from the existing load trace
when available, attaches them, and renders. Source lookup or rendering failures
leave the original rejection intact. Prefix validation remains tied to the exact
compiler and Base source.

Older compiler artifacts keep the String-checker path and optional diagnostic
replay. The driver uses the replay's presentation only when its error equals the
original rejection; a mismatch or optional-path failure preserves that rejection.

## Provenance and formatting

Origins contain the actual final core term, module source, UTF-16 start/end offsets,
and a path into the final freshened declaration. Only retained lexer positions
receive origins. Lookup requires the same definition and an exact structural term
match. Distinct matching locations are ambiguous and are not guessed; an exact
ancestor origin may supply a less specific location.

Filtered and unfiltered provenance share one traversal of the frontend load trace,
including its module paths, parsed records, final definitions and freshening
bases. An explicit Boolean selects all definitions; an empty definition filter
still means an exact empty-name filter. The traversal preserves origin order and
returns the original load failure without attempting to collect origins.

The renderer normalizes displayed terms, reconstructs shadowed binder names,
aligns context columns, preserves adjacent source lines and line-number widths,
and supports message-only errors and notes. It does not substitute fixture text.

Source positions currently survive for Ref/ADT/Ctr nodes. Variable occurrences,
binders, generated nodes, and expanded literals can lose their positions before
this phase. These diagnostics retain their expected/observed/context information
but omit unavailable source excerpts. Parser errors and declaration failures that
still expose only a string retain legacy output. This is not a claim of complete
byte-for-byte diagnostic parity for the entire upstream suite.

## Verification

`tools/verify.mjs` includes the diagnostic and provenance tests. Focused tests use
`BEND_DIAGNOSTIC_API` for an API exporting the diagnostic functions and
`BEND_FRONT_API` for frontend provenance functions:

- `tests/diagnostic.mjs`: 22 renderer, producer, ambiguity, and fallback checks.
- `tests/diagnostic-source.mjs`: eight generated source programs compared directly
  with the pinned upstream checker: six exact complete diagnostics, two exact
  structured diagnostics where source spans are unavailable.
- `tests/frontend/origins.mjs`: imported/beta-substituted references, constructor
  and alias locations, UTF-16 offsets, final-core paths, graph equality, filters.
- `tests/kernel.mjs`: all 43 existing checker/annotation assertions remain valid.

`tools/diagnostic-source.mjs OUTPUT --frontend` assembles a focused diagnostic
compiler. Its guarded instrumentation support also reproduces the earlier isolated
experiment from an uninstrumented kernel. `kernel-instrumentation.patch` records
that source change; production `kernel.bend` already contains it.
