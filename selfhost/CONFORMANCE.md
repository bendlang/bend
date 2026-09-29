# Compiler validation

The target remains upstream `b2111cf43244e65f76ddc278ee695e669f720cbf`, Bend2
2.0.32 era. The [Phase19 release report](../implementation/phase19/live-checker-release.md)
binds the final checked artifact, controls, exact vectors, timing and preserved
failures. The [release manifest](dist/release.json) identifies the installed
guarded version5 derivative, genuine checked B1, source, Base, runtime and host.
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

Phase16 reduced exact reference differences **459→2**, with **457 new matches
and zero lost matches** versus Phase15. Phase17 and both Phase19 releases preserve every complete result. The remaining rows are parse and check for
`check/monad_do_destructure.bend`: rejection agrees, but the first diagnostic
differs because of an earlier do-block parsing checkpoint. All measured primitive
status, phase, type/trust, unsafe-list, exit and output axes agree on this corpus.
This finite result does not establish all intended typing rules or features.

Strict check results are **1,493 passes / 5 failures**. Four failures are expected
later-emission errors accepted by both frontends; the fifth is the do-block
oracle above. Exact reference comparison and strict fixture verdicts are separate.
Neither classification nor an integration no-regression gate weakens the oracle.

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

The installed live checker additionally passes all22 saved chronology observations
(two previous differences), all6 let-closure observations (three previous strict
differences), memo8, parsed instances29, canonical keys61, world/freshness/demand40,
and recursion4. Independent final-image boundary104 passes its stated contracts;
its runtime-reference projection is not full checked-term equivalence. Actual
backend41 and literal JS/native20 executions, helper16/authentic replay5, original
paired histories226 and installed/relocatedCLI42 were rerun on this exact API.

The frozen older public18 comparison retains six intentional differences:
instances are checked earlier, checked output uses completion order, and failure
results retain the actual failing world. Its overall report remains failed.
All nine stable four-field/projection-demand rows pass. The independently pinned
boundary104 suite validates the new behavior. See the
[live-checker implementation](../implementation/phase19/instance-live-checking.md)
and [independent review](../implementation/phase19/instance-independent-review.md).

Phase16's broader controls recorded the following gaps outside that inventory.
The contextual 39 / host 43 selections were rerun for Phase17. The198-observation
integration selection was rerun for Phase19 and now has **198 exact matches**,
closing its same-body live-instance difference. Its immutable runner retains
`pass:false` for14 inherited negative parse `observed` labels; exact result
comparison is a separate axis. Other selections below retain their stated scope:

- The separate196-observation group selection was rerun for Phase19:128exact
  and68known differences, unchanged from its Phase17 candidate. Its raw runner
  fails the selected-completion assertion despite complete healthy acquisition;
  a separate vector audit does not relabel strict failures as passing.
- The 114-observation marked-pattern selection has **71 exact matches and 43
  known differences**. Its raw oracle report is `pass:false`, including the
  known do-block check failure. A separate audit establishes 114 unchanged
  candidate outcomes and zero regressions against its accepted predecessor;
  it does not establish full selected conformance. Six direct demand controls pass.
- The supplied-source 39 and ordered-host 43 controls each retain one known
  wording difference for `@unsafe` followed by an import. Namespace eight,
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
error-order gaps. The installed Phase19 checker now matches all22 instance
observations and memo8; the group/parser prototype remains isolated. These
selections overlap and their counts must not be summed.

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
