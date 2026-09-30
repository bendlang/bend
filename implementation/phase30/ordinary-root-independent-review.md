# Independent ordinary-root compiler review

The attempt11 integration reuses the existing scalar-region proof and runtime
entry contract. Static review found no blocker in the new `region.bend` root
entry, the common `worker.bend` input predicate, or the `emit.bend` dispatch.
There is no new intermediate-language node or runtime mechanism.

The root eligibility check requires an ordinary, template-free, native scalar
signature and one complete live lambda telescope of at most 32 arguments. The
existing prefix analysis rejects labels and preserves owner binders; its active
set initially contains the owner, so root self/mutual recursion cannot be
silently treated as a private acyclic helper. Profitability requires a completed
Mat helper from the separately proved Nat countdown analysis. Boolean helper
matches have already become conditional expressions, so they do not satisfy
that test by themselves.

The public ordinary callback consumes exact-entry permission before reading its
original argument slots. Both fast and generic bodies then bind those saved
slots through the same existing emitter. The ordinary input predicate accepts
the full unprojected native Nat range, while successor workers retain their
strict predecessor bound. The usual global emitter captures the root descriptor
once at construction.

`review-ordinary-root-admission-11b` uses the immutable checked attempt11 API,
runtime and driver. All **28 synthetic books and 44 execution observations**
pass. Admitted cases include a forward nested helper, a transitive helper,
parallel-let shadowing, native Boolean decisions, and a maximum Nat value carried
as unused scalar state through a zero-count helper. Counts through 50,000 check
scalar results and U32 wrapping. The maximum Nat test verifies the emitted
inclusive root guard and executes without an enormous loop. Saved partials
observe later helper mutation, and a raw root callback retains its tail bounce.

Refusals cover missing/partial leading lambdas, erased/record arguments and record
results, templates/native roots, duplicate/labelled binders, root self/mutual
recursion, unknown/foreign/higher-order/partial/overapplied helpers, invalid native
Nat identity, refinements, an unproved recursive counter and helper-depth limits.
A trivial root or an unused loop elsewhere in the book does not gain a region.

The first `review-ordinary-root-admission-11` receipt is retained. It passed 12
earlier books and all 44 execution observations, then stopped because the test
harness assumed a refused template still emits a global. Such definitions are
omitted by the existing emitter. The follow-up records `globalEmitted` explicitly
and uses the emitter's actual `$js.` internal-label spelling in the queued label
case. No compiler change was required by this test correction.

These books exercise actual `j_library` admission, rather than claiming frontend
acceptance of deliberately malformed synthetic terms. Original-program oracle
and host-boundary controls are separate evidence owned by the parent, and these
counts must not be added to a language-conformance percentage.
