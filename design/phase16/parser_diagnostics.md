# Phase16 parser diagnostics

This work implements the parser portion of [full conformance](full_conformance.md).
The frozen Phase15 API is `b8d658c564226a52764a435df86059aa3cea6b0c428bbde5341a62c2253c2e2d`;
the unchanged TypeScript target is `b2111cf43244e65f76ddc278ee695e669f720cbf`.
The baseline census retains every complete reference/candidate result in
`selfhost/build/phase16/parser-census-01/report.json`. There are 122 differing
parse observations on 122 fixtures, each with the same parser diagnostic gap in
the check lane: 244 observations in this ownership scope.

## Causes and sequential stages

1. Preserve exact observed text and source ranges. The existing `fpe` failure
   payload retains an expected string, a starting token and line/column, but the
   renderer unconditionally observes one character and renders a point. Six
   duplicate constructors, thirteen match-arity errors, one malformed declaration
   name and four illegal import paths account for all 24 same-expectation parse
   gaps. Extend the existing failure payload with one optional range record and
   explicit observed override; obtain normal observed text from the original
   source range. Reuse `dg_snippet` unchanged. This replaces the incorrect
   constructor-next-token workaround. Import diagnostics deliberately keep a
   point marker while observing the entire path, matching pinned TypeScript.
2. Preserve the first syntax failure and use shared declaration/name validation.
   Several callers discard the node from `f_expect` and parse its empty tail,
   replacing a useful failure with line 0 EOF. Thread `FParsed` failures through
   those continuations. Emit explicit expectations where validation currently
   returns unstructured strings. Validate names consistently, retaining keyword,
   malformed-name, duplicate and import-alias precedence. Do not parse old error
   strings to reconstruct structured errors.
3. Carry rejection origins through frontend elaboration and flattening. The
   thirteen computed-match fixtures and other pattern/local-binding errors need
   the original expression or binder span, not a guessed nearby token. Coordinate
   the smallest origin strategy with the checker source-origin owner before any
   overlap. Preserve exact term structure and successful lowering; only existing
   failures gain metadata. If a shared origin API is needed, freeze a supplement
   before implementing it.
4. Close remaining lexical/body/template diagnostic differences from the actual
   pinned parser rules. Test each shared rule with direct small witnesses and all
   corpus members, including error-order pairs and the inherited eight direct
   parser controls. Freeze additional changes before probes. No fixture-name
   branches, oracle changes, host-language fallback, or TypeScript semantics in
   the host are allowed.

The initial census shape groups are 72 legacy/unstructured, 24 same expectation,
13 computed-match legacy and 13 other shapes. These are shapes, not a claim that
one edit fixes each group. Exact IDs and diagnostic bytes are in the census.
The implementation report will separately identify corrected causes and remaining
counterexamples after each isolated checked build.

## Verification and preservation

Each source attempt is a new `selfhost/build/phase16/parser-*` project copied from
Phase15 combined-02. Normal source, old attempts and the unrelated Phase6 files
remain untouched. The first stage changes `front/parser.bend`,
`front/declarations.bend` and `front/validate.bend`. Later likely owners include
`front/families.bend`, `front/elaborate.bend`, `front/flatten.bend`, and literal
validation, but those files are not permission to perform a broad rewrite.
`diagnostic/render.bend` remains shared and unchanged.

No compiler process starts until root releases the baseline timing window. Then
use an assigned CPU, genuine checked B1 plus the maintained guarded derivative,
focused workflow controls and exact paired parser/check witnesses. Keep successful
parse books/imports unchanged when a change is diagnostic-only. Keep status,
phase, checked/type/trust, exit/output and complete diagnostic text separate.
Any unexpected acceptance or earlier-error change is a failed candidate.

Root owns integrated whole-corpus, backend, history, performance and publication
gates. This subtask makes no speed claim. Keep each failed attempt, exact consumed
script/source/API/config/input identities and complete paired results. All 244
parser-origin observations must be accounted for; partial selected passes are not
full conformance. The report is
[parser diagnostics](../../implementation/phase16/parser_diagnostics.md).
