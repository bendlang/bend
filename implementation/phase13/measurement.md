# Phase13 measurement and replay

Status: the three experimental images pass the paired fresh/history correctness
gate and exclusive pilot comparisons. Plain worker lifting takes 1.01% more
process time; selector fusion takes 6.63% less; the constant-scope expansion
takes 10.56% less. Root defers production promotion: the best result falls below
the agreed roughly20% target and the concrete standalone helper is larger.
The usable Phase12 compiler remains selected. The prospective
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

## Constant-scope expansion gate

The prospective [P13-006 plan](../../experiments/phase13/P13-006-constant-scope-selectors.md)
permits narrowly guarded local constants while preserving their initialization
and demand positions. The separately frozen
`rewriter-selector-const-combined-01/manifest.json` identifies API
`7eca544a1f2e3ab637064533117f290bd576c5774d111a619fdd12755817c81e`.
It selects six checking owners accepted by the actual transform; it does not
silently weaken the refused `core_subst_stable` case.

After the independent extended semantic controls passed, the unchanged v2
measurement tool ran `measure-const-history-01/report.json` on CPU3. Both fresh
6,000-character checks and all 226 paired exact-history observations pass with
complete results equal to Phase12. Original digests and the historical seed
failure remain distinct. There are no worker restarts, errors or input changes;
the full transformation and report replay before and after execution. The
supervised launcher closes with exit zero and no error, signal, timeout or
overflow. Resources and cache policy are unchanged. This is another experimental
derivative gate, not a new checked bootstrap or final conformance suite.

The actual prototype dependency count is 640 helper/support/legacy physical
lines, or 847 including the same 207 retained maintained test lines: 823
nonblank lines and 64,819 bytes. The exact report is
`measure-preparation-03/complexity-const-report.json`. This includes the full
historical helper and does not assume that a future integration removes code.
Root completed the exclusive ABBA run using the frozen
`measure-preparation-03/pilot-const-config.json`. The completed
`measure-const-pilot-01/report.json` passes all four complete-result and input/
launch checks. Mean process wall falls from 27.362s to 24.474s, 10.56% less;
mean request time falls from 26.207s to 23.327s, 10.99% less. The unchanged v2
measurement tools and all raw samples remain retained. No additional experiment
is planned by this owner.

## Final complexity and decision

The implementation owner also prepared one actual standalone feasibility helper,
not merely an estimate of future deduplication. Its frozen identity is
`cdf6d41c68b79d77b120ab6e367c2805a94c512338c5672afee21144c49df6d4`
at `rewriter-maintained-01/project/tools/development/equality.mjs`. Independent
static accounting in `measure-preparation-05/complexity-standalone-helper-report.json`
finds 535 physical / 519 nonblank lines and 34,355 bytes, including historical
profiles. It imports only Node built-ins: no legacy helper or parser dependency
is hidden outside that total. Against 296 / 285 lines and 27,345 bytes, it adds
239 physical lines and 7,010 bytes, about 80.7% more lines and 25.6% more source
bytes. Independent experiment controls remain additional code. The preceding
`measure-preparation-04` audit is retained: its import check correctly identified
that adding the old tests at their original path still imports the old helper,
so that aggregate cannot describe a runnable standalone replacement test bundle.
The final comparison counts the actual two helper files directly; it neither
hides that unresolved test dependency nor credits tests as removed code.
The owner's closed `rewriter-maintained-replay-01/report.json` separately verifies
authentic v1–v5 bytes/statistics with both lineage verifiers and reproduces the
same `7eca544a…` API/report through the feasibility helper's default and explicit
v6 profile. That compatibility success does not install or promote the helper.

The structured implementation therefore demonstrates a bounded checking speed
gain, but no reduction in implementation length or obligation count. Historical
reproduction, selector scope, Unit demand, constant initialization and resource
behavior still require distinct guards and evidence. Root's decision is to keep
Phase12 installed and preserve these experimental results for future work.
No Phase13 production release, fresh TypeScript speed ratio, full conformance
claim, new bootstrap or generated-program runtime improvement follows from
these pilots. Calibration, three candidate gates and three exclusive ABBA
comparisons remain separate retained runs. All owned compiler/CPU jobs are
closed, consumed inputs remain unchanged, and this owner has performed no
archive capture.
