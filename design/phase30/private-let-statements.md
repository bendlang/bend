# Lower private scalar Let expressions to statement blocks

The checked attempt12 Mandelbrot output still spells private `rpix`, `pix` and
`bkt` bindings as nested arrow-function applications. Those functions already
execute inside a guarded pure scalar region. Test whether removing these
administrative calls helps JavaScript optimize their ordinary scalar arithmetic.
This is a generated-JavaScript ablation, not permission to widen region admission
or change arithmetic, entry guards, public callbacks or runtime behavior.

Freeze two independently checked attempt12 emissions: the original Mandelbrot
library from `transfer-12/mandelbrot/candidate.mjs` and the identical-source
scalar fixture from `review-entry-state-source-12/candidate.mjs`. Verify their
checked receipts, input, API, runtime, Base and attempt identities. Derive one
statement variant per source and retain each original byte for byte. If the
fixture contains no eligible expression, record that no-op rather than inventing
a changed helper or timing identical variants.

Only inspect declarations named `$R_<codepoints>` whose whole body is exactly
`{return EXPR;}`. A transformable expression must have the exact generated shape
`((x1,x2,)=>BODY)(ARG1,ARG2,)`, with distinct `x<number>` parameters, the same
argument count, ordinary expression arguments and no rest/default/destructuring
syntax. Single binding is the same rule with one parameter. Refuse ambiguous
syntax and lexical features outside the generated subset. Leave primitive IIFEs
with binders such as `a`, `b` and `n` unchanged. In particular, do not inspect or
rewrite IIFEs inside primitive expressions or argument expressions. Private
helpers containing existing statements, Nat loops or tree loops are unchanged.

Evaluate every argument into a globally fresh temporary, in its original order,
before introducing any source binder. Then open a nested block and bind the
source names to those temporaries. Recursively lower only the returned BODY:

```js
function $R_example($p0) {
  const $let30_0 = ARG1;
  const $let30_1 = ARG2;
  {
    const x1 = $let30_0;
    const x2 = $let30_1;
    return BODY;
  }
}
```

The separate argument and binder scopes preserve parallel binding and shadowing:
no right-hand side can see another binder from the same Let. Nested scopes retain
outer bindings for a later Let argument even if that Let reuses a name. The
generated pure scalar expressions do not use `this`, `arguments`, `eval`,
`new.target`, asynchronous control, reflection on the administrative closure, or
escaping closures. Reject those shapes. Preserve every leaf/argument expression
slice, helper parameter list, helper name, private call and numeric operation.
The normal guarded region already proves purity and scalar provenance; this
probe adds no second purity analysis or new runtime promise.

Retain offset-indexed original/replacement body patches. Apply them from the end
of the module, then reconstruct the exact original module using the corresponding
changed offsets and assert byte equality. Retain the parser, derivation, design,
checked inputs and patch manifest. Report static changed helper and binding
counts separately from runtime costs; lexical copies are not dynamic call counts.

Before timing, independently execute focused synthetic scope/evaluation-order
examples, including parallel shadowing, nested rebinding and a throwing later
argument. Execute the existing original Mandelbrot scalar-tree oracle and public
boundary controls on baseline and statement variant. Preserve numeric operations
in the independent oracle, all public mutation/partial/raw-entry/overapplication
witnesses, and its safe depth sentinels. Include whole original bench outputs at
the existing sizes. If the scalar fixture changes, also run its independent
numeric and exact-entry controls. Only the generated modules with no diagnostic
instrumentation may enter a clean timing window.

Use the maintained three-sample screen and, only for a promising result, the
five-sample confirmation protocol on original Mandelbrot `bench(2,0)` and its
existing small `rcol` adapter. Keep original inputs, expected outputs and guard
costs. A changed helper fixture uses its existing `bench(128,524800)` point;
an unchanged fixture is only a derivation control. The root must explicitly
release acquisition and separately grant clean timing. Preserve failures and
warmup drift rather than selecting only favorable points.

A confirmed win could become a small `j_region_return` emitter which recognizes
the existing KTerm Let and uses the existing value/name/context helpers to emit
ordered temporaries, nested binder blocks and a terminal return. It needs no new
IR or optimizer. Do not implement that production rule until this isolated
ablation passes correctness and shows a useful measured benefit.
