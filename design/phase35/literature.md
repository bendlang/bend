# Phase35: compiler literature applied to generated-program speed

Research date: 2026-10-01. This review uses primary papers and compiler source,
including arXiv and official GitHub repositories, as requested. It does not rank
compilers by an unspecified universal performance score. No external compiler
was installed or benchmarked, and no published speedup is a prediction for Bend.
GitHub `main`/`master` links below identify inspected development sources, not
frozen releases or a claim about the latest stable version.

The starting evidence is the [Phase34 profile and source comparison](../../implementation/phase34/opportunities.md).
Our generated raytrace, lexer, symreg and tree programs spend substantial sampled
CPU time in generic application/matching machinery. Pair/fold have already
entered direct private code, but still allocate temporary state vectors. Those
are different bottlenecks and require separate experiments.

## 1. Scalar replacement is a representation change, not a smaller box

LLVM's SROA pass separates promotable portions of an aggregate and promotes them
to scalar values, leaving unsuitable memory regions intact. Its input is LLVM
stack allocation, so applying its principle to a JavaScript heap vector requires
a separate nonescape argument. MLton's `DeepFlatten` explicitly distinguishes
flat/nonflat representations and avoids replacing reads from mutable fields with
stale known values. These are implementation precedents for selective flattening,
not licenses to scalarize arbitrary host-visible records.
[LLVM SROA source](https://github.com/llvm/llvm-project/blob/main/llvm/lib/Transforms/Scalar/SROA.cpp),
[MLton DeepFlatten source](https://github.com/MLton/mlton/blob/master/mlton/ssa/deep-flatten.fun).

**Local inference.** Phase32 replaced private shells with vectors; Phase34 now
finds the surviving `cell.f4` vector constructor receives about 65% of pair
sampled allocation. Replacing a record with a fresh array preserves most of the
allocation event. The next step should carry fields in loop variables or into
the immediately consuming continuation. Preserve the array *handles* and writes;
eliminate only the temporary container. The independent `fold.step` two-slot
result is a second instance of the same rule.

**Cheapest test.** Saved-output pair/fold ablations with complete results and
alias/write-order controls, followed by the maintained 20-second fast screen.
Inspect the exact changed functions and compare allocation separately from clean
timing. A smaller allocation estimate with unchanged/slower execution is a null
speed result. Use original edit distance as transfer confirmation.

**Semantic boundary.** Preserve all producer evaluations, even unused fields;
simultaneous loop updates require old-value temporaries before slot assignment.
Do not use a single global scratch return vector: nested calls, recursion and
reentry can overwrite it. A per-invocation destination needs its own lifetime
proof, and mutating an existing vector needs evidence that no alias observes it.

## 2. Return the values directly to their consumer

The arXiv paper *Stream Fusion, to Completeness* separates three eliminations:
stepper abstraction, stream state, and the remaining functional loop machinery.
Staging represents known state structure at code-generation time so the emitted
loop need not allocate the corresponding tuples. Its guarantees apply to the
paper's staged stream language; Bend's arbitrary functions, effects and public
runtime are outside that theorem.
[Paper, sections 5.1–5.3](https://arxiv.org/html/1612.06668),
[authors' implementation](https://github.com/strymonas/strymonas-scala).

*Compiling without Continuations* explains join points: locally scoped bindings
called only by saturated tail calls can compile as jumps, while retaining a
direct-style functional IR. Its contification conditions exclude escaping or
nontail uses. This is a control-flow abstraction, not a proposal to allocate a
JavaScript callback on every iteration.
[Authors' paper](https://simon.peytonjones.org/assets/pdfs/compiling-without-continuations.pdf).

**Local inference.** A private producer immediately destructured by a known
consumer can be emitted into that consumer's slots. Prefer one bounded plan
operation that conveys the continuation/destination through existing `Let`,
`JUnpack` and branch nodes to a collection of source-name rewrites. At the JS
level use local statements or a bounded inlining decision; a freshly allocated
callback would replace one source of churn with another.

**Cheapest test.** First one cell-result/row-consumer path, then independent fold.
Keep public return boxing unchanged. For branching loops, a small Nat countdown
whose final Boolean match chooses two saturated recursive transfers distinguishes
whether control-flow lowering works, without running full raytrace.

**Semantic boundary.** The consumer must run at the same demand point, with the
same argument order. A producer that returns deferred work cannot generally have
that work moved earlier. Scope and capture identities remain fresh per iteration;
bounded-stack behavior is part of the test, not a benefit assumed from syntax.

## 3. Worker/wrapper makes a large private interior useful

GHC separates the public calling convention from workers informed by strictness
and constructed-product-result analysis. Its implementation also documents why
blindly applying result worker/wrapper to join points is unnecessary: pushing the
consumer into the join can achieve the intended unboxed result. Its CPR analysis
records that deep unboxing can change sharing and increase space use. These
counterexamples matter as much as the favorable transformation.
[GHC worker/wrapper source](https://github.com/ghc/ghc/blob/master/compiler/GHC/Core/Opt/WorkWrap.hs),
[GHC constructed-product-result analysis](https://github.com/ghc/ghc/blob/master/compiler/GHC/Core/Opt/CprAnal.hs).

**Local inference.** Bend already has a worker/wrapper-like architecture: original
public descriptors plus a guarded, closed private first-order region. Expand
useful work inside that region instead of creating another guard on every small
leaf. This specifically respects the earlier tiny guarded F32 regressions. Source
declarations and private helper references must continue to match the identities
captured by the entry guard; names alone are not proof of a native operation.

Three concrete admission limits are visible at the starting compiler:

1. `j_region_scalar` accepts only `U32`, `Bool`, and `Nat`; region literals also
   exclude `F32`. The generic primitive emitter already supports rounded F32
   operations. Adding arithmetic emission alone therefore misses the blocker.
2. `j_region_prefix_on` accepts a Boolean matcher only when `keep=False`.
   Nested Nat successor planning uses `keep=True`, and the Boolean-match planner
   currently passes an empty recursive tail target to its arms. A residual match
   in a recursive transfer needs a deliberate branch/loop plan.
3. `j_region_local_ctor_head` admits single-constructor private data; recursive
   sum types and strings are outside this proof. F32 admission will not by itself
   make lexer/symreg/tree programs direct.

Sources: [region.bend](../../selfhost/src/back/js/region.bend),
[local.bend](../../selfhost/src/back/js/local.bend),
[worker.bend](../../selfhost/src/back/js/worker.bend),
[primitive.bend](../../selfhost/src/back/js/primitive.bend).

**Cheapest tests.** Separate F32 admission, branch-aware saturated tail transfer,
and finite Nat selector specialization. Use small complete nearest-hit/miss and
selector cases before raytrace. Preserve exact `Math.fround` placement, NaN,
infinity, signed zero and large Nat behavior. Check public partial applications,
descriptor mutation, callback timing and generic fallback independently.

## 4. Track just enough shape information to remove repeated decoding

Flambda2's value-approximation design tracks number kinds, block tags/fields,
function identities, projections and aliases. It describes a bounded
single-traversal simplification strategy and its tradeoffs for loop information.
Known relationships between a value and its fields let later code avoid repeated
decoding. Its must-alias relation does not prove that two arbitrary values cannot
alias.
[Flambda2 design in the compiler repository](https://github.com/oxcaml/oxcaml/blob/main/middle_end/flambda2/docs/types.md).

**Local inference.** Our private plan already carries positional slots, complete
field telescopes and captured helper identities. Add a small per-binding fact
only when it discharges a measured blocker: known constructor, field slots,
fully demanded result, saturated callee or private destination. There is no
current evidence that implementing Flambda2's complete abstract domain would
improve our developer loop. Bounds on plan nodes, helper count and recursive
analysis must remain explicit.

**Cheapest test.** Record the first rejection reason for an affected helper graph,
then show one new fact admits that graph while rejecting adversarial public input.
Count compiler visits/plan size and checked acquisition time as well as output
execution. A broad region that costs disproportionate compile time can lose the
iteration-speed objective even if one generated benchmark improves.

## 5. Ownership enables reuse, but removing an allocation comes first

*Counting Immutable Beans* studies reference counting for an eager pure language,
including borrowed references and reuse of nonshared values. Exact sharing
information enables destructive updates while preserving the functional view.
The paper's runtime mechanism is not present in JavaScript's tracing collector;
it cannot be copied by assuming a Bend value has one JS reference.
[Ullrich and de Moura, arXiv:1908.05647](https://arxiv.org/abs/1908.05647).

**Local inference.** Existing closed regions already have stronger knowledge than
public callbacks about where arrays and record shells originate. Use that proof
for lifetime-limited scratch storage only after checking all aliases. The easiest
pair/fold improvement is to avoid the temporary result altogether; adding a new
runtime reference counter would be much larger and presently unsupported work.
For tree algorithms, reusable nodes remain a later separate experiment after
direct traversal, since mixing representation, traversal and reuse hides causes.

## 6. Keep compile speed and output speed separate

The [Phase31 Zig review](../phase31/zig-lessons.md) already established compact
representations, explicit dependency boundaries and the value of a quick debug
backend. Zig's faster compilation figures did not prove faster generated code;
some explicitly traded code quality for compilation latency. This phase should
not repackage those numbers as a runtime optimization result.

The useful transfer here is procedural: cheap saved-output counterexamples,
small checked acquisitions, then bounded clean timing and only justified wider
gates. Preserve every failed or regressing attempt. Do not add a heavyweight new
optimizer before a small output ablation establishes that its transformation
matters. Inspect the TypeScript compiler's existing loop/table lowering as a
same-language implementation reference, with our stronger public-ABI controls.

## Decision order and promotion evidence

| Order | Transformation family | First discriminator | Required semantic focus |
|---|---|---|---|
| 1 | Eliminate private loop-state containers | Pair + fold, fast set | Full state, array aliases, writes, initial zero and swaps |
| 2 | Finite Nat-to-F32 selectors | Every arm/default, then small complete ray | Rounded constants, large Nat, captured helper identity |
| 3 | F32 + branch-aware direct regions | Recursive nearest hit/miss; small column traversal | Rounding, complete records, tail depth, one entry guard |
| 4 | Known private sum/string traversal | Small expression tree or lexer input | Tags/fields, Unicode, demand order, fallback and stack |
| 5 | Reuse of surviving private objects | Two alias-sensitive complete fixtures | Nonescape/liveness, reentry, mutation observations |

This ordering is a cost/risk recommendation, not a promised speed ranking. The
parent campaign freezes each concrete hypothesis and time/resource ceiling before
execution. The maintained 20/60-second sets are screens; a surviving candidate
gets longer same-run confirmation and affected original programs. Instrumented
profiles establish mechanisms, while uninstrumented matched timing decides speed.
Faster-than-TypeScript is an admissible outcome to measure, not an acceptance
assumption. Correctness, compiler overhead, memory and source complexity remain
separate reported axes.


## Concrete Phase35 implementation hypotheses

The literature now maps to three separately reviewable code changes, rather
than to a general request for a more aggressive optimizer:

1. Bounded private helper inlining exposes state producers to their consumers.
   Final-vector destination slots can then remove transient loop-state arrays
   without introducing a shared mutable result buffer. This is the local
   scalar-replacement/worker-wrapper experiment.
2. A finite complete Nat matcher can become a decision chain inside an already
   guarded region. It retains original leaf expressions and dependencies; it
   does not precompute rounded constants or change public selector callbacks.
3. A final Boolean matcher can become a statement branch whose saturated
   recursive leaves transfer to one local loop. The outer public Nat and
   leading-lambda stages must remain, because staged public application is part
   of this runtime's observable behavior. This is the useful join-point analogy;
   it does not require converting the whole compiler to CPS.

The saved-output ray prototype isolates item 3 while retaining generic helpers.
An admission-counter derivative is separate from timing: a valid output checksum
alone cannot establish that the intended region ever ran. Host intrinsic checks
must precede floating canonical-input validation, and type aliases must be
normalized when deciding whether those checks are needed. These are local proof
obligations established by code review, not claims supplied by the papers. Root's
checked acquisitions and matched timing determine whether any hypothesis wins.

The private-sum experiment adds a fourth concrete application: leave the tagged
data representation in place, but replace repeated generic elimination and
curried selfcalls with a typed saturated structural consumer. A generic producer
can remain inside the enclosing region only after an independent whole-graph
purity proof. The compiler subset uses an explicit postorder stack, complete
constructor coverage and unchanged scalar parameters. This is a narrow
worker/wrapper and known-data-consumer transformation, not a new general fusion
framework. Root's saved-output ablation found that a private dataset loop alone
did not matter, while replacing eval/size traversal did; the detailed measured
scope and the initial inactive-guard failure are in
[the sum report](../../implementation/phase35/sum-review.md). No literature result
supplies the local speedup or discharges the public JavaScript ABI obligations.
