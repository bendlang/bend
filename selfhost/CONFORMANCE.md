# Compiler validation

The [Phase29 installed release](../implementation/phase29/generated-program-fast-loop.md)
adds guarded native scalar inlining and a private Nat countdown loop. Fresh gates
pass36 strict focused observations, 15 checked upstream JS fixtures, 23 libraries
with 127 scalar points, all ten original Phase28 libraries plus the HVM program,
and22 actual compiler component observations. Exact complete results are checked.

The [independent semantic review](../implementation/phase29/semantic-review.md)
records 56,205 primitive scalar/ABI executions, 1,129 primitive guards and 25
order/error observations; 3,759 worker scalar executions and 14 descriptor/effect
transcripts; 40 worker guards, two let witnesses and 144 nested-Nat regression
observations. Counts overlap and include multiple emitters. These finite scopes
do not renew the entire frontend inventory or establish full backend conformance.

Attempt03 passed the smaller gates but overflowed during symbolic-regression and
ray-tracing emission because an eager Boolean guard still entered recursive
recognition. Attempt04 uses explicit branching and bounded counts. Both original
programs now compile/run, and the new small test reproduces the failure on03 and
passes on04. Source, failing receipts and corrected controls remain preserved.
The runtime, native backend, Base and pinned upstream target are unchanged.

## Historical Phase27 validation

The [Phase27 release](../implementation/phase27/constructor-arm-prebinding.md)
adds selected constructor-arm prebinding through a shared JS runtime helper.
Fresh gates:36 strict focused observations, 15 pinned upstream JS fixtures exact,
23 libraries / 127 scalar points,72 detailed descriptor/effect/ownership observations,
and22 real compiler membership oracles. The previous numeric suite passes2816
scalar checks and four expected refusals per emitter, plus468 supplement checks
per emitter. The runtime argument-ownership test also passes.

The initial inline variant passed the same scoped semantics but was rejected for
a20% short-window substitution regression. The shared version corrects that
measured regression; all attempts are retained. These overlapping finite scopes
do not renew every historical suite below or establish full backend conformance.
The frontend, native backend, Base and upstream pin are unchanged. Previous
[Phase26 guard results](../implementation/phase26/direct-u32-decisions.md) remain
separately scoped evidence for the unchanged numeric recognizer.

## Historical frontend and broader release evidence

The current compiler targets upstream
`018751270e800bc222a93dad7f257083ee53a5f7`, after Bend2 **2.0.34**. The
[Phase23 report](../implementation/phase23/upstream-graph-conversion.md) records
checked compiler identities, the updated Base and guarded version6 profile,
retained failures and release decisions. The [release manifest](dist/release.json)
identifies the installed artifact; `npm run verify:release` checks its integrity
and lineage, without rerunning conformance or proving a self-hosted fixed point.

The new inventory contains **1,513 fixtures** and **3,026 parse/check observations**.
The final installed candidate03 agrees exactly with the new TypeScript reference
on **3,026/3,026** main observations and **196/196** retained broader parser
observations. This includes all15 added upstream fixtures and both depth32
shared-equality regressions. Final candidate acquisitions use explicitly verified
fresh-reference checkpoint results, with zero behavioral differences, worker
failures/timeouts or changed input identities. The
[frontend validation report](../implementation/phase23/frontend-validation.md)
retains both initial and final compiler gates and their exact artifact identities.

Raw main verdicts remain **2,525 pass /497 observed /4 fail** on both sides:
parse1,016 pass/497 observed and check1,509 pass/4 fail. The four failures expect
later emission errors; both frontends accept them at the earlier check stage.
Exact reference agreement therefore coexists with the original failed fixture
verdicts. No oracle or raw report is rewritten.

Final candidate03 also retains **226 paired history observations and two fresh
6,000-character string checks**, with complete result equality apart from
independently validated host provenance. There is no diagnostic exception.
The unchanged baseline114 observations were reused with verified input hashes;
candidate03 supplied114 fresh observations. Original53/60-request order,4MiB
stack,4GiB heap and generation1 are preserved, with no worker failure, timeout
or recycling. The [history report](../implementation/phase23/history-controls.md)
keeps earlier stack failures and the original acquisition boundaries explicit.

Graph conversion now preserves sharing through the existing graph evaluator;
native and JavaScript array atomics use the existing uniform array representation.
Backend execution, aliasing/ownership controls and installed/relocated CLI checks
have their own gates in the Phase23 report. Frontend agreement does not establish
all backend behavior, independent proof-kernel validity or universal language
equivalence. Independent `--verdict`, GPU/device execution, hub/package fetching
and broader platform coverage remain unsupported or unvalidated as recorded below.
Concurrent ordinary structural array reads against writes are not claimed safe.

## Phase22 historical frontend agreement

Phase22 targeted upstream `b2111cf43244e65f76ddc278ee695e669f720cbf`, Bend2
2.0.32 era. The [Phase22 release report](../implementation/phase22/contextual-conformance.md)
binds the final checked artifact, controls, exact vectors, timing and preserved
failures. That release used the guarded version5 derivative, genuine checked B1, source,
Base, runtime and host.
`npm run verify:release` checks integrity and lineage after relocation; it does
not rerun conformance or establish a new self-hosted fixed point. Independent
proof-kernel validation and `--verdict` remain unsupported.

The full inventory has **1,498 fixtures**: 1,001 positive expectations,
482 validation negatives, 11 declaration-only trust refusals and four
later-emission errors. Eleven additional Bend files supply imports without
independent oracles. The final run completes all **2,996 parse/check observations**.
All 1,001 positives accept types; all 482 validation negatives reject, with no
observed invalid acceptance, timeout or unresolved observation. All 11 trust
cases type-check and reach the intended refusal, exactly matching TypeScript.

Phase22 reaches **2,996/2,996 exact complete results** on this corpus, closing
the final two do-block first-diagnostic differences with zero lost matches.
Phase16 had reduced459 differences to2; subsequent releases retained those two
until the contextual frontend put semantic decisions at their actual parsing
checkpoints. All measured primitive status, phase, type/trust, unsafe-list,
exit and output axes agree. This is full agreement on the tested frontend
corpus, not proof of universal language equivalence.

Strict check results are **1,494 passes /4 failures**. Those four fixtures expect
later-emission errors and both frontends accept them at this earlier stage.
The parse lane retains1,001 passes and497 observed negatives. Exact reference
comparison and original fixture verdicts are separate; no oracle was weakened.

Fresh final-artifact gates also establish broader parser196/196 exact (+57,
zero lost), independent public176/176, check/interpreter/JS/native36/36, and
integration198/198. The marked114 selection is an audited exact subset of the
fresh196, closing its43 historical differences. Header12, normalization12,
completion17, constructor-index42 and actual checkup4 controls pass their stated
contracts. Original226 paired history requests plus two fresh long-string checks
pass with exactly one prospectively pinned diagnostic correction; all other
complete results and the original resource/order boundaries are preserved.
The unchanged standalone frontend test rebuilds26 modules without the checker
or diagnostic tracing dependencies. Suites overlap and must not be summed as
unique programs. See the Phase22 report for exact source/API/host identities.

The sections below retain artifact-specific historical results and failures.
Where Phase22 supersedes a frontier, the current result is stated explicitly.
Independent proof-kernel validation, GPU execution and broader platform/device
coverage remain outside the demonstrated result.

The earlier Phase19 prefix release fixes a separate public-prefix error outside that inventory.
The Phase17 compiler accepts a changed `{0n == 1n : Nat}` proof when reusing a
validated `{0n == 0n : Nat}` prefix, despite rejecting the changed book in a full
check. The corrected compiler detects the changed literal and rejects in both
paths. All twelve identity controls pass; five failed on Phase17. This does not
establish a bypass of the host's separately hashed Base cache. The
[independent prefix report](../implementation/phase19/instance-boundary.md)
retains the original failure and pinned oracle. Maintained 36, the complete
2,996-result comparison and all 42 installed/relocated CLI checks were rerun on
the corrected API; other named controls below retain their stated prior scope.

The Phase19 live-checker image additionally passed all22 saved chronology observations
(two previous differences), all6 let-closure observations (three previous strict
differences), memo8, parsed instances29, canonical keys61, world/freshness/demand40,
and recursion4. Independent final-image boundary104 passes its stated contracts;
its runtime-reference projection is not full checked-term equivalence. Actual
backend41 and literal JS/native20 executions, helper16/authentic replay5, original
paired histories226 and installed/relocatedCLI42 were rerun on that Phase19 API.

The frozen older public18 comparison retains six intentional differences:
instances are checked earlier, checked output uses completion order, and failure
results retain the actual failing world. Its overall report remains failed.
All nine stable four-field/projection-demand rows pass. The independently pinned
boundary104 suite validates the new behavior. See the
[live-checker implementation](../implementation/phase19/instance-live-checking.md)
and [independent review](../implementation/phase19/instance-independent-review.md).

Phase20 also reruns the maintained36 with zero strict differences, decorator24,
constructor50, first-element54 and expanded whitespace44, all exact. Original
supplied39 and ordered-host43 now have zero strict differences. Three new accepted
constructor programs pass check/interpreter/JS/native comparisons (12observations),
and all42 installed/relocated CLI checks pass. These suites overlap; do not add
their counts as distinct programs. A rejected intermediate constructor candidate's
semicolon false acceptances remain documented in the independent review.

Phase16's broader controls recorded the following gaps outside that inventory.
The contextual39 / host43 selections now have the Phase20 results above. The198-observation
integration selection was rerun for Phase19 and now has **198 exact matches**,
closing its same-body live-instance difference. Its immutable runner retains
`pass:false` for14 inherited negative parse `observed` labels; exact result
comparison is a separate axis. Other selections below retain their stated scope:

- Historically, the separate196-observation group selection on Phase21 had139exact
  and57remaining differences, three newly exact and none lost from Phase20.
  Only local-pattern parse/check and local-callee check change. The raw runner
  still fails selected completion with three inherited failed verdicts; the
  separate acquisition/no-regression audit preserves this raw failure.
- Phase21's independent68 improves44→60exact with16gains and no primitive or
  exact-match regressions. Typed-RHS4 adds two exact/two unchanged diagnostics.
  Complete-graph172 and positive annotation-coordinate30 gates pass; inherited
  grouped-constructor false acceptances stay visible. Program12 has exact healthy
  observations, including nine successful actual executions, but the original
  output-oracle verdicts remain failed because their comments omitted Nat's `n`.
  Maintained36 is strict exact and installed/relocatedCLI42 passes.
- Historically, the 114-observation marked-pattern selection had **71 exact
  matches and43 known differences**; Phase22 closes all43 as described above. Its raw oracle report is `pass:false`, including the
  known do-block check failure. A separate audit establishes 114 unchanged
  candidate outcomes and zero regressions against its accepted predecessor;
  it does not establish full selected conformance. Six direct demand controls pass.
- The historical Phase16 supplied-source39 and ordered-host43 controls each
  retained one wording difference for `@unsafe` followed by an import; Phase20
  closes that gap as recorded above. Historical namespace eight,
  term/cache 39 and whole-program host ten controls pass without exceptions.

On the historical Phase17 API, the maintained 36 cases pass their selected contract
with two inherited exact differences. All **41 paired backend rows** match the
pin. The direct frontend-lookup probes pass **23 paired / 46 independent expected
outcomes**, including lazy demand, exact access order and a 100,000-definition
miss. Each probe preserves the entire production API prefix and adds one named
internal wrapper with a distinct identity. The supplied-source 39 and host 43
controls rerun on this API with the same known wording gap.

Phase16's additional **20 literal JS/native executions**, **176 literal
observations**, **29 instance controls**, **two specialization growth controls**,
**61 canonical-key controls**, namespace 8, term/cache 39 and program-host 10 remain
artifact-specific historical evidence. They were not all rerun for Phase17's
single lookup-worker change. All 2,996 complete compiler result objects are
unchanged, but that does not manufacture new execution evidence for these other
selections. See the [Phase16 gate report](../implementation/phase16/checker-compact-final-gates.md).

The Phase17 standalone 25-module loader rebuilds without checker or diagnostic
tracing dependencies. All 16 unchanged derivation groups and five authentic
version1–5 byte replays pass, as do all **42 installed/relocated CLI checks**.
[Phase17 validation](../implementation/phase17/find-demand-gates.md) records the
exact images, complete-vector comparison and gate boundaries.

Fresh long strings and the original 53/60-request histories preserve all
**226 paired complete results**, with original ordering and 4 MiB stack / 4 GiB
heap limits. The Phase16 and Phase17 APIs run under the same byte-identical compatible
host; original historical inputs and host differences remain explicit. The old 21-case prefix can
overflow even Phase11, so the maintained selection keeps the string first.
Finite histories do not establish general stack safety.

New independent Phase17 research keeps additional failures visible. The
[group-boundary trial](../implementation/phase17/group-boundary.md) retains
128/196 exact observations, including eight existing semantic mismatches in
four grouped-comma/zero-head-match witnesses. The
[instance-order investigation](../implementation/phase17/instance-chronology.md)
has 20/22 exact observations and 8 exact memo/name controls, with two distinct
error-order gaps. The retained Phase19 checker matches all22 instance
observations and memo8; Phase20 separately closes the eight zero-head observations.
The original contextual parser prototype remains an isolated historical artifact;
Phase22 integrates a separately validated contextual implementation and closes
its measured frontend gaps. These selections overlap and must not be summed.

Other limits include hub/package fetching, independent proof-kernel validation,
backend/platform coverage and source Nat payloads restricted to U32 size (wider
runtime values have a separate representation). Native Process requires a libc
symbol unavailable on this host, also blocking upstream. GPU execution and
interactive devices are unvalidated. These control sets overlap and must not be
summed into a count of unique conformance programs. Earlier span/control counts
refer to their historical compiler images, not automatically to this release.

## Historical evidence

The following sections describe their recorded old-pin artifacts.

The supplied baseline compiler results are in [the compatibility matrix](docs/COMPATIBILITY-MATRIX.md).
Phase 1 changes have separate artifact-specific evidence in the
[implementation report](../implementation/phase1/report.md).
Phase 2 adds [exact paired checks and retained replay](../docs/PHASE2_DEVELOPMENT.md),
with revision-specific results in its [implementation report](../implementation/phase2/report.md).
Phase 3 adds [persistent frontend workers](../docs/PHASE3_DEVELOPMENT.md),
with artifact-specific validation and remaining gates in its
[implementation report](../implementation/phase3/report.md).
Phase 4 separates genuine checked B1, derived development images, native and
self-emitted artifacts in its [report](../implementation/phase4/report.md).
Phase 5 adds the [maintained checked workflow](../docs/PHASE5_DEVELOPMENT.md),
with source-specific repairs, controlled timings and remaining failures in its
[report](../implementation/phase5/report.md).
Its [final-source checked self-reproduction](../implementation/phase5/final-selfhost.md)
has actual equal stage2/stage3 bytes and matching current/frozen source modules;
this is separate from the supplied distribution's historical proof below.
Selected acceptance/phase checks, exact diagnostics, full-corpus coverage and
self-emission are distinct verdicts; none substitutes for the others.
The complete pinned corpus contains 1,378 fixtures across 24 namespaces; all 919
positive fixtures parsed and passed checking in the recorded full run. Exact
execution results, diagnostic differences, timeouts and hardware gates are
reported separately, with artifact hashes.

- [Component verification](dist/component-report.json) checks the assembled Bend source and compiler subsystems.
- [Negative-test audit](docs/NEGATIVE-COMPATIBILITY.md) separates presentation differences, different rejection rules/phases, and unproven intended-rule coverage.
- [Compiler ABI validation](docs/COMPILER-ABI.md) covers the lazy host adapter used by self-emitted compiler libraries. It is separate from the recorded full-corpus run, whose compiler, runtime and host hashes remain explicit.
- [Typed fixed-point verification](dist/selfhost/seed-verification/report.json) records direct checked seed self-emission and byte comparison. [Earlier failed attempts](dist/selfhost/release/report.json) remain separate evidence.
- [Conformance protocol](tools/conformance/README.md) explains reproducible runs and verdicts.
- [Original prototype baseline](docs/PROTOTYPE-BASELINE.md) and [earlier subset survey](docs/PROTOTYPE-SURVEY.md) are historical evidence for the unchecked compiler.

The typed compiler independently passed its complete checked self-rebuild on
2026-09-21: seed and output bytes match exactly. The recorded comparison uses
the same source and Base path layout; relocated checkouts need a local seed.
Passing positive programs does not establish full diagnostic or proof-checker equivalence.


## Phase24 execution inventory

The active pin has999 positive main programs:999 eligible interpreter lanes,
833 JavaScript lanes and812 native lanes (2,644 total). These are a coverage
inventory, not2,644 newly passed observations. The bounded current-image pilot
and its uncovered rows are recorded in the [Phase24 backend report](../implementation/phase24/backend-census.md).

That pilot found two additional emission gaps despite exact frontend agreement:
constructor/foreign-name collisions were incorrectly accepted, and native
function-name normalization rejected distinct import names. Phase24 adds the
shared emission check and injective function identifiers. The four fixtures with
later-emission errors still retain their matching raw frontend oracle failures;
the execution tests validate the actual refusal boundary separately.

[Environment results](../implementation/phase24/backend-environment.md) acquire
the two previously blocked TCP comparisons using unchanged upstream emissions
under Bun1.2.22 and unchanged candidate emissions under Node24. This is a supported
host comparison, not Node support for upstream's bun:ffi or general Bun support
for our runtime. Matching Clang16 TSan runs eight saved emitted-program executions
without sanitizer diagnostics, including a two-core shared atomic witness; these
are finite controls on Phase23 emissions, not a universal race-safety guarantee.
Independent kernel, GPU/device and complete execution-corpus coverage remain open.
