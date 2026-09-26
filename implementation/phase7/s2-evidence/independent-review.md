# S2 independent implementation review

Reviewed against the committed S2 design and S1 `af3c639`. The reviewed
`selfhost/src/diagnostic/frontend.bend` SHA-256 is
`3dff9649db9ced1eb6815f6fae3a540797a5fec697ef32b4b10e910ca80a88e3`.
This review changed only this report; it did not rebuild or execute a compiler.
The reviewer independently proposed the trace consolidation and authored the
cross-version test, but did not implement the production change.

## Verdict

The source change follows the frozen design and passes the inspected correctness
evidence. No material implementation defect found. Promotion remains conditional
on the phase's performance, release and preservation gates; this review does not
declare those gates complete.

The module shrinks from 369 to 234 physical lines and 12,117 to 8,353 bytes:
**135 lines, 134 nonblank lines and 3,764 bytes removed**. The whole compiler is
15,826 physical lines, 13,209 nonblank lines and 491,193 bytes. Definitions and
laws each fall by 13; datatype count is unchanged. This exceeds the prospectively
required 99-line and 2,444-byte reductions, without moving compiler logic elsewhere.

The alternate reparse/event-source alignment implementation disappears. Existing
trace module counts become the single alignment rule. The added explicit Boolean
selection argument replaces the two public orchestration routes; it is not an
empty-name sentinel or an additional term/source representation.

## Contract inspection

- All three source APIs remain: `f_load_origins`, `f_load_origins_for` and
  `f_loaded_origins_for`. The first selects all definitions explicitly; both
  filtered APIs pass `False` and retain exact string matching, including `""`.
- Both loading entries obtain the same `f_graph_result_at` result through
  `f_load_graph_trace`. A nonempty loader error still returns no origins. Neither
  source selection nor origin display changes the loader's rejection verdict.
- Reversing `done` restores declaration order, and existing `take`/`drop` helpers
  consume the recorded declaration-event counts. Separate law/fill events remain
  separate events. Pinned `List.reverse` is the same tail-recursive accumulator
  reversal as the deleted private helper.
- Thirteen existing helper bodies are byte-identical after trimming boundary
  whitespace: term/constructor traversal, origin construction, lexer token lookup,
  UTF-16 conversion, trace slicing and definition-membership checks. Six-field
  `KTerm`, public token ranges and final-core paths are unchanged.
- `all=False` preserves rejection-only module filtering. `all=True` lexes each
  loaded module and visits its definitions in order; it no longer reparses source
  to invent a parallel declaration/source list.

The valid parsed-source contract remains important: `FParsedSource` carries this
compiler's unqualified parse of the supplied text. Arbitrarily forged parsed
results or traces with unrelated text/counts are not proved equivalent by this
review. No such malformed-input behavior is claimed as newly supported.

## Evidence inspected and limits

The checked and optimized generated-function comparisons preserve all 54 ordinary
exports and their wrappers. Their conservative dependency comparisons identify
only `f_load_origins_for` and `f_loaded_origins_for` as changed public closures;
parser, checker, emitters and runtime prefix remain unchanged. The unfiltered API
is absent from that ordinary selection, so it is covered by separately built
targeted component APIs rather than silently skipped.

`selfhost/build/phase7/s2/provenance-equivalence.json` records **530 comparisons,
20 complete passing rows**, with consumed API/test/helper hashes independently
rechecked during this review. Its baseline and candidate both export all three
provenance entries and the load/trace/seed/parse helpers. Full ordered objects are
compared before hashes are recorded; fields or origins are not normalized away.
The cases cover raw and valid parsed sources, empty and unknown filters, repeated
terms, CRLF/astral offsets, beta substitution, constructor routes, law/fill events,
aliases, a diamond import, four loading-error families and seeded/fallback traces.
Caller input hashes remain unchanged. Any prematurely aborted row keeps the report
incomplete rather than turning a partial comparison into success.

The test is a cross-version preservation control, not a TypeScript conformance
oracle. Its independent range check requires known `Missing` occurrences to select
that exact token; other ranges rely on baseline equality plus bounds and final-core
route invariants. The seed fixture is a small valid Base, not the full library.
Existing `diagnostic-reuse-01/report.json` complements it with **204 comparisons
across 23 passing rows**, including the actual pinned Base, complete diagnostics,
prefix guards and real host rejection results. Neither test proves arbitrary
program equivalence, malformed raw-ADT behavior, generated-code execution or speed.

The new test costs 127 lines / 9,575 bytes outside production compiler membership;
that validation cost is explicit. Preserve its reports and the targeted component
build identities in the phase capsule before claiming durable evidence.
