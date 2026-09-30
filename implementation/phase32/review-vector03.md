# Independent static review of checked candidate03 source

Review date2026-09-30. [Exact reviewed identities](review-vector03-identities.json)
include production source, prepared controls and actual02 emissions. No compiler
or generated module was executed by this reviewer. The root owns candidate03's
build and dynamic admission.

**Decision:** no static semantic blocker found; proceed to the scoped actual
output and compiled-predicate controls. This does not approve release or establish
an execution-speed improvement.

## Uniform private representation

`j_region_local_vector` first normalizes its input using `wnf`. Canonical Sigma
returns true under the existing native identity check. Otherwise the predicate
requires an eligible ordinary constructor and rejection by `j_region_record` on
that normalized head. The predicate is a representation choice after successful
`j_region_local_type`, not a replacement for the bounded type proof. Its ordinary
constructor lookup refuses native array/scalar owners. Flat public terminal
records remain boxed; aliases to them remain boxed as well.

`j_region_constructor_done` creates JVector only inside a transformed region plan.
Its caller has already checked constructor owner/name, arity, complete local field
types and all constructor argument expressions. Failed argument analysis retains
an invalid plan, so no partial JVector can reach emission. The new emitter uses
the existing specialized local field telescope and `j_ctor_args`, preserving field
evaluation order and completed private-return demand. Canonical two-field Sigma
already used its field vector, so removing its generic constructor dispatch does
not introduce a new tuple layout.

Both expression-position and return-position JUnpack use the same normalized
predicate as construction. Private calls and variables transmit the same value
without representation conversion. The existing field-snapshot scopes and ordinary
boxed paths remain intact. Public/generic constructor emission is unchanged;
JVector is an internal node produced solely by the successful private planner.

## Public boundary

Public scalar roots cannot return a record. The existing public Nat-worker record
exception admits only quantity2 flat records of scalars. A newly vectorized
ordinary record therefore cannot be that result or one of its fields. External
container inputs, callbacks, foreign/unknown calls and function fields remain
refused. The only admitted array natives use U32 elements and cannot store the
new record. Private helper copies are separate lexical functions; public calls
to the same source helper still use the original boxed implementation.

Accordingly, PairBox remains boxed even when nested in a private Nest vector.
A quantity1 flat record is also non-public under this existing output rule, so it
can be private despite having only scalar fields. The prepared predicate controls
cover that distinction and alias chains explicitly. `localGuard` remains unchanged,
including Array prototype checks, so the new field vectors do not weaken the
existing observable forcing/prototype boundary.

## Actual02 control assumptions

Static inspection of the checked actual02 emitted files finds12 bridge/read
pairs in the full-pair module and3 in the independent-fold module. Each uses the
exact `$data=arraydata($array)` and immediate indexed-read sequence expected by
the new control tools. The fold contains the two-prefix bridge selected by the
order tool. No instrumentation adjustment is required.

The vector-alias fixture's `bench` and public `terminal` definitions both contain
`localGuard($guards)`; its public `pair_box` and `nest` definitions do not. Thus the
prepared public-result assertion exercises the intended optimized terminal-return
boundary rather than passing solely because no optimized worker was produced.
The source receipt marks the fixture checked. Numeric and boxed-object oracles
remain unexecuted by this reviewer.

## Remaining dynamic gates

Run the21 compiled-predicate cases,40 scalar and40 boxed-public-result cases and
14 public metadata/field-getter observations. Retain existing array-free Sigma
prototype-marker tests. Run unchanged full-pair state/schedule and independent
fold controls against02 and03; vectorization must preserve all logical native
operations. Initial zero and loop-to-zero must keep boxed terminal results.
Candidate03's timing and normal compiler-request costs require their own paired
measurements after these correctness gates pass.

## Subsequent focused-gate result

The root completed all six planned gate groups successfully. I inspected their
receipts and identities rather than rerunning them. [The gate summary](review-local-gates.json)
records exact per-group output and supervisor hashes; [complexity and scope](local-complexity.md)
list the individual control counts. The actual03 alias tests preserve boxed
terminal results at initial zero and after countdowns. The actual compiled
normalized-vector predicate passes21 guarded cases. Pair/fold state and logical
native schedules agree across the four checked Bend variants. Maximum supervised
RSS was292.5625MiB. No failure was hidden or repaired by changing expected answers.

Static review plus these focused gates supports performance measurement and
broader integration. It does not establish broad conformance, release readiness
or an isolated speedup. [The vector ablation clarification](../../design/phase32/vector-ablation-scope.md)
records that03 also removes canonical Sigma constructor dispatch; the fold is42
bytes smaller rather than byte-identical.
