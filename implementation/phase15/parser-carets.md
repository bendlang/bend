# Phase15 parser caret rendering

The isolated candidate fixes **all 132 target observations across 66 fixtures**
exactly against pinned TypeScript while removing **35 physical / 30 nonblank
Bend lines, 1,017 bytes, four definitions and three laws**. All 26 maintained
focused controls pass. The change is ready for root integration under
[P15-002](../../experiments/phase15/P15-002-parser-carets.md); this report does not
claim it is installed or that the combined release gates have passed.

## Change and coordinate contract

The parser's `fpe_snippet` family duplicated the checker's source snippet renderer
and omitted the caret row. The candidate removes that family and passes a point
`DSpan` to the existing `dg_snippet`. No new type, host code or rendering protocol
is introduced. The generated derived API is 1,583 bytes smaller.

Lexer coordinates count Unicode codepoints; upstream diagnostic spans count
UTF-16 units. The existing source scan still matches the same line and column,
carrying a separate UTF-16 offset. Astral characters before the error advance
that offset by two. The prior token verification and conservative fallback for
astral or surrogate characters at the error remain unchanged. Existing structured
parser errors represent a point, so the shared renderer emits the upstream
minimum of one caret; it does not invent a token-length span.

No parsing rule, accepted program, error selection or span origin changes.
The shared renderer already preserves tabs and handles empty, clipped/reversed
and multiline spans. The patch changes only `src/front/parser.bend`.

## Evidence and limits

All paths below are relative to `selfhost/build/phase15/` and retained for the
phase evidence publication. `carets-prepare-01` freezes source/configuration,
`parser.patch`, the 132-observation selection and twenty direct parser controls
before compiler execution. The checked attempt is `carets-build-01`:

- Untouched checked B1: `6e812b9ba1dd6934fe421e65687ab0977952f385bcdd6dbc2c88d15d12fa3e97`.
- Guarded version5 derived API: `a07fe93e192af218c16d0fe812375be458c6f20b074699ae0aa113202c51d488`.
- Upstream: unchanged `b2111cf43244e65f76ddc278ee695e669f720cbf`.

| Gate | Result | Evidence |
| --- | --- | --- |
| Genuine checked build and maintained focus | 26/26 pass; seven exact differences retained | `carets-build-01/validation-001/report.json` |
| Target parser family | 132/132 exact; complete/pass, zero exact differences | `carets-family-01/selected/paired.json` |
| Public parser controls | 20/20 rendering-only, complete-book/import and error-order invariants; 12 exact messages | `carets-controls-02/report.json` |
| Caret coordinates within those controls | All 13 emitted caret rows individually match TypeScript | `carets-controls-02/report.json` |
| Shared renderer boundaries | 24/24 exact against pinned `err_show` | `carets-renderer-01/report.json` |
| Source and observation audit | Only parser module changes; every family observation preserves semantic axes and adds only a caret | `carets-final-gates-02/report.json` |

Public parser controls compare baseline and candidate `f_parse` with pinned
`parse_book`; they do not add experimental public compiler exports. They include
empty/positive input, tabs, astral characters before and at the error, lone
surrogates, CRLF, EOF, blank/multiple-digit lines, multichar tokens, semicolon
separators and an earlier error before a later malformed declaration. Shared
renderer controls additionally exercise zero/reversed/oversized ranges and
split-surrogate offsets. No span-producing parser logic is inferred from those
synthetic renderer spans.

Eight direct parser controls retain prior exact gaps: two EOF cases lack a usable
lexer position; three cases select a different expected-message string despite
matching caret coordinates; astral and lone-surrogate error tokens keep the
conservative legacy fallback; and one malformed parameter keeps its old legacy
message. These remain visible in the report and are outside this rendering patch.
The family opportunity ceiling happens to be fully realized; this does not imply
that every parser diagnostic or source origin matches upstream.

The first direct-control runner and `carets-controls-01` are retained. A second
runner adds explicit exact caret-row assertions to the same frozen inputs;
`carets-controls-02` and `carets-final-gates-02` supersede their weaker audits
without replacing earlier evidence. No failed compiler attempt or hidden retry
occurred in this workstream. An initial read-only inspection used an overlong
line range and raised Python `IndexError`; it performed no compiler execution
or mutation.

Correctness jobs used CPU1, Node24.18.0, a 4MiB stack and 4GiB heap where controlled
by the maintained workflow, after the exclusive profile closed. Workflow reports
verify spawn errors, signals, timeouts and overflow alongside exit status. No
throughput, memory improvement or universal stack-safety claim is made.

The four retained research tools total 142 lines / 15,860 bytes and are separate
from the decreased production source. No maintained runtime/helper change or
permanent extra compiler export is required.

## Loader component boundary discovered during integration

The frontend now intentionally shares `diagnostic/model.bend` and
`diagnostic/render.bend`, plus `core/pretty.bend` required by that formatter.
The maintained standalone loader trace component previously excluded every
diagnostic module and therefore needed its minimal module closure updated.
The revised test explicitly excludes all checker modules and the diagnostic
trace, producer and frontend modules. This retains independent loader tracing
while describing its actual formatting dependency. No Bend source change is
needed for the test correction. The genuine component build against
`integration-source-03/combined` passes with 25 modules and three public loader
exports. Raw, traced and seeded loading return identical results, and seeded and
ordinary trace completion lists agree. The component contains no checker module
or diagnostic trace/producer/frontend module. All consumed source/tool identities
remain stable and the child exits cleanly. Evidence is
`selfhost/build/phase15/trace-component-01/report.json`; its checked component API
is `4e6f939dd94122b674cdd1992550c5b200411b7fb71d9361111d1ef2eb252de7`.
This component gate establishes the stated dependency boundary and loader controls,
not full language conformance or a separately shipped compiler image.
