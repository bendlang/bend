# Phase13 measurement and replay

Status: both experimental images pass the paired fresh/history correctness gate.
Plain worker lifting takes 1.01% more process time; the selector follow-up takes
6.63% less. The latter justifies inspecting bounded expansion of the same rule,
not promotion. The prospective
[P13-004 plan](../../experiments/phase13/P13-004-measurement.md)
binds released Phase12 API `0975a4a8…`, exact stack histories, resource policy and
separate complexity accounting. Root completed the unchanged-baseline profile
before releasing CPU3 for these correctness checks.

## Initial findings

The unchanged Phase9 `check-matrix.mjs` already verifies genuine attempts,
source/host/runtime/Base identities, API-specific caches, worker affinity,
ordinary type/trust results and complete launch status. Its full-source matrix
is suitable for root's final comparison after integration. It measures request
and process wall separately and documents Bend's validated Base-cache asymmetry
against TypeScript. This owner will not replace that final timing boundary.

Phase12's replay tools retain both the 53-request failing integration history
and the 60-request originally passing Phase11 history. Their original digests
remain useful, but the 53rd historical result is a known rejected compiler's
failure. A generalized candidate gate must distinguish historical reproduction
from the current baseline acceptance oracle. All predecessor results must stay
exact; comparing only the final string result would lose evidence.

The existing no-seed replay script is an experiment-specific predecessor: it
hardcodes image choices, CPU3 and a broad-prototype verifier. Reuse the unchanged
persistent runner and integrity functions, while replacing that orchestration
with an explicit prospective config and current-image identities. Do not alter
the predecessor or its retained observations. A fresh isolated string check
precedes history replay so a simple stack regression fails cheaply.

The current 296-line helper combines historical profiles, tokenization,
runtime/export/protected-binding guards, equality/choice/leaf rewrites and
bootstrap/derivation replay. A replacement must count all retained historical
implementation, parser/rewriter modules and tests, not only the new entry file.
The current pilot adds code; its actual accounting appears below. No speed
result is inferred from the transformation or these correctness runs.

## Static baseline accounting

`measure-preparation-01/complexity-baseline-report.json` counts the frozen
Phase12 helper and maintained tests: 503 physical / 486 nonblank lines and
45,024 bytes in total. The shared current/historical helper contributes
296 / 285 lines and 27,345 bytes; tests contribute 207 / 201 and 17,679 bytes.
The conservative static-import audit finds no unaccounted imports. The tool
records its limitation: dynamic/generated dependencies still require review.
Ten named baseline obligations are declared in the configuration, not inferred
as a scientific complexity score. The counter executes no compiler modules.

The candidate owner has agreed to deterministic
`transform(source, options) -> {source, report}` and explicit checked-parent,
baseline/API, helper, runtime, Base and derivation identities. Compatibility
must first reproduce version5 bytes and statistics exactly. A lifted-worker
image is a distinct derivative with its own options and report.

## Calibration harness

`measure-calibrate.mjs` freezes its own source and the consumed unchanged
Phase12 no-seed prefix tool, then prepares a private byte-identical host project
and validated cache for the isolated string check. It wraps every launch with
the maintained supervisor and rejects errors/signals/deadlines/overflow.
Each persistent history runs through the proven predecessor, retaining all raw
digests, and the wrapper additionally compares every result with the previously
released Phase12 history. The 53rd historical seed failure remains visible while
the current target must accept. No request timing is promoted from calibration.

`measure-calibration-01/report.json` completes successfully on CPU3. The fresh
6,000-character string accepts in check phase with ordinary proof trust passed.
Both histories complete without restart or launch/protocol failure: all 53 and
60 complete results agree exactly with their previous released Phase12 vectors.
Every original digest remains recorded; the 53rd historical seed failure is
still distinguished from current acceptance. The preserved original and copied
input identities remain unchanged. Outer stdout/stderr are retained alongside
the run directory. These observations calibrate the current baseline and do not
validate any new transformation or establish a speedup. All calibration CPU jobs
have ended. Calibration stays separate from candidate observations.

## Experimental image and paired replay

The frozen `rewriter-norm-eval-01/manifest.json` identifies API
`d74ecdbd243bb1bafe4ed726b1b697ccb3b942ca39a0b7a8dfe27e5ff5581554`
as an explicit derivative of genuine checked parent `a8453133…`, preserving
released v5 baseline `0975a4a8…`, runtime, Base and public exports. It lifts seven
selected choices into 14 workers, with 63 explicit capture parameters. This is
an experimental image, not a new bootstrap or maintained v6 profile.

`measure-inputs.mjs` verifies the parent attempt and all manifest/helper inputs,
then independently repeats the exact transformation and compares both complete
source bytes and transformation report. That replay is repeated after the gate.
Private host copies retain the verified snapshot bytes. The baseline uses its
existing validated Base cache; the candidate checks Base through the unchanged
driver to create its own cache. Cache preparation is outside workers and timing.

`measure-norm-eval-history-01/report.json` passes on CPU3. Each image passes the
fresh pinned 6,000-character string check with ordinary check/proof-trust success.
Each also completes both exact 53- and 60-request histories: 226 complete replay
observations across the paired images, plus two isolated fresh observations.
Every result equals the corresponding retained released Phase12 result, and all
candidate results equal the newly reproduced baseline results without result
normalization. Original historical digests, including the 53rd seed failure,
remain recorded separately. There are no unexpected worker generations, early
recycles, errors or input drift. Node24.18.0, 4MiB stack, 4GiB heap, 30s request
deadlines and the original worker/recycling policy remain unchanged.

The outer supervised launch exits cleanly with no signal, launch error,
deadline or output overflow; its durable execution record is
`measure-norm-eval-history-01-launch.json`. Intermediate reports and consumed
tool copies remain alongside complete vectors. These correctness observations
do not measure compiler speed or prove arbitrary-history stack safety.

## Pilot timing preparation

`measure-pilot.mjs` requires the passed paired gate and an explicit root-authorized
configuration. `measure-preparation-01/pilot-norm-eval-config.json` selects the
exact parent assembled compiler source, CPU0 and opposite-order ABBA sampling.
The unchanged Phase8 worker records ordinary type acceptance and expected unsafe
trust, request and process time separately, input integrity and affinity. The
runner additionally compares complete compiler results across all four rows.
It rejects error/signal/timeout/overflow even when a process returns exit zero.
All host and API-specific cache identities are checked before and after samples;
Base preparation and deterministic transformation replay stay outside timing.
Root owns authorization, exclusive execution and interpretation. No TypeScript
ratio can be inferred from this two-image pilot.

Root completed `measure-norm-eval-pilot-01/report.json` in an exclusive CPU0
window. All four complete ordinary results are identical and all launch/input
checks pass. The fixed baseline–candidate–candidate–baseline order gives:

| Two-sample mean | Phase12 baseline | Plain worker lifting |
| --- | ---: | ---: |
| Process wall | 27.454s | 27.732s |
| Request | 26.307s | 26.584s |

The candidate takes 1.01% more process time and 1.05% more request time. Two
samples do not establish a precise small regression, but they provide no
evidence for the required material gain. Independent allocation accounting
explains the tradeoff: named workers eliminate closures while retaining the
dispatch and adding explicit capture-array slots. This image is not promoted.
The consumed v1 measurement tools remain unchanged; a separately named v2
binder/harness can inspect the next selector derivative without rewriting this
comparison's inputs or outcomes.

## Current pilot complexity

`measure-preparation-01/complexity-pilot-report.json` counts the actual imported
implementation, including the full historical helper retained by structured
v5 compatibility. The conservative static-import audit has no missing imported
modules. The following totals are code needed by the experimental image; they
are not a claim that the experiment is already promoted maintenance code.

| Surface | Physical lines | Nonblank lines | Bytes |
| --- | ---: | ---: | ---: |
| Phase12 helper, active and historical | 296 | 285 | 27,345 |
| Pilot structured support plus wrappers/lifter | 355 | 347 | 19,896 |
| Pilot including retained historical helper | 651 | 632 | 47,241 |
| Same retained maintained helper tests | 207 | 201 | 17,679 |
| Pilot implementation plus those tests | 858 | 833 | 64,920 |

The pilot therefore adds 355 helper/support lines; it has not reduced the
296-line maintained baseline. Its entry point does not hide the imported old
helper. Additional experiment orchestration, independent semantic controls and
measurement tools are separate experimental surfaces and are not credited as
removed production lines. The obligations also grow: structured token spans,
capture/binding analysis, deterministic named worker extraction and explicit
capture vectors supplement historical replay, guarding and runtime provenance.
Only a later actual replacement could support a simplification claim.

## Selector follow-up

The separately frozen `selector-norm-eval-02/manifest.json` identifies API
`5a1a9449ec9a190e1bee0b695d211fd83e5672a6e1fc87623c3e3826268d4441`.
It removes intermediate tag-selection steps while retaining selected branch
arrows, rather than introducing explicit capture arrays. Root retains the first
preparation's guard failure separately; no API was produced by that failed run.
The old measurement tools remain unchanged. New `measure-*-v2.mjs` copies only
generalize the permitted experimental manifest kind and their local imports;
`measure-preparation-02/preserved-v1-inputs.json` retains the consumed v1 hashes.

After the independent actual selector controls passed, CPU3 ran
`measure-selector-history-01/report.json`. Both fresh checks and all 226 paired
history observations pass with unchanged complete results, resources, workers
and verified inputs. The clean supervised launch is retained at
`measure-selector-history-01-launch.json`. The exact transform source and report
replay before and after the gate. This extends correctness evidence only; the
53rd historical seed failure is still retained, not silently replaced.

The follow-up's current code also grows the baseline: the actual selector,
shared structured view, compatibility wrapper and complete retained historical
helper total 626 physical lines, versus 296. Including the same 207 maintained
test lines gives 833 physical / 809 nonblank lines and 63,817 bytes. These counts
are in `measure-preparation-02/complexity-selector-report.json`; no imported
static dependency is omitted. Independent experimental controls and timing tools
remain additional experimental surfaces, not a source-line reduction.

`measure-preparation-02/pilot-selector-config.json` freezes the same source and
CPU0 ABBA policy. Root's completed exclusive comparison is retained in
`measure-selector-pilot-01/report.json`: all four ordinary complete results and
input/launch checks pass. Mean process wall falls from 27.330s to 25.517s,
6.63% less; request time falls 6.91%. These are two samples per image under the
fixed opposite order, not a TypeScript comparison or a generated-program speed
claim. The selector pilot improves checking without yet meeting the roughly
20% promotion target or reducing maintained complexity. Root has authorized a
bounded inventory of other sites admitted by the same exact rule. Its outcome
must justify a separately frozen expanded candidate and repeated correctness
gates; this one-family image is not promoted. All measurement CPU jobs are closed
and raw comparison inputs remain unchanged.
