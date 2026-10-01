# Independent review by the producer owner

This review reads source and control producers only; root owns all executions.

## Inliner identity preflight

`cost-preflight.patch` scans the original helper list for the exact definition
conditions required by the sole `j_region_inline_children` rewriting rule:
non-native Def, Ann body, private-vector result. If none exists, no recursive
reconstruction can introduce an eligible target, because target lookup uses the
unchanged original helper list. Complete reconstruction is structural identity;
fuel failure also retains the original definition. The metadata identity
assertion and deep fuel-failure case in `cost-inline-controls.mjs` check both.
The vector call and vector-order cases keep the original analysis path. No
correctness blocker found. A synthetic new JProducer no-rewrite case was requested
from the cost owner for additive integration coverage.

The preflight examines unused Ann definitions too. This can add a bounded amount
of type inspection where the original pass would not query that particular
helper. Checked region helper types are already admitted; this is a cost concern,
not a reason to claim an unmeasured compiler-throughput win. Normal checked
request timing remains required.

## Scoped guard reuse, version2

The original proposal omitted mutable global `Error`: `bad` invokes it after a
Nat overflow, allowing host mutation/reentry before the outer finally. The
version2 patch suspends the current proof while constructing and throwing an
error, then restores it only during exception unwinding. Reentry therefore
receives complete fresh guards. This avoids expanding the normal host guard
scope while preserving the original Error callback behavior.

The safety invariant is that **no admitted computation catches a bad error and
resumes under the restored proof**. Current JPure permits only F32.to_u32 as a
residual native; Number.read's catch, IO result handlers and foreign code are
excluded. Source pure expressions have no exception handlers. An expansion of
native admission must recheck this invariant. The owner was notified explicitly.

Direct Error throws in private fold invariant arms are unreachable for correctly
proved locally constructed sums, so complete shape/admission/refusal controls
remain necessary. Proof cleanup tests cover throws, bounce/build returns and
coverage mismatch; the actual overflow/Error-callback/mutation/reentry fixture
must also pass before promotion. No additional blocker found in version2's
current proof boundary. This is scoped review, not universal JS host equivalence.

## Counter-free producer timings

`producer-clean.py` was run as a read/write-only derivation, producing
`selfhost/build/phase36/producer-clean01`. Frozen derived01 stays unchanged. The
only removed bytes are counter declarations, increments and entry-count exports;
recorded spans replay exactly to each output. All input/output hashes are retained.
The comparison config uses baseline/generator/producer/TS, original bench(6,42)
and expected2490246820. No program import, compiler build, profile or timing was
performed by this owner.

## Correction: guard grant purity review was incomplete

The cost owner's subsequent review found a blocker in the version2 grant:
scalar-only inputs plus `j_region_has_residual` proves neither that all direct
helpers are pure nor that the entire region is callback-free. A direct Array.new
path can coexist with one independently proved residual. Array native operations
were admitted by the ordinary region planner under a different ownership/host
boundary; that is insufficient to retain a proof across arbitrary nested calls.

The earlier statement “no additional blocker found” is withdrawn. It addressed
error suspension but failed to challenge the grant's full closure premise.
Promotion requires a **whole-root independent JPure graph check**, using the
original definition and complete own-body/callee validation, before emitting the
scope wrapper. Add a refusal fixture mixing Array.new/native-array state with a
pure residual and a mutation/reentry-capable hook. Failure must retain the normal
per-call guards. This correction does not affect producer planning, which already
requires `j_pure_graph(book,d,...)` before constructing its JProducer plan.
