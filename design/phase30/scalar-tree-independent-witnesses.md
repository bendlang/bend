# Independent witnesses for the prospective scalar-tree compiler

Prepare these before the compiler implementation is exercised. Use actual
`j_library` from an immutable checked attempt, retain each synthetic book and
module, and distinguish backend admission from frontend acceptance. Keep the
existing generated-output tree controls and their source unchanged.

Positive scalar trees should include all of the following, with small depths
and an independently written recursive arithmetic reference:

- Zero returns its U32 state; left child receives `state+1`, right child receives
  `state*3`; combine is `U32.sub(left,right)`. This distinguishes child order,
  parent-state restoration, right-argument timing and noncommutative combination.
- The same child arguments with the combination reversed, plus U32 boundary
  states, so accidental swapping cannot be hidden by addition or equal leaves.
- Pure helpers shared across the zero body, both child argument vectors and the
  combination. Completed helpers appear once and consume one shared budget.
- A nested proved Nat countdown inside a child argument or zero expression.
  It receives an unprojected count and handles zero before predecessor setup.
- Native Bool or Nat carried state, where supported by the same scalar proof,
  and multiple successive calls with different values.

Refuse additional/erased children, missing or oversaturated self arguments,
different predecessors, self calls inside a child argument, indirect owner
reentry through a helper, helper cycles, record state/results and escaping
closures. Refuse a child result binder equal to any parent binder or to the
other child binder. A right child expression referring to the left result must
not be admitted: these are parallel bindings, so both right sides see the old
parent environment. The combine environment contains only the two child
results, so a combine that directly captures the parent state must also decline.
Preserve annotations, and reject labels or invalid native constructor identity.

Test source size, helper depth/count and analysis fuel with admitted neighbors
where practical; do not restart budgets at each child or analyze an incomplete
cached helper as if it were proved. Retain the existing countdown/refusal tests
after factoring the shared Nat header, so a tree extension cannot silently
weaken the tail-loop rule.

The semantic gate uses raw callbacks, saved partials, later descriptor mutation,
copied-vector length effects and coercible inputs. Force generic fallback with a
helper wrapper that records the left-child arguments, right-child arguments and
combination order; compare the full transcript. For the pristine private path,
independent frame/leaf/index counters demonstrate traversal without introducing
observable source effects. Post-guard sentinel copies test projected predecessor
31 admitted and 32 refused without running an exponential tree. Those copies
are diagnostic and never timed.

The independent supplementary host suite also covers persistent primitive
runtime-marker getters, all nine descriptors' metadata and `code.call` getters,
and copied-length mutation/throw at reads 2, 3 and 5. Stable host intrinsics,
including private Array storage operations, remain the declared scope.
