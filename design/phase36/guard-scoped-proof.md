# Reuse entry proofs inside a closed private tree

## Hypothesis and scope

Phase35 ray tracing spends 47.24% of CPU sample ancestry under host/scalar/local
guards. `rowf` already checks every reachable pure residual dependency, including
`colf`, `nearest` and `nearest.t`. The latter wrappers repeat descriptor and host
protocol checks while executing that same synchronous proved region. Reusing a
covering entry proof should materially reduce this work without caching any fact
across public calls. The initial target is **private scalar-input tree regions
with independently proved residual calls**, not all compiler-generated code.

The cheapest discriminator rewrites only the frozen Phase35 ray module, grants
a scoped proof in the existing `rowf`/`colf` fast branches, and lets nested guards
reuse it only for covered names. It leaves public wrappers, input reads, exact
entry, canonical-input checks, generic dispatch and all original program bodies
intact. Original full ray tracing is the transfer benchmark; small colf/rowf calls
and adversarial public calls are the mechanism controls. A 1.3× original-program
gain would justify production integration; a null result or any event/result
mismatch rejects this attempt. The CPU-share upper bound is about 1.9×, not a
prediction.

## Proof boundary

1. The existing exact-entry token is consumed before reading inputs. Input reads
   and their getters/reentry occur before any new proof is installed.
2. Grant only after the full existing host, canonical primitive-input and
   dependency descriptor guards pass. All input types are native scalars. No
   external object, native array, function, IO or foreign input is admitted.
3. The **complete original root graph**, including every directly lowered helper,
   must pass an independent `j_pure_graph` proof. A pure residual's presence is
   insufficient: a separate direct helper could allocate a native array and run
   mutable `Array.prototype.fill`/`Number.isSafeInteger` hooks. Whole-root purity
   rejects those native arrays and calls. Every transitive callee identity is in
   the checked name set. Private frame allocation is covered by the existing
   prototype-key and array protocol guard.
4. A private null-prototype dictionary records covered dependency names. It uses
   object-literal creation, indexed string lookup/assignment and counted loops,
   not new Set/Map constructors or unguarded prototype methods.
5. `localGuard(names)` and `scalarGuard(names)` may reuse only a covering active
   dictionary. `regionHostGuard()` may reuse the active region's host proof.
   Missing names still receive the original descriptor check. No user-facing
   function receives the dictionary; it is not exported by production output.
6. The dynamic extent is a `try/finally` inside the existing admitted branch.
   Exits, exceptions and tail/build values restore the previous proof before
   returning. A delayed constructor field or bounce forced after return runs
   without inherited permission. Strict residual `callOwned` work runs within
   the extent. This is a scoped proof, not a global boolean or public-call cache.
7. A nested admitted tree with an existing proof preserves the outer dictionary
   instead of broadening it. The outer closed call graph already covers it.
   Facts never escape into a subsequent external call.

This relies on the same standard-at-import boundary as Phase35. It makes no new
claim of universal host reflection equivalence. An unexpected callback is a
correctness failure, not a reason to loosen the proof.

### Error-construction boundary found during independent review

Native Nat **constructor** evaluation can overflow on canonical scalar inputs.
`checkedNat` calls `bad`, and `bad` constructs a mutable global `Error`. That
constructor, and host error properties it consults, can execute user code before
exception unwinding reaches the region's `finally`. Thus the first success-path
prototype is insufficient even though its original colf controls passed.

The v2 proposal suspends the active proof inside `bad` before constructing the
error, then restores it only in that function's exception-unwind `finally`.
Admitted source has no catch/handler construct, so only enclosing cleanup runs
after that restoration. Reentrant Error callbacks see no proof and revalidate
their own public entry. This retains Error hook observability instead of relying
on an incomplete list of error intrinsic properties. The actual Bend fixture
`guard-overflow-v2.bend` overflows `Succ` in a pure residual graph; an Error callback mutates
a separately lowered private helper and reenters the same root. Reentry must
observe the mutation, and both normal errors and replacement-constructor throws
must leave no active proof. The original v1 proposal remains preserved.

The v1 Nat.add fixture is preserved but superseded: native Nat.add/mul are not
admitted by JPure, so they could not establish an active-proof error witness.
The complete-root requirement is the v3 production proposal. Its mixed
`guard-array-refusal.bend` control must retain the preexisting private tree while
refusing a proof extent and preserving actual fill callback/reentry observations.

## Controls and implementation sequence

The saved-output producer must assert the exact frozen module hash and AST shape,
preserve original bytes, retain producer provenance and parse every variant.
Instrumented variants count full host checks, reused checks, entry grants and
final active state. Counters are separate from clean timing artifacts.

Reuse Phase35's complete colf mutation/demand controls, then add scope-specific
checks: public calls after success and after throw, dependency replacement
between calls, raw/forged/oversaturated entry, slot mutation/reentry/throw,
dependency name not in the outer proof, inherited numeric setters, and a delayed
build forced after the dynamic extent. Assert actual nested guard reuse on a
live ray path, and zero active proof after every observation.

Only a passing mechanism proceeds to a small compiler patch: a helper wrapping
the already-built private tree body when scalar signature plus residual proof
holds, and the small runtime proof operations. Checked B1 focused tests and the
same final owner controls precede the unchanged maintained benchmark. Compare
source/output size and normal checked compilation cost, since Phase35 increased
both. No broad validation or promotion is inferred from a saved-output result.
