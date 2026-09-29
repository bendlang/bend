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


## Integration checkpoint 01

Both checked builds completed, but their new 36-case validation is failed:
32 pass and four retain the known illegal-import-path diagnostic differences.
The selection placed acceptance/phase fields on upstream-only selectors; the
maintained harness retains upstream exact oracles for those selectors. This is
an experiment setup error, not a passing routine gate. The original reports and
consumed selections remain failed. The next selection will use the documented
custom-fixture form for the four explicit scoped oracles planned in P15-004;
full-inventory strict diagnostics remain untouched.

An additional three-way cycle boundary exposed a separate interaction. With
syntax errors in both parent and child, the first behavior candidate changes
which syntax error wins, while TypeScript reports the earlier import cycle.
That candidate is not selected. P15-005 adds an active canonical IO-path guard
and shared Bend cycle rendering before the next combined build. The valid-cycle
and single-body-error gaps are inherited, but that does not excuse the new
precedence change. No production/default compiler has changed.


## Corrected integration

Root and the speed owner independently reviewed final host SHA-256
`f4753d3e826557d70c71f305f72cf0afc794306151c2be0268c9b937246fef63`.
Active keys are canonical realpaths, checked before seen/physical reuse. The
closing-edge catch uses its caller's source/import token and the actual cycle
path; its parse phase prevents ancestor catches from replacing that context.
Completed aliases remain valid. Fatal errors discard the request-local active
set, so it cannot leak into another request. Diagnostic text and UTF-16 snippets
remain in the single Bend helper. All 16 expanded cycle/alias/diamond observations
are exact; nine finite host IO controls pass.

Both corrected `conformance-02` and `combined-02` builds pass 36 focused cases.
Four local scoped witnesses use distinct IDs and blank only the copied upstream
`#|` lines; the six other new cases retain upstream strict oracles. The original
four upstream diagnostic failures remain visible in the strict full inventory.
The full gate passes 2,996 observations, 144 new exact matches and zero regressions.
All saved paired histories and the 41-row backend gate pass.

Root also identified the standalone loader component's outdated no-renderer
assumption. The maintained component test now includes core pretty-printing and
shared model/rendering modules, and forbids checker/diagnostic tracing modules.
Its genuine 25-module checked build and raw/traced/seeded API controls pass. No
extra Bend implementation was introduced to keep an obsolete module boundary.
The final source preparation corrects two graph-boundary comment lines; the
immediately previous preparation is retained as an unconsumed snapshot.
