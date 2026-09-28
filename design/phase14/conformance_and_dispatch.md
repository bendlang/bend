# Phase14: semantic conformance and source-level dispatch

Status: prospective plan frozen before implementation and measurement, 2026-09-28.
The user authorizes the recommended next phase: fix the four imported-law gaps,
classify exact differences and address one shared cause, and run one bounded
source-level normalizer dispatch experiment. Designs, actual results, failures,
release documentation and evidence will be committed and pushed. Historical
six/ten-hour authorizations are not renewed. The dispatch feasibility work has a
90-minute cap; conformance and a usable validated release are the main outcome.

## Starting point

Repository HEAD is d0d587800eb266aee38d0044f6f39b4fe8cbec1b. Installed Phase12
API is 0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697,
checked parent a8453133f37a0965b7291795af2e06c7c65e3ee7c97a8ff4b14b98cfba2e5568.
The upstream pin remains b2111cf43244e65f76ddc278ee695e669f720cbf. Neither the
pinned checkout nor human-written bend2/bend.ts will be edited. All 75 unrelated
Phase6 dirty files are preserved and excluded from staging; initial identities
are in selfhost/build/phase14/start-state.json.

The last full frontend gate contains 2,996 parse/check observations of 1,498
fixtures. All 1,001 positive programs accept types and all 482 validation negatives
reject. Four imported-law cases fail early; seven of eleven trust-refusal cases
reach their intended phase. There are 730 exact reference differences, including
198 parse and 532 check differences, and strict checks report 1,006 passes / 492
failures. These are different axes, not 730 independent semantic defects.

The last paired full-source checking result is 26.8969 s versus TypeScript
2.8550 s, a 9.42× process gap. The observed checked-build plus 22 focused cases
spans 27.59 s. These distinct workloads are not interchangeable. Phase13's
uninstalled selector prototype uses 10.56% less checking time but adds 239 helper
lines / 7,010 bytes; it remains preserved and uninstalled.

## Workstreams and sequence

### 1. Imported-law semantics (P14-001)

Reproduce import/unsafe_law_derived.bend, unsafe_law_fill.bend,
unsafe_law_own.bend and unsafe_law_unused.bend with the frozen released API and
pinned TypeScript. Read their complete import graphs and the upstream and Bend
implementations. Find the first divergence before changing code. Keep parsing,
type acceptance, proof trust, checked status, error phase and exact output separate.

Implement the smallest shared correction in an isolated source snapshot. Preserve
namespace/import identity, declaration chronology, legal law fills, duplicate
refusal and dependency trust. Imported unsafe declarations must not silently
become proofs. Add boundary tests for the actual rule and its negative cases.
Use genuine checked B1 development and focused differential gates after each
source edit. Only verified patches are considered for root integration.

### 2. One shared exact-difference cause (P14-002)

Classify the retained 730 observations by lane, phase, diagnostic shape and likely
shared implementation path. Preserve every original fixture and observation;
normalize only for clustering, never for pass/fail comparison. Count observations
and unique fixtures separately. Read concrete examples and pinned code before
selecting a family. Prefer a shared correction with clear semantics and a small
patch, not widespread copied output strings or weakened comparison rules.

Record the chosen cause and expected changed cases before executing its candidate.
One bounded family is the deliverable; do not promise elimination of all differences.
Validate exact output and unchanged acceptance/trust/error precedence on relevant
positive and negative controls. Coordinate with the law workstream where paths
overlap; snapshots are independent and only root edits the live production source.

### 3. Simpler source dispatch feasibility (P14-003)

Begin with norm_eval_node only. Use Boolean-parameter match workers following the
successful Phase10 index-lookup pattern. Do not retry the retained rejected local
Boolean-match form. Keep conditions and branch demand in order, preserve the
normalizer fallback allocation and selected computation boundaries. Do not revive
broad generated-JS inlining or the rejected normalizer seed change.

First inspect upstream emitted code: does the source shape eliminate intermediate
selection work or create a loop? Count actual dispatch/closure/capture work on
valid fixed small graphs. Stop if it merely transfers allocation or needs broad
infrastructure. Include all added Bend laws/helpers, maintained JS and tests in
complexity accounting; no line reduction through minification or formatting.

Before timing, require relevant semantic/demand controls, a fresh long string,
and the exact retained 53/60-request histories at the original 4 MiB stack and
4 GiB heap, with every predecessor compared. Failed controls remain failures.
No worker recycling or ordering changes may mask a resource regression. A passing
single-owner pilot may be judged useful without an arbitrary universal speed
promise, but expansion beyond this bounded source family needs a separate decision.
Promote only a useful measured gain with proportionate total maintenance cost.

## Ownership and resource policy

Agents own disjoint Phase14 tool/report names and isolated source snapshots under
selfhost/build/phase14. Root owns integration, user documentation, ledger, release
and final evidence. No agent installs or commits production changes independently.
Each owner retains exact inputs, consumed helpers, commands and all failed attempts.
Plans are prospective inputs; outcomes go in implementation/phase14 reports.

Cheap read-only analyses can run in parallel. Timed workloads are serial and
exclusive of intentional compiler/archive jobs. Owners request an explicit timing
window from root. Check process-launch errors, signals, timeouts and overflow as
well as exit status and semantic results; status zero alone is not success.
Use Node 24.18.0 and the existing pinned tools/resource policy. Prefer short
selected gates and reuse verified snapshots; do not rebuild unchanged compilers
or run broad suites on each small edit.

## Integration and release gates

Combine only independently surviving patches in a fresh checked B1 attempt. Keep
raw checked B1 and guarded equality derivative identities distinct. Protected
profile changes require exact dependency review and historical replay, never a
weakened generic allow-list. The released host/runtime/default remain intact until
all applicable gates complete.

For frontend changes run the maintained focused selection plus new semantic and
exact-output witnesses, then one complete candidate frontend inventory against
the retained unchanged-pin reference and Phase12 vector. Account explicitly for
all changed observations, including intended diagnostic changes. No positive
acceptance or negative refusal regression is allowed; known gaps stay visible.
Run applicable backend/release/relocated smoke gates because the frontend is
shared by check, interpreter, JS and native workflows. Revalidate exact saved stack
histories for any surviving dispatch change on the integrated artifact.

Measure complete-source checking on the exact final source against frozen Phase12
and pinned TypeScript with serial alternating fresh processes, recorded cache
preparation, CPU/stack/heap and full-result oracles. This supplies a current ratio
and checks performance regression after semantic fixes. Exclude preparation,
profiles and counters from controlled timing. Report process/request boundaries
and memory, and avoid multiplying historical gains. Broader self-reproduction,
Lean and GPU work are outside this phase unless a concrete regression requires it.

## Deliverables and completion

The final report identifies each hypothesis, actual correction, passing/failed
scope, source/helper/test complexity, complete conformance deltas and fresh paired
performance. Update the compiler guide, README links, conformance/architecture
boundaries, experiment ledger and steering. Release one usable compiler if the
candidate passes; otherwise preserve the old default and clearly report blockers.

Freeze all producers before evidence capture. Preserve exact original and failed
records, sources, snapshots, histories, artifacts and measurements durably, with
explicit external dependencies and independently verified byte/mode recovery.
Keep publication metadata outside captured roots. Explicitly stage only owned
Phase14 work and intended production/documentation changes, verify unrelated
Phase6 hashes/statuses, commit, push selfhost/bootstrap and verify remote HEAD.
