# Independent review of the terminal-region compiler extension

Reviewed the current `region.bend` and `worker.bend` against the immutable
attempt08 snapshot, whose change was lexical private-helper names. This is a
static review only; it does not claim that this source has compiled or that its
new admission paths have executed.

Reviewed identities:

- `region.bend`: `bf264833f0a39d6435c6462ec3cba105e969508a38280dfd8dbbe246432aa845`
- `worker.bend`: `729e7bf31cb7f85ab12988ef5038953ac57badee1b5c9122072458358cb2a189`

No semantic blocker was found in these changes under the existing checked-input
and runtime-intrinsics contracts. The implementation follows the prospective
[minimal extension plan](../../design/phase30/terminal-region-compiler-extension.md).

## Admission and forcing

The new result predicate accepts either an existing scalar or a closed,
unrefined, nonnative Data type with one constructor and at most 32 live scalar
fields. Constructor lookup is local to that validated owner. The field telescope
must end at the same zero-parameter ADT; neither a record name alone nor a fallback
global constructor search establishes admission.

The broader result predicate does not broaden the environment: input prefixes,
every call argument and every Let RHS remain scalar. Ordinary helper signatures
also retain scalar results. Consequently record variables, carried records,
projections and record-returning helpers cannot enter this grammar. `Ann` keeps
the expected normalized owner identity. Invalid argument/field analysis retains
the failure bit even where a result wrapper is subsequently reconstructed.

`j_region_field_values` permits only stripped variables, literals or nullary Bool
constants, and the ordinary typed argument walk validates those values against
the scalar field telescope. A superficially admitted String literal or unrelated
constructor therefore still refuses. No private helper call is postponed into
the returned record's fields. Existing `j_nat_loop_emit` and `j_lambda_code`
create immutable final aliases, and ordinary `j_constructor_mode` retains the
build/thunk forcing boundary. External Zero behavior remains generic.

## Nested loops and limits

The factored Nat shape proof retains the original native identity, lambda,
distinct-binder, source-bound and exact predecessor tail checks. It additionally
checks match child counts, terminal Efq shape and agreement with definition arity.
These extra checks conservatively refuse malformed shapes.

Nested Zero and Succ receive the same incoming `JRegionBuild`, completed-helper
cache, active chain and remaining fuel. Depth increments once for the nested
definition. The helper is inserted only after both arms pass; partially analyzed
definitions are never cached. Thus a recursive reference from a Let RHS, an
argument or Zero sees the active-name refusal, while the already-proven final
self call is retained for the existing tail emitter. Cross-helper cycles do not
gain a fresh analysis budget.

The retained nested Mat/Lam form is distinct from ordinary helper prefixes,
which are already consumed into annotated expressions/JIf. Its private emitter
tests the original unprojected `$p0` for zero, binds Zero's remaining arguments,
then uses `$s0=$p0-1n` and the existing Nat-loop body for Succ. This preserves the
actual `mit` convention and introduces no second tail-transfer implementation.

The original helper/depth/source/expression/work limits remain. New field walks
are bounded by 32; field-count mismatches refuse before a long argument walk.
There is no reset of the global work budget or active chain in nested analysis.

## Required executable evidence

The highest-value next checks are actual checked emission of original `hchunk`,
complete eight-counter comparisons and the eight-descriptor guard closure;
zero/one nested iterations; record inputs/RHSs/computed fields refusing; non-tail
and mixed mutual cycles; and shared depth/fuel exhaustion across both arms.
Then reuse the retained public mutation, exact-entry, copied-length and terminal
thunk controls against the new emitted module. The favorable generated-JavaScript
experiment is evidence for the mechanism, not a substitute for those compiler
admission and emission checks.
