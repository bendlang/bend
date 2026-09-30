# Remaining generated-code costs after Phase29

This is a static inspection of attempt04's checked emissions and the identical
Phase28 inputs compiled by pinned upstream. No profiling, instrumentation,
program execution or additional compiler change was performed for this note.
The timing report measures performance; this note identifies mechanisms still
visible in the generated code. It does not assign fractions of runtime to them.

## Next direction

The most promising broad next step is **private saturated workers that consume
the complete checked parameter and match telescope**, retaining the existing
public descriptors. Phase29 proves a narrow form for scalar Nat countdowns.
The remaining examples require records, additional matched parameters, different
tail-recursion shapes, or ordinary non-tail calls. Making more arithmetic
operators intrinsic will not remove those boundaries.

Start with edit distance's `cell`/`cell.f1`–`cell.f4` chain: ordinary parameters
followed by one-constructor record/tuple matches. This is a smaller admission
problem than arbitrary pattern trees, and it occurs in every dynamic-programming
cell. A private entry can accept complete arguments, perform the existing
projection, and call another proven private entry without rebuilding the public
partial-function chain. The public entry must still preserve intermediate
application behavior. Keep the existing `project`, `build` and array helpers
initially; reducing their costs is a separate experiment.

Then test transfer to a record-carrying countdown such as `dp`, the final Boolean
parameter of ray tracing's `nearest`, and the string/tuple loop in `lex`.
Supporting these requires a small structured emitter with explicit branches and
tail transfers, rather than accumulating workload-specific rewrites. This is an
architectural extension to the current worker; the inspection does not establish
that it will close the remaining gap or specify a justified speedup factor.

## Concrete observations

The following paths are relative to the repository root. Each pair's checked
source, upstream revision and output identities are retained in
`selfhost/build/phase29/transfer-04/report.json` and its acquisition receipts.
The Phase29 evidence capsule preserves the candidate bytes; the upstream bytes
are also preserved in the Phase28 capsule.

| Workload | Attempt04 emission | Pinned upstream emission |
| --- | --- | --- |
| Edit distance | `selfhost/build/phase29/transfer-04/editdist/candidate.mjs` | `selfhost/build/phase28/runtime-01/editdist/upstream.mjs` |
| Lexer | `selfhost/build/phase29/transfer-04/lexer/candidate.mjs` | `selfhost/build/phase28/runtime-01/lexer/upstream.mjs` |
| Ray tracing | `selfhost/build/phase29/transfer-04/raytrace/candidate.mjs` | `selfhost/build/phase28/runtime-03-raytrace/raytrace/upstream.mjs` |

None of these three candidate modules contains a `/* private Nat loop */` site.
That is expected conservative fallback, not evidence that the production rule
failed to fire on its supported shape. Their arithmetic does contain
`/* primitive */` expressions. For example, lexer `prng` has six primitive sites
and no generic `call` left in its definition, while the main traversal still uses
generic matchers and calls.

### Edit distance: the cell pipeline still creates function boundaries

Candidate lines631–635 define `cell.f4`, `cell.f3`, `cell.f2`, `cell.f1` and `cell`.
Each begins with a leading `fn(n, ...)` and returns a `matcher1` for the final
Tuple or Dp parameter. The tuple matcher then obtains another field-consuming
`fn`. A typical transition remains:

```js
jump(call(get(G,"cell.f4"),[j,cost,diag,up,a,b,prev]),
     [call(get(G,"Array.get"),[null,cur,j])])
```

This excerpt renames local binder IDs for readability. Its two-stage invocation
is intentional: the old leading arguments are applied before the last argument
is evaluated. Eliminating it needs proof that the intervening initialization is
pure, or a private path entered only after that boundary has been respected.

Upstream lines233–265 use ordinary functions taking all arguments, read pair
fields directly and invoke the next function directly. Its array accesses and
updates are inline JavaScript indexing; the candidate still calls `Array.get`
and `Array.set` through runtime descriptors. Candidate `cell.f4` also returns a
scheduled `build("Dp", [...field thunks...])`, whereas upstream returns a record.
These are additional costs; this inspection does not quantify them.

Candidate `row` and `dp` (lines636 and639) retain respectively three and two
nested curried `call` stages before their final recursive `jump`. Their carried
`Dp` state and result are outside Phase29's scalar-only worker contract. `row`'s
Zero arm additionally matches that record instead of containing a complete
explicit residual lambda prefix. Upstream `row` and `dp` (lines268–325) are local
slot loops. Relaxing only the scalar type check would therefore be insufficient.

### Lexer: a native string still passes through generic elimination

Candidate `lex` (line653) is a chain of SNil/SCon, Chr and Tuple matchers.
Its recursive transition remains `jump(call(get(G,"lex"),[tail]),[nextState])`.
The `step` wrapper at line651 applies `step.at` in four stages because `step.at`
begins with matching rather than a complete leading lambda prefix.

Candidate `step.at` (line650) contains 15 matcher sites and 24 scheduled `build`
sites across its branches. These are **static syntactic counts**, not the number
executed for one character. Upstream `step.at` (lines343–379) uses direct tag
conditionals and record construction. Upstream `lex` (lines397–417) checks the
native string, extracts its codepoint/tail and tuple fields, and updates local
slots in a loop.

Both compilers already use native JavaScript strings. The visible distinction
is the surrounding projection, descriptor and scheduling machinery. String
representation replacement is not supported as the primary next step by this
inspection.

### Ray tracing: recursive transfers still carry large partial chains

Candidate `nearest` and `nearest.t` (lines633 and641) match Nat first, accept a
sequence of scalar parameters and then return a matcher for the last Boolean
argument. Each recursive branch of `nearest` invokes its twelve arguments
through twelve nested `call` sites; `nearest.t` similarly has ten stages.
Upstream's corresponding functions (lines276–333 and378–429) are direct loops
with Boolean branches and local-slot updates.

Phase29 deliberately excludes the candidate shapes: a residual Boolean matcher
interrupts the explicit lambda prefix; `nearest` also returns a Hit record.
This explains why further generalization needs match-aware entry analysis and
cannot be achieved merely by recognizing another Nat helper name.

The candidate `colf` and `rowf` (lines647–648) retain six-stage calls on both
recursive branches. Upstream (lines674–697) uses direct six-argument calls.
These functions are binary non-tail recursion followed by addition, so the
countdown self-tail rule cannot cover them. The unchanged small raytrace input
still performs 1,048,576 column probes; this makes the repeated call structure a
plausible significant cost, but its share has not been measured here.

## Cheap discriminating experiment and safeguards

Freeze a small edit-distance row fixture with several sizes, seeds and complete
result arrays. Reuse emitted baseline and upstream artifacts. First alter only
private entry/transfer plumbing in a disposable generated-code experiment;
leave arithmetic, arrays, projection and construction unchanged. Verify complete
outputs and ownership effects, then use the maintained short comparison loop.
Count partial descriptors, argument-array copies and forced jumps separately
from clean timings. If those counts fall without a material speedup, investigate
array access and construction before building a general worker emitter.

A successful experiment should be implemented as one general checked rule,
then confirmed on the original row and at least one second workload. The
following boundaries remain necessary:

- Keep public arities, partial descriptors, erased slots and intermediate
  errors/effects. Increasing public arity or evaluating every later argument
  before an earlier matcher is not an equivalent transformation.
- Preserve source argument order and parallel-binding scope. Tail updates need
  temporaries; captured values need fresh immutable aliases on each iteration.
- Treat native identity and result representation separately from spelling.
  Record/tuple projection must retain trusted foreign getter and slice behavior
  until a stronger provenance restriction is established.
- Preserve array ownership/mutation order and constructor field forcing.
  A direct constructor path must not silently replace bounded deep construction
  with host recursion.
- Preserve bounded tail-stack behavior. Non-tail and mutual recursion need their
  own explicit admission or fallback; the Nat prototype does not prove them.
- Keep recognizer work bounded with explicit `kc` admission fences. Bend's eager
  Boolean conjunction is not a guard against recursive work on rejected shapes.

BigInt Nat values, array helper dispatch, constructor scheduling and general
matcher projection remain distinct possible costs. The next experiment should
keep those fixed so a gain can be attributed to the changed call structure.
