# Review notes for a compact compiler region rule

These are prospective implementation constraints for the guarded scalar-region
experiment. They do not establish that a general compiler rule exists or passes.

Use the existing private Nat-loop admission as the outer boundary. Add a small
helper analysis rather than a new general core representation. The first useful
scope is U32/Bool scalar helpers, a Nat countdown, reviewed scalar primitives,
and an acyclic helper graph. Unknown terms decline to the existing loop.

## Two analyses

**Transparent parameter prefix.** Normalize and validate a bounded, live native
scalar telescope. Traverse only annotations, explicit unlifted lambdas and
exhaustive native Boolean matches until every parameter is consumed. Both match
branches must support the same complete telescope. Do not allow lets, computed
globals or arbitrary expressions before complete saturation. Preserve binder
identity and branch scope. Reject erased, function-valued, parameterized,
refined/unknown-domain and malformed types in this first rule.

**Pure scalar body.** After saturation, admit typed lexical variables, validated
scalar literals, parallel lets, exact reviewed primitive calls and exactly full
calls to other admitted helper definitions. Analyze helper dependencies with a
bounded DFS stack; a repeated active definition declines rather than recursively
expanding forever. Shared callees need one collected snapshot. Do not treat a
bare global Ref as a scalar atom: its initializer can execute. Do not admit
foreign bodies, higher-order applications, records, arrays, constructor-field
projections or computed closures. The preexisting loop handles the sole admitted
repetition; helper cycles need a later loop/SCC rule.

Each intermediate expression must preserve the scalar type invariant. A Var
obtains its native scalar kind from the lexical environment. A primitive or
helper call obtains argument/result kinds from its validated telescope, then
checks arguments recursively in source order. A let must either carry a usable
annotation or have an inferred supported scalar value shape; all sibling RHSs
use the outer environment. Ambiguous types decline. Initial simplicity is more
valuable than accepting all syntactically pure-looking terms.

Native identity and the already reviewed primitive manifest should be reused.
The initial U32/Bool arithmetic/comparison operations are total on admitted
inputs. Nat.add and other potentially failing unreviewed runtime calls remain
outside the first helper subset. Purity alone would not justify rearranging two
possible errors: transparent prefixes and total admitted scalar operations are
what remove the intermediate demand hazard.

## Emission and runtime boundary

Emit private helper functions with complete positional scalar arguments. Their
direct Boolean branches and primitive expressions must preserve the current
operation/rounding boundaries. Reuse primitive rendering where possible by
separating operand rendering from the existing operation template; do not create
a second arithmetic specification or rewrite generated strings in production.

The loop callback reads its existing state vector once, then validates those
locals and the unique reachable helper snapshots. The accepted branch calls
the private loop; the declined branch retains the original loop body. A small
backend plan can retain helper names, validated scalar telescopes, dependencies
and supported bodies. It need not replace the frontend core, ordinary emitter
or runtime representations.

Private code cannot call a runtime helper that performs an unguarded G lookup
or invokes a callback. Primitive recognition must cover the actual final native
implementation, not merely a familiar source name. In the first scalar fixture,
private helpers use the existing emitted native expressions and no constructor,
array or foreign runtime machinery.

Keep a finite term/node/arity/dependency budget and explicit branching before
recursive admission. Bend Boolean operators are eager. Oversized, cyclic or
unsupported input must promptly retain normal emission rather than overflow
the compiler stack.

## Verification that discriminates the new path

Use a checked source with the same scalar helper structure but different names
and arithmetic values, plus one-branch and multi-helper variants. Verify actual
private-region emission and a once-per-entry guard counter. Add near misses:
computed globals, effectful foreign functions, callback arguments, recursion,
early lets, erased slots, native-name impostors, Bool refinements and wrong
scalar types. Each must preserve ordinary output and decline region emission.

Compare saved public partials, state-vector accessors, invalid/coercible scalar
inputs, replaced G entries, descriptor mutation and 50,000 iterations. Preserve
the standard-intrinsic/prototype assumption explicitly. A fast-path failure may
not be masked by tests that only exercised fallback. Finally measure short as
well as longer loops: a one-time reflection guard can dominate a tiny invocation
even when it removes almost all repeated dispatch in a larger loop.
