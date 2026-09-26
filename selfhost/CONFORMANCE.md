# Compiler validation

The ordinary CLI now uses the [consolidated Phase 5 release](../implementation/phase5/consolidated-release.md).
Its [manifest](dist/release.json) identifies the exact API/source/runtime/host;
`npm run verify:release` checks local integrity and transformation replay.
The [final frontend gate](../implementation/phase5/final-artifact-frontend.md)
preserves all 2,756 checked-parent observations for this optimized artifact,
including 318 strict failures. Historical sections below retain their recorded
artifact scope and do not substitute for the current release's separate gates.

[S1](../implementation/phase7/s1-report.md) rebuilds that same selected API from
15,961 lines of source after retiring unreachable private declarations. Both
checked and optimized API bytes, runtime and host are unchanged. S1 has fresh
checked, component and selected-control evidence; it does not claim a new broad
conformance run or full-source self-host fixed point.

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
