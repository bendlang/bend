# Phase31 inherited correctness gates

Candidate04 passes all six inherited gates. These acquisitions preserve the
maintained test assertions and saved independent references; they do not establish
full-language conformance or a performance ratio. The checked candidate identity is
`attempt-04/attempt.json`, SHA-256
`0767041902dabe950022c39c44fa3d987f8b61a5d5b775725464a55816829ae5`.

The prospective candidate04 plan and machine-readable summary are retained at
[`gates-04/plan.json`](../../selfhost/build/phase31/gates-04/plan.json) and
[`gates-04/summary.json`](../../selfhost/build/phase31/gates-04/summary.json).
The plan records candidate, launchers, original Phase30 plan and corpus baseline
identities. Its six inputs still match their frozen hashes after acquisition.

| Maintained gate | Outcome | Acquisition wall time |
|---|---|---:|
| Selected upstream JavaScript | PASS: 15/15; zero exact differences | 44.107 s |
| Primitive operations | PASS: 56,205 scalar checks; 58 observations | 9.785 s |
| Worker and host boundaries | PASS: 3,759 scalar checks; 14 observations | 6.578 s |
| Nested Nat regression | PASS: 144 checks | 9.885 s |
| Primitive recognizer guards | PASS: 1,129 guards; 25 observations | 1.418 s |
| Representative corpus | PASS: 23 libraries; 127 execution points | 118.655 s |

The wall times describe acquisition cost while other correctness work could run.
They are not clean performance measurements. All outer commands completed within
their bounds: 180 seconds for selected upstream, 300 seconds for the other gates.
They used the maintained Phase30 outer runner on CPU7. The upstream tool retains
its expected CPU4 child configuration; the other children use the already frozen
Phase30 CPU7 launchers. No test, oracle, assertion or inner timeout was changed.
The corpus launcher retains both its consumed originals and the count-checked
path/CPU derivation. Existing reference artifacts were read in place.

Primitive and worker gates compare newly compiled checked Bend sources with saved
pinned-TypeScript and earlier selfhost outputs, with mathematical scalar oracles
and complete value equality. They include signed zero/NaN, partial application,
closure fields and host-observable callback order where applicable. Nested cases
retain their expected `loop:false` shapes. No admission assertion needed amendment.
The primitive-guard gate uses synthetic KDefs for recognizer refusal, generated ABI
and host argument order; it is not a checked-source conformance result. The corpus
compiles all 23 maintained libraries and checks 127 recorded input/result points
against the retained baseline observations. These overlapping counts must not be
summed into a new language-conformance total.

## Retained candidate03 failure

Candidate03 had a packaging defect: the edited runtime core had not yet been
regenerated into the bundled `src/runtime.mjs`. The primitive gate passed its
56,205 scalar checks, but selected upstream execution passed only 14/15. The exact
failure was `compile/erasure_match_arm.bend`: expected `11\n`, observed
`bend: localGuard is not defined\n` with exit status 1. This was a real emitted
program failure, even though the isolated runtime-core support controls passed.

The remaining four candidate03 gates were stopped after that diagnosis. Their
absence is not a pass. The original plan, successful primitive result and failing
upstream result are retained under
[`gates-03`](../../selfhost/build/phase31/gates-03/summary.json).
The root agent regenerated the bundled runtime, built candidate04, and these six
fresh acquisitions target that rebuilt artifact. All candidate03 results remain
unchanged. This finding makes bundle regeneration and testing an emitted consumer
necessary parts of validating future runtime-core edits.

All gate CPU jobs were closed before the subsequent exclusive performance window.
No new PR comment was posted and no commit or push was made by this gate worker.
