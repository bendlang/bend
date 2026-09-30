# Phase30 independent semantic plan

Reviewer: `phase30_review`, separate from the prototype and compiler owners.
This prospective plan reviews private direct calls; it is not a conformance
result or an estimate of their runtime contribution.

## Smallest useful rule

Keep each public `G` descriptor and all partial application behavior. Add a
private entry for a checked definition whose complete parameter prefix consists
of literal lambdas and recognized constructor matches. Initially call it only
from a fully entered caller and only when moving later actual arguments across
an earlier application boundary is proved harmless. Lexical variables and
validated native scalar constants are the smallest useful such set. A `Ref` is
not automatically harmless: `get` can execute its zero-arity initializer.

Emit matches in their existing order using `fields`/`project`, preserving field
snapshots. Ordinary tail calls must keep the trampoline until a separate loop
transformation proves bounded stack. Arbitrary argument expressions require an
explicit staged evaluation plan or retention of the old call path. A saturated
source application alone does not establish those obligations.

The first disposable edit-distance prototype can be narrower: replace the
fully entered row's cell invocation and the fixed cell/f1/f2/f3/f4 chain. The
leading lambdas in this chain only construct a matcher; matching starts after
the final argument is available. Arithmetic, Array helpers, constructors and
forcing stay unchanged. This tests a mechanism without yet requiring a general
backend representation.

## Required boundaries

| Boundary | Counterexample or control |
| --- | --- |
| Match before later demand | The first record projection throws; a later argument producer must never run. |
| Interleaved work | Selecting an arm evaluates a factory or let before the next argument. Preserve that event. |
| Public ABI | Same leading arity, staged partial bound values, copied ownership, higher-order invocation and oversaturation. |
| Foreign field access | Named getters, `a` getters, proxy arrays, custom `slice`, sparse and frozen vectors. |
| Exact field-copy protocol | Original matcher reads source length, then `apply` calls slice, then tests copied lengths in its existing branch order. |
| Unexpected vector size | Zero, short, exact and long vectors; a custom slice can return a different length or change length between reads. |
| Fallback effects | Never re-run projection after observing it. Fall back with the already obtained vector/state. |
| Erasure | Erased actuals and let right-hand sides stay undemanded and retain null ABI slots. |
| Live globals | Known ordinary function references may be replaced through exported `G`; do not silently assume immutability. |
| Closure capture | Each iteration captures fresh immutable bindings; closures must not capture mutable loop slots. |
| Parallel binding scope | Every right-hand side sees the outer scope before any sibling binding is installed. |
| Tail stack | 50,000 iterations and mutually recursive cycles retain bounded stack. |
| Admission | Native identity, declared/supplied arity, templates, foreign code, field telescopes and deep lifted closures. |

For native scalar matches, native identity remains part of the proof: names
alone cannot identify representation. Unknown or malformed core shapes must
decline finitely. Recursive guard calls require explicit `kc` branches because
Bend's Boolean `&&` eagerly evaluates its arguments.

## Protocol detail that a fast path must preserve

For an ordinary single-constructor matcher, the operational sequence is:

1. Project the matched value exactly once; read the projected vector's length.
2. If length is zero, evaluate and return the arm. Otherwise evaluate the arm
   and create the same pending application boundary.
3. The application copies with `p.slice()`. The slice method, its receiver and
   the read/copy order can be observable for trusted foreign values.
4. Test copied length for equality, then less-than. In the greater case, slice
   its prefix, enter the body, read copied length again, force the result if
   overapplication remains, and slice its suffix.

A direct worker can eliminate descriptor allocation in the ordinary exact
case. It cannot recover the original semantics after extra length reads or a
second projection by merely falling back to the public function. Existing
Phase27 `test-arm.mjs` already records these boundaries.

`G` mutation needs an explicit decision. The existing backend tests require
live delayed ordinary references. A causal prototype may state an immutable
compiled-function scope. A production rule should preserve lookup/replacement
behavior (for example, by checking the descriptor identity before entering a
private worker) unless a separately justified public contract excludes it.

## Evidence to acquire

First run independent executable counterexamples for the tempting unsafe
transformations and an exact runtime-level matcher shortcut. These are
mechanism controls, not compiler admission tests. Then compare the prototype
against its immutable baseline with complete values and ordered event traces.
Finally run checked source and synthetic core controls against the actual
compiler candidate; verify emitted markers so a passing fallback does not count
as coverage of the new path. Use the existing selected semantic suites for
unchanged primitive, public partial and Nat-loop boundaries.

Only after those pass run clean timings without instrumentation. Counters and
static output shapes are separate evidence. Preserve failed attempts rather
than silently updating the expectation or reusing an output directory.

## Upstream lessons and limits

Pinned `bend2/comp.ts` computes raised arity with `def_raise`, traversing lambda
and match branches, and lowers `js_func`/`js_match` using direct arguments. Its
`loop_of` and `js_def` give each tail-cycle iteration fresh aliases. Those are
useful structural models. Our current exposed descriptor/runtime contract is
different: copying those implementations directly would change partial ABI,
field access and intermediate error ordering. We should adopt the analyses and
explicit execution boundaries, not assume observational equivalence from
similar output.
