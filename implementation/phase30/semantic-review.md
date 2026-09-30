# Phase30 independent semantic review

Reviewer: `phase30_review`, separate from prototype and production owners.
The [prospective plan](semantic-plan.md) names admission and semantic boundaries.
This report is incrementally updated; failed executions retain their own files.

## Initial runtime controls

`selfhost/build/phase30/review-contract-01/report.json` passes 17 runtime-level
observations and three executable counterexamples. The exact consumed tool and
append-only diagnostic runtime are retained in that directory. These checks
exercise the existing runtime and a manually specified matcher shortcut; they
do not establish any compiler candidate's correctness.

The counterexamples demonstrate that eager saturation can demand a later
argument before an earlier match throws, moving field copying can observe a
later mutation, and falling back by re-projecting a record repeats a getter.
The positive cases include named getters, array proxies, sparse/frozen fields,
custom and throwing slice methods, changed lengths and partial/overapplication.

## First edit-row prototype: static review

The first prototype adds a fixed private cell/f1/f2/f3/f4 chain and changes one
fully entered row call. Original public cell descriptors stay intact. For plain
compiler-created field vectors, the explicit leading lambdas only build a
matcher; removing those stages preserves argument demand. The direct helper
chain has a fixed depth and therefore does not introduce a recursive stack
growth path. Array operations, arithmetic, construction and final forcing stay
outside the intended mechanism change.

This initial causal prototype has an explicit immutable compiled-function
scope. A private direct call bypasses replacement of the corresponding public
`G` entry. An identity-guarded follow-up is being prepared; in-place mutation of
the same descriptor needs additional data-descriptor validation or a narrower
contract. Ordinary effects and delayed references must remain live.

Review identified an additional exceptional-vector issue before timing:
copying `apply`'s branch conditions verbatim is insufficient when the copied
body calls its next private stage eagerly. In an oversaturated arm, the old
body returns a jump, then `apply` reads the copied vector's length again before
forcing the next match. Calling the private next stage immediately moves its
projection/effects before that length read. A foreign slice result with an
observable length getter distinguishes them. The recommended repair is to
retain the original arm body for cold zero/partial/oversaturated paths, using
the already projected/copied fields. The normal exact-size path may retain the
optimized body. This is a scope qualification for the first prototype, not
evidence that the common-path timing is invalid.

## Separate fresh-array ownership mechanism

A compiler-emitted nontail call creates a fresh administrative argument array.
If no bound arguments exist, runtime `apply` immediately copies that array.
The fresh vector has no other owner before the call, so an explicit internal
owned-call entry can omit that copy while retaining public `call`, matcher
vectors, `bound.concat`, and oversaturation's prefix/suffix copies.

Tail messages require a separate argument. A raw generated descriptor's code
can return an inspectable bounce whose array a host retains before forcing.
Consuming that vector in place changes aliasing if the invoked host function
mutates its argument array. The conservative first ablation therefore keeps
tail-jump copying. Standard JavaScript intrinsic behavior is assumed; removing
an administrative copy is observable under monkeypatching Array.prototype.slice.
No ownership optimization has been validated by this initial review alone.

## Executed edit-row boundary review

The independent `review-private-prototype.mjs` reproduced the predicted cold
ordering failure in prototype01. The first 18 boundary observations passed;
the changing copied-length case differed. The exact baseline and candidate
event streams are retained in
`selfhost/build/phase30/review-prototype-counterexample-01/report.json`.
The earlier first run and the diagnostic-enhanced rerun are separate records.

Prototype02 retains a separate original arm-body helper for every cold path.
Both its private and identity-guarded variants pass 33 ordered/public-descriptor
observations in `review-prototype-02` and `review-prototype-guard-02`. Coverage
includes named and `a` getters, proxy/sparse/frozen vectors, custom/throwing slice,
short/exact/long and changing copied lengths, four Array.get failures, b2u/umin
and Array.set failures, tuple getters, and byte-identical public descriptor
code. The unguarded version records a live G.cell replacement difference;
the guarded version produces the same result in that case.

The separate `review-global-guards.mjs` passes 20 replacement/order observations
on guarded02: ordinary replacement, a zero-arity initializer, a G entry getter,
and installing the next callee during Array.get, across all five helpers.
It also retains 12 in-place mutation comparisons. Ten differ: code replacement,
code getter, bound-vector mutation, own typeName and own io on cell and cell.f2.
Changing arity to zero matches because `get` forces it before the identity
guard. These negative observations define the guarded prototype's remaining
scope; they are not counted as passing production conformance. Raw receipt:
`selfhost/build/phase30/review-global-guard-02/report.json`.

The initial review harness had one missing parenthesis and failed parsing
before importing either generated module. Its exact source and diagnostic are
retained as `review-harness-syntax-01`; this was a reviewer-tool failure, not a
compiler observation.

## General worker guard placement

A guard must run after lookup and evaluation of the leading arguments, but
before evaluation of the final matched argument. Leading-argument effects can
mutate the descriptor before the original prefix application; final-argument
effects run after the original prefix has already produced its matcher. A
single guard placed after every argument is evaluated loses that distinction.

Use staged bindings to preserve this order. A validated guard can enter the
private worker after evaluating the last argument; its fallback must perform
the original prefix application before that final argument. Cached private
function descriptors may carry tail transfers through the existing trampoline;
direct JavaScript tail recursion must not be introduced without a separate
cycle/loop proof. General tail-loop lowering remains a separate hypothesis.

The general matcher fast path can share a cold helper, provided that helper
starts after the already performed failed equality-length test. Repeating that
test is observable on foreign copied vectors. Cold paths must use the original
body, not an optimized body whose tail transfers execute earlier. These
constraints let the first rule stay small: live explicit leading lambdas, one
selected constructor, an exact live field-lambda telescope, bounded arities,
and conservative refusal of lifted, erased and eta-short shapes.

## Exact-field arm reuse

The separate exact-arm prototype reuses existing `matcher1p` with field count
equal to lambda arity. Its runtime already implements the exact-saturation
branch with `c.call(null, b)` and preserves cold mismatch/partial/oversaturation
paths. Only literal, unlifted, live field telescopes qualify; count remains
positive. Constructing the literal code function earlier is observation-free.
Tail bodies retain their original jumps, avoiding the private prototype's cold
continuation-order issue.

`review-exact-arm-01/report.json` passes the same 33 ordered/public-shape controls
through the actual public call path against the unchanged module. It also
preserves ordinary G.cell replacement. The control tool's `public` mode records
different generated code hashes as expected; function source text is not treated
as a semantic ABI guarantee. This disposable five-arm prototype is not yet a
compiler admission result.

## Checked owned-call implementation

The production diff changes only two emitted nontail fresh-array call strings,
adds the explicit owned flag to apply, and adds an internal callOwned helper.
It leaves public calls, matcher vectors, tail messages, bound concatenation and
oversaturation slices unchanged. The independently reviewed implementation
matches the intended ownership argument.

`review-owned-emitter-01/report.json` passes 22 observations against Phase29.
Both actual `j_library` APIs emit the same synthetic core book using their own
frozen attempt runtimes: Phase29 attempt04 and Phase30 checked attempt01.
The tool verifies five changed emission sites (one-argument, batched, partial,
erased and ordered calls) and an unchanged tail jump. Executions cover receiver
vector mutation, partial-bound ownership, erasure, left/right/body exception
ordering, changed arities/overapplication, metadata getters, environments,
null/type application, public-copy isolation and reusable tail messages.
Synthetic books isolate backend/runtime behavior; frontend admission remains
the independently reported checked build/focused gate. No timing follows from
these controls.

## Closed scalar region prototype

The independent `review-region-inputs.mjs` passes 37 observations against the
first guarded region prototype in `inspection-region-01`. Thirty-six cover
every carried scalar position with boxed Number, Symbol.toPrimitive, coercion
that mutates b2u.code, throwing coercion, an ordinary Proxy and a proxy-wrapped
Number. The remaining observation checks 50,000 iterations and a saved partial
descriptor's bound-vector ownership. Raw receipt:
`selfhost/build/phase30/review-region-inputs-01/report.json`.

A separate retained witness installs a Boolean.prototype.request getter. The
old output reads it during native Boolean matching; direct private Boolean
code does not. Values agree but effect traces differ. This witness is explicitly
outside the prospectively stated standard-prototype assumption; it is not
counted as passing general host interoperation. The ordinary boxed/coercible
input controls are within the fallback contract and must match exactly.

No blocker was found for this prototype under its documented native-scalar,
closed-helper and standard-intrinsic/prototype scope. It remains a generated-JS
experiment. A compiler rule still needs conservative admission and direct-path
coverage beyond this one observed program.

## Non-tail native Array.get prototype

Independent review of the guarded array prototype found no blocker within its
frozen standard-intrinsic, non-tail-only scope. The guard inspects known original
ordinary descriptors; replacement targets decline by identity before any
replacement metadata is read. The original G lookup still precedes argument
evaluation, and the already captured target remains authoritative if an argument
replaces its G binding. Native arrayget and the surrounding force are unchanged.

`review-native-array-01/report.json` passes 28 additional observations across
the unchanged and corrected private baselines. These cover metadata accessors
that mutate other metadata, own code.call getters, replacing the G entry while
evaluating an argument, changing code before entry, backing getters and proxies
that change future calls, reentrant backing/index callbacks, coercion mutations,
and coercion exceptions. Each scenario also makes a subsequent call to expose
the changed binding, and checks complete effect/error order. Consumed tool and
module hashes are retained. These are generated-JavaScript controls, not a
compiler admission or timing result.

The earlier proposed direct tail path remains excluded. Computing array access
immediately would move effects before the caller's post-body copied-vector
length checks or before a retained bounce is forced. The amendment and retained
tail witness document that distinction; passing non-tail controls does not
justify restoring the tail transformation.
