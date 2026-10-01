# Small extension from generator-only to complete private production

Status: proposal only. Implement only if the clean full-producer ablation
materially improves the original symreg benchmark over generator-only. No new IR,
public representation or benchmark-constant specialization is required.

## Exact current limitations

`j_region_match` already lowers a complete Bool True/False permutation with
**any remaining argument count**, using `j_region_prefix` for both arms. Thus
`gen.leaf(h,z)` does not need a new Bool matcher. It fails because Expr is a
multi-constructor sum and `j_region_constructor` currently asks for a single
`j_region_local_ctor`. Existing local-type admission already accepts Expr through
`j_fold_type`; constructor selection is the missing operation.

Finite Nat selection emits `JNatCase`/`JNatRest`, but `j_region_prefix_on` currently
permits it only at `left==1`. `node(o,a,b)` has two trailing Expr arguments, so it
fails before its 0/1/2/default choices are lowered. Existing Nat-selector code
also feeds the zero arm and remainder-lambda body to `j_region_expr`, which
cannot consume the remaining lambda telescope. Its offset<=64 and ordinary
complete Zero/Succ/Efq obligations should remain unchanged.

## Minimal implementation

1. Carry `left` through the four existing finite-Nat selector functions. In a
   zero arm call `j_region_prefix(... at+1,left-1,keep=False)`; in a remainder
   lambda retain its `JEnvNat` binding at the original slot and then call the same
   prefix operation for trailing parameters. Successor matching keeps the same
   slot, increments only the Nat offset, and preserves `left`. Existing
   `JNatCase` emission and `JNatRest` subtraction remain unchanged. With left==1
   this reduces to the present expression path.
2. Under a **private-producer analysis context only**, select a constructor from
   the already-proved closed `j_fold_type` owner's constructor table by source
   name. Keep the exact original arity and `dt(c)` field telescope. Accept only
   inert fields or bounded primitive scalar expressions using existing
   `j_fold_terminal_fields`; ordinary expression planning checks their actual
   field types. All sum child fields remain original aliases. Reuse `Ctr` and
   `j_region_constructor_done`; `j_region_local_vector` remains false for sums,
   so output is the original generic constructor tag and field array.
3. Propagate this analysis context only from JProducer's independently proved
   whole-original-body graph into its zero/successor/helper lowering. Use an
   explicit reserved internal active-context marker, never a source definition
   name. Context is compile-time only and is not a runtime proof token. Guard
   forcing remains guaranteed by the existing JProducer host-guard rule. A
   previously lowered helper reused elsewhere in the same root retains the
   enclosing JProducer dependency and host guard. Do not broaden ordinary root
   constructor admission as part of this experiment.

Estimated change: **15–25 existing lines modified and 15–30 net new Bend lines**,
including a small constructor-selector helper and the explicit context marker.
No new module/type/runtime helper is needed beyond the proposed producer module.
If implementation grows materially beyond that, keep the already-reviewed
smaller producer subset and reassess rather than build another optimizer.

The generator itself remains iterative over runtime Nat depth. This extension
removes generic node/gen.leaf dispatch; it does not eliminate tree allocation,
change layout, inline the entire tree or change consumers.

## Controls before admission

- Existing saved-output complete trees and full benchmark result across seeds,
  then the same controls bound to actual checked emission. Assert direct
  node/leaf helper calls and positive producer entry; marker presence alone is
  insufficient. Capture the actual private helper for complete tree and shared
  child identity checks.
- Nat selectors at offsets0/1/2/3 and a larger default remainder, with two trailing
  arguments. Include a combiner that observes the remainder after the case,
  swapped child order and parent seed. Test equivalent last-argument Nat choice
  to ensure the old left==1 behavior remains byte/semantically stable.
- Bool selectors in both constructor orders, before and after trailing scalar or
  locally produced sum arguments, with all branch outputs checked.
- Full original tags, arities, field arrays and left===right sharing. Primitive
  U32 wrap endpoints, zero-field Var and one-field Lit cases, not only folded
  hashes. Keep original public partial calls, noncanonical inputs, metadata
  changes, getter/throw/reentry, Math/native and inherited-prototype mutations.
- Refuse constructor name/type mismatch, excess/missing/erased fields, unproved
  native/foreign/dependent/function/array fields, incomplete/default-conflicting
  selector shapes, offset overflow and exhaustion. Refuse the new sum-constructor
  lowering outside the producer context. The independent JPure proof remains
  required; the existence of one pure residual is not closure purity.
- Feasible complete depth12 plus structural absence of private recursive JS
  calls. Do not allocate an exponential deep binary tree to test stack depth.

The checked final producer controls should test both sequential and parallel
producers, dependent-RHS refusal, unary refusal and original public ABI. Full
maintained timings and normal compiler costs remain final integration gates.
The code-size/compile-time increase must be measured; no promised gain follows
from the small source change estimate.

## Concrete proposal and reserved-context audit

The prepared [extension patch](../../implementation/phase36/producer-selectors.patch)
adds **10 net Bend lines**, reusing existing `JNatCase`, `JNatRest`, `Ctr` and
prefix/field planners. The complete producer module is114 lines after this
extension, versus107 before. The derivation and parent hashes are in
[producer-selectors.json](../../implementation/phase36/producer-selectors.json).
No production source was changed by its owner.

`@producer` cannot be a source definition name. Selfhost `f_valid_name` in
`selfhost/src/front/validate.bend` requires an ASCII letter or underscore first;
`f_def_header` and `f_named_top` in `front/declarations.bend` enforce it. The pinned
TypeScript `parse_lexeme` requires `^[A-Za-z_]\w*(\.[A-Za-z_]\w*)*$`.
Generated closure marks use the separate `$js.` namespace; the existing
`@root-return` context uses the same reserved-character principle. Within the
region planner `active` is used for membership/cycle refusal, never as a depth or
helper-budget counter. Those remain separate numeric depth, fuel and helper-list
length checks. Adding the compile-time marker therefore does not consume or
weaken a recursion/member budget and is never emitted into dependency names.

Preseeded `JResidual` entries do not prevent upgrading node/leaf: `j_region_helper`
returns a cached definition early only when its body is **not** JResidual.
Successful direct plans replace the old same-name helper through
`j_region_helper_done`/`j_pure_remove`; failed ones retain independent purity and
original generic evaluation. The producer's selfcalls match `name==tail` before
helper lookup, and the iterative tree emitter consumes their argument spines.
No residual merge movement or additional cache is needed. Actual checked output
must still witness direct node/leaf helpers; the source reasoning is not a
substitute for that non-vacuity check.
