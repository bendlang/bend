# Phase16 source spans: explicit provenance and conformance

Explicit source intervals and the integrated range-preservation fixes make 160
of 169 targeted checker diagnostics exact. Integration04 passes the full frontend
regression gate: 314 newly exact observations, 145 strict differences remaining,
zero lost exact matches, and all 2,996 primitive results unchanged. The first
populated-range cost pilot on integration03 is 10.17% slower, so performance
investigation remains open. The sections below distinguish that pilot from the
later correctness fixes and the separate allocation experiment.

The first checked candidate preserved compiler behavior and established the
representation cost baseline; that ablation deliberately fixed no diagnostics. The
shared cause of 153 missing snippets is erased occurrence provenance, rather
than the renderer. Seven caret and nine mixed note/location differences need
the same ranges plus the checker owner's note correction.

## Findings from the two implementations

`diagnostic/frontend.bend` attaches origins only to final Ref/ADT/Ctr nodes
whose `id` still contains an original lexer coordinate. It then finds an origin
by structural comparison. Literal expansion, reference binding and alpha-renaming
erase coordinates; identical occurrences cannot be distinguished structurally.
Pinned TypeScript instead carries an optional Span on each term through lowering.
Its ranges are syntactic: constructors include braces, datatype applications
currently end after their first angle argument, lambdas often mark their binder,
and generated do-bind references mark the originating statement.

The exact seven caret fixtures are `check/ctor_arity.bend`,
`check/do_missing_bind.bend`, `flatten/match_as_term.bend`,
`io/channel_send_recv.bend`, `page/ctor_list_mismatch_000.bend`,
`page/usage_plain_words.bend` and `parse/qualified_constructor.bend`.
The first, third, fourth, fifth and seventh need full syntactic ranges. The
do-bind case needs a generated-node origin; usage_plain_words needs the lambda
binder instead of its constructor ancestor. All nine location/span fixtures also
miss an unrestricted-binder Note; three already have exact spans. Counts are
triage opportunities, not claims of future exact gains.

The unpromoted Phase6 reports supplied useful negative evidence. Object origins
failed two accepted-cost pilots; a later scalar-origin prototype reduced cache
size but recorded only starts. It cannot be promoted as current full-range
support. Those reports and all 75 unrelated files remain untouched. The current
design uses two primitive UTF-16 interval coordinates to retain both endpoints
without an object allocation for every term.

## First candidate and checked scope

The [prospective design](../../design/phase16/source-spans.md) and
[P16-002](../../experiments/phase16/P16-002-source-spans.md) precede the source
preparation. `selfhost/build/phase16/spans-prepare-03/project` was copied from
the immutable Phase15 combined-02 snapshot, not the working tree. Its only
compiler change adds zero `originBegin`/`originEnd` fields, projections and an
explicit `compiler_span_abi() == 3`. Existing direct record rebuilds preserve
those fields. Parser instrumentation and the complete nonzero-span propagation
policy were deferred until the cost review recorded below.

The source patch touches 40 original constructor/pattern sites in 15 modules,
adding 18 physical lines, 15 nonblank lines, 1,153 bytes and three definitions;
no laws, types or modules are added. The only host delta is typed-driver ABI
export discovery, conditional named-field conversion and explicit zeros on
foreign-source records. The runtime and maintained equality helper v5 are byte
identical. Historical private H helpers were investigated but are not on the
checked-B1 path and were not changed.

`selfhost/build/phase16/spans-build-01` is a genuine checked B1 with maintained
v5 derivative API `2c6c673e944462927fa0972f19ae47330109c91537c0dff5a5659071e1a0b143`.
All 36 maintained focused observations complete and pass their existing scope;
the same 11 exact TypeScript differences remain. No failed strict oracle is
weakened.

`selfhost/build/phase16/spans-controls-06/report.json` passes 20 direct/control
groups. Ten raw parser sources preserve every original semantic field and all
new fields remain zero. The full 36 focused vectors agree after verifying the
expected per-image host hash and mapping only equal-byte snapshot fixture paths;
diagnostics and all remaining result fields compare exactly. Internal controls
append exports to a byte-identical checked image prefix, then check canonical
absence, projections, origin-independent equality and substitution's parent/
replacement ranges. They do not claim all lowering paths preserve nonzero spans.

The validated Base caches have identical 28,780 KTerm occurrences and 115,649
JSON objects, and their original six semantic fields are exactly equal. All
candidate origins are zero. Serialized book bytes increase 3,653,389→4,516,789
(23.63%), entirely from the two named zero fields. This is a serialized-size
measurement, not a live-allocation or elapsed-time measurement.

## Preserved failed tools and next gate

Preparation01 failed on a direct constructor with a custom `removed` list;
preparation02 then failed on commas inside generic declaration types. Their
consumed scripts, partial preparations and explicit failures remain. Preparation03
handles those structural cases and completed before the compiler build.

Controls01/02 failed to parse because the runner omitted a closing function brace;
neither executed a compiler. Controls03 exposed a runner's assumption that a
native Bool was a constructor plus legitimate per-image identity/path changes.
Controls04/05 retained incorrect assumptions about the result provenance field
and incomplete path normalization. Controls06 explicitly binds the real
`hostProvenance` hashes and equal-byte source paths; all controls pass. These
failed harness outputs and exact consumed tools remain separate, unchanged.

Root reviewed the one-file host patch. Before full instrumentation, an explicitly
present unknown ABI must be rejected rather than using the old six-field layout.
That hardening belongs in a fresh candidate; the consumed ablation stays frozen.
The ablation then proceeded to the exclusive same-source cost pilot below.
Its metadata-only result does not establish full provenance coverage or justify
promotion of later instrumentation.

## Controlled metadata cost

Root's closed `selfhost/build/phase16/spans-matrix-01/report.json` compares the
same assembled candidate source with Phase15 and the zero-metadata candidate,
using two fresh-process samples per image and the established serial TS–baseline–
candidate–candidate–baseline–TS order. Phase15 averages 24.2841 seconds; metadata
averages 24.5297 seconds, **1.01% more process time** and 1.07% more request time.
Pinned TypeScript averages 2.8936 seconds. Peak RSS rises 1,384,712→1,508,412 KiB
(8.93%). The reviewed one-file host delta and all ordinary checking results are
bound in the matrix. This stays below the phase's 3% investigation threshold;
it does not establish zero overhead, and real provenance collection still needs
its own final cost gate. Root authorizes the next instrumentation step.

## Common child-rebuild simplification

[P16-002B](../../experiments/phase16/P16-002B-source-rebuild.md) freezes a separate
helper candidate before instrumentation. `k_with_children(parent, kids)` uses one
record pattern and preserves every nonchild field. Fifteen exact unchanged-head
record rebuild sites now call it instead of making 105 field-projector calls.
Sites intentionally changing names, IDs, quantities or removed constructors stay
explicit. The helper adds seven physical/six nonblank lines and one definition,
while removing 275 source bytes. For well-typed immutable KTerms the eliminated
projections are total and side-effect-free; the child expression remains a single
argument evaluation. No traversal or semantic normalization is added.

`spans-rebuild-build-01` is genuinely checked and its maintained v5 derivative is
`f3e13701f60293eb986e33d8dd51f8666c6f53cdf8cba1554dd639b997f04322`.
All 36 focused cases pass with the same 11 exact differences. The one-file host
follow-up rejects an explicitly present unknown span ABI before choosing a layout.
`spans-rebuild-controls-02` passes 22 control groups against the first metadata
image, including empty/nonempty child replacement, preservation of every other
field, and refusal to perform beta normalization as part of rebuilding. Its
bounded census check binds the report, requires all origins zero on both sides,
and asserts equal term/object/serialized-byte counts plus the exact serialized
six-field semantic digest. A helper throughput result is not yet available.

The first helper-control run is retained as a failure with exit137. A reused
runner stripped candidate fields but compared them to an already-eight-field
baseline; its large assertion attempted to render the full differing Base book
and was killed. No complete result is inferred from that run. The corrected
runner symmetrically projects both books and compares their exact serialized
semantic digests, so a mismatch cannot expand the entire graph into an exception.

## Located source and lowering integration (in progress)

The frozen instrumentation contract is `design/phase16/source-spans-instrumentation.md`.
The first private overlay, `spans-origin-source-01`, replaces the old token and
structural-term origin search with numeric interval lookup. One `FLocatedSource`
wrapper retains raw versus pre-parsed delivery. Scope, call lowering, literal
expansion, alpha-renaming, substitution and residual application rebuilding
preserve explicit occurrence ranges. Synthesized values retain zero/zero.

The host reserves Base's interval first for both cold and cached loads. Physical
aliases share source bytes and an interval. Cache schema 4 binds span ABI 3,
compiler hash, Base hash, canonical path, interval and serialized book hash.
The existing persistent memo retains exact byte-identity checks and avoids
revalidating the immutable Base graph on every request. Supplied low-level
parsed ASTs remain trusted inputs, as before; public host and source-aware
replay boundaries validate range ownership. There is no unconditional Bend
rescan of Base on the successful low-level graph path.

`spans-integration-build-01` genuinely compiled the combined source ownership
and parser cursor source02 in 9.6 seconds, then failed Base preparation. The new
validator found exactly one malformed App range (0,70672) among 28,780 terms.
Parser analysis identified `f_bang` discarding the function reference's range
before `Image.drop!(image)`. This failure, raw range census and original build
are retained; the parser owner is preparing the specific preservation fix.
This is not a passing integration or performance result.

The source02 host preparation also corrects indexed-export discovery (the public
entry is in declarations.bend), and teaches the workflow to bind schema4's
explicit source interval without adding a new launcher dependency. The initial
launcher used the old schema2 validator; subsequent checks must launch the
candidate workflow containing the reviewed schema4 admission. The first attempt
failed earlier during Base range validation, so it did not reach that gate.

The next immutable union, `spans-integration-source-02`, compiled and passed the
existing optimized v5 derivation without any guard relaxation. All 36 maintained
focused checks passed. The new `spans-origin-controls-01` passed 28 explicit
ownership/replay/cache controls, including exact cold-versus-seeded book identity,
unknown ABI refusal, malformed source/term intervals and canonical alias checks.

The first complete assigned diagnostic census (`spans-family-01`) improves **141
of 169 previously nonexact checker observations to exact TypeScript agreement**.
The other 28 remain strict failures; every primitive result field still agrees.
The independent raw-vector audit binds all 169 rows and their identities. Remaining
causes are localized: missing local-binder trace points, match-header provenance
for generated empty cases, pattern substitution preserving the binder rather than
the use occurrence, do/Exists synthetic producers, inequality/rewrite endpoints,
and one independently visible checker Note mismatch. The full 2,996-observation
regression sweep is owned by root and remains a separate gate.

The frozen source03 follow-up threads one existing Match term through the match
workers so generated Efq nodes have the actual header origin. It distinguishes
pattern renaming/destructuring (retain each use's source occurrence) from beta
substitution (retain the inserted argument's occurrence). Do lowering now retains
header ranges on inserted quantities and statement ranges on generated calls.
These changes are prepared; their integration results are not yet claimed.

Root's first full sweep of integration02 is **not selectable**: the healthy full
run observed 283 newly exact rows, but also six lost exact matches and fourteen
primitive phase changes (seven parser refusals in both lanes). All fourteen
reported the host's range error before the original parser error because the
host inspected a rejected partial book. They remain recorded in
`wave2-frontend-01/behavior-differences.json` and `lost-exact-differences.json`.
No full-sweep gain is claimed while this regression is open.

The corrected boundary validates ranges on successfully returned parser books.
Rejected partial books never reach semantic loading/checking, and their original
parse/import ordering remains authoritative. Every affected fixture is included
in the new prospective boundary selection. The parser owner is also checking
canonical ranges on its partial error results; this does not substitute for
preserving the original error at the host boundary.

Integration03's 25-observation boundary run is retained as a failure: nine exact,
sixteen remaining strict differences. The original fourteen phase mismatches
persisted because these parser errors are embedded Error terms while the raw
FResult.error is empty; the host's top-level error condition alone is insufficient.
The parser owner is repairing absent/reversed endpoint production directly.
No host code will interpret Error tags or exempt arbitrary malformed ASTs.

Both independent Nat-literal backend diagnostics now match exactly. Repeated
literal/reference, CRLF/tab, astral text/string, multiline call and EOF controls
also match. The nested-note control has the correct caret and Note but differs
in the preceding import line: upstream's loader blanks leading imports before
parsing the module. This is a source-presentation contract, not an incorrect
term range. One intended imported-origin fixture mistakenly omitted the required
path/alias syntax; fixture set02 corrects that input while preserving set01 and
its parse-rejection observation.

The first actual populated-range pilot on integration03 measures
25.588→28.190 seconds, **10.17% more process time** and 10.61% more request time;
pinned TypeScript is 2.890 seconds. Peak RSS increases 1,452,500→1,478,180 KiB
(1.77%). This exceeds the 3% investigation threshold. Root is profiling before
any promotion, and a confirmatory controlled comparison is still required.
The metadata-only 1% result did not predict the full collection cost.

The separate checker-only module display patch is genuinely checked and passes
the existing v5 derivation and 36 focused checks. Eight independent formatting
controls match pinned `err_show` exactly, including leading imports/comments,
tabs, CRLF, astral text, a foreign import inside a declaration and the import
keyword boundary. Coordinates remain raw; only the displayed line list changes.
Generic parser/import-error snippets and the DSpan ABI remain unchanged.

## Correctness closure on integration04

The immutable integration04 combines the located lowering fixes, parser10's
canonical partial-book ranges and precise do/Exists/Match ranges, import-elided
checker display, and root's bare-family predicate correction. It genuinely
compiles, retains the existing optimized v5 derivation, and passes all 36
maintained focused checks with seven pre-existing strict differences retained.
The optimized API is
`9a5294d51db35fc5317ae94bc8439bb62f586b4ea7b8314366cb4ff4473a4c11`.

The repeated assigned-family census is **160 exact / 9 strict differences**,
with no primitive changes. The independent raw-vector audit in
`spans-family-02/independent-audit.json` verifies exact row membership, retained
failures, worker health, identities and result fields. Its first two audit-runner
attempts incorrectly conflated harness `complete`/`selectedComplete` with probe
coverage; both failed attempts remain recorded. The final audit checks coverage
explicitly and does not require known strict diagnostic failures to pass.

The 25 independent boundary observations now have **24 exact / 1 strict
remaining**, with no primitive changes. In particular all fourteen observations
from the seven former partial-parser-book regressions are exact, closing the
full-gate regression. The remaining custom imported-origin diagnostic has the
correct caret but still prints qualified names (`dep.T`/`dep.bad`) where upstream
uses module-local names (`T`/`bad`); the checker display owner handles that scope.
The two custom Nat-literal backend diagnostics and nested equal-type Note control
are exact.

Root's fresh full sweep (`wave3-frontend-01/report.json`) passes its explicit
no-regression policy: **459→145** exact frontend differences, **314 newly exact**,
**zero lost exacts**, and primitive agreement on all **2,996** observations.
All 1,001 positive type acceptances, 482 validation refusals and 11 exact
proof-trust refusals remain. This is not a claim of full conformance: the 145
strict failures are preserved. The successful full sweep supersedes the earlier
unselected sweep; its failure evidence remains unchanged.

## One-allocation range attachment experiment

The prospective experiment is `P16-002D-source-span-allocation.md`. Its private
source starts from integration04 and changes only `f_span_created`: one KTerm
pattern match builds the final record directly, replacing a child-rebuilt record
followed by a second range-replaced record. The unchanged guard still leaves
legacy zero-start terms and already-located terms intact, and the same recursive
child walk stops at the same boundaries. There are no new definitions, types,
passes, host rules or semantic cases. Static record allocations per newly filled
node fall from two to one; this is not a measured speed gain.

`spans-allocation-build-01` genuinely compiles and passes the existing v5 guards
and all 36 focused cases, retaining seven strict differences. Optimized API:
`97d42f0f6ff47950939a86bffe10ffa9e37952506d45ddf55322a423dd322c24`.
All **32** controls in `spans-allocation-controls-01/report.json` pass. They compare
complete serialized book hashes and explicit term/range/object counts for legacy
and indexed parses, Base, the assembled compiler, synthetic sugar and all seven
partial-error regressions; they also compare complete cached Base, cold/seeded
load traces, provenance, rendered diagnostics and unlocated replay results.
Consumed input identities are rechecked afterward. Controlled timing is pending;
this candidate remains a separate overlay from the correctness baseline.
