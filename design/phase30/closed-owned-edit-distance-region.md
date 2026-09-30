# A closed scalar-input region with local arrays and records

Prospective investigation after the scalar-tree integration. This document
authorizes no production rewrite. First demonstrate a disposable generated-code
ladder with exact state oracles and public-boundary controls, then decide whether
its benefit warrants a broader checked region grammar.

## Evidence and the boundary to use

The canonical source remains
`selfhost/tools/performance/phase28/corpus/editdist.bend`. Inspection of checked
`transfer-12/editdist/candidate.mjs` shows that scalar and tree work elsewhere
has not removed its `cell`/`cell.f1`–`cell.f4` record-and-tuple chain, `umin` and
`b2u` applications, or the `row`, `dp`, `gen` and `init` trampolines. Each cell
still performs four native Array reads and one write through generic calls.

Earlier row probes isolated the problem: after removing the five cell helper
boundaries, 47.3% of remaining generic applications originated in minimum/Bool
helpers, 26.6% in the row and 26.1% in native Array calls. A separate profile put
43.5% of samples in generic apply/force/call. These are old-artifact mechanism
observations, not current attempt12 timing shares. Per-call native guards lost
time, and preserving live row lookup per iteration reduced that optimization's
gain to about 1.11×. Repeating either guard at every cell is the wrong scope.

The existing source `pair(p: U32) -> U32` is a more useful boundary. It creates
two 256-word input arrays and two 512-word working arrays, executes the complete
dynamic program and returns a scalar checksum. No caller-supplied array, record
or callback enters this source graph. The full dependency set to inspect is:

`pair`, `prng`, `gen`, `init`, `dist`, `dist.fin`, `dp`, `dp.row`, `dp.f1`, `row`,
`cell`, `cell.f1`, `cell.f2`, `cell.f3`, `cell.f4`, `umin`, `umin.go`, `b2u`, and
the original runtime natives `Array.new`, `Array.get`, `Array.set`.

The distinction is **locality, not uniqueness**. Several records and tuple
results deliberately refer to the same mutable array handle. All aliases may
remain inside a closed region without being uniquely owned. Requiring a new
whole-program uniqueness analysis would add work that this experiment does not
need; treating a local array as immutable would be wrong.

## Keep the public boundary and original representations first

Retain the public ordinary function descriptor, callable kind, exact application
permission, one-time original slot reads and unchanged generic fallback. Admit
only immediate U32 input and the complete pristine dependency closure. Raw,
partial, hooked, over-saturated, malformed and changed-binding entries retain
their existing behavior. The complete private invocation must not call external
code between its entry guard and scalar return.

All compiled helpers need original-definition snapshots, including helpers
which are not currently scalar-region roots. The Array native descriptors are
**not currently captured by `scalarCapture`**. A prototype must capture those
known original definitions during module initialization, before external
mutation is possible, then include their code/arity/env/bound/prototype and
metadata in the same guard. Capturing a native at first use would bless a prior
replacement and is invalid. A later compiler rule must validate native source
provenance, rather than infer an intrinsic from its spelling alone.

Initially retain BigInt Nat, exact U32 wrapping, `{array: ...}` handles, native
`arrayfill`/`arrayget`/`arrayset`, Tuple arrays, `Dp` objects, projections, field
snapshots and the `build`/`force` scheduler. Native Array.new's argument is a
block exponent, not an element count. Keep its power-of-two sizing and errors.
Native reads/writes keep `Number(index) % length`, even where a particular
fixture happens to access only in-range indices. No typed array, flat record,
storage layout, arithmetic or modulo rewrite belongs in the first ladder.

The existing stable-host-intrinsics scope remains explicit. Primitive runtime
marker hooks are observable even for scalars and must cause guard rejection.
Arbitrary mutation of Array allocation/indexing intrinsics remains outside the
initial proof; local allocation by itself does not hide a prototype setter.

## Strongest ownership and scheduling objections

1. **The write is deferred.** `cell.f4` returns
   `build("Dp", [aThunk,bThunk,prevThunk,setCurThunk])`. The fourth thunk creates
   an Array.set bounce. An ordinary non-tail cell call forces that build and
   its fields before the next row step. Preserve this schedule first: direct
   private cell calls still return the same build, and the caller forces it at
   the original demand point. Eagerly writing while merely constructing a thunk
   is a different transformation and needs a separate proof.
2. **Fresh arrays still alias internally.** Array.get returns `[sameHandle,word]`;
   Array.set mutates and returns that same handle. Row completion swaps prev/cur
   identities. Do not clone handles, deduplicate equal allocations, copy on each
   access or infer that old records stop observing later writes. The zero-row
   arm swaps rows even when no cells were visited; a plain zero-iteration loop
   returning its input would be incorrect.
3. **A public row is not a closed region.** Public `row` accepts foreign Dp
   records and array handles, whose getters, proxies, malformed fields and
   callbacks remain observable. The fast row worker may be called only from a
   proved local creator inside the guarded scalar-input root. Keep public row
   and cell descriptors and their fallback behavior intact.
4. **Initializers and records can carry effects.** Restrict initial arrays to
   immediate U32 elements. Reject object/function fill values, nested arrays,
   unknown constructor fields, higher-order Array operations and escaping field
   thunks. A closure stored in a field can capture an old loop alias; use fresh
   immutable aliases on every iteration. No arbitrary callback may enter through
   a supposedly local constructor or native helper.
5. **Control order remains relevant internally.** Preserve source RHS order,
   parallel-let scope, read-before-write order, gen's PRNG update and complete
   left-to-right pair initialization. The row and dp counters differ in their
   zero behavior. Use iterative local workers for proved Nat-tail edges, with
   original unprojected zero cases; do not introduce unbounded host recursion.
6. **A root guard is valid only for a closed execution.** If any helper can
   invoke foreign code, publish a handle, perform IO or consult an uncaptured
   mutable target, a single outer guard is insufficient. Refuse that region.
   Scalar inputs are helpful evidence, not a substitute for this closure proof.
7. **A scalar checksum can hide state corruption.** Equal `pair` results alone
   cannot detect a wrong intermediate array, lost write or changed aliasing.
   Small controls must compare every element of all four arrays, input-array
   preservation, handle identities and a following operation on saved aliases.

## Disposable ablation ladder

First acquire a tiny checked Bend probe using the **unchanged** original helper
definitions. Its public inputs are scalar size/seed values; it allocates its
arrays internally and executes a single row. Use fixed sufficiently large
power-of-two buffers and bounded sizes 0,1,2,7,16,32,64. Its host observation
adapter serializes the complete four-array result only after the region exits.
Returning this record is diagnostic visibility, not permission to widen the
initial production `pair` rule to arbitrary escaping container results. The
same source is compiled by actual12 and pinned TypeScript; preserve checked
source, import closure, flags, output and complete independent expected states.

All optimized variants use the same one-entry closed dependency guard and the
same externally visible allocation/observation wrapper. Counter instrumentation
is separate. Each step builds on the preceding step, with unchanged public
descriptors and a pristine generic fallback:

| Step | Change | Deliberately retained work |
| --- | --- | --- |
| 0 | Checked original probe and original `pair` controls | Complete generic implementation |
| 1 | Private acyclic cell chain under one outer guard | Existing projection, field copy, Tuple/Dp representation, build/force, scalar helper calls and row trampoline |
| 2 | Private scalar `umin`, `umin.go`, `b2u` using existing primitive expressions and Bool semantics | Array native calls and record scheduling |
| 3 | Private BigInt row loop with fresh aliases and original zero swap | Force each cell result at the original point; arrays, projections and builds unchanged |
| 4 | Direct original native Array helper functions inside the admitted region | Same handles, tuples, mutation, modulo and errors; no per-call guard |
| 5 | Extend the proved local closure to iterative gen/init/dp and original scalar-returning `pair` | Same initialization order, record representation and complete outputs |

This cumulative ladder identifies which remaining boundary is worth its proof.
If needed, add a separately frozen scalar-helper-only control to disambiguate
interactions; do not infer multiplicative gains from unrelated historical runs.
Do not silently append projection removal or state flattening to step 4 or 5.
Those are later experiments only if retained representation work is still a
measured bottleneck.

## Independent controls before timing

Use a scalar reference recurrence independent of the generated helper chain.
At every probe point compare every array slot, final prev/cur roles, untouched
input arrays, tuple handle preservation, zero-row swap and repeated invocations
with fresh storage. Add U32 extreme seeds and explicitly model index wrapping.
Add diagnostic snapshots after selected cells/rows for the original full pair;
do not time these instrumented copies.

Compare public controls for owner and every helper/native replacement, accessor,
in-place descriptor mutation, bound/env/metadata change, own `.call` getter,
saved partial, reentrant argument getter, raw callback, constructor call and
over-saturated copied-vector effects. A changed native must be observed through
the original captured fallback, including one changed before the first call.
Run persistent primitive runtime-marker hooks. Demonstrate that direct public
row/cell calls on foreign/proxy/aliased arrays still use the original code.

Use a deliberately incorrect eager-build derivative only as a retained witness
if needed; never time an artifact that fails its declared domain. Keep the old
Phase29 private-cell and row artifacts separate because their runtime predates
the repaired exact-entry scheduling contract.

Acquire mechanism counts per row for apply/fn/partial/jump/force/project/build,
Array get/set and field snapshots. Require unchanged read/write counts and exact
complete results before interpreting application reductions. A source-proven
closed region can remove scheduling machinery; counts cannot establish speed.

Freeze the cheap complete-state row comparison before its clean screen and
confirmation. Use single original `pair` checks for transfer first, with a
prospective limited-call protocol if later full-pair timing is needed. Do not
reuse the 100-call confirmation floor on a slow original program. No numerical
gain is promised before this corrected-runtime experiment passes its gates.

## Decision for compiler architecture

A successful prototype would support a bounded extension of the existing region
proof: classify a value as scalar or **region-local container**, preserve aliases,
and admit only known pure/local constructors, projections and native mutations
whose operands have that provenance. Reuse exact public entry, definition
snapshots, closed dependency analysis, shared budgets and private loops.

This is substantially broader than adding a scalar root. It needs a locality and
non-escape proof, explicit field scheduling and native provenance. First keep the
ordinary runtime representation so those new obligations are isolated. A new
general optimizer or independent compiler IR is not justified by the current
evidence. The disposable ladder should determine whether this one extension is
worth implementing and which parts can remain generic.
