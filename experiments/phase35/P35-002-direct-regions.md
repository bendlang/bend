# P35-002 — Guard a useful region once, including pure residual calls

- Owner / independent reviewer: `phase35_regions` / `phase35_research`; root owns serial acquisition and execution.
- Initial evidence cutoff: 2026-10-01 04:13 UTC, retained below as historical mechanism evidence. Final release and preservation closure are appended after the completed checked09 gates.
- Objective: reduce generated-program time and shorten optimization iterations without changing public call stages or source demand.
- Correctness: final checked09 owner controls pass, including purity, Hit, colf and structural folds; all 15 postinstall audit groups, 42 ordinary/relocated CLI checks and 225 canonical file checks pass.
- Measurement: final integrated raytrace improves 5.475× over its same-run Phase32 reference, retaining a 54.781× TypeScript gap. Earlier screens and separate prototype transfers remain distinct evidence.
- Decision: **promoted in installed checked09**, with measured compiler/source-size costs explicitly accepted. No new public ABI, broad backend or self-hosting fixed-point claim.
- [Design](../../design/phase35/direct-regions.md), [implementation report](../../implementation/phase35/direct-regions.md), [independent review](../../implementation/phase35/independent-review.md).
- Final [release](../../implementation/phase35/release-09.md), [conformance audit](../../implementation/phase35/final-conformance/gates.md), [profiles](../../implementation/phase35/profile-findings.md) and [evidence capsule](../../implementation/phase35/evidence/README.md).

## Claim and cheapest disproof

**Hypothesis A — finite decisions:** nested native Nat matchers impose avoidable
descriptor/argument-vector allocation. A private equality chain should reduce the
cost when guarded with its enclosing computation. The default predecessor is the
original Nat minus the number of preceding failed Zero tests; subtraction occurs
only where those tests establish nonnegativity. Leaf expressions and dependencies
stay live. Scope is a complete, bounded, canonical private Nat decision.

**Hypothesis B — conditional countdown:** preserving the public Nat, scalar prefix
and final Bool stages while running complete Bool-tail iterations privately should
remove repeated dispatch without flattening the exported function ABI. Each call
copies immutable captured prefix values to fresh loop locals.

**Hypothesis C — partial region:** expensive residual helpers should not prevent
lowering surrounding cheap work. The ray program visits 1,048,576 column leaves
but only 5,120 active pixels at its documented small input. A direct scalar tree
with generic pixel calls can remove inactive-leaf overhead, provided a separate
typed graph proof establishes that the residual cannot mutate dependencies or
invoke host callbacks during the region.

**Invariant:** canonical scalar roots; closed first-order typed graph; complete
constructor matching; every residual field/branch/callee checked with shared fuel;
definition reservation only after its entire own body passes; one live descriptor
and host guard before entry. Raw/partial/overapplied callbacks retain the generic
path. Generic residual calls delegate to the existing source call emitter, keeping
argument demand and saturation grouping. Standard host intrinsics at module
initialization and the existing dispatch-intrinsic trust boundary remain explicit.

**Disproof:** any changed result, callback/error order, public prefix metadata or
fallback behavior; an absent actual admission witness; any unproved native/foreign,
effectful, higher-order or array path entering purity; resource refusal; or no
transfer beyond an isolated mechanism. Full input checksums remain mandatory.

Whole-compiler rewrites rank after this discriminator: the first standalone Bool
loop gains only 1.074×, motivating a measured change of target to inactive work.
The explicitly unprotected selector ceiling is informative but never promotable.

## Controlled setup

- Baseline: Phase32 checked03 B1-generated programs in the maintained frozen
  [reference manifest](../../selfhost/tools/performance/programs/baseline/manifest.json).
  Compiler source SHA256 `e3cc44245444ac2509431d44c8909692c9223cd977968ffb087771c1ae2859ae`.
- Upstream TypeScript pin: `018751270e800bc222a93dad7f257083ee53a5f7`;
  canonical Base SHA256 `c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661`.
- Frozen original ray module SHA256
  `3d1bc9a29878c1c079fdafcad3e6733037194323edc9a099efd940d811b3b367`.
  Saved-output producers require that exact identity and Acorn 8.16.0.
- Candidate compiler attempts: checked04, checked05, failed checked06, checked07,
  checked08 and checked09. Each attempt manifest freezes source, runtime, Base,
  generated API and checked bootstrap identity; dirty overlays are included there.
- Node 24.18.0, CPU3, serial children, 4 MiB stack and 1 GiB heap; root supervises
  all executions. Mechanism timing/profile runs use a 1.5 GiB process-tree RSS
  ceiling; final release gates use 2 GiB. Both keep a 2 GiB available-memory floor.
- Mechanism screens: three fresh rotations, 350 ms warmup, 50 ms calibration,
  150 ms target. Full transfers: three fresh rotations, 1,000 ms warmup,
  50 ms calibration, 300 ms target. Full calls exceed the target and run once per
  timed sample; they are not subdivided or silently shortened.
- Measurement boundaries: build wall/RSS separately from emitted-program
  milliseconds per complete call. Code-generation receipts establish compilation;
  scalar checksums and public probes establish actual execution observations.

Minimal final-candidate control reproduction, from repository root (fresh output
directories are required):

```sh
node selfhost/tools/performance/phase35/region-pure-guards.mjs \
  selfhost/build/phase35/regions-config09.json selfhost/build/phase35/recheck-pure
python3 selfhost/tools/performance/phase35/region-colf-cohort.py \
  selfhost/build/phase35/combined-full-01/manifest.json selfhost/build/phase35/recheck-colf
node selfhost/build/phase35/recheck-colf/controls.mjs \
  selfhost/build/phase35/recheck-colf selfhost/build/phase35/recheck-colf-controls
```

Use Node24.18.0 under the maintained final-integration resource supervisor with
the final-gate process limits above; do not run these concurrently with acquisition
or timing. The named config and prepared manifest identify the installed checked09
artifact; the fresh `recheck-*` output paths are intentionally absent. Mechanism
runs retain exact consumed configuration in each screen report and exact
producers/modules in its derive manifest.

## Gates and observations

All run names below are under `selfhost/build/phase35/`.

| Attempt / artifact | Correctness result | Time / memory | Interpretation |
|---|---|---:|---|
| selector-controls-01 / selector-screen-01 | 180 value +44 public boundaries pass | 29.532→17.727 ms guarded; 6.438 ms unprotected | 1.666× usable mechanism; 4.587× nonpromotable ceiling |
| branch-controls-01 | 143 numerical +61 boundaries pass, then source-quoted constructor TypeError differs | Failure retained | Both reject construction; raw error retained |
| branch-controls-02 / branch-screen-01 | 143 numerical +116 boundaries pass; only quoted callback text normalized for IsConstructor case | 83.523→77.733 ms | 1.074× standalone loop, generic helpers retained |
| regions-nat-guards-01 | 26 positive/refusal cases pass | Diagnostic recognizer | Includes used predecessor, native identity, 64/65-depth, fuel and stage refusals |
| regions-controls-01 | 177 source oracles +47 boundaries pass | Actual checked04 compiler | Nat offsets, U32/F32 Bool loops, FloatAlias guard |
| regions-ray-controls-02 | 143 numerical +116 boundaries pass | 1.71 s gate | Actual checked04 ray module |
| regions-ray-transfer-01 | Original `bench(80,0)==402971`, 3/3 rotations complete | 8950.426→8202.211 ms; TS34.130 ms | Checked04 is 1.091× baseline, still240.323× TS |
| colf-controls-01 / colf-screen-01 | 57 traversal +200 boundaries pass; active/inactive entry witnessed | 89.042→0.709427 ms | 125.5× at deliberately inactive width0; not full-ray claim |
| colf-ray-transfer-01 | Original unchanged full ray checksum, 3/3 rotations complete | 9152.034→5826.265 ms; TS34.241 ms | Saved-output prototype1.571× baseline; still170.153× TS |
| checked06 | Parser rejects normalization binding before `match xs` | Build failure retained | Fixed by immediate-match helper; no timing admitted |
| checked07 | Checked build/focus pass; all15 maintained points compile | 41.988 s; peak1,077,370,880 B | Corrected partial graph integration |
| checked08 | Checked build/focused36 pass | 41.987 s; peak1,112,576,000 B | Adds independent fold work; no isolated gain claim |
| checked09 | Checked build/focused36 pass | 42.5058 s; peak1,129,676,800 B | Adds inherited numeric prototype-key guard |
| final-plan-09 owner controls | All15 owner groups pass on the selected API | Regions177+47; Nat26; ray143+116; extra180+91; pure37; colf57+200 | Actual checked output and active/inactive witnesses; counts overlap |
| combined-full-confirm-01 | All15 expected results pass | Full ray10291.414→1879.845 ms; TS34.315 ms; full suite518.338 s | Integrated compiler5.475× baseline; still54.781× TS; not an isolated colf gain |
| final-audit09-postinstall | 15/15 audit groups,42CLI,225canonical files pass | Installed API equals checked09 | Scoped release closure; historical backend failures remain visible |
| final evidence capture/reopen | Complete inventory and source rehash pass | 24,717 files;2 volumes | Failed/superseded acquisitions preserved |

The checked04 and saved-output colf gains are separate experiments and are not
multiplied. Final owner gates and combined timing were pending at the initial
cutoff; the appended rows record their completion. A focused 36-observation gate
alone is not a full conformance result. Full final timing uses five rotations for
the shorter points and three for ray, at least one second of warmup and a 300 ms
target; see the [complete measurements](../../implementation/phase35/measurements/full.md).

## Independent audit

The research agent checked private Nat offset provenance, selected-leaf demand,
public Bool stages and aliases; it identified the need to normalize F32 aliases
before placing the Math guard. It reviewed the colf producer and shared purity
analyzer, including SCC reservation and recursive constructor fields. This owner
reviewed the fold frame algorithm and native array-call simplification separately.

Two non-vacuity hazards were corrected: descriptor comparison must use captured
`Object.is` when snapshots include `Number.NaN`, and semantic controls need a real
fast-entry witness. The former was corrected before the first colf acquisition;
the independently owned sum experiment preserves its earlier always-fallback run.
Inherited numeric prototype setters were then identified as residual allocation
callbacks; checked09 rejects changed Array/Object prototype key lists. Dedicated
actual-source probes for numeric keys0/8 subsequently pass on checked09 in the
final extra-region owner group.

## Decision and next discriminating test

The initial decision was to withhold promotion until the final purity, colf,
Hit/partial-tree and full-suite gates executed. Those gates now pass on checked09,
and root has installed and verified that exact compiler after separate normal
compiler-cost measurements. The [admission decision](../../implementation/phase35/performance-admission.md)
accepts the measured compile latency and source/output growth for the integrated
execution gains. This does not attribute all final gains to this one experiment.

The next useful discriminator comes from the separate final profiles: ray's
host/scalar/local entry guards account for 47.24% of sampled CPU ancestry. A
private internal-entry proof could amortize repeated guards while keeping every
public wrapper and mutation fallback. Test that on saved output with an explicit
admission witness before changing the compiler. These diagnostic proportions are
not promised speedups; a failed public-stage, effect or checksum control still
blocks promotion regardless of a mechanism's timing gain.

## Preservation

Tracked design/report, source patches, synthetic proof controls, checked-source
fixtures and acquisition/cohort tools are under the linked phase35 directories.
`region-ray-cohort-v1.py` preserves the failed bundle-role assumption. The original
partial-regions patch and proposed jpure source preserve the checked06 parser
failure; the acquired checked07/08/09 source snapshots contain root's correction.
Each raw run lives under the unique build directory listed above with consumed
tools, hashes, modules, observations and supervisor receipts. The completed
[capsule receipt](../../implementation/phase35/evidence/capture.json) preserves
24,717 files in two volumes, verifies every member on reopen and rehashes the
source inventory. Independent reopening is also complete. The concatenated gzip
SHA256 is `905fca0e9eec65d70b540df8009d4f8f8c67adb1e6ccd9eca4fd2eb980113b31`.
Historical working-tree base commit at the initial cutoff was
`573284adc12cf6406ec584d00cb2d7ac90f072b6`. Final installation is recorded by
[release09](../../implementation/phase35/release-09.md); commit/push publication
remains a separate root action.
