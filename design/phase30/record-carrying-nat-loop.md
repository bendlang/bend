# Prospective record-carrying Nat loop

Frozen before deriving or executing this experiment. This is a disposable
generated-JavaScript ablation, not a new compiler or permission to relax the
current worker recognizer. The parent owns `worker.bend`.

## Question and admission

The existing private Nat worker requires primitive scalar types for every
carried argument and the result. That prevents `gen` and `init` carrying
`Array<U32>` and `dp` carrying `Dp`, although their successor and zero branches
have the same explicit live parameter telescopes as admitted scalar loops.
Array or record values in mutable worker slots need not be opened, copied,
forced, or represented differently. Fresh immutable source aliases on every
iteration preserve captured values.

`row` has an additional obstacle: its zero arm has two explicit lambdas and
then a `Dp` matcher; the successor has four explicit lambdas. The existing
zero-lambda-count equality rejects it independently of the scalar restriction.
Supporting residual zero matching is a separate extension. It must invoke the
original residual expression with the original remaining arguments rather than
silently return the matcher or emit all arguments through `j_lambda_code`.

A prospective general compiler admission should recognize closed normalized
primitive scalars, exact native `Array<T>` with a bounded recursively admitted
closed element type, and user algebraic record types whose identity and closed
arguments are known. It must reject unresolved variables, dependent result
families, function/IO types, erased arguments, lifted telescopes, unknown type
constructors, and recursive type inspection exceeding a fixed bound. This is a
conservative admission proposal, not evidence that every such type is safe.
Representation traversal is unnecessary: the loop carries opaque values.
Repeatedly unfolding user datatype fields would add work without establishing
the demand property that actually matters.

The real semantic proof concerns the *parameter telescope*. Each removed
recursive prefix must consist only of the native Nat match and explicit live,
unlifted lambdas. An intermediate match or helper evaluation may demand state
before a later argument expression and must remain. The original zero arm must
run at its original final demand point. Result type alone does not imply purity.
Existing scalar region planning must remain scalar-only when this admission
widens; unknown input kinds currently produce a false region input guard.

## Scheduling hazard and initial artifact

An ordinary public successor callback computes one iteration and returns a
bounce. On oversaturation, generic `apply` reads the copied argument vector's
length after that callback and only then forces the bounce. Executing every
iteration immediately inside the callback can move later cell effects before
that observable read. This applies even to a scalar loop if a called helper is
replaced by an effectful descriptor. Scalar types are not a general effect
guarantee.

The first ablation therefore keeps the original public matchers, successor
partial descriptor, first recursive prefix, and first cell computation. For a
nonterminal recursive step it returns a bounce to a private worker. The worker
uses a local loop only after the outer public callback has returned. All private
worker argument arrays are ordinary fresh arrays under the standard host
intrinsic assumption. The terminal step evaluates the original zero continuation
before the final cell expression and returns its original-style bounce, keeping
zero record projection and construction deferred. Cold public overapplication
therefore retains the original scheduling boundary.

The worker keeps `cell`, every `Array.get/set`, all `project`, all `build`, and
all four array values unchanged. It evaluates next values once in source order,
uses fresh lexical aliases, and swaps rows only through the original zero arm.
It does not hoist or copy record fields. The initial artifact assumes the
compiled recursive `G.row` descriptor and its internals remain unchanged.
Replacement/in-place mutation is an explicit counterexample test, not a hidden
production contract. Mutations of the still-called `G.cell` remain observable.
A production path requires either preserving recursive lookup and a safe guard
at the corresponding demand point or a separately justified immutable binding
contract; no such contract is granted here.

## Acquisition and falsification

Inputs are immutable `prototype-02/unchanged.mjs`, `private.mjs`, and
`upstream.mjs`, with their existing 28 complete-state independent Python oracle
points: n=0,1,2,7,16,32,64 and seed=0,1,17,4294967295. Preserve baseline and
private-cell variants separately; derive `row-loop` from unchanged and
`private-row-loop` from private02. This isolates recursive row plumbing and
reveals whether gains combine with the already measured cell improvement.

Acquire under CPU6, Node24.18.0, 4MiB stack, 1GiB heap with sanitized environment.
Archive exact tools, input identities, rewrites, stdout, stderr and exit status.
Check all 140 complete-state observations, then ordered controls for zero/one/
many iterations, public partials, full-state identity/aliasing, foreign record
field getters and custom copied-vector lengths, throwing cell calls, cell
replacement during execution, returned raw bounce deferral, and overapplication.
Retain a deliberately eager-loop scheduling counterexample and a live recursive
G replacement counterexample. Request independent review before timing.

Descriptive counters use separate instrumented artifacts and count generic
applications, descriptors, copied slots, jumps, record projections/builds and
array operations. They are mechanism evidence, not time shares or total heap
allocation. No comparative timing occurs before the parent's exclusive grant.

Freeze the existing paired screen and longer-warm confirmation protocols on the
five unchanged/row-loop/private/private-row-loop/TypeScript modules, row32seed17.
Confirm if semantic checks pass; retain losses and warmup drift. Preserve wrapper
allocation and complete-state serialization in every variant. A speedup would
justify a general typed prototype or proposed patch, not adoption by itself.
