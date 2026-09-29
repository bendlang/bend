# R1 independent complete-graph controls

Freeze the installed Phase20 checked API40c8f7f3 and exact fixture bytes before
candidate execution. This reviewer changes no compiler source. The candidate
hypothesis is the one existing f_let_body kt→kt_span expression, using the
existing pattern's begin/end.

The main structural risk is wider than the Local node: f_span_created stops at
an already located subtree. Locating Local early can stop previous whole-group
range propagation into synthetic descendants such as typed-let Ann. Record
every changed path and both complete origin pairs; do not whitelist Local/Let
alone or erase all range fields. Constructor lowering explicitly passes the RHS
as match origin in both f_flat_local and ff_local, which must remain true for
destructuring groups and a group used as an outer pattern.

For each small no-Base program, retain complete raw and lowered results for
legacy unindexed and indexed entrypoints. Compare every key, constructor tag,
name, ID, quantity, child and scalar field exactly. Only originBegin/originEnd
fields are classified as range differences, and those differences are listed
with their actual graph paths and old/new values. Raw/lowered diagnostic strings
are retained verbatim as a separate outcome, because R1 intentionally changes
some rendered locations; they are never normalized for graph equality.

Controls cover ordinary/grouped/nested/same-spelling locals, typed Ann,
parallel first/second binders, erased and marked binders, comments/newlines with
an astral prefix, local callee/argument, nested groups used as outer patterns,
constructor/nested-constructor destructuring, and typed constructor rejection.
Legacy graphs must retain absent0/0 coordinates. Candidate metadata changes in
synthetic descendants are findings, not automatically accepted improvements.

For representative existing Base fixtures, compare entire raw/lowered books in
memory and compute streaming full-field digests, including ranges. Persist only
program-owned definitions plus every changed path, avoiding repeated giant Base
JSON dumps. Also compare the Base seed itself. Freeze the exact original fixture
paths and hashes; do not rewrite saved programs. Pinned parsed/lowered term spans
are independent evidence for disputed Let/Ann/constructor origins; replace only
the cyclic span.file handle with its complete source text and identity in saved
small reference terms, documenting that representation explicitly.

This is a structural and source-origin review, not a semantic type checker or
new parser. Retain setup failures and all changed nonrange fields as failures.
Parent owns candidate build, strict diagnostic/acceptance gates and promotion.
