# Compiler validation

The current target is upstream `b2111cf43244e65f76ddc278ee695e669f720cbf`,
Bend2 2.0.32 era. The [Phase12 report](../implementation/phase12/avoidable_work.md)
records full reference/candidate vectors, focused regression controls, execution,
known gaps and exact artifact identities. Its [raw evidence](../implementation/phase12/evidence/README.md)
preserves failures as well as passes.

The installed [release manifest](dist/release.json) identifies a guarded equality/choice
derivative, its genuine checked B1 parent, source, Base, runtime and host.
`npm run verify:release` verifies integrity
and lineage after relocation. It does not rerun conformance or claim a new
self-hosted fixed point. Historical fixed-point evidence is not transferred to
the current artifact.

The new upstream fixture gate has 1,498 fixtures: 1,001 positive expectations,
482 validation negatives, 11 declaration-only proof-trust refusals and 4 cases
whose expected error happens during emission. Eleven additional Bend files are
import support without independent oracles. `typeAccepted`, `proofTrust` and
`kernelChecked` keep these outcomes separate; no run claims Lean validation.

The final candidate frontend run, compared with the retained unchanged-pin
reference, completes 2,996 observations. All 1,001 positive
programs parse and all 1,001 accept types. All 482 validation negatives reject;
none is observed accepting invalid types. Strict checks record
1,006 passes and 492 failures, with no timeouts. There are 730 exact reference differences
(532 check, 198 parse), including diagnostic and phase differences. Seven of 11
trust-refusal fixtures reach the proper phase; four imported-law fills fail early.
The long-string fixture passes at the same 4 MiB stack in the final full run
and in both retained 53- and 60-request history replays. Phase12 rejects the
normalizer seed cleanup and broad branch inlining after reproducing stack
regressions. The narrower released transformation preserves all 2,996 Phase11
observations. A different history consisting of the former 21 focused cases
before the string can overflow even on Phase11; the new focused gate runs the
string first. These observations do not establish general stack safety.
These frontend counts do not establish full backend conformance.

The final combined compiler passes 22 maintained controls, 16 derivation
regression groups, and current plus historical version1–4 byte replay. A fresh
37-row paired backend selection passes with three known exact TypeScript
differences. Nat300 emits native C, builds with Clang16 and returns `306n`.
Raw arithmetic, constructor identity and demand controls are separately recorded;
their counts are not additional unique conformance fixtures. Historical Phase9
and Phase10 evidence remains tied to those artifacts.
Inherited Phase8 evidence includes 21 maintained development controls,
134 frontend observations, 26 semantic observations, 32 soundness observations,
18 semantic execution observations, 35 import/JS executions, 44 foreign-runtime
executions and 13 native/scanner controls. Some sets overlap. Do not add them
as if they counted unique language programs or infer full backend conformance.
Exact diagnostics are compared separately from custom acceptance/phase oracles.

Known remaining gaps include imported law fills,
diagnostic carets/text and some error phases. The maintained component suite
preserves its diagnostic-source parity failure against new upstream instead of
weakening that exact gate. Native Process requires a libc symbol missing on this
host, which also blocks upstream. GPU and interactive device execution are not
validated here. Open-Succ compaction resolves the retained Nat300 native C
expansion case; this does not establish all-pattern backend scalability. Compact
source Nat payloads remain U32-sized; wider runtime values retain their dynamic
representation. Consult the report for the final full-corpus counts.

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
