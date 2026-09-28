# Compiler validation

The target remains upstream `b2111cf43244e65f76ddc278ee695e669f720cbf`, Bend2
2.0.32 era. The [Phase14 report](../implementation/phase14/conformance_and_dispatch.md)
and [evidence](../implementation/phase14/evidence/README.md) bind the exact checked
parent, selected derivative, inputs, controls, full vectors and preserved failures.

The [release manifest](dist/release.json) identifies the installed guarded
version5 derivative, genuine checked B1, source, Base, runtime and host.
`npm run verify:release` checks integrity/lineage after relocation; it does not
rerun conformance or establish a new self-hosted fixed point. There is no proof
kernel validation, and `--verdict` remains unsupported.

The full inventory has 1,498 fixtures: 1,001 positive expectations, 482 validation
negatives, 11 declaration-only trust refusals and four later-emission errors.
Eleven additional Bend files supply imports without independent oracles.
The final run completes all 2,996 parse/check observations. All 1,001 positives
accept types; all 482 validation negatives reject, with no observed invalid
acceptance, timeout or unresolved observation. All 11 trust cases now type-check
and reach the intended proof-trust refusal, exactly matching TypeScript.

Exact reference differences fall from 730 to **603**: 194 parse and 409 check,
across 409 unique fixtures. There are 127 new exact matches and zero lost matches.
Strict check results are **1,085 passes / 413 failures**. These counts differ
because exact reference comparison and expected-fixture verdicts are separate
oracles. Eight improvements cover the four imported-law cases across both lanes;
71 improve checker diagnostics and 48 correct trust-reporting lists/output. Another 26 observations add carets but retain
an exact difference. `import/alias_decl.bend` now refuses at the correct parse
phase in both lanes, while retaining different diagnostic text.

Both final build variants pass the maintained 26-case development gate, retaining
12 existing exact diagnostic gaps. The release passes 16 unchanged derivation
regression groups and five current/historical version1–5 byte replays. Its
41-row paired backend selection passes with three known exact differences,
including a dependent imported-law fill that returns `5n` in the interpreter,
JavaScript and actual Clang16/native execution. All 42 ordinary/relocated CLI
checks pass; relocation supplies no upstream checkout. These scoped execution
results do not establish full backend conformance.

The fresh 6,000-character string and exact 53/60-request histories pass at the
original 4MiB stack / 4GiB heap limits. Conformance-only and combined candidates
agree on every paired result and predecessor. The old 21-case prefix can overflow
even Phase11; the maintained selection keeps the string first. Rejected seed and
broader branch transformations remain excluded. Finite histories do not establish
general stack safety.

Known remaining gaps include parser diagnostics, error spans/text and some
rejection phases. The renderer's selected family is exact in 71 of 78 cases;
seven existing span-origin failures remain. Acceptance/refusal agreement does
not prove the intended rule caused every rejection. The old component suite's
new-upstream diagnostic-source parity failure remains preserved. Native Process
requires a libc symbol unavailable on this host, also blocking upstream. GPU
and interactive devices are unvalidated. Source Nat payloads remain U32-sized;
wider runtime values use dynamic representations. Historical control sets overlap
and must not be summed into a claimed total of unique conformance programs.

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
