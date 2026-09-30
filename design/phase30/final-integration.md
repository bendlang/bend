# Freeze and validate the final Phase30 compiler

This is a prospective release checklist. Bind it to one completed checked
attempt after the selected improvements settle. Earlier attempt07 integration
is useful regression evidence but does not certify the final image. Do not
rerun the broad suite for each intermediate prototype, and do not count reused
historical frontend evidence as a fresh final-image run.

`inspect-final-integration-plan.py FINAL_ATTEMPT NEW_OUT` will record the exact
attempt, API, runtime, Base, driver and consumed gate identities, produce fresh
configs, and list commands. Preparing the plan executes no compiler or tests.
Every run gets a new output directory; failures and timeouts stay retained.

## Fresh selected correctness gates

Use the established Phase30 derivation of the Phase29 launchers. The test
selection, expected results, child limits and source programs stay unchanged.
These run serially outside clean timing windows. For the candidate attempt12
integration, derive the inherited and corpus/component launchers from their
retained bytes onto CPU7, recording only tool-root/resource substitutions.
The upstream validator reads CPU4 from the immutable attempt and runs only
after the parent releases that acquisition CPU. The parent separately owns the
original-ten acquisition on CPU4; do not duplicate it.

| Gate | Scope and acceptance |
| --- | --- |
| Checked attempt validation | The build's36 maintained exact controls; require successful immutable attempt and equality provenance. Do not repeat the same36 through a second launcher. |
| Selected upstream JavaScript | Existing15 exact execution probes, zero exact differences. Retain complete upstream and candidate observations, including any shared failure. |
| Primitive execution | Existing scalar primitive oracle against saved pinned TypeScript and pre-worker Phase27 references; all56,205 observations must pass in the maintained suite. |
| Native worker execution | Existing worker and nested-worker oracles, including ordered evaluation witnesses; preserve their3,759 scalar and144 nested observation scopes. |
| Primitive refusal | Existing1,129 synthetic admission/refusal controls against the actual final API. |
| Worker refusal | Reuse the exact Phase30 attempt07 adapted guard tool: erased-let intentionally refuses the fast path, while its original erased-RHS semantics witness remains. All40 cases and both execution witnesses stay. Rebind only API/runtime/Base/driver to the final attempt. Do not rerun the obsolete positive assertion and then hide its failure. |
| Library corpus | Existing23 checked libraries and127 complete points against the unchanged Phase25 reference manifest. |
| Real compiler component | Fresh checked membership component and its22 full observations. |
| Whole application | Fresh checked HVM5 demo emission and exact entire stdout, empty stderr. Its saved comparison references are TypeScript and Phase27, not Phase29. |
| New Phase30 rules | Owners run the existing final-artifact exact-entry, live-descriptor, scalar-region, terminal-record, ordinary-root and tree controls, including the independent refusal books. Associate each receipt with the final API/runtime/emitted module hashes; avoid duplicate runs of the same observation through differently named wrappers. |

Run the ten original-program acquisition once as another correctness gate.
`acquire-transfer.py` verifies each source, saved TypeScript/Phase29 module and
checked emission receipt before compiling the final side and checking its full
original point. Its elapsed durations are acquisition costs, not controlled
compiler or generated-program timing.

## Final generated-program comparison

Use the acquired ten original programs, original arguments and full expected
outputs. Report each case separately against pinned TypeScript and Phase29;
an overall arithmetic average would conceal both large gaps and regressions.
Keep first-call and warmed execution separate, module sizes and provenance
visible, and an explicit list of missing/failed cases if any gate fails.

The maintained `phase29/compare.py` transfer protocol has five rotating fresh
process samples per side, minimum three warmup calls and1000ms warmup,100ms
calibration,300ms timed target and120s per child. This remains the final protocol.
Do not use the microbenchmark confirmation's100-call floor on full programs.
Split the config into one file per case so completion and failure are independent.
Do not omit the slowest cases or replace their original inputs with small ones.

The standard Phase30 launcher's600s outer deadline may be too small for raytrace:
one slow side can execute about31 complete calls across checks, calibration and
five samples. A separately recorded1,200s outer limit for each original-program
case is permitted prospectively; the per-child120s limit and sample protocol
remain unchanged. Record start/end, command, stdout/stderr, timeout and hashes,
including when the outer limit expires. This is an explicit full-program cost,
not a relaxation after observing a failed run. Budget roughly15–20 minutes for
the complete exclusive timing window; stop and retain evidence if reality
exceeds that estimate rather than silently dropping points.

All other compiler builds, controls, profiles and counters pause during the
clean CPU3 measurement. Static documentation may continue. Preserve sample
order, raw repetitions, checksums, first calls, warmup counts, half drift and
peak RSS. Single-repetition slow samples have no within-sample drift estimate.
Run the existing timing receipt audit over completed comparison reports.

## Ordinary compiler cost is a separate measurement

Reuse unchanged `phase23/check-matrix.mjs` and its Phase8 worker, as in Phase24.
Use the same frozen compiler-source workload SHA-256
`fac061286a2683914244178eb1f9b4dc2fbc2d393560739663e8bd08bbc12996`.
Compare pinned TypeScript, the usable Phase29 attempt04, and the final attempt.
Freeze three rotating observations per side on CPU0,4MiB stack and4GiB heap,
180s per child. Run this in a separate exclusive interval from CPU3 timing.

Each Bend image uses its own validated Base cache and frozen host; TypeScript
checks the same pinned Base. The complete result must agree after separately
verifying the permitted host-provenance field. Ordinary type acceptance plus
unsafe-proof refusal is the expected observation, not a successful proof-kernel
check. Report process wall, request wall and peak RSS independently. Process
time includes startup and input-union identity hashing; request time includes
lazy API loading. No emitted program execution or emission is inside this
ratio. This nine-observation screen is a regression/cost check on one workload,
not evidence of a newly self-emitted fixed point or universal compiler speed.

Do not use the top-level historical performance runner with its obsolete pin.
Do not compare the new absolute wall values to old screens with a different
hashed input union to infer a startup trend.

## Installation, relocation and evidence closure

After correctness and the final artifact decision, the parent installs the
selected attempt through `tools/development/release.mjs --install-attempt` and
runs `--verify`. Installation verifies current canonical sources/runtime/host
against that immutable attempt and preserves old release history. It does not
build a new compiler. Retain the exact selected API and derivation identity.

Run the maintained Phase23 release-smoke launcher once against the installed
project and expected API hash. It performs42 checks across ordinary and copied
relocated installations, including release verification, version, checking,
interpretation, JS emission/execution and native emission/build/execution on
three fixtures. It uses CPU1,20-minute outer and180s child limits and the recorded
Clang16 toolchain. The copied installation omits the upstream checkout; recorded
historical absolute paths remain provenance data. This is relocation validation,
not operating-system isolation or broad native-backend conformance.

At closure verify the installed API/runtime match the selected image, all
consumed identities still match, untouched upstream sources and103 unrelated
initial dirty-file identities remain preserved, and every reported result links
to its receipt. The parent owns release mutation, capsule generation and commit
and push. No PR comment is authorized by this checklist.

## Exact scope of conformance claims

Fresh evidence here is the final build's36 controls, selected backend gates,
corpus/component/application points, original ten programs, new-rule controls
and release smoke. Phase24's3,026/3,026 main exact and196/196 broader exact
frontend observations remain historical unless separately rerun. Their raw main
statuses2525pass/497observed/4fail are not rewritten: four fixtures expect a
later emission error and match on both frontend sides. The historical81/81
backend pilot covers77 execution rows, not all2,654 eligible opportunities.
No new independent BendTT, broad native/GPU, network, ThreadSanitizer or full
selfhost fixed-point claim follows from this selected JavaScript release gate.
