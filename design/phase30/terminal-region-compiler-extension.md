# Minimal compiler extension for the measured terminal-record region

Prospective implementation plan, conditional on the generated-JavaScript timing
experiment. No compiler source is changed by this document. Read alongside
[terminal-record-nested-region.md](terminal-record-nested-region.md) and its
[implementation report](../../implementation/phase30/terminal-record-region.md).

## Actual checked shapes to admit

The checked coverage receipt is
`selfhost/build/phase30/inspection-region-coverage-01/report.json`; original
attempt07 output is `selfhost/build/phase30/transfer-07/mandelbrot/candidate.mjs`.
The receipt records checked KTerm summaries, not a complete serialized book.
The following uses source binder names for readability; implementation must
retain the original globally unique binder IDs and annotations.

| Definition | Checked telescope | Checked value shape |
|---|---|---|
| `hchunk` | `Nat, U32, Nat, U32×8 → Hs` | `Mat Zero (Lam×10 → Ctr Hl) (Mat Succ (Lam×11 → Let×10 → exact self App) Efq)` |
| `mit` | `Nat, U32×6 → U32` | `Mat Zero (Lam×6 → Var it) (Mat Succ (Lam×7 → Let×7 → exact self App) Efq)` |
| `pix` | `U32, Nat → U32` | `Lam×2 → Let×2 → exact saturated App mit` |
| `bkt` | `U32, Nat → U32` | `Lam×2 → Let → exact saturated App sel` |

These shapes contain ordinary `Ann` nodes throughout. The checked shape walk
visits 416 expression nodes for `hchunk`, 315 for `mit`, 80 for `pix`, and 45 for
`bkt`, using the receipt's stated traversal. Its repeated annotated expressions
are not counts of dynamic executions. `Hs` is a closed user Data declaration with
one constructor `Hl` and eight U32 fields. The emitted metadata identifies the
constructor as nonnative and keeps its existing eight-field layout.

Two grammar extensions suffice: a flat Data value in a terminal result position,
and a nested helper proven to be the same existing Nat countdown. Native Nat in
acyclic helper signatures is needed for `pix` and `bkt`; it adds no representation.
Leave nested helpers' results scalar in the first implementation.

## Admit a record result without adding a flag to every traversal

Keep `j_region_scalar` unchanged. Add a bounded result-type predicate accepting
either that scalar predicate or one conservative flat Data shape. Initially the
Data shape should require:

- The normalized type is an unrefined `ADT` with zero parameters. The owner is
  a nonnative, parameterless/template-free `KDef` of kind `ADT`, whose kind is
  `Data` (`Typ` with `Qua 2`). No constructor-name or type-name-only proof.
- Exactly one local `Ctr`, with a canonical constructor identity, no templates,
  and at most 32 fields. Its telescope has only live fields of native scalar
  types, and ends at that same zero-parameter ADT. Reject recursive fields,
  functions, records, arrays, erased fields, dependent fields and refinements.
- The constructor term is found in this owner's local `dc`, not through the
  permissive fallback of `j_layout_ctor`. Its field count matches its telescope.

This deliberately admits `Hs` while leaving a future sum-type/result extension
separate. Reuse checked KTerms and the existing ordinary constructor emitter.

Change these boundaries, without threading a new record-context flag:

1. `j_region_expr` and its `Ann` case may accept the new result predicate. Keep
   `Var` restricted to scalar environment entries and keep scalar literals as
   they are. The constructor case accepts the validated terminal record and
   transforms its fields using their original telescope.
2. In `j_region_bindings`, explicitly check that every RHS type is scalar before
   calling the broader expression function. Parallel RHSs still see the old
   environment; only the final body sees the extended one. A record can therefore
   occur as the final body, but cannot enter the environment.
3. In `j_region_args`, explicitly require every argument's telescope type to be
   scalar. Its empty-argument result check can accept the new result predicate:
   this is necessary both for the terminal constructor and the retained owner's
   self-tail application. It does not authorize record arguments.
4. Keep `j_region_signature` scalar at its result. Expand its native whitelist
   from U32/Bool to U32/Bool/Nat, so private ordinary helpers cannot return records.
   Keep unknown/effectful call shapes rejected.
5. Let `j_nat_loop_signature` accept the new result predicate only at the end of
   the owner telescope; input slots retain their existing scalar checks.

The resulting record-valued grammar is only `Ann`, scalar-binding `Let`, the
validated constructor, and the already-proven owner's terminal self call. There
is no record variable, record argument, projection, or record-returning helper.
The source is already checked; annotations and constructor owner/telescope checks
must still match the expected result, rather than accepting an unrelated ADT.

The ordinary `j_constructor_mode`/`j_ctor_thunks` path preserves forcing. At loop
exit, `j_nat_loop_emit` already creates the final argument vector and invokes
`j_lambda_code` on Zero, introducing immutable aliases. Keep those aliases and
the `build` result. Do not hoist fields, eagerly call `ctor`, or flatten fields.
Actual `Hl` fields are scalar variables. Independent review recommends that the
first patch explicitly admit only scalar variable fields (optionally scalar
literals). That avoids any private helper call being deferred beyond the guarded
worker return: the proof is immutable scalar aliases and unchanged build forcing.
General computed fields remain a separate extension requiring an explicit
no-intervening-observer argument over the deferred forcing interval.

## Factor the existing Nat shape proof once

`j_nat_loop_worker`/`j_nat_loop_match` currently select the two-arm shape, and
`j_nat_loop_checked` combines its structural checks with emission. Extract a
Boolean admission function so the public worker and nested helper reuse all of:

- ordinary nonnative/template-free definition, `Mat Zero`, `Mat Succ`, terminal
  `Efq`, and exact child counts;
- existing arity range, native Nat identity, 8,192-node source bound, scalar input
  telescope and admissible result;
- existing lambda counts/types, distinct binders, absence of labeled binders;
- existing `j_nat_loop_tail`/`j_nat_loop_call`: exact saturation and the captured
  predecessor in the first self-tail argument, with safe intermediate bindings.

One practical split is `j_nat_loop_shape(book,d)` for the outer Mat checks plus
`j_nat_loop_shape_arms(book,d,zero,succ,total)` for the existing checked predicate.
The public worker extracts the same arms and emits only when this predicate is
true. The helper path adds its stricter scalar-result signature. Do not create a
new loop IR, duplicate the tail matcher, or infer a loop merely from recursion.

## Analyze nested loops using the existing traversal state

Inside `j_region_helper`, after the existing cache/active/depth/count checks and
source bound, distinguish an admitted Nat loop from the ordinary lambda/Boolean
helper path. Keep the same completed-helper cache and `JRegionBuild` record.

For a nested loop:

1. Add its name to the current `active` list and increment the current helper
   depth once. Analyze its Zero arm with `j_region_prefix`, `keep=True`, no tail
   name, the same accumulated helper list and remaining fuel.
2. Preserve that rewritten Zero term; analyze Succ with the returned state,
   `keep=True`, and this helper's name as the permitted tail target. Use its
   original arm telescope and arity. Both arms retain their Lam spines.
3. Reconstruct the original `Mat Zero / Mat Succ / Efq` KTerm around those two
   rewritten arms, preserving its metadata and the original definition type.
   Only after both branches pass, use `j_region_helper_done` to cache the complete
   rewritten KDef.

Small continuations analogous to `j_region_plan_zero`/`j_region_plan_done` are
sufficient; there is no new analysis-state type. In particular, **do not call a
fresh `j_region_plan` for the nested definition**. That would reset the active
chain, shared 32,768-node work budget and accumulated helpers, weakening cycle
rejection and duplicating work.

`j_region_prefix_on` already uses `Env` rather than `JEnv` for preserved Lam
spines. The private loop therefore retains its original binder identities and
uses the existing `$s`-slot alias emitter. Scalar acyclic helpers still consume
their prefixes into `JSlot` and `JIf`. No normalization is run after injecting
private nodes.

An accepted helper's self call remains an ordinary typed `App` for the existing
tail-loop emitter. Calls elsewhere in its Let RHSs or arguments carry no permitted
tail name and encounter the active-name refusal. Mutual recursion across helpers
also refuses. A proved self-edge is the only exception; the graph between helpers
remains acyclic. Completion caching never admits a partially analyzed loop.

## Emit the private helper with the existing loop body

`j_region_definitions` currently emits each rewritten helper as scalar positional
parameters plus `return j_expr(...)`. Add one branch for the deliberately retained
Mat form. Boolean helper matches have already become `JIf`, so this distinguishes
the admitted nested loop without a new tag or metadata field.

Emit a private function with its original total arity and unprojected Nat in
`$p0`. Its body is conceptually:

```js
if ($p0 === 0n) {
  const a = [$p1, /* ... */];
  // Existing j_lambda_code on the rewritten Zero arm.
}
let $s0 = $p0 - 1n;
let $s1 = $p1; // ... remaining original scalar parameters
// Existing j_nat_loop_body on the rewritten KDef and Succ arm.
```

Reuse `j_lambda_code`, `j_nat_loop_body`, `j_nat_loop_enter`,
`j_nat_loop_emit`, `j_nat_loop_next`, and their existing zero-transfer code. A
small parameter-to-slot string helper is enough. There is no nested snapshot
check, public matcher, `fn`, bounce, or new primitive lowering in this private
function. The proof of scalar provenance and the complete outer closure guard
authorize it.

The outer helper list now includes `pix`, `bkt`, `mit`, `asr8`, `sel`, `sel.go`,
`b2u`; the wrapper already adds `hchunk`. Existing `scalarCapture` registration
must occur at definition construction for `pix` and `bkt` after Nat signature
admission. Both loop owners must be guarded. Missing/forward captures continue
to fail closed. There is no runtime change or relaxed metadata policy.

## Expected source cost and boundaries

Estimated net cost is roughly **100–170 physical Bend lines**, or **80–140
nonblank lines**, depending on continuation factoring and whether conservative
constructor checks are shared. This is a planning estimate, not a measured patch.
The expected changes are confined to `region.bend` and `worker.bend`; reuse the
ordinary constructor emitter and runtime unchanged. No new KTerm tag, public API,
record representation, graph/SCC pass, pattern compiler, or analysis-state field
is needed. The two added admission concepts are terminal flat Data and a proved
nested Nat countdown. Avoid expanding to F32, arbitrary Nat selectors, carried
records, general recursion or additional primitive operations in this patch.

Preserve the existing 32-helper, depth-16, 8,192-source-node, shared 32,768-work,
expression-depth and binding-count limits. Bound new record/telescope scans by
32 fields. Do not hide compile-time growth by increasing build/check timeouts.

## Implementation and refusal controls

First add the reusable Nat-shape predicate while keeping admission unchanged;
verify generated-output equality. Then add terminal Data admission with scalar
helper dependencies only, and finally the nested helper analysis/emission. Use
the same checked small fixtures and fast original Mandelbrot acquisition between
steps. Keep an immutable checked attempt and provenance for the final candidate.

Positive cases should include full histogram equality across the prototype's
200 states, zero/one nested iteration, both scalar and record owner results,
nonzero/wrapping counters, scalar Let bindings before the final constructor,
shared nested helper dependencies, nested loops in both owner branches, forward
definition order, and the existing successful scalar suite. Compare the admitted
private calls/guard closure with the generated-JavaScript experiment.

Refusal cases should explicitly cover:

- a record parameter or Let RHS; record projection; a record-returning ordinary
  helper; nested/recursive/functional/erased/dependent constructor fields;
  parameterized/refined/native Data; wrong constructor owner or field count;
- non-tail self recursion, unchanged/increased countdown, wrong predecessor,
  recursion hidden in a Let RHS/argument, and mutual cycles through a nested
  loop or an acyclic helper;
- malformed/extra match arms, native/type-name impostors, labels, erased runtime
  parameters, under/overapplication, computed globals, unknown/foreign callbacks;
- a depth-17 mixed graph, more than 32 completed helpers, shared fuel exhaustion
  across Zero and Succ, and repeated references that must reuse only completed
  helpers rather than resetting their budgets.

Finally rerun the prototype's hostile public controls against actual checked
emission: all eight descriptor mutations, exact-entry/raw/overapplication order,
slot getters/reentrancy, code shape/constructibility, primitive/prototype hooks,
and terminal build/field forcing. Use the corrected generic output as reference.
The final promotion requires measured retained benefit and the scoped conformance
and build checks; a synthetic admission test alone is insufficient.
