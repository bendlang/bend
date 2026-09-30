# Phase28: structural findings in the paired JavaScript

Read-only inspection of the exact acquired Mandelbrot and lexer libraries shows
three concrete optimization opportunities. These are observed differences in
emitted structures, **not a measured decomposition of the performance gap**.
No profiling, instrumentation or optimization was run as part of this inspection.
The comparison report supplies the clean timings; the
[workload notes](workloads.md) explain input limits.

The captured libraries are:

- `selfhost/build/phase28/runtime-01/mandelbrot/{upstream,selfhost}.mjs`
- `selfhost/build/phase28/runtime-01/lexer/{upstream,selfhost}.mjs`

Their exact source, module and emitter identities are in the acquisition receipts
and `selfhost/build/phase28/runtime-pairs.json`. The TypeScript emitter inspected
is pinned `018751270e800bc222a93dad7f257083ee53a5f7`, available locally at
`selfhost/.bootstrap/upstream-phase23/bend2/comp.ts`; the candidate is the unchanged
Phase27 checked image and runtime. The emitted modules are part of the Phase28
raw evidence, not handwritten benchmark implementations.

## 1. Calls remain fragmented across pattern matches

Upstream Mandelbrot's `$mit$` is an ordinary seven-parameter JavaScript function
with a `for (;;)` loop. Its recursive tail transfer assigns the next arguments
to local slots and executes `continue`. `$hchunk$` does the same with eleven
parameters. The upstream lexer uses an ordinary two-parameter loop for `$lex$`.

The corresponding selfhost definitions have different shapes:

- `G["mit"]` starts with a Nat matcher. The recursive invocation contains six
  nested unary `call(...)` operations before its final `jump(...)`.
- `G["hchunk"]` similarly contains ten nested unary `call(...)` operations before
  its final `jump(...)`.
- `G["lex"]` traverses the generic SNil/SCon, Chr and Tuple matchers to recover
  its character and state before calling the next iteration.

These are visible in the Mandelbrot selfhost module around lines 628–633 and
lexer module around lines 638–654. Upstream's corresponding `$mit$`, `$hchunk$`
and `$lex$` definitions begin at lines 188, 247 and 397 in their respective modules.

The relevant compiler boundary is
[`j_apply_regular` and `j_call_arity`](../../selfhost/src/back/js/emit.bend).
Call grouping uses intrinsic arity or the count of leading lambdas; that count
stops at a match instead of recognizing the complete source function's parameters
across its matched argument. The emitted matcher retains its public one-argument
boundary. The
[`apply`, `call`, `fn` and `jump` runtime helpers](../../selfhost/src/runtime.mjs)
then perform generic descriptor dispatch: copying or concatenating argument
arrays, allocating partial descriptors when undersaturated, and forcing results.
Phase27 prebinding removes one boundary inside selected arms but leaves these
visible nested application chains.

Both compilers already have tail-jump machinery. The selfhost's `jump`/`force`
protocol handles tail transfers; upstream has `run_tail`/`run_loop` for closures
that need them. The difference here is which known calls can become ordinary
fully saturated functions and loops. Pinned upstream `js_call`, `js_func` and
`js_def` use known call spines and tail-cycle information to generate those direct
paths; generic closure bounces remain available separately.

**Testable direction:** generate a private saturated worker for `mit`, then for
`lex`, while preserving the public partial-function descriptor and the original
argument-demand order. Measure each as a separate ablation. Merely raising the
public arity would change the established partial-application contract. Generic
apply counts and descriptor allocations should fall if this hypothesis transfers;
the size of the speedup remains unmeasured.

## 2. Tiny arithmetic operations still cross generic runtime boundaries

Upstream `$asr8$`, `$mit$`, `$prng$`, `$mix$` and `$fnv$` contain direct JavaScript
shifts, comparisons, addition, bitwise operations and `Math.imul`, with the
appropriate unsigned wrapping. For example, lexer's `$prng$` is a short straight
line of shifts and XORs.

Selfhost `$prng$` instead calls registered `U32.shln`, `U32.shrn` and `U32.xor`
primitives through `call(get(G, ...), [...])`. Mandelbrot's inner arithmetic has
the same pattern for its adds, multiplies, shifts and comparisons. Native
primitives do perform host arithmetic, but reaching that arithmetic goes through
the descriptor and argument-array protocol. These differences are visible in
lexer module line 633 and Mandelbrot lines 627–631.

Pinned upstream `js_call` expands each intrinsic's JavaScript template directly
(`intr_of(...).JS`, around `comp.ts:3060`). Selfhost's
[`j_intrinsic` and ordinary call emission](../../selfhost/src/back/js/emit.bend)
recognize native calls for registration/arity but generally emit runtime calls
at these sites. The Phase26 scalar decision optimization addresses a different
eligible shape; it has not made these ordinary arithmetic sequences direct.

There is also a representation difference in the captured paths: selfhost Nat
values use BigInt, including literal shift counts, and the native shift helpers
convert those counts to Number. Upstream uses numeric Nat values in these
functions. The [runtime helpers](../../selfhost/src/runtime.mjs) show
`U32.shln`/`U32.shrn` testing against `32n` and converting with `Number(n)`;
upstream emitted shifts use numeric constants. This is an additional observed
cost boundary, not evidence that BigInt is the main cause of either gap.

**Testable direction:** inline guarded primitive expressions in a small pure U32
helper such as lexer `prng` or Mandelbrot `asr8`, then compare that isolated change
before combining it with call/loop lowering. Preserve unsigned wrapping, shift
limits and evaluation order. Direct arithmetic could remove many generic calls
and expose more work to V8 optimization, but neither the direct dispatch cost nor
the indirect JIT benefit has been separately quantified here.

## 3. Native construction and elimination retain generic scheduling objects

Upstream lexer `$ident$` and `$num$` construct a character and concatenate it with
the recursively produced string. `$step$at$` uses direct conditionals and creates
ordinary tagged records with named fields; `$lex$` reads its pair fields directly.

Selfhost lexer `G["ident"]` and `G["num"]` build SCon/Chr nodes through `build(...)`
objects containing field thunks. The runtime's `force` follows those thunks and
maintains an explicit pending-frame stack before invoking `ctor`. Matching
similarly enters generic `matcher`/`matcher1`/`matcher1p` helpers and obtains
projected field arrays and arm descriptors. These are visible in lexer
lines 638–639 and 653 and in
[`build`, `force`, `fields`, `project` and the matcher helpers](../../selfhost/src/runtime.mjs).
Pinned upstream `js_expr`'s constructor branch and `js_match` lower known native
constructors and eliminators directly (`comp.ts`, around lines 3115 and 3216).

**Both outputs already use native JavaScript strings.** Claiming that this
comparison is a linked-string representation versus a native string would be
incorrect. The observed distinction is the surrounding construction, matching
and scheduling machinery. Both still perform the source's string generation,
character traversal and token-state processing.

**Testable direction:** a guarded direct path for known native constructors and
field matches, measured independently from primitive or call changes. Preserve
field evaluation order, forcing and deep-construction stack behavior; replacing
all scheduled construction with recursive host calls would need separate safety
and correctness evidence. Allocation diagnostics can test whether the predicted
thunk/frame/descriptor reduction actually occurs before attributing timing gains.

## What this inspection does not establish

These mechanisms plausibly compound: fragmented calls conceal arithmetic from
V8 while producing temporary descriptors and arrays, and generic construction
adds more scheduling work. That is a hypothesis, not a fitted explanation of the
measured ratios. No percentage of the slowdown is assigned to any mechanism.
The very small, geometrically restricted Mandelbrot input can also magnify the
importance of host optimization and a small reference denominator. Controlled
ablations on unchanged inputs, followed by the broader suite, are needed before
selecting or promoting a compiler change.
