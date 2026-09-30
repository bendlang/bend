# Phase26: the next call-lowering ablation

Read-only source investigation at commit `7199b391865f79acd38e67b44c4fdf21bfa721e9`, before the Phase26 U32 implementation. No compiler edit or new execution measurement supports this note. The source anchors are [our JS emitter](../../selfhost/src/back/js/emit.bend), [projection specialization](../../selfhost/src/back/js/projection.bend), [choice specialization](../../selfhost/src/back/js/choice.bend), [runtime](../../selfhost/src/runtime.mjs), and [upstream emitter](../../bend2/comp.ts).

## What upstream does that we currently lose

Our `j_lambda_count` stops at `Mat`; `j_call_arity` uses that count, except for recognized native Base definitions. `j_apply_regular` only groups a named application's arguments when their count fits that initial arity. A match therefore splits a semantically multi-argument definition into several runtime applications. `j_match` builds a one-argument matcher whose selected arm is another function; constructor fields partially apply that arm before the remaining source arguments arrive.

The frozen Phase25 `walk` witness has a `Con` arm with four lambdas: two constructor fields, then scale and offset. It emits nested `call(call(call(get(G,"walk"),[tail]),[scale]),[offset])`. Upstream receives three parameters and lowers this definition through `js_func`/`js_match`; selected constructor fields are prepended to the still-unconsumed argument list. Current upstream `fun_of` uses declared parameter count plus `def_raise`, bounded by the type telescope; it does not simply make every arrow in a type an eagerly consumed parameter. It also computes tail cycles separately.

The [Phase25 diagnostics](../phase25/dynamic-findings.md) measure 769 partial records and 3,591 `apply` entries per complete size256 match-remaining-args benchmark. They establish a hot mechanism, not the share attributable solely to `walk`, and not a predicted speedup. The benchmark also constructs its input and dispatches arithmetic primitives.

## Smallest useful ablation: prebind a selected constructor arm

Before generating general saturated private workers, remove the redundant runtime partial application of constructor fields. Keep the outer matcher arity1, the later source applications, and the returned partial function's original descriptor.

For a known single-remaining-constructor match with two live fields and a literal four-lambda arm, the current path is schematically:

```js
fn(1, ([x]) => {
  const p = project("Con", x);
  return p.length ? jump(fn(4, armCode), p) : fn(4, armCode);
});
```

After `force`/`apply`, an ordinary two-field input returns `fn(4, armCode, null, p.slice())`. Emit that result directly for the eligible field-count case:

```js
fn(1, ([x]) => {
  const p = project("Con", x);
  if (p.length !== 2) return p.length ? jump(originalArm(), p) : originalArm();
  return fn(4, armCode, null, p.slice());
});
```

`originalArm` above denotes emitted fallback code, not a proposed new global. This removes the initial arm function record, one bounce and one `apply` entry per eligible match. The field-vector copy remains. The returned function retains arity4 and two bound fields; replacing it with an arity2 closure would change the runtime descriptor exposed through `G`.

Initial eligibility should be deliberately small: a single remaining constructor; a completely explicit, non-lifted leading-lambda arm; all constructor fields live; a positive field count strictly smaller than the arm's leading-lambda count; and normal typed constructor/arm telescopes. Reuse `j_specialize`, `j_find_ctor`, `j_lambda_count` and `j_lambda_code`. Reject erased-field telescopes, eta-short arms and lifted factories at first. No native layout assumption is needed if the emitted code retains `project` and the generic field-count fallback.

This is approximately an 80–120 physical-line implementation hypothesis including guards/type signatures, not an implemented line count. Its main addition is one lowering rule, not a new runtime representation, analysis graph or global calling convention. A later exact-field-count arm can inline its body while retaining the bounce return convention, but that should be a separate extension.

The field snapshot must preserve the existing left-to-right `slice` reads, including accessor observations covered by the projection tests. Additional/removed meta-operations on adversarial proxies are not proved equivalent by this sketch. A production implementation must either retain the relevant property-read schedule or state and validate a narrower internal-data domain; a property-count guard alone does not prove arbitrary proxy equivalence.

This ablation is less ambitious than saturated workers: it leaves later argument dispatch, generic primitives and recursion scheduling intact. It could therefore lose on timing even if counters improve. Compare unchanged/candidate emitted `match-remaining-args`, `partial-application`, `term-substitution` and a no-match control first. Require the specifically predicted record/dispatch decrease and unchanged exact outputs before timing; then use the frozen serial paired harness. Do not infer whole-H speed from this result.

## Why simply increasing arity is incorrect

1. **Later argument demand:** `call(call(f,[badScrutinee]),[later()])` matches or fails before `later()` runs. Rewriting to `call(f,[badScrutinee,later()])` runs `later()` first. A throwing or diverging later argument distinguishes them. Purity and a multi-arrow type do not fix the issue.
2. **Partial calls:** after only the scrutinee, the existing matcher has already performed its match. Raising its public arity can delay that error or effect until another argument arrives.
3. **Eta-short arms:** a constructor with a function field can return that field before consuming all projected fields; generic overapplication then calls it on the remaining field. The existing projection test's `short` witness demonstrates this. Counting the constructor telescope alone is insufficient.
4. **Erasure:** our ABI retains null slots while suppressing erased argument evaluation. Upstream's live-only argument machinery is not directly interchangeable with ours.
5. **Trusted foreign records:** `project` intentionally differs from `fields`: a final constructor match can accept trusted foreign field layouts. Replacing it with a new tag test changes behavior.
6. **Stack and construction order:** direct JS recursion/eager constructor construction can overflow or reorder a failing head and tail. Keep `jump` and ordered build thunks until their own separately controlled optimization.

A real private saturated worker remains possible at named exact call sites when all moved arguments are already-bound values and the worker has a checked demand schedule. That requires a separate entry, eligibility tracking and a worker body emitter. It is not honestly a generic ~100-line change. The [earlier one-site substitution worker](../phase4/private-substitution-workers.md) passed157 controls but produced7.25% and1.99% opposite-order request reductions, failing its predeclared consistent5% gate. This is preserved negative evidence, not a reason to promise that another worker automatically wins.

## Real compiler component for U32 integration

The smallest actual compiler component is `j_escape_char_on` plus `j_escape_char`/`j_escape` in `selfhost/src/back/js/emit.bend`. Its numeric cases are34,92,10,13,9,0 with a character fallback. `j_escape_char_on(c,key)` has a leading character argument and then the numeric match, making it a useful captured/remaining-argument integration witness as well as real emitter work. `j_escape` applies it across a string; its surrounding recursive string processing is retained and may dominate after numeric decisions become cheap.

Extract the actual definitions without renaming or editing their bodies, record their source byte ranges/hash, and append a small `bench` wrapper with runtime-generated strings and a complete checksum. Check all six escaped characters, ordinary ASCII, non-ASCII BMP and astral scalars. Preserve the output text in a correctness probe; a checksum alone is insufficient. Compare old selfhost, candidate selfhost and upstream emissions using the same wrapper and input. Compilation time, generated-program execution, generated function size and eliminated `word`/constructor events are separate observations.

A second real component is `sk_char`/`sk_escape` in `selfhost/src/check/specialize.bend`: seven direct numeric cases plus lower-control/surrogate/default handling. It has additional dependencies (`kc`, `kp_hex`) and more demanding JSON-string correctness, so the JS escape component is the faster first discriminator. Neither component establishes end-to-end compiler speed; no current full self-emitted compiler H was built by this investigation.

The initial Phase26 prototype is planned to restrict results to U32. Under that restriction the actual escape helper is an **unchanged fallback/transfer-limit control**, not an expected optimized component. A source census of numeric literal/default U32 patterns found only four current compiler owners: `j_escape_char_on` and `sk_char` return String; `nb_regs` and `nb_fork_close` return lists of strings. It found no corresponding real U32-result numeric-decision component. This census is source-syntax scoped and does not classify every generated/elaborated match. The extracted [component](../../selfhost/tools/performance/phase26/compiler-escape.bend) and [oracle](../../selfhost/tools/performance/phase26/compiler-escape-oracle.mjs) preserve the exact helper fragment hash; whether broader result support pays off remains a later measured question.

The extracted component subsequently passed an upstream-only checked-emission and oracle pilot on CPU6/Node24.18.0, 4MiB stack/1GiB heap: five full-text edge inputs and all six wrapper scalar/full-text points, including benchmark sizes32/128. Evidence is `selfhost/build/phase26/compiler-escape-upstream-01/{upstream.mjs.json,oracle.json}`; emitted module SHA256 `4536951ca620cc49e11fd8b9c93ea112af4bc2b980e4c2cbd0663d2a9ef5e890`. This validates the fixture, not candidate behavior or optimization speed. The opening no-new-measurement statement refers to the call-lowering investigation; the component pilot is a correctness acquisition, not timed comparative evidence.
