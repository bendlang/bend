# Static integration options for closed scalar regions

Agent-generated Phase30 design notes. These are implementation options, not an
approved compiler patch or measured result. They follow the generated-JavaScript
region experiment and should be reconsidered after its clean timing and transfer.

The smallest useful general rule is a closed, first-order scalar helper region
entered from an already admitted Nat loop. It does not require a full new backend
IR. It does require a clear separation between qualification, private-call
lowering, and emission; otherwise extending a string recognizer becomes fragile.

## Reuse what is already proved

`worker.bend` already checks native Nat identity, exact live scalar telescopes,
bounded body size, distinct binder IDs, lambda/arm correspondence, a predecessor
self-tail call and supported Let scope. Its emitted successor callback reads each
argument vector slot into a local `$sN` before the loop. Those are precisely the
right places to preserve argument-demand semantics and enter a private region.

Do not change public matcher arity, public descriptors or the original fallback
loop. Keep the existing Zero branch and successor entry. Add a bounded helper
closure analysis and private loop variant only after existing admission passes.
The private mode should reuse the same next-argument temporaries and immutable
iteration aliases; the new optimization is direct calls, not a second tail-loop
implementation.

## A deliberately narrow admission grammar

An initial implementation can admit:

- all live parameters and results are identified native Nat/U32/F32/Bool scalars;
- no templates, erased slots, computed global initialization or open result types;
- expressions are scalar variables/literals, annotations, existing valid Let
  forms, identified primitive operations, and exactly saturated calls to other
  admitted helpers;
- native Bool matching may consume a parameter and branch to two scalar bodies;
- the helper graph is acyclic at first; the entry's existing Nat self-tail loop
  is handled by the current worker, not by helper recursion;
- every reachable helper is in the admission closure and checked against the
  actual definition/type/constructor identities, with bounded node and graph fuel.

Reject unknown calls, foreign code, higher-order parameters/results, function
values that escape, host objects, arrays, records, strings, custom constructors,
non-tail recursion and ambiguous matches. Later extensions need their own
counterexamples and cost justification. A scalar type alone does not prove
purity: a scalar-returning foreign function must still be rejected.

Use explicit `kc` fences before recursive recognition. The Phase29 eager-`&&`
stack failure remains applicable. Graph fuel must bound both definition count
and repeated expansion; store the discovered helper names once and do not
recompute a full transitive graph at every application site.

## The emission decision that matters

Simply adding a private function declaration is insufficient. `j_primitive_apply`
emits its operands through `j_expr`; a helper call nested inside an arithmetic
operand will remain generic unless private-call information reaches that recursive
emission. The prototype removes those nested calls too, including asr8→sel and
sel→sel.go. A compiler implementation must either do the same or report the
narrower generated mechanism honestly.

Two reasonable approaches:

1. Add an explicit private-call emission context to the expression walker. A
   successful call lookup emits a direct positional call; other code follows
   the existing emitter. This avoids a new IR node but risks threading a context
   through many helpers and accidentally losing it in primitive/Let operands.
2. After qualification, lower admitted exact calls to a small internal direct-call
   node and native Bool parameters to a branch plan. Let the existing expression
   emitter recursively emit operands and reuse primitive code. This is a small
   backend-only representation, not a new checked source construct or parser
   feature. Qualify first; do not let raw source construct those nodes.

The second option makes admission and emitted intent independently inspectable.
Its direct-call node needs only the private symbol and argument expressions if
all argument/result scalar types have already been checked and retained. A
parameter/match plan can map explicit Lam binders and implicit Boolean matched
parameters to positional variables without changing source binder identities.
Do not encode the mode using fake Env entries with colliding binder IDs: current
`j_env` looks up IDs without a distinct metadata-tag guard. Likewise, avoid
mutating the indexed book or inventing source names that a user could collide
with. Keep compiler-owned symbols and context separate.

Whichever representation is chosen, maintain one implementation of primitive
arithmetic and one implementation of Let scope. Duplicating those semantics to
make the new helper emitter look small would increase conceptual complexity.

## Runtime entry guard and public behavior

For JavaScript library output, the public G bindings and descriptors are mutable.
The entry guard checks the complete admitted closure, not just the outer helper:
G own data bindings; ordinary function descriptors and their live arity/code/env/
bound values; original empty bound vectors; callable `.call` shape. Argument
values must be checked without coercion after the original vector reads. A Proxy,
accessor, replacement, unexpected partial prefix or host-object input falls back
to the unchanged loop.

The pure region cannot mutate any of those bindings: its inputs and internal
values are scalar, its helper closure is complete, and it invokes no foreign or
higher-order code. This is the reason one guard can cover the full region. It is
not valid to reuse the guard across independent public calls or arbitrary foreign
callbacks without revalidation.

The prototype explicitly assumes standard intrinsics and primitive/Object/Array
prototype behavior; an independent excluded request-getter witness demonstrates
why that scope matters. Either preserve that documented backend contract or
include the relevant prototype/intrinsic fingerprints in the entry guard.
Checking every descriptor on every internal call defeats the amortization and is
measured separately as the per-call negative-control candidate.

## Promotion gates and cost accounting

Before changing the compiler, require a clean measured region gain and preserved
counterexamples. After implementation, first emit the same fixture and check that
nested generic calls are actually gone in its admitted region. Compare original
partial descriptors, code.call/G getters, invalid scalar values, slot getters,
parallel Lets and long loops against the baseline. Add synthetic rejection tests
for a scalar-returning foreign call and a hidden higher-order helper.

Use one second source with the same grammar but different helper graph to prevent
a workload-name rewrite. Native provenance controls must reject user definitions
that merely reuse names. Measure compiler acquisition cost and canonical Bend
line/definition growth separately from generated-program gains. A prototype
copies the old loop into a fast variant, so emitted code growth is real; shared
private helpers should be emitted once per eligible closure rather than once
per call site.

The design should remove duplicated responsibility as it grows. A full general
match-aware worker may eventually subsume the narrow Nat worker; that is a later
consolidation decision supported by equivalent tests, not a reason to remove the
known fallback before this rule proves useful.
