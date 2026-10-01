# Independent review: producer lowering and scoped guards

Review is static inspection by `phase36_cost`; execution remains root-owned.
This file records findings, not promotion or completed correctness gates.

## Producer patch

Read `producer-source.patch`, the reused `tree.bend`/`region.bend` helpers,
`JPure`, and the producer fixture/control sources. No transformation blocker was
found in the proposed binary subset.

The normalization joins exactly two single sequential lets only when the entire
right RHS has no occurrence of the left binder. Existing fresh frontend IDs make
that test meaningful. `j_tree_shape` requires exactly two live binds with exact
self calls on the captured predecessor; `j_tree_distinct` separates their names
from parent binders. The independent purity proof reads original source, before
normalization, rather than inferring purity from a partially successful lowering.
The emitted traversal stages the left arguments before descent, stages right
arguments only after the left returns, and restores saved parent aliases before
the combiner. Reusing the original `{$,a}` values and original generic node/leaf
calls preserves the intended sharing and demand boundary.

The initial fixture controls compare 32-bit hashes and static marker presence.
Those checks do not establish actual private entry, complete tree contents or
the repeated-child identity claimed by `p.share`. The new independent
[producer-reviewed-controls.mjs](../../selfhost/tools/performance/phase36/producer-reviewed-controls.mjs)
therefore captures actual emitted private helpers in a diagnostic copy, counts
their entries, compares full trees against baseline and TypeScript plus an
independent opcode model, checks object identity for shared children, and includes
depth twelve (8,191 logical nodes). It also checks public fast entries and live
dependency replacement/getter refusal with paired observations. These controls
are written but not executed by this reviewer. The existing owner's controls
remain unchanged.

## Guard v2: admission blocker

`guard-production-v2.patch` grants a proof when the public signature has native
scalar inputs and the helper list contains a `JResidual`. This establishes an
independent purity proof for each residual graph, **not for the entire root**.
Direct region lowering separately admits `Array.new`, `Array.get` and `Array.set`.
Even a scalar-input root can allocate a private array inside a helper.

The concrete callback path is `Array.new` → `arrayfill` →
`Number.isSafeInteger(size)` and `Array(size).fill(v)`. The current host protocol
snapshot does not include `Number.isSafeInteger` or `Array.prototype.fill`.
A replaced hook can mutate or reenter the module. Consequently, a tree root
combining direct array work with one pure residual does not justify bypassing
guards across its dynamic extent. Passing only the present ray controls would
not fix this general admission hole. This review does not claim a newly executed
counterexample; the guard owner is preparing an actual scalar-root/array refusal
fixture.

The requested correction is a complete independent `j_pure_graph` of the root
before granting the scoped proof. That proof rejects native arrays and validates
all reachable bodies; its fuel and graph cap must remain explicit. The desired
ray closures have 27 names including `colf` and 28 including `rowf`, below the
32-definition cap, but actual compiler admission still needs a witness. The
guard owner accepted this blocker and is producing v3 plus refusal controls.

## Error callbacks

Temporarily clearing the active proof before `Error(m)` in `bad`, then restoring
it in `finally`, protects reentry from a replaced Error constructor/getter. It
retains the original Error lookup and throw and does not swallow the exception.
Restoring the previous proof is safe only because the admitted graph contains no
catch-and-resume path; after `bad` throws, only internal unwind/finally work may
precede the outer region's cleanup. Complete root purity is therefore part of
this argument too. Tests should witness actual reentry and verify proof absence
both inside the hook and after the outer throw. Diagnostic fault injection is
cleanup evidence, not proof that a source fixture reaches this boundary.

For a correctly admitted graph, the null-prototype coverage dictionary avoids
new Set/Map/prototype dependencies. Proof installation follows the existing
input reads and complete guards. Nested opens preserve the previous authority,
and the enclosing `try/finally` restores it before delayed build/bounce results
are forced. These positive observations do not supersede the v2 blocker.

## Guard v3 follow-up

Read `guard-production-v3.patch`, `guard-array-refusal.bend` and
`guard-array-controls.mjs`. The new full-root `j_pure_graph` check, bounded to
32 definitions / 32,768 fuel, resolves the static admission blocker. The added
fixture deliberately combines an existing private scalar tree, an opaque pure
residual and direct private arrays. Its controls require the existing tree to
remain, the scoped proof to be absent, and live fill/isSafeInteger callbacks to
observe no proof during mutation, reentry and throw.

No further source blocker was found in v3. Root must still demonstrate actual
ray proof admission, actual array refusal and overflow/reentry behavior in the
checked compiler. This follow-up records static approval of the correction, not
completed execution or permission to infer full correctness from the prototype.
