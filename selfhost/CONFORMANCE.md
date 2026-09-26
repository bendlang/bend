# Compiler validation

The ordinary CLI uses the [S3 simplification release](../implementation/phase7/s3-report.md).
Its [manifest](dist/release.json) identifies the exact API/source/runtime/host;
`npm run verify:release` checks local integrity and transformation replay.
Fresh checked build, 21 focused paired cases, all component groups and 52 harness
tests pass. The focused suite retains its seven known exact differences.

Fresh baseline/candidate parse/check vectors compare all 2,756 observations
exactly: 919 positive and 459 negative check fixtures, zero behavioral differences,
and the same 318 strict check failures. Diagnostic reuse passes 204 comparisons;
39 compound-error comparisons and host call counters validate one authoritative
result and four-to-one failure checking. The separately verified host identity
field differs by design; diagnostic text is not normalized.

The [Phase 5 frontend gate](../implementation/phase5/final-artifact-frontend.md)
and full-source fixed point remain historical artifact-specific evidence. S3's
new full frontend preservation gate does not claim complete upstream conformance,
a new live TypeScript diagnostic comparison, or a new B1→H→H proof. Historical
sections retain their recorded scope.

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
