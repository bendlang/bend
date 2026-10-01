# Private state ablation

The checked09 combined compiler retains private vector-result inlining, scalar
loop state, an exact private Number countdown and direct native get/set calls.
Its full maintained execution comparison completes 15/15 points; complete pair
improves 1.324×, independent fold 2.360× and original edit distance 1.278× versus
the same-run Phase32 baseline. Checked09 is installed and verified: final
postinstall audit closes 15/15 groups, all 42 CLI checks and 225 canonical-file
identities. Earlier isolated mechanisms and rejected broad inlining remain below
as history. The [admission report](performance-admission.md) records accepted
compiler-cost/source-size tradeoffs and the completed evidence capsule.

The current combined screen and full confirmation, including the generic-row
regression investigation, are consolidated in
[P35-001](../../experiments/phase35/P35-001-private-state.md). The full comparison
places pair/fold/edit distance at 3.058×/3.497×/3.259× pinned TypeScript; improving
over baseline does not mean closing that entire gap. A short screen's different
TypeScript fold median must not replace the longer same-run denominator.

Independent final-source inspection after checked09 found no concrete blocker
in vector destinations, read argument scopes, counter escape prevention, direct
get/set argument order, bounded fold-frame access or the mandatory host guard for
fold helpers. This was static inspection only. Subsequent actual final-API owner
controls, scoped conformance and compiler-cost measurements are recorded in the
admission report; those executed gates close the release.

`vector-prototype.mjs` parses saved generated modules with Node 24.18.0's embedded
Acorn 8.16.0, replaces only the named private row or fold helper copies, preserves
all public code and guards, reparses the result and writes input/output/producer
identities. This explicit fixture mechanism probe is not a compiler specialization.
The `inline` variant retains one fresh state vector per iteration; `scalar` carries
fields in local slots. Both preserve the native array operations and BigInt loop.

Root can create each candidate from:

```
node selfhost/tools/performance/phase35/vector-prototype.mjs \
  selfhost/build/programs/validation-20/modules/baseline/baseline/modules/local-row.mjs \
  selfhost/build/phase35/vectors/pair-scalar.mjs pair scalar
node selfhost/tools/performance/phase35/vector-prototype.mjs \
  selfhost/build/programs/validation-20/modules/baseline/baseline/modules/local-fold.mjs \
  selfhost/build/phase35/vectors/fold-scalar.mjs fold scalar
```

Repeat with final argument `inline` and fresh output filenames for that ablation.
Use `programs/prototype.py --replace local-pair=... --replace local-fold=...` to
make explicit unchecked bundles, then `run.py --budget 60 --cases local-pair,local-fold`
with one candidate bundle per run. The compared baseline is measured afresh by
the same runner. No expected values are changed.

The producer's row replacement preserves four ordered reads (other string byte,
diagonal, above, left), one ordered write, increment wrapping and the terminal
row swap. The fold preserves reading before the update and returns its original
input vector at zero. Full state/event controls and broader guard controls remain
required before a source implementation is eligible for promotion.

## Independent static review

The Phase35 research agent compared the exact baseline helper bodies to both
prototypes. It found no discrepancy in the private-domain read/write order,
wrapped arithmetic, initial-zero behavior or row swaps. Its review identified
that encoded helper names alone were insufficient to constrain a fixture-specific
producer. The producer now refuses any input module other than the exact frozen
pair/fold hashes and records each replaced original body's hash. This is static
review, not an executed correctness result.

## Proposed compiler inlining stage

`private-state.patch` adds a general transformation of already-admitted private
plans. It does not dispatch on benchmark names. Each helper has a shared 2,048-node
visit budget including copied callees, with at most eight nested expansions;
exhaustion retains that helper's original plan. Existing loop helpers are not
inlined. There may be up to 32 independently bounded helpers in a region.

Private JCall/JReadCall nodes become inline plans. All argument expressions are
captured in their source order outside a new positional binder scope. Tail returns
emit scoped statements; expression positions use one immediately invoked closure.
Canonical read bridges retain erased argument positions and the immediate indexed
read before the consumer. The vector representation itself is unchanged by this
stage. It needs a checked build, exact semantic controls and actual-output timing.

Independent static review found no blocker: annotation types remain, parallel let
scope is intact, the `$get` argument offsets match the existing bridge, JUnpack
stays available to bridge recognition, and the dependency guard list is unchanged.
This does not establish runtime correctness or a speed gain.

## Root's first execution screens

The first fixture-pinned producer was executed before the input-hash restriction
was added. Its exact bytes are preserved as `vector-prototype-v1.mjs`, SHA256
`9b96d6ad1781793d5f67326e322895715461dbaee575cf1fc4e6d33f913818aa`, matching the
per-module production receipts. The restricted successor remains separate.

| Saved-output variant | Pair baseline / candidate / TS ms | Fold baseline / candidate / TS ms |
|---|---:|---:|
| Inlined, vectors retained | 3.89716 / 3.41842 / 1.24568 | 0.237530 / 0.157384 / 0.0629463 |
| Inlined, local fields | 3.93633 / 2.97609 / 1.25777 | 0.238338 / 0.128941 / 0.0636085 |

Both complete their two-point screen. Relative to each run's own baseline, the
inline variant reduces pair time 12.3% and fold time 33.7%; local fields reduce
pair time 24.4% and fold time 45.9%. These are unchecked emitted-output prototypes,
not a compiler improvement. Their independent baseline windows must not be mixed
to calculate an exact scalar-replacement increment.

The first checked build of the source inliner (`checked01`) failed during parsing:
Bend requires a named match scrutinee, whereas the proposal used `match ks(t)`.
The original failed proposal is retained as `private-state-v1.patch`; the corrected
proposal introduces `j_region_inline_args_on` and matches its `xs` argument. No
failed build is relabeled as checked output.

## Scalar-loop follow-up proposal

`private-state-scalar.patch` is a second, independent delta against the inlining
stage. It targets a private Nat loop's final argument when the existing local type
proof gives it vector representation. Initial zero uses the original return path.
Otherwise the fields enter independent loop slots. A virtual-vector plan replaces
the loop state's variable in the body; a complete immediately inlined match binds
its fields without allocating a vector. Other uses reconstruct a vector normally.

The next recursive result writes fresh next-field slots, in source field order.
Only after all argument computations finish are those next fields copied to the
current slots. Thus swapping fields, preserving older aliases and array effects
do not require mutating a record buffer. Terminal zero reifies the next vector
before the unchanged zero arm. This is a bounded specialization of the existing
private loop emitter, not a new general SSA IR. It remains a proposal until checked
output passes semantic and timing controls.

## Unrestricted inlining rejected

The actual checked inliner is not the same transformation as the hand-written
loop ablation. Its eight-point core screen (`inline-core-screen-01`) passes all
outputs in 57.47 seconds but reveals substantial regressions:

| Point | Baseline ms | Checked inliner ms | Baseline / candidate |
|---|---:|---:|---:|
| Complete pair | 3.88727 | 6.49923 | 0.598× |
| Fold | 0.238938 | 0.197910 | 1.207× |
| Long scalar | 0.139860 | 0.587179 | 0.238× |
| Mandelbrot | 0.197276 | 0.412532 | 0.478× |
| Original edit distance | 15.79999 | 26.19992 | 0.603× |

Pair/fold complete-state and logical operation controls pass; the full pair
candidate observes 59 canonical read sites, including 47 inlined copies, versus
12 baseline bridges. The 12 inline argument/read-order witnesses pass. Correctness
does not justify promoting this regressing version.

The likely mechanism is excessive expression/IIFE expansion and generated-body
size, but the timings alone do not identify the exact V8 cause. The next delta
`private-state-vector-only.patch` restricts expansion to callees whose annotated
result already has private-vector representation. Scalar helpers and boxed public
terminal results remain calls. The scalar-loop delta then removes the hot result
array and expression-level return boundary. These are hypotheses until measured;
the negative unrestricted run stays separate and preserved.

The regions agent independently reviewed the scalar-loop delta before execution
and found no blocking issue in field snapshots, zero reboxing, virtual matcher
arity/field-count admission or lexical scopes. It explicitly checked the boundary:
outer private vector identity is not observable in the admitted Bend region, while
nested native array handle identities are preserved. The alias fixture is a
required dynamic gate, not a substitute for this domain restriction.

## Checked vector-only inlining and scalar slots screen

The combined checked03 build completes in 36.645 seconds at 1.082 GB peak RSS.
Its eight-point core screen passes in 57.49 seconds. This is a short
screen with the maintained 60-second preset, not a steady-state claim.

| Point | Baseline ms | Checked03 ms | TypeScript ms | Baseline / candidate |
|---|---:|---:|---:|---:|
| local-pair | 3.9407 | 3.31665 | 1.24242 | 1.188× |
| local-fold | 0.237256 | 0.141959 | 0.06377 | 1.671× |
| scalar-region-0 | 0.00404147 | 0.00407373 | 7.40753e-05 | 0.992× |
| scalar-region-8192 | 0.139897 | 0.141101 | 0.0996353 | 0.991× |
| complete-generic-row32 | 0.397309 | 0.405309 | 0.00693664 | 0.980× |
| mandelbrot | 0.198003 | 0.202129 | 0.0478391 | 0.980× |
| editdist | 15.6793 | 13.432 | 5.06922 | 1.167× |
| test-rle-roundtrip | 0.051377 | 0.0511072 | 0.000583874 | 1.005× |

The focused source change now improves pair, fold and original edit distance in
this screen. Long scalar and Mandelbrot are close to their same-run baselines;
small differences need confirmation rather than a claim of improvement. The
checked compiler is still roughly 2.65× TypeScript on original edit distance here.
Full pair/fold state/events, alias and nested-vector controls and longer confirmation
remain distinct admission steps.

## Acquisition and control failures retained

The initial acquisition helper had a Python keyword error (`pass` used as a
`dict` keyword); `vector-acquire-v1.py` retains it. The next version correctly
failed installed-release validation after compiler source edits, rather than
bypassing that validation. `vector-acquire-v2.py` preserves that producer. The
current tool requires an explicit historical checked baseline attempt; Phase32
`attempt-03` has the exact reference API SHA256 `8be506d8…` and is verified through
the unchanged checked-attempt worker.

The first alias fixture was rejected by the source checker because `U32 & U32`
is affine `Type`, while a `+st` binder requires `Data`. The source intent was a
reusable pair, so the corrected fixture uses the explicit upstream convention
`Sigma<&2, &2, U32, _ => U32>`. The nested fixture uses the corresponding nested
Data Sigma. Their original sources remain in `vector-aliases-v1.bend` and
`vector-nested-v1.bend`; expected oracle answers are unchanged.

The inline-order scaffold tool initially required exactly two ordinary prefix
arguments, which fits fold but rejects the real pair's four-or-more prefix
bridges. That failed control is preserved. The v2 tool reads the actual arity,
retains exact capture/rebinding/read statements, observes every prefix in order
and generates one prefix-write witness per actual argument. The original tool is
retained as `vector-inline-order-controls-v1.mjs`. This broadens the observer's
supported generated shape without weakening the semantic checks.

The nested fixture's next source version was also rejected for using unpacked
`x` and `y` twice. A Data tuple does not implicitly make each pattern binder
reusable. The corrected fixture consumes each field once into explicit reusable
`+old_x` / `+old_y` scalar lets, then performs the two uses. The prior version is
preserved as `vector-nested-v2.bend`; this source correction leaves the independent
oracle unchanged.

## Subsequent scalar-state evidence and countdown experiment

Root reports the checked03 complete pair controls pass, including full state and
native operation events (7.737 seconds), and the corresponding fold controls
pass. Allocation sampling reports pair 8.01881 MB → 6.42518 MB, with 97.8% of
candidate allocation attributed to row; fold 652893 → 431062 bytes, 97.7% in its
loop. These are profiles of that saved candidate, not final-release metrics.

The next mechanism experiment changes only unobservable private loop countdowns
from BigInt to Number. `vector-countdown.mjs` accepts only the exact checked03
pair/fold module hashes. Its AST proof requires the predecessor to occur solely
as the self-tail count, and verifies the initializer, zero test and decrement.
The original public Nat and zero-entry paths remain. The producer captures Number
once at module initialization; ordinary array conversions remain untouched.
`vector-countdown-v1.mjs` preserves the earlier producer whose occurrence walk
skipped nested function descendants. The current producer counts those too,
conservatively rejecting any captured predecessor.

Root's `number-screen02` passed in 19.42 seconds, four roles within one window:

| Fixture | Original baseline ms | Scalar fields ms | Number counter ms | TypeScript ms | Counter-only speedup |
| --- | ---: | ---: | ---: | ---: | ---: |
| local-pair | 3.90893 | 3.37020 | 2.68776 | 1.23506 | 1.254× |
| local-fold | 0.237823 | 0.142637 | 0.109657 | 0.0635602 | 1.301× |

This is an uncertified saved-output mechanism screen. The prototype's total
candidate/TypeScript ratio is approximately 2.18× for pair and 1.73× for fold.
It does not demonstrate those ratios for the checked compiler or a broad suite.
The first number-screen configuration failed before execution; its failed bundle
is retained.

`private-counter.patch` proposes the small generic compiler rule: revalidate the
exact self-tail predecessor and scan every plan child, saturating at two uses.
Only a nested loop with a final vector state is eligible. Both independent agents
reviewed the patch without finding a blocker; they requested explicit ordinary
conversion/storage/alias/scalar refusal controls. The patch adds the captured
`regionCounterNumber` to the runtime fragment; the parent regenerates the runtime.

`vector-countdown-controls.mjs` executes the actual emitted counter expressions
for at most 32 transitions per input, including values at 2^48−1. It also compares
complete pair/fold calls with Number replaced by a counting function, a getter,
or a throwing function. `vector-counters.bend` supplies independent accepted and
rejected source forms; the corresponding fixture control requires the intended
private functions to be present so passing generic fallbacks cannot masquerade as
proof of optimization. Those controls were prepared without execution by this
agent; parent reports are authoritative for completion.

## Nested-vector control admission

The nested fixture's numeric and public mutation checks passed for v3, but its
structural gate correctly failed: neither nested scalarized loop was emitted.
Consecutive tuple matches compile to a partially consumed matcher telescope,
which the existing private-region proof rejects. Separate complete helper matches
make the intended nested vector fields visible without changing the compiler's
admission rule. The v4 source then exposed Bend's declaration-order requirement;
v5 places both `.pair` helpers before callers. All previous fixture bytes and
failed acquisition reports are preserved. The structural gate still requires both
inner and outer private loops to contain scalar slots; it was not relaxed.

The acquisition producer before adding counter fixtures is retained as
`vector-acquire-v3.py`. The current producer adds only the explicit `counters`
case to its available checked cohorts; historical baseline validation is unchanged.


Direct inspection of root's saved reports confirms additional passing gates:
`regions-alias-controls` has 40 oracle points, four mutation boundaries and three
negative alias witnesses; `scalar-order-controls-02` has 14 capture/read-order
scenarios and two negative schedule witnesses. The checked03 complete pair report
contains six independent oracle points, two full-state runs and 17 boundaries;
fold contains 41 oracle points, eight state runs and seven boundaries. All these
reports have `complete: true` and `pass: true`. At that historical cutoff, the
nested control remained separate until its revised source passed the structural
requirement. The final checked09 owner group subsequently passes, including the
unchanged requirement that both nested private loops are actually scalarized;
see the final admission report and preserved owner receipts.
