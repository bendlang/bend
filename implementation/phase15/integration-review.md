# Phase15 integration review

Root independently read the isolated parser, import, host and lookup patches
before integration. The conformance candidate and speed candidate remain
separate checked artifacts until the integration gates pass.

The lookup change preserves the list-empty test, head/tail reads, cache-marker
test, ordinary-name test and first matching definition. A cache marker wins
before reading an ordinary name or descending into the tail. The checked
generated `speed-analysis-01/candidate-selection.mjs` contains one three-state
tail loop; its selected branches contain no closure, Unit or message creation.
The original index implementation is unchanged. This agrees with the finite
68 tailored controls, 5,769 index assertions and exact request-history evidence;
it is not a proof for arbitrary malformed host objects or an expected speedup.

The parser change retains code-point token lookup and fallback diagnostics,
accumulating a separate UTF-16 offset for the already tested shared renderer.
It removes the duplicate snippet/padding implementation. The isolated 132-row
exact gate, 20 parser invariants and 24 shared-renderer boundary controls support
integration. Eight inherited differences in the direct parser controls remain
recorded in the parser report.

The import change validates local spelling before filesystem resolution and
preserves earlier import errors before later body errors. Only imported ENOENT
with no existing compiler phase is rendered as a parser error; entry-file and
other IO failures retain their original category. Root requested an additional
optional-module guard around bootstrap export detection and three-way cycle
boundary controls before freezing the host patch. General cycle conformance
must not be inferred from missing-file fixtures named `cycle_terminates`.

An independent review of `frontend-gate.mjs` found its strict inventory,
identity, process-health and delta gates consistent with P15-004. Root accepted
the recommendation to require all 20 named behavior observations to match
reference semantic/output axes even when a row is unchanged. Existing exact
matches cannot regress through the diagnostic or named-behavior exceptions.
