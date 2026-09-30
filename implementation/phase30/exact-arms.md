# Exact constructor-arm prebinding

Agent-generated Phase30 implementation note. The prospective
[design](../../design/phase30/exact-constructor-arms.md) and isolated JavaScript
[experiment](prototype-findings.md#exact-arm-ablation-and-remaining-application-counts)
precede this source change.

## Change

`selfhost/src/back/js/arm.bend` changes the existing admission condition from
`0 < count < total` to `0 < count <= total`. The current `matcher1p` runtime helper
already handles exact saturation; its body, public matcher arity, projected-vector
snapshot and cold-path ordering remain unchanged. No new runtime helper, compiler
module, intermediate representation or datatype is introduced.

All other guards remain: identified constructor/owner, live fields, literal
unlifted lambda arm, valid type telescope and nonzero field count. Too-short arms,
erased fields, zero-field constructors, lifted lambdas and effectful arm factories
continue to use the existing fallback. Exact saturation executes the original arm
body at the same boundary; a returned jump/build is not eagerly forced past the
runtime's existing boundary. Partial and overapplied foreign field vectors remain
handled by the same helper branches.

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

For the coordinated new checked attempt, use the same harness with the new
candidate paths, `expectPrebinding:true`, `expectExactArms:true`, and `baseline`
pointing to the complete `exact-arm-controls-old-02/report.json`. This agent has
not started that build, changed other compiler/runtime files, or committed the
change; those integration actions are owned by the lead.
