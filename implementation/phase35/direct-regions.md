# Direct regions: finite Nat, final Bool and pure residual calls

**Final status: checked09 is installed and verified.** The
[release record](release-09.md) and [final conformance audit](final-conformance/gates.md)
record all 15 owner groups, 15 postinstall audit groups, 42 ordinary/relocated CLI
checks and equality of all 225 canonical snapshot files. The
[evidence capsule](evidence/README.md) is captured and independently reopened:
24,717 files in two volumes, including failed and superseded experiments.

Historical cutoff, 2026-10-01 04:13 UTC: checked09 had passed only its checked
build and focused 36-observation gate; final owner controls and combined timing
were pending. Checked04 and the separately derived colf prototype had completed
their distinct full-ray comparisons. The mechanism narrative below retains that
sequence; the final results in the next section supersede its pending status.

## Final checked09 results

The combined compiler's unchanged full raytrace improves **5.475×** over the
same-run Phase32 reference: 10,291.414 → 1,879.845 ms per call; pinned TypeScript
takes 34.315 ms, leaving a **54.781×** gap. All fifteen maintained execution points
complete with exact expected results. Symbolic regression improves **6.865×**
(106.609 → 15.529 ms; TypeScript 1.108 ms). These are integrated-compiler results,
including private state and structural folds; earlier isolated gains must not be
multiplied into them. The [full measurements](measurements/full.md) and
[performance admission](performance-admission.md) retain every case, timing
spread, generic-row recheck and accepted compiler/source-size cost.

Final owner controls use the selected checked09 API and its checked emissions:

| Owner control | Final observed result |
|---|---|
| Finite Nat/F32/final Bool source fixtures | 177 independent results + 47 public boundaries pass; alias guard placement checked |
| Finite Nat recognizer | 26 admission/refusal cases pass |
| Actual ray final-Bool path | 143 independent results + 116 public boundaries pass |
| Hit fields and independent partial-tree fixture | 180 independent results + 91 boundaries pass; inactive/active private entry witnessed |
| Pure graph recognizer | 37 admission/refusal cases pass |
| Actual ray partial-column path | 57 traversal oracles + 200 boundaries pass; inactive/active private entry witnessed |

These finite scopes overlap and do not prove universal JavaScript-host
equivalence. They include inherited numeric prototype hooks and retained public
prefixes. The backend audit preserves 69 passes, 8 not-applicable observations
and 4 shared failures; no full-backend, GPU or new self-hosting fixed-point claim
is made. The final audit binds each owner report through checked-emission/cohort
receipts to the selected API and attempt.

The separate [24-profile analysis](profile-findings.md) shows the next targets:
ray entry guards account for 47.24% of sampled CPU ancestry, while symbolic
regression's generic producer accounts for 64.33%. These single-profile
diagnostics motivate amortizing internal guards and improving local producers;
they do not authorize removing public guards or predict proportional speedups.

[Design](../../design/phase35/direct-regions.md) records the prospective invariant.
[Patch](direct-regions.patch) extends only `region.bend` and the private-node
expression emitter. The branch scanner retains ordinary leaf analysis, the shared
helper dependency list and fuel. Default binders retain their original type and
identity through a positional Nat-minus-offset mapping. Runtime, Base and public
function representations are unchanged by this patch.

An independent static review found no blocking issue for the admitted private
canonical-Nat domain. It specifically checked the predecessor nonnegativity
invariant, `j_env`'s tag-independent type lookup, helper/dependency propagation,
selected-arm demand and the last-argument saturation restriction. Static review is
not an executed correctness gate.

The saved-output producers are:

- `selfhost/tools/performance/phase35/region-selector-derive.mjs`: parses the
  exact generated raytrace module with Node's embedded Acorn and preserves all
  non-selector source. It writes baseline, guarded and explicitly unprotected
  selector variants. The wrapper's scalar result observes all selected values.
- `region-selector-controls.mjs`: independent source-value oracle, selected-leaf
  dependencies/errors, public callback boundaries and prototype fallback probes.
- `region-nat-guards.mjs`: synthetic native-owner, completeness, order, fuel,
  chain-depth, input-position and used-default-binder recognizer controls. It
  appends diagnostic exports to the checked API without changing its bodies.
- `region-finite-nat.bend`: checked-source transfer fixture with two selector
  positions, repeated used remainder and an enclosing Nat countdown.

The saved-output variant is distinct from the compiler patch. Its per-selector
entry/prototype guard may outweigh the removed work; it is a falsifiable cost
screen, not the selected production architecture. The private compiler patch
amortizes existing guard work over its enclosing region and does not inspect
benchmark names or replace benchmark source.

## Integrated compiler changes

`branch-loop.patch` adds the final-Boolean countdown recognizer and planner while
retaining the original public Nat/scalar-prefix/Boolean stages. `float-regions.patch`
adds F32 admission with a host-intrinsic/protocol guard preceding input validation.
It changes `runtime/js/core.mjs`; the assembled runtime must be regenerated through
its maintained builder after integration. Both are integrated in checked04 and
later candidates. Integer-only regions without residual calls or folds retain
their previous guard behavior.

Independent static review of the other workstream's private vector scalarization
found no blocking issue: fresh next-field destinations precede all current-slot
updates, zero rebinding reconstructs complete state, virtual matching requires a
complete same-arity unpack, and general reification preserves inner Array aliases.
The closed private type boundary excludes observable outer-vector identity.
Root subsequently executed the alias/zero/deep fixtures on final checked09;
their passing receipts belong to the final owner closure.

`record-compare-fields.patch` is a later proposal over the sequential Nat/F32/branch
scratch tree, integrated by root into checked05. That candidate passes checked
acquisition and the focused 36-observation gate. The rule admits only native
comparisons on inert operands inside terminal record fields. It is not part of
checked04 or its earlier measured result. Final checked09's Hit-field controls
subsequently pass as part of the 180-result/91-boundary extra-region group above.

## Executed mechanism screens

Root acquired these serially with Node 24.18.0, CPU3 and the maintained execution
worker. Exact producers, modules, observations and resource receipts remain under
`selfhost/build/phase35/`; the phase capsule/report supplies durable preservation.

| Screen | Baseline median | Candidate median | Baseline / candidate |
|---|---:|---:|---:|
| Five selectors, 4,096 indices, guarded standalone switch | 29.532 ms | 17.727 ms | 1.666× |
| Same selector screen, unprotected mechanism ceiling | 29.532 ms | 6.438 ms | 4.587× |
| 1,000 complete `nearest.t` calls, loop with generic helpers | 83.523 ms | 77.733 ms | 1.074× |

These are three fresh rotations with a 350 ms warmup, 50 ms calibration and
150 ms target; they are fast mechanism screens rather than steady-state claims.
The unprotected selector variant remains explicitly nonpromotable. The large
gap between guarded and unprotected selection supports amortizing guards over a
larger proved region. The branch-only gain is small because all intersection and
selector calls remain generic; it does not measure the combined compiler rule.

`selector-controls-01` passes 180 independent F32-value observations and 44 paired
boundary observations. `regions-nat-guards-01` passes all 26 synthetic recognizer
observations, including used remainder slots, 64/65-depth and ownership refusals.

The first branch control run passes 143 numerical cases and 61 boundaries before
stopping on V8's constructor TypeError string: both callbacks reject construction,
but V8 quotes their different source text. That failure and v1 producer remain
preserved. The separate v2 control normalizes only the quoted callback text for
that explicit IsConstructor test while retaining raw observations; all 143 oracle
and 116 boundary observations then pass. No ordinary error, effect sequence or
numeric result is normalized.

`region-acquire.py` now acquires independently checked finite-Nat and U32/F32/alias
fixtures from the historical checked baseline, the candidate and pinned upstream.
`region-controls.mjs` supplies independent arithmetic and public mutation/order
controls, including the previously identified unused-F32-alias guard boundary.
`region-ray-cohort.py` adapts the preserved v2 ray controls to actual checked
compiler modules, changing only the provenance label and structural marker.
Its first acquisition failed because the frozen bundle contains both baseline
and TypeScript roles; v1 is preserved and v2 requests both roles before selecting
the baseline control module. This was a cohort-tool failure, not a compiler
correctness observation.

The acquired checked04 ray module passes the same 143 numerical and 116 public
boundary observations in `regions-ray-controls-02` (1.71 seconds reported by the
root supervisor). This tests actual compiler output, including the combined Nat
selectors, floating private graph and preserved final Boolean stage. The separate
`regions-controls-01` source-fixture gate passes 177 independent numerical cases
and 47 paired boundaries, including both Nat remainder positions, U32/F32 Boolean
countdowns and the unused floating-alias Math guard.

`regions-ray-transfer-01` passes the original `bench(80,0) == 402971` point in all
three fresh rotations, with a 1,000 ms warmup and 300 ms target. The per-call
medians are baseline 8,950.426 ms, checked04 8,202.211 ms and pinned TypeScript
34.130 ms: **1.091× faster than baseline**, while still **240.323× TypeScript**.
The candidate range is 8,086.580–8,667.027 ms, so this is a useful but modest
full-program gain. Acquisition took 222.56 seconds under root supervision.

## Partial-region follow-up

The full-ray transfer shows that the successful `nearest.t` mechanism does not
dominate the complete program. The next discriminator therefore targets the
inactive `colf` traversal, which visits 1,048,576 leaves at the documented point
but invokes the expensive pixel calculation only 5,120 times.

`region-colf-derive.mjs` preserves the original public Nat and fn5/fn6 stages,
keeps active pixel calls generic, and directly traverses only the balanced tree
and scalar predicate. It freezes the original ray module, captures every reachable
descriptor including the residual native `F32.to_u32`, and guards the complete
host descriptor surface before checking canonical inputs. This is an experimental
mechanism, not a source compiler transformation or a general purity theorem.
`region-colf-controls.mjs` checks admission explicitly for both inactive and active
traversals, supplies an independent worklist/BigInt traversal model, and compares
public metadata, saved prefixes, all dependency mutations, host protocols, callback
entry behavior and coercion boundaries. Neither tool has been executed by this
sub-agent; acquisition and timing remain root-owned.

Root's first acquisition now passes all 57 traversal oracles and 200 paired
boundaries, with explicit admission witnesses for inactive and active calls.
`colf-screen-01` measures `colfCandidatePoint(14,0,0)`: the common-wrapper baseline
median is 89.042 ms and the guarded partial variant is 0.709427 ms, about **125.5×**
faster. Width zero deliberately selects only inactive leaves; this is a dispatch
mechanism screen, not a representative full-ray speedup.

The separate `colf-ray-transfer-01` subsequently passes the unchanged full
`bench(80,0) == 402971` point in three fresh rotations. Baseline median is
9,152.034 ms, the saved-output partial variant 5,826.265 ms, and pinned TypeScript
34.241 ms: **1.571× faster than baseline**, still **170.153× TypeScript**. The
candidate range is 5,806.046–5,893.167 ms. This experiment changes the frozen
baseline output and does not include checked04's separate Boolean-region gains;
the two speedups must not be multiplied into a compiler performance claim.

Independent static review found no blocking issue in that frozen scope. The review
identified two important experimental requirements: descriptor equality must use
`Object.is` because `Number.NaN !== Number.NaN`, and an explicit fast-entry witness
must distinguish successful controls from an always-fallback implementation.
Both are present before the first colf acquisition. The same NaN issue was found
in a separate sum experiment; its earlier acquired artifact remains preserved by
that experiment's owner.

`partial-regions.patch` records the compiler transfer, corrected and integrated
by root in checked07 after the parser failure described below. Its new `jpure.bend`
module is a separate bounded source proof, shared with the later tagged-sum
workstream. It validates monomorphic scalar/recursive tagged types, every field
and branch, complete match coverage, saturated first-order calls and a guarded
native allowlist. An own body passes completely before its SCC node is reserved;
all collected callees are then checked. Invalid direct-lowering state is discarded
before this independent proof starts. Guard-only `JResidual` dependencies emit no
private definitions, and `JGeneric` delegates its original App spine to the normal
call emitter. This preserves its existing saturation and argument-demand rules.

The runtime proposal captures native `F32.to_u32` metadata and extends the host
guard to include `Number.isFinite`, Array push/pop/includes, Reflect.apply and
WeakSet add/has. Those operations are reachable inside residual generic execution
and could otherwise mutate G before the next direct operation. Guard reflection
uses captured descriptor/prototype intrinsics so mutated inspection hooks can be
refused safely. `region-pure-guards.mjs` supplies synthetic positive and adversarial
proof tests; all 37 final checked09 cases pass before installation.
This protects execution inside the admitted region. The existing `invokeExact`
dispatch itself still uses reflection and WeakSet operations before callback entry,
so this does not extend its prior trust boundary to promise identical observation
counts when those dispatch implementation intrinsics are globally replaced.
Independent review of the standalone analyzer found no blocking issue in its
stated closed monomorphic scope. Final-API adversarial execution was pending at
the initial cutoff and is now included in the closed final owner gate.

The first partial-region acquisition, checked06, fails parsing because
`j_pure_args` places a normalization binding before `match xs`, violating Bend's
match binding restriction. Root preserves the failure and fixes it by passing the
normalized type to an immediate-match helper. A static scan finds no second
instance in the new purity or fold modules. Checked07 subsequently compiles all
15 maintained benchmark points, including actual `colf` tree and `nearest` Boolean
paths. Checked08, which also includes the independent fold work, passes the focused
36-observation gate. These acquisitions are not runtime performance measurements.

| Acquired candidate | Checked build and focused gate | Build wall time | Peak process-tree RSS |
|---|---|---:|---:|
| checked07: corrected purity/partial regions | Pass; all 15 benchmark sources compile | 41.988 s | 1,077,370,880 B |
| checked08: additional fold integration | Pass; focused 36 observations | 41.987 s | 1,112,576,000 B |
| checked09: inherited numeric prototype guard | Pass; focused 36 observations | 42.5058 s | 1,129,676,800 B |

These serial resource measurements are reported by the root supervisor; their
candidate source/API identities and bootstrap receipts are in the corresponding
`selfhost/build/phase35/checkedNN/attempt.json` manifests. They are build costs,
not emitted-program timings, and a focused gate is not full conformance.

Review of residual allocation identifies a second guard requirement: inherited
numeric setters on Array/Object prototypes could run while generic code creates
temporary arrays and mutate a dependency mid-traversal. Root's checked09 candidate
adds a captured own-property-name snapshot and rejects any changed Array/Object
prototype key list. The separate existing descriptor checks cover used methods.
Static review finds no blocker in this combined guard under standard intrinsics
at module initialization.

The final control producers were frozen and then executed by root on checked09:

- `region-colf-cohort.py PREP_MANIFEST NEW_OUT` binds actual checked ray output to
  the preserved 57-oracle/200-boundary matrix. Its only candidate body edit is a
  diagnostic counter after actual `colf` tree admission, making an always-fallback
  implementation distinguishable from a working optimization.
- `region-extra-acquire.py` serially acquires `region-hit-fields.bend` and
  `region-partial-tree.bend` through the maintained checked-emission worker.
  `region-extra-controls.mjs` compares 180 independent numerical cases, tests
  public stages and dependency mutations, witnesses private-tree admission, and
  probes inherited numeric accessors at keys 0 and 8 which mutate a dependency.
  This uses arbitrary fixture names and a separate sum-shaped residual helper.
