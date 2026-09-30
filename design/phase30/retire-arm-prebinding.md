# Conditional removal of constructor-arm prebinding

Status: proposal only. First establish the isolated generic runtime B result and
establish a separate checked runtime-repair artifact with current emitter
call sites unchanged. Install only the final reviewed compiler after any
separately checked source retirement; do not install intermediate versions.
Do not fold this source cleanup into that attribution experiment.

The maintained compiler has two matcher1p emission paths. Generic matches use
`src/back/js/arm.bend`, selected by `j_match` in emit.bend. Scalar Nat loop/tree
wrappers use `j_nat_loop_wrapper` in worker.bend. Removing only arm.bend would
leave the runtime helper required by scalar workers; both paths must change.
The shared `j_arm_type`/`j_arm_tel` functions in emit.bend remain necessary for
ordinary matches, scalar regions, validation and tree workers. They are not
prebinding-specific and must remain.

If generic B wins, a later checked change can remove all58 lines and eight
functions of arm.bend, and its one compiler.json manifest entry. Replace the
single-constructor branch of j_match directly with the existing generic fallback:

```bend
"matcher1(" ++ j_quote(nm(t)) ++ ",()=>" ++
j_expr(book, env, kid(t, 0), j_arm_type(book, ty, nm(t)), False{}) ++ ")"
```

No new admission rule replaces the deleted live-field counting, lambda telescope
checking, owner/constructor lookup, size comparison or specialized code assembly.
Those analyses existed only to avoid an intermediate descriptor/application.
The ordinary typed lambda emitter already emits the required literal arm.

Change the successor wrapper spelling in j_nat_loop_wrapper from:

```js
matcher1p("Succ",1,total,()=>exactCode(inner))
```

to:

```js
matcher1("Succ",()=>fn(total,exactCode(inner)))
```

Keep inner, exactCode, its creation time, scalar captures, guards, worker loops,
zero matcher and generic fallback byte-identical. Only the outer partial matcher
is generic. The final fully entered worker callback remains registered and
retains its permission protocol. Both Nat loops and tree workers share this
wrapper, so neither needs a new special case.

Once a checked compiler emits no matcher1p calls, remove the private runtime
bridge. This removes about62–65 maintained implementation lines relative to a
release that keeps the compact generic bridge:58 Bend source lines, one manifest
line and roughly4–6 runtime lines, with the two call-site substitutions having
no material line increase. Against current14's larger specialized matcher helper
the saving would be roughly70 lines, but that is not the right incremental
baseline after the runtime-only repair. Eight compiler functions and the
prebinding-specific runtime entry are removed. Exact-entry tokens and guards
remain for actual private workers; do not claim that this eliminates that
separate mechanism.

## Structural correspondence, before relying on outputs

For a formerly admitted arm, arm.bend requires a literal unlifted Lam/Ann spine.
Its `total` is the same leading Lam/Ann count used by j_lambda_count; it calls the
same j_lambda_code with the same environment, body and arm type. Annotation and
lambda-type normalization happen through the same recursive bind path. The old
anonymous code factory uses `(0,function(a){body})`; the generic emitter passes
`function(a){body}` directly as an argument to fn, which also suppresses name
inference. Saved partial code name/length/constructibility must still be checked.
Lifted, erased, computed, short and other previously refused arms already use
the generic branch and should remain structurally unchanged.

A structural audit can normalize only these old emitted forms:

```js
(/* prebind-arm */matcher1p(tag,count,total,()=> (0,function(a){BODY})))
// becomes
matcher1(tag,()=>fn(total,function(a){BODY}))
```

and the exactCode successor form above. Verify the count/arity/factory AST shapes
before rewriting; preserve BODY nodes and every unrelated generated node. Parse
both actual compiler outputs using the existing Acorn auditor, strip positions,
comments and only the harmless `(0,function...)` grouping in these recognized
sites, then require complete AST equality after the named rewrite. This is an
experimental comparison tool, never a compiler string postprocessor. A failed
structural comparison is a finding to explain, not permission to broaden the
normalization until it passes.

The runtime argument for the rewrite is direct. Generic B projects once, reads
the vector length, creates the code and descriptor, and returns an unsliced
bounce or the zero-field descriptor. matcher1 projects once, reads length, then
its literal arm factory creates exactly that same fresh code/descriptor and
returns the same bounce or zero-field descriptor. Captures, construction timing,
code identity freshness and public callback arrow shape are preserved. Generic
apply owns all later field copying, partial/exact/oversaturated scheduling and
call hooks. For scalar wrappers the registration occurs inside the selected arm
factory at the same point, before fn construction; the final exact-entry check
therefore remains unchanged.

## Validation and documentation

Retain test-arm.mjs as semantic coverage, with expectPrebinding=false and
expectExactArms=false in a new receipt. Do not discard its72 original and22 newer
public descriptor/effect/foreign-vector observations because an optimization was
removed. Preserve comparisons to generic B, the seven original scheduling
witnesses, public callable shape, scalar entry controls, tree admission/numeric
boundaries, and original-program outputs. Run one fresh checked build; do not
repeat unrelated large budget books when admission source is verified unchanged.
A cheap row and scalar-worker confirmation checks that changing helper spelling
did not accidentally reintroduce a performance boundary.

Replace the maintained JS README's prebinding paragraph with the generic delayed
arm contract and link the rejection/retirement report. Keep Phase27 historical
reports and experiment tools unchanged. Update compiler documentation and current
metrics to remove this optimization from the maintained concept count. No new
runtime metadata field, host side map, IR node or compiler state is needed.
