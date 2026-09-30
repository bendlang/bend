# The smallest general proof for local-container regions

This is a static implementation outline, pending measured benefit from the
closed-row ladder. It proposes no production edit. The aim is one bounded
extension of the existing region analysis, not a new ownership type system.

## A structural locality theorem

Start with an ordinary root whose live inputs and final result are supported
immediate scalars. The internal type grammar can initially be:

`T = scalar | Array<U32> | Tuple<T,T> | closed single-constructor record of T`.

Bound type expansion and field count; refuse recursive container type cycles,
dependent fields, functions, IO, unresolved types and open polymorphism. Keep
the root boundary strictly scalar. A record-returning diagnostic probe is not
an initial production admission rule.

Permit only variables already in the local environment, scalar literals and
proved primitives, local constructors, projections of local values, saturated
calls to a closed first-order helper graph, fresh original Array.new, and
original Array.get/set on local Array<U32>. Array.new's fill value is scalar;
Array.set can store only scalar words. Refuse references to global data values,
zero-arity data factories initially, dynamic/partial calls, source lambdas as
values, higher-order natives, reflection, foreign operations and all escapes.

The induction is small: root parameters are scalars; each admitted producer
either returns a scalar or constructs a local value from local/scalar inputs;
each helper receives only such values and can use only the same grammar.
Saturated calls and proved self-tail loops preserve the invariant. All global
references are captured callee definitions; none imports a container from
outside. A scalar root result publishes no container. This can establish
locality uniformly for a complete helper context, without assigning allocation
identities or proving unique ownership of individual variables.

Aliasing is explicitly permitted. Array.get returns its original handle,
Array.set mutates that handle, records can retain it and row completion swaps
handles. The transformation preserves those objects and operation order. The
proof does not authorize copying, CSE of allocation, mutation elimination or
storage flattening. A value shared by several local variables remains local.

Use original-definition snapshots for every compiled/native dependency and the
existing exact-entry capability. Validate scalar input representation after
the original one-time slot reads. Finish all local deferred work before leaving
the admitted callback. All refused or foreign entries use the original body.
Stable host intrinsics remain explicit; existing runtime-marker hooks reject
the private path. No global ownership fact survives a call or is cached across
root invocations.

## What is already available

`src/back/js/region.bend` already supplies the shared dependency cache and active
chain, depth/fuel/definition budgets, checked type lookup, saturated-call proof,
private lexical names, primitive lowering, exact public entry and generic
fallback. `j_region_bindings` already preserves parallel RHS scope and immutable
source identities. Its nested Nat workers already keep zero handling and
BigInt transfer semantics. `JRegionBuild` is adequate for bounded failure and
helper collection; a separate optimizer state is unnecessary in the first pass.

The first-order graph argument is easier than arbitrary ownership analysis.
It also avoids trying to speed up public `row(Array,...)`: that public entry
continues to accept foreign arrays and records through the generic runtime.
Only a private call reached from a proved scalar root gains locality.

## The real implementation blockers

| Existing boundary | Required narrow change | Why changing a type predicate alone is wrong |
| --- | --- | --- |
| `j_region_signature`, variables, bindings and `j_region_args` accept scalar intermediates | Admit bounded closed local types inside a scalar root/helper context | The current guard alone does not prove an externally supplied record is local; public roots must stay scalar |
| `j_region_prefix_on` consumes Lambdas and only residual Bool matches | Add a complete single-constructor record/Tuple match prefix, with the exact checked field telescope | A source `cell` has two explicit Lambdas, then one record argument, then four field binders; source arity is not emitted leading-fn arity |
| `j_region_field_values` intentionally allows only trivial scalar terminal fields | Preserve computed local fields as original deferred thunks and force at proved demand points | `cell.f4` delays Array.set inside a Dp field; evaluating constructor children eagerly can move a write before another read |
| Scalar capture eligibility excludes array/record helper signatures | Separate private-helper eligibility from public-root scalar eligibility; snapshot admitted original helpers | Widening public admission simultaneously would expose private assumptions to foreign getters/aliases |
| Native Array calls carry an erased type argument and have no original scalar snapshots | Recognize only the exact proved original native signatures/source provenance and snapshot originals at runtime definition time | General erased-argument widening would undo deliberate refusals and may evaluate erased work; first-use snapshotting blesses prior mutation |
| Scalar Nat-loop signatures and equal explicit prefixes | Admit opaque local state only inside the proved closed graph; preserve residual zero matches | `row` zero returns a Dp matcher and swaps fields, while its successor has a longer explicit Lambda spine |
| Private scalar calls can simply return values | Track the existing non-tail force versus tail/deferred result convention for local constructors | A local build can contain a pending write; direct call lowering must not silently turn it into an unforced argument or reorder a pending field |

The record-prefix lowering needs one small explicit operation or emission
routine: read/project the known local argument once, retain the existing field
snapshot, bind its fields to fresh immutable aliases, then continue the checked
body. Reuse the type/field telescope rather than inventing a second record layout.
Initially keep `project(...).slice()` and the ordinary build/force representation.
Eliminating those operations is a later ablation, not a prerequisite for removing
generic apply/partial descriptors.

Array mutation makes demand analysis the substantive new part. The current
terminal-record optimization avoided it deliberately by allowing only variable
or literal fields. Preserve source evaluation contexts first: arguments used by
non-tail calls must be fully forced where the generic call did so; tail helper
results may stay deferred until the containing known force. The root's full
force guarantees no private deferred computation escapes, but that guarantee
alone does not license reordering operations *within* the region. Initial
lowering can retain original `build` thunks and add explicit force at the same
private-call demand points, as the measured ladder does.

For Nat loops, keep the proof of a predecessor self-tail edge separate from the
carried type grammar. At each iteration, create immutable aliases, evaluate
next arguments in source order and force the previous cell/row result at its
original demand point before overwriting slots. Zero must still execute the
original residual record match; `row(0,...)` swaps, while `dp(0,...)` returns its
state. Mutual recursion and unproved non-tail recursion remain refused.

## A small staged implementation, if justified

1. Add the closed local type predicate and a read-only admission classifier.
   It reports refusal causes and collected dependencies without changing output.
   Test synthetic renamed examples, not only editdist. Keep original root and
   helper budgets shared, and prove no external data producers enter the graph.
2. Add complete single-constructor record/Tuple private prefixes and native
   provenance/snapshots. Initially retain ordinary Array calls and constructors.
   Preserve the generic public callback and compare full state plus alias traces.
3. Add local non-tail forcing and private opaque-state Nat workers only after
   the record scheduling tests pass. Reuse current loop machinery with explicit
   zero residual handling; do not widen every public Nat worker.
4. Measure the actual compiler and a second renamed/structurally different
   program. Native-call direct lowering and projection/storage changes remain
   separate measured decisions.

Required refusal cases include externally supplied records/arrays, global data
references, user-shadowed native spellings, erased-effect cases, wrong record
field counts/types, partial/dynamic helpers, escaping callbacks, unsupported
native operations, unknown recursive edges and exhausted shared budgets.
Required runtime controls include original binding and native mutation before
first use, entry reentry, delayed Array.set, old aliases after later writes,
zero-row swap, raw/constructed/over-saturated entry and unchanged foreign public
row behavior. Passing the fixture ladder does not replace those compiler gates.
