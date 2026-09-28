# P14-002 family: checker span caret rendering

Status: prospective frozen addendum, before candidate execution, 2026-09-28.
Root selected this bounded family after the retained-vector census. CPU1 is
reserved for correctness builds/probes; no performance claim is planned here.

## Hypothesis and inspected evidence

`diagnostic/render.bend` currently renders the three-line checker source excerpt
but omits its caret row. The pinned `bend.ts` `err_show` (lines1466–1495) renders
one caret per UTF-16 code unit, preserves tabs in the left padding and clips the
underline at the current line end, with a minimum length of one. Existing DSpan
stores source and begin/end offsets. Rendering must use those existing offsets;
missing spans remain missing.

The full retained comparison has730 observations over532unique fixtures.
210observations/144fixtures differ only by caret rows plus verdict/evidence
consequences. Of those, **78check-lane/check-phase observations** are the selected
family. The remaining132observations are66parser failures repeated in parse/check
lanes and are explicitly deferred. Concrete checker witnesses include
`base/bytes_ops.bend`, `base/heap_queue_deque.bend`, `base/json.bend` and
`base/parser.bend`; complete original strings and axes are in
`selfhost/build/phase14/differences-census-01/report.json`.

## Change and invariants

Edit only an isolated copy of `src/diagnostic/render.bend`: add span-aware marker
rendering to the existing excerpt path. No parser, loader, checker, span-production,
proof-trust, validation, diagnostic priority, host, runtime or maintained
transformation rule changes. Preserve no-span behavior and previous/next source
lines. A UTF-16 position inside a supplementary character must match the pinned
JavaScript string slicing rule; tabs remain tabs. Empty and end-of-line spans
print one caret; multiline spans clip on the first line. End before begin also
prints one caret without unsigned wraparound.

## Discriminating controls and gates

1. Build a genuine checked B1 with unchanged version5 equality profile. Run the
maintained22-case focused set first.
2. Expose the private renderer read-only in the frozen API for direct comparison
against pinned `err_show`, using bounded ASCII, tabs, supplementary Unicode,
partial-surrogate offsets, newline/end-of-file/empty spans, multiline and reversed
span examples. Preserve original image identities; test export views are not
installed compiler artifacts.
3. Run all78existing target observations through the paired exact harness, plus
positive/no-span/parse-failure and multiple-error precedence controls. Exact
comparison is never relaxed. A diagnostic may improve without an exact fixture
pass if another mismatch remains; report both counts.
4. Give root the source patch, identities and every result. Root owns combined
full frontend delta accounting and final release. Failed attempts remain frozen.

Stop or narrow if source offsets do not represent the upstream domain, if the
renderer changes acceptance/trust/error order, or if fixes require broad span
propagation. The153retained snippet-only observations are a separate future
span-propagation family, not a promise for this patch.
