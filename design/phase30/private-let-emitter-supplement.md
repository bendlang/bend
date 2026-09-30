# Smallest maintained form of the private Let experiment

This is an implementation proposal contingent on the isolated
[private-Let ablation](private-let-statements.md) winning. No production source
change is part of this document. Limit the rule to the ordinary private helper
return branch of `j_region_definitions`; leave `j_region_nested_body`, public
ordinary-root bodies, tree traversal, generic fallback and all argument emission
unchanged.

Replace the current ordinary-helper fragment

```bend
"return " ++ j_expr(book, Nil{}, dv(d), kid(dv(d), 1), False{}) ++ ";"
```

with a call to one small statement emitter:

```bend
j_region_return(book, Nil{}, dv(d), kid(dv(d), 1))
```

Its proposed definition directly reuses existing Let and annotation machinery:

```bend
@unsafe
def j_region_return(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm) -> String:
  kc(String, String.eq(tg(t), "Ann"), u => j_region_return(book, env, kid(t, 0), kid(t, 1)), u =>
  kc(String, String.eq(tg(t), "Let"), u => "{" ++ j_nat_loop_values(book, env, ks(t), 0) ++ "{" ++
    j_nat_loop_names(ks(t), 0) ++ j_region_return(book, j_context(book, env, ks(t)), j_body(ks(t)), ty) ++ "}}", u =>
    "return " ++ j_expr(book, env, t, ty, False{}) ++ ";"))
```

This adds one emitter function and changes one existing expression branch,
approximately eight physical source lines plus the annotation/separator. It
introduces no analysis rule, representation, IR tag, context mode or runtime
operation. Region analysis has already checked scalar bindings and bounded the
transformed expression. `Ann` carries exactly the type that the existing
expression emitter would select. Terminal expressions still use that emitter.

The outer block gives the reused `$v<number>` temporaries their own scope at each
nested Let. `j_nat_loop_values` emits all RHS expressions with the old environment
and ordinary expression emission; the inner block introduces all source names
using `j_nat_loop_names`. Only then does `j_context` provide the body environment.
This preserves parallel shadowing and lets nested blocks safely reuse temporary
indices. Source variable names use the existing `x<number>` namespace and helper
parameters use `$p<number>`, so the administrative temporaries cannot collide.
Do not replace this with directly interleaved `const sourceName=RHS` declarations.

The plain temporary initializer does not create an anonymous-function-name
difference in this private-only rule. `j_region_bindings` requires every RHS to
have a scalar native type and successfully pass the region expression recognizer;
the latter does not admit lambda-valued or class-valued results. Primitive arrow
IIFEs may remain *inside* an RHS, but the initializer evaluates their scalar call
result, so no new function identity receives the temporary's inferred name.
This argument relies on existing region admission and checked-source/scalar-entry
preconditions. It must not be reused for arbitrary generic callback Lets. The
separate general-tail experiment uses comma initializers to handle that wider
anonymous-function/class boundary without changing this shared helper.

Do not recurse into private calls, primitive arguments or conditional branches.
Those are terminal expressions for this emitter and retain their existing bytes.
Do not route private nested Nat helper emission through the new function. This
keeps the scope of a maintained change aligned with the successful generated-JS
experiment, if one is confirmed.

Validation should first compare actual newly checked emission with the frozen
statement ablation modulo administrative temporary spelling and the redundant
outer block. Retain source-level parallel and nested shadowing controls, including
the independently checked `[2,10]` example, erased-binding refusal and an
unchanged RHS expression witness. Then run the existing private-region numeric,
public scheduling, scalar-tree and original-program controls on the actual image.
Confirm the same whole/tree timing points before attributing a compiler-produced
gain. The unchanged scalar helper is a useful byte-equality control, not another
speedup claim.

## Final-image scalar scaling binding

After the lead builds attempt14, acquire `fixture-mandelbrot.bend` through that
attempt's ordinary checked library path into a new output directory. Keep its
API/runtime/Base/driver/source/attempt receipt. The fixture is expected to stay
byte-identical because its private scalar helpers contain no eligible top-level
Let chain; compare the full output hash to attempt12's
`990a2a7568cdb40541883237b97e008ee785a8d8e890400b9890fe21274204f5` rather than
assuming identity from the planned source scope.

Run the existing parameterized `inspect-scalar-scaling-plan.py` with attempt14,
that newly checked module and a fresh `scalar-scaling-plan-14` directory. It
retains the unchanged source, original Phase29 and pinned TypeScript references,
four input points and the prospective confirmation protocol. Then run the
existing public precheck to require all twelve exact side/point results before
it creates the new `confirm.json`. No benchmark is authorized by either step.
Do not edit or relabel plan12, its public checks or any timing already using it.

If a plan12 timing already completes and the final14 module is proven identical,
the figure/report tool can pair that explicitly named measured window with the
new final-image checked-byte receipt. This saves redundant timing while retaining
both acquisition identities. If bytes differ, require a fresh final-image timing
window; do not infer equivalence or carry forward the old candidate measurements.
