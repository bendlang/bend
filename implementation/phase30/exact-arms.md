# Exact constructor-arm prebinding

Agent-generated Phase30 investigation. **The extension is rejected and reverted.**
Three later independent outer-application witnesses expose an effect-order
regression missed by the original field-vector controls. The ordinary row speed
gain was only 1.023×, so the lead chooses the original `count < total` admission
rather than adding another boundary mechanism for this extension. All failed
artifacts and earlier measurements remain evidence for the rejected proposal.

The prospective
[design](../../design/phase30/exact-constructor-arms.md) and isolated JavaScript
[experiment](prototype-findings.md#exact-arm-ablation-and-remaining-application-counts)
precede this source change.

## Proposed change, subsequently reverted

The trial changes the admission condition from `0 < count < total` to
`0 < count <= total`. The `matcher1p` runtime helper already has an exact
saturation branch; its source and public matcher arity are unchanged by the
trial. That alone does **not** establish equivalent caller scheduling. No runtime helper, compiler
module, intermediate representation or datatype is introduced.

All other guards remain: identified constructor/owner, live fields, literal
unlifted lambda arm, valid type telescope and nonzero field count. Too-short arms,
erased fields, zero-field constructors, lifted lambdas and effectful arm factories
continue to use the existing fallback. The original hypothesis was that a returned
jump/build and unchanged field-vector branches preserved demand boundaries. The
later outer-vector witness below falsifies that hypothesis for exact saturation.

## Why this small extension

The isolated five-site edit-distance variant removes1,600generic applications and
1,600function descriptors over ten32-cell rows. It preserves all calls, projections,
construction, array operations and26,650counted copied slots. Longer-warm execution
improves1.023× (0.280140→0.273785ms), with disjoint five-sample ranges and no half
ratio beyond5.9%. This is a modest scoped gain for a one-condition extension;
it is not a claim of a proportional speedup from descriptor-count reductions.

Independent prototype controls pass33ordered/public-boundary observations. They
exercise the exact helper's projection, copying, changing lengths and saturation
behavior separately from the compiler recognizer. The source change still needs
the coordinated checked-build gate and actual-emission admission checks.

## Actual compiler controls

The existing harness is `selfhost/src/back/js/test-arm.mjs`; there is no
`selfhost/tools/performance/phase26/test-arm.mjs`. It accepts
`expectExactArms`, defaulting to `false` so historical image expectations remain
explicit. Set it to `true` for a candidate containing this source change.

The harness preserves its72historical observations and adds22separate
`exactObservations`. When a fresh baseline contains those observations, candidate
runs compare their full transcript as well. A historical report without the new
section still supplies the original72-observation comparison; explicit expected
results and ordering assertions cover the new section.

Added exact-arm cases cover annotated and captured arms, function-valued results,
late effects, zero/one/two supplied fields, zero/one/two fields returned by custom
slice implementations, changing copied-vector lengths, throwing field getters,
and independent selection markers. Unknown/unsupported existing cases continue to
assert fallback. Function-valued arms call an opaque identity helper so that the
separate projection optimization cannot absorb the test before arm recognition.

Focused acquisition using the earlier checked Phase30 attempt01 (owned-argument
change only; old exact-arm admission) passes72+22observations with all five new
exact-arm definitions correctly declining prebinding. Evidence:

- `selfhost/build/phase30/exact-arm-controls-old-config.json`
- `selfhost/build/phase30/exact-arm-controls-old-02/report.json`
- Adjacent stdout/stderr and the consumed harness copied into that attempt.

The first new function-result witness was itself unsuitable: a bare projected
function selected the existing projection optimization, so its expected malformed
three-field overapplication behavior did not apply. That failed harness run and
its exact source survive in `exact-arm-controls-old-01`. The corrected opaque
identity witness passes; the original72observations are identical between attempts.
No compiler repair is claimed for that test correction.

The trial used `expectExactArms:true`; builds after the revert use
`expectExactArms:false`. The expanded harness and separate 22 observations remain
useful regression controls even though this admission is rejected. Integration
builds and commits are owned by the lead.

## Independent outer-vector counterexample and revert

`selfhost/build/phase30/review-exact-arm-outer-01/report.json` preserves three
counterexamples using the unchanged and exact-arm disposable outputs, with full
input/tool identities and no changed inputs. These are separate from the earlier
33 observations, which exercised the projected field vector's cold branches.

The new caller first obtains the record matcher with `call(G.cell,[j,ai])`, then
overapplies **that outer matcher** with a custom copied vector. Ordinary
`matcher1` returns an arm bounce, so the caller reads `outer.length` for the
fourth time before any Array.get arm effect. Exact `matcher1p` calls the arm body
inside the outer callback; its first Array.get now precedes that fourth read.

All three controls expose the difference: a plain event trace, a length getter
that throws, and a length getter that replaces a later callee. Even when the final
error text agrees, the exact variant performs an extra read before the stopping
or replacement boundary. Complete row-output equality did not test this contract.

Under the lead's authorization, the reviewer restores the original strict
`count < total` condition and header in `selfhost/src/back/js/arm.bend`. This
returns that file to its pretrial bytes. The count-equals-total optimization is
not part of the intended compiler release. A separately discovered scheduling
question for historical partial prebinding is being investigated independently;
this revert does not claim to settle that older runtime behavior.
