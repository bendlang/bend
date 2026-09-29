# Phase16 parser diagnostics report

Status: stages1–3 passed scoped correctness gates. Latest isolated source05 fixes116 of244 parser-origin observations. Root owns integration and promotion.

The [design](../../design/phase16/parser_diagnostics.md) owns the 122 remaining
parse differences, also present in the check lane (244 observations). The exact
census is `selfhost/build/phase16/parser-census-01/report.json`, and its selection
contains both lanes for all 122 fixture IDs. The frozen inputs and hashes are
recorded there. No fixture or oracle was changed and no compiler process ran for
this census.

The first proven structural cause is loss of observed ranges in the existing
`fpe` payload/render path. Six duplicate constructors, thirteen match-arity
errors, one malformed declaration name and four invalid import paths produce the
24 same-expectation parse gaps. Later stages address discarded failures, legacy
validation errors and origins needed by computed-match/pattern diagnostics.

Execution results, preserved failures and independent review will be appended
here after the corresponding prospective scope is frozen.

## Stage 1: exact observed text and source ranges

`parser-source-01` changes only parser/declarations/validation source, adding12
physical lines. It replaces the old next-token constructor workaround with the
shared source-range mechanism. `parser-checked-01` is a genuine checked B1 with
the maintained equality derivative; all36 focused controls pass and their exact
differences fall11→7. The isolated source and consumed preparation script are
frozen beside the patch and workflow configuration.

All32 direct parser controls pass (`parser-controls-01`): the20 inherited cases
retain12 exact matches and eight explicit gaps; all12 new range/error-order/valid
cases are exact. All direct baseline/candidate books and imports agree.
`parser-range-validation-01` passes all48 observations over the24 targeted corpus
fixtures with zero exact TypeScript differences. This accounts for48 of the244
parser-origin differences; it does not establish full conformance. The complete
122-fixture census is being validated independently before expanding the source
scope. There is no performance measurement in these correctness runs.

## Stage 2: preserve the first syntax failure

The frozen [supplement](../../experiments/phase16/P16-parser-propagation.md)
replaces discarded `f_expect` nodes with explicit expression/body continuations,
uses structured punctuation expectations, and aligns parallel-let and typed-let
failure order. EOF location is derived from the original source on failure only.

`parser-source-02`/`parser-checked-02` passed36focused cases and completed the
244-observation census, but failed direct control18: matching TypeScript's first
UTF16 unit of an astral character tried to construct surrogate55357, which Bend
rejects as a non-scalar character. `parser-controls-02` is incomplete and failed;
its exception and all17 preceding observations remain preserved. It is rejected.
No successful corpus count erases that direct counterexample.

`parser-source-03` restores the original astral/surrogate point fallback, retaining
the supported propagation and EOF changes. Genuine `parser-checked-03` passes all
36focused cases. `parser-controls-03` passes all32controls,29exact: EOF with and
without a newline and the three parallel-binding punctuation cases now match.
Astral/surrogate point formatting and the malformed parameter-name cursor remain
explicit inherited direct gaps.

`parser-census-validation-03` completes all244 observations. Its strict exit1
retains81checker-lane diagnostic failures; the independent raw-vector audit
`parser-census-audit-03.json` passes with82new exact observations versusPhase15,
162remaining differences and zero changed behavior axes. The34new exact results
beyondstage1 arise from17fixtures. Sixteen observations change diagnostic text
but retain an earlier gap. This selection does not establish absence of losses
outside the122fixtures; root's full-corpus integration owns that claim.

All stage03 compiler/control/census producers closed before the root metadata
performance window. Stage04 is separately planned in
[parser names](../../experiments/phase16/P16-parser-names.md).

## Stage 3: shared name validation

Source04 was prepared but never compiled: read-only review caught a forbidden
quantified `~` being unmarked before selecting its diagnostic cursor. Source05
preserves04 and corrects the cursor before execution. The frozen name-validation
supplement covers shared keyword/malformed/missing-name expectations, explicit
law/type header cursors, quantified binder punctuation and first-error propagation.
The complete delta versusPhase15 is five frontend files: parser, declarations,
validate, parallel and sugar. No host/type-layout/renderer change is included.

Genuine `parser-checked-05` passes36focused cases. The122-fixture census completes
all244observations:116new exact results versusPhase15,128remaining (64fixtures),
zero changed behavior axes. `parser-census-audit-05.json` independently verifies
these counts. This is34additional exact observations beyondsource03.

`parser-controls-05` completed47direct cases with45exact diagnostics, but its
unchanged-raw-book assertion failed on two quantified binder errors. The old
`f_parse` returned an empty error while embedding Error nodes inside its partial
book; the new parser reports the exact upstream failure immediately. The first
followup runner05b incorrectly called unexported `f_elaborate` and failed before
its first case. Both failed reports and consumed tools remain preserved.

Corrected runner v3 uses the public `f_load` API. `parser-controls-05c` passes
all47cases,45exact; it verifies that the two old partial books already failed
frontend elaboration and that the new failure is exact. It allows partial-book
drift only for that general, explicitly checked condition, not fixture labels.
Successful books/imports remain equal; all prior exact controls remain exact.
The two unsupported direct astral/surrogate point renderings remain explicit.

All stage05 producers closed before handing the immutable five-file delta to
the shared origin-representation investigation. General origin attachment,
remaining64parser fixture gaps and the canonical Empty negation fence are not
claimed by this stage.

## Stage 4: explicit UTF16 token cursors and parser origins

This stage uses the authoritative union of parser05 and checker03, migrated by
its owner to eight KTerm fields. The prospective experiment is
[P16-parser-origins](../../experiments/phase16/P16-parser-origins.md). It changes
neither production files nor the conformance oracle.

`parser-span-source-01` adds begin/end/previousEnd to FToken and threads one
optional UTF16 cursor through the existing lexer. Legacy lexing retains its old
list membership and line/column behavior; only indexed lexing appends an EOF
cursor. Comments advance source offsets while preserving the old comment-column
projection. Source01 passes a genuine checked build and all36focused cases,
with7retained exact differences. Its new indexed entry was not yet exported by
the host roots, so source02 adds that required public export before controls.

Source02 adds origin capture at atom, call, binary, family and binder
construction. Parentheses preserve inner origins; lambda ranges cover their
binder; family ranges retain upstream's first-argument endpoint. The genuine
checked source02 build passes36focused cases, still7exact differences.

`parser-cursor-controls-02` is a preserved runner failure: exposing an internal
generated tail-jump worker without run_loop returned `$JMP`. The corrected
runner v2 changes only that test wrapper. `parser-cursor-controls-02b` passes54
controls at both origin1and4097, comparing complete legacy/indexed raw parse
results after erasing origin fields, token projections, source slices, UTF16
bounds and previous significant-token ends. Cases include comments, tabs,
CRLF, astral characters, multiline quotes, split delimiters and EOF.

`parser-range-controls-02` completes26independent comparisons with the pinned
TypeScript parse_term. Twenty-one pass. Five reveal missing inner synthesized
node ranges (Exists, binary application, list), natural-offset trailing
whitespace, and array-index root location. These are explicit failures, not
conformance gains. Source03 adds bounded transfers for those constructors and
f_app_span; the checked build rejects an extra closing parenthesis in f_locate.
Source03 and its failure remain preserved. Corrected source04 is the next
attempt; its results will be recorded before promotion.

Source04 passes the genuine checked36-case build and all26upstream term-range
controls. The span owner's whole-Base check then found one missing transfer:
`f_bang` reconstructed its function Ref without a range. Source05 preserves that
range. `parser-cursor-controls-05` passes56controls, including the full Base at
two disjoint origins. Base contains26,684tokens and16,856raw KTerms,14,022located;
allranges are valid and erased raw parse results match parser05. The expanded
`parser-range-controls-05` passes27TypeScript comparisons including offload.
The frozen source05 handoff records allpatches and hashes. Its source increment
over the shared eight-field union is75physical Bend lines and6,558bytes, plus
an18-byte host export addition. The diagnostic pattern-arity hunk is superseded
by the span owner's direct interval implementation.

Source06 prepares positioned semantic Error transport and an explicit `!=`
operator range for the generated Empty reference. Pre-probe review found that
source-length validation needed an explicit lazy zero-origin exit; source07
adds it, keeping whole-source scans off successful indexed parse completion.
Source06 is retained but was not compiled. Source07 passes genuine checked36,
18independent error-origin controls against pinned err_show (message,
expected/observed, Unicode, multiline, EOF and invalid/absent-origin fallback),
and all56cursor/Base controls. Root separately owns the canonical-reference
semantic fence; this metadata source keeps the old Ref tag.

## Additional producer boundaries and the failed full integration gate

The span owner's integrated census revealed missing do-header default quantity,
do-binding statement and law existential locations. The parser followup carries
one located monad term through do workers, replacing separate monad-name and
type-list parameters, while preserving the raw FDo shape after metadata erasure.
It also captures whole Match ranges, erased local binder prefixes and the law
Exists reference range. Source08 is a retained preparation.

Root's independent full gate on its earlier combined metadata candidate found
14primitive phase differences across7fixtures: an embedded Error in an unfinished
raw book left a composite wrapper range with start>0andend0, and host validation
replaced the eventual parser refusal with a range-contract error. These failures
are retained in wave2-frontend-01 and the candidate remains unselected. All7raw
parsed.error strings are empty; their errors are inside the partial AST. Thus
merely checking parsed.error at the host boundary cannot resolve this issue.

Source09 leaves unavailable wrapper endpoints absent, preserves existing Error
ranges while collecting family arguments, and avoids a partial do return range.
Its checked build fails on a stale f_do law after the do-worker parameter
consolidation. Source10 removes that obsolete declaration. It is prepared,
uncompiled, while root holds an exclusive performance window. A frozen63-case
cursor suite now includes all7full-gate failures and checks metadata-erased
AST/error equality plus every individual KTerm range. No corrected full-gate
claim is made yet.

Source10 passes genuine checked36, all63cursor/AST invariance controls, and14
independent pinned TypeScript body-range comparisons. Those compare do binding,
return, semicolon and final-expression boundaries, implicit header quantities,
whole Match, erased binder and law Exists origins. The07→10 handoff is frozen
in parser-span-source-10-handoff. It removes75physical lines overall by carrying
one monad header term and removing superseded separate laws; byte count grows
by221. The span owner's subsequent strict integration boundary suite reports
all14observations from the7former phase regressions exact, with no range-check
exemptions. Its full-corpus rerun remains the root's responsibility.

## Stage 5: carrying semantic parser failures as terms

The prospective semantic-error plan selects31fixtures/62paired observations:
13scrutinee failures,5local-binding match failures,7pattern failures,4operator
namespace failures and2array-count failures. Eight accepted upstream fixtures
provide positive controls across these constructs. The source base is immutable
spans-integration-source03, including checker04 and the canonical Empty fence,
with the validated parser10 overlay.

Pattern validation now transports Maybe<KTerm> instead of a String: None is
success; Some carries the first actual error and its offending term range.
Known constructor patterns recurse in the same order. Unsupported patterns keep
their input tree for ordinary compiler lowering/printing on rejection; no second
validator or fallback-message interpretation is added. Literal pattern expansion
receives the original literal range at each generated constructor, including the
257n backend boundary. Match producers distinguish a consumed/global name,
already-destructed constructor, computed value and local binder using explicit
terms and the original Match origin passed by the span owner.

Semantic source01 fails the genuine upstream check because a standalone local
String literal lacks the explicit type needed by pinned Bend inference.
Source02 adds that annotation; both attempts and exact preparers are retained.
No semantic-stage conformance improvement is claimed before its probes complete.


The semantic producer experiments retain four unsuccessful intermediates:
source01 missed a String annotation; source02 referenced a nonexistent
core_word predicate (actual word values are constructors); source03 passed
genuine bootstrap/B1 but the live version2 cache validator rejected its
span-aware version4 cache. Reusing the candidate's frozen reviewed workflow
validated source03 without changing compiler artifacts:36 focused probes passed.
Its62 semantic observations had54 exact matches and8 remaining differences,
all the four operator errors' explanatory Note; worker errors/timeouts were zero.
Source04 added an explicit generic ParseNote but a missing closing parenthesis
failed the upstream parse check. Source05 repairs that typo and passes genuine
checked bootstrap/B1 and36 focused probes (4 retained exact differences).
The target62, positive16 and full244 census remain separate gates.

Semantic source05 closes all31 selected fixtures/62 paired observations exactly;
16 positive observations also match exactly. The full122-fixture/244-observation
parser census has178 exact and66 remaining differences, with healthy workers
and zero primitive-axis changes. An independent audit against integration04's
wave3 vector confirms62 new exact observations and zero lost exact observations.
Thus the remaining parser frontier is33 fixtures/66 observations. The earlier
Phase15 comparison also preserves all116 previous parser gains.

The seven-file semantic overlay is frozen in
`selfhost/build/phase16/parser-semantic-source-05-handoff/manifest.json`:23 additional
physical Bend lines (the payload replaces string-return/reconstruction paths).
Apply those explicit frontend deltas to integration04; the candidate was built
from integration03 plus parser10, so copying its unrelated diagnostic renderer
would discard integration04's newer renderer fixes. Parent owns the full-corpus
and runtime/257n backend gates. No speed claim is made for this correctness wave.
