# Contextual module parsing

This work follows `design/phase16/contextual-module-parsing.md` and P16-002F.
It is isolated from the live compiler and inherits the checked local-law-source-01
parent. KTerm8 and cache schema4 are unchanged. No performance gain is claimed.

## Checkpoint A: shared Bend completion

Frozen candidate: `selfhost/build/phase16/spans-context-source-02/project`.
Its complete parent-relative patch manifest is in
`selfhost/build/phase16/spans-context-source-02-handoff/manifest.json`.
`spans-context-build-02` is a genuine checked B1 with the current v5 derivative;
all36 maintained focused cases pass, retaining two strict diagnostic differences.

A header-only scan records the valid import prefix and defers a later header
error until those dependencies finish. One contextual body parse then receives
the actual prior declarations. Existing law-fill and native-definition rules
therefore select the right error before parsing later malformed syntax. Imported
law fills retain the existing ImportLaw/ImportFill lowering. Standalone parsers
retain their signatures and empty context. Trusted FParsedSource inputs are
reused exactly; their caller remains responsible for parse-context suitability.

The candidate adds a module-level FHeader, FCompletion and private FParseScope.
The context is threaded through25 declaration workers. Prior definitions use
the existing exact-name index; the exceptional constructor-vs-definition
resolution case still uses the existing constructor lookup. Trusted parsed
inputs avoid constructing an unused prior index. The host recognizes the new
record fields and rejects an unknown present load ABI. Its ordinary IO discovery
still uses the previous lifecycle at this checkpoint; load ABI1 is an incomplete
experiment until checkpoint B connects the header/completion operations.

`spans-context-controls-02/report.json` completes39 controls with no control
failures:38 are exact, and one explicitly retains the independently confirmed
baseline `@unsafe` followed by import wording difference. Tests compare indexed
and unindexed standalone outputs, including the complete Base parse, with the
parent; test22 dependency-context fixtures against pinned TypeScript; bind
original physical positions through Unicode comments; compare seeded/cold
results; and verify shared completion versus the pure raw-source graph loader.
Native IO, U32 and String.eq collision precedence, annotated imported-law fills,
template parameter errors, constructor freshness, same-file aliases, and earlier
dependency errors before later header/body errors are included.

The original `spans-context-controls-01` failure is preserved: it demanded exact
wording for that newly added, already nonexact decorator/import boundary. The
second runner verifies the same rejection and identical baseline wording and
records the strict difference separately. Source/build01 are also retained.

## Checkpoint B: ordered host IO

Frozen final candidate: `selfhost/build/phase16/spans-context-source-04/project`.
The complete local-law-source-01-relative patches and identities are in
`selfhost/build/phase16/spans-context-source-04-handoff/manifest.json`.
`spans-context-build-04` is genuine checked B1/current v5; all36 maintained cases
pass with the same two strict differences. Source/build03 are preserved as the
successful predecessor before the separately approved prefix-order refinement.

The host now obtains a header, completes each child in source order, then asks
Bend to parse and complete the current module once. Its final accumulated graph
goes through one ordinary graph finalizer. It does not call the full graph loader
again. Canonical physical identity, active-cycle checks, aliases, raw source
intervals, source snapshots and foreign path collection remain explicit. New
module books receive the existing range validation against this request's
canonical intervals. Valid Base injection is lazy and additionally bound inside
Bend to the actual source path/text; the immutable cache format is unchanged.

Module completion checks only the newly lowered fragment for structured frontend
errors before the next sibling IO request. This makes a dependency's invalid match
win over a later missing file or cycle without rescanning cached Base terms.
On a later parser failure, the retained completed-declaration prefix is lowered
through that same path. Its first structured Error wins if present; otherwise
the original parser diagnostic remains unchanged. This never compares diagnostic
strings or source positions to choose an error and adds no successful traversal.
Unfinished bodies within a single declaration remain outside this refinement.

Final evidence:

- `spans-context-host-controls-02/report.json`:43 completed controls, all pass;
  42 exact controls and the explicit inherited decorator/import wording gap.
  Both orderings of completed-body vs later syntax are covered, and pinned
  framed_cell_capture is now exact. Earlier dependency syntax/lowering errors
  precede later missing files/cycles; missing files/cycles still precede a later
  main-body error. Cache/source-range guards, foreign paths and aliases pass.
- `spans-context-controls-04/report.json`:39 completed controls, all pass;
  38 exact controls and the same explicitly recorded wording gap. Complete Base
  and standalone parser projections remain identical to the parent; contextual
  raw, trusted parsed, cold and seeded behavior are checked independently.
- A derived copy of the exact checked API instruments the actual Bend
  `f_body_header`, module completion, seed and finalizer functions. A four-file
  graph with a duplicate symlink alias performs four body parses cold, three
  with a valid Base seed, one seed injection in the latter case, and exactly one
  finalizer in both. The alias causes no repeated body parse. Complete returned
  graphs equal the uninstrumented checked candidate.

The final delta is211 physical lines across eight files and26 Bend definitions.
The three new records are per-module/header state;25 existing declaration
workers receive the private scope argument. The one host-file delta consists of
export/field/capability handling and the ordered discovery/finalization route.
No TypeScript reference, core term representation, cache schema or default
compiler changed. All earlier attempts, failures and consumed tools are retained.

All owned compiler/probe processes closed after these controls. Root integration,
full corpus/history/backend gates and serial performance comparison remain
required before promotion; this isolated checkpoint makes no speed claim.
