# Independent local-data review

The fresh checked17 setup and Dp-shell derivatives pass this bounded independent
review. This establishes their behavior on the saved row diagnostic and selected
public boundaries. It does not establish a general local-container compiler
rule, complete backend conformance, or a speed improvement.

The prospective [review design](../../design/phase31/local-data-independent-review.md)
predates execution. The maintained reviewer is
`selfhost/tools/performance/phase31/review-local-data.mjs`. Inputs are bound in
`selfhost/build/phase31/review-local-data-01/report.json`; the outer command,
limits, stdout, stderr, and consumed runner are in
`selfhost/build/phase31/review-local-data-launch-01/`. The correctness acquisition
completed in 0.817 seconds on CPU6 with Node24.18.0, a 1 GiB heap limit, 4 MiB
stack, and 180-second outer limit. This duration is not a performance comparison.

| Artifact | SHA256 |
| --- | --- |
| Original checked17 row | `fc31165c8fbc5ac6c595ca12e9c57e18960ff2e3cef2f9d20c71220ee3b52475` |
| Rebound direct-native row | `cc12037562709b9a4df5212b7ff25a27d74f829b59b467c2902b4c803da319f8` |
| Private setup | `6acb1ce1966fc113dcb2a590b432d26ccfa4c5779a1ceff98e16b26ff2f3fbd4` |
| Private setup plus Dp shell removal | `3c15742ec845022b2cacdac2bc0a20871be0f3c2f01bd8092bf71669cb4b294d` |

## Why the two transformations are admissible here

Setup A preserves the exact emitted PRNG expression. Its private `gen` computes
the next seed, computes the next index, performs the existing native Array.set,
and forces that result before the next iteration. Private `init` similarly
retains its write and force before transfer. The public root limits its scalar
count to 64, so its Nat counters are nonnegative and its incremented initializer
count cannot wrap. Four original allocations still occur in order: initialize
the first input, initialize the second, initialize prev, then allocate cur.

Shell B returns the exact original four field thunks from private `cell.f4`.
The fourth thunk still contains Array.set. Its private row evaluates and forces
those thunks left to right at the point where the preceding implementation
forced the complete cell result. It carries their resulting handle vector into
the next cell, removing the intervening Dp wrapper and projection/copy. Initial
Dp projection remains; final Dp reconstruction precedes the unchanged public
zero-row arm, which swaps prev and cur. A zero-iteration call follows that same
original arm without entering the private loop.

All mutable handles and all Tuple read chains survive. No array storage layout,
native checking, arithmetic, or modulo behavior changes. Original-definition
snapshots and exact entry admit only the closed, scalar-input path. Public row,
cell, gen, init, native descriptors, and unsupported-entry code remain unchanged.
Under the declared stable host intrinsics and primitive/Array marker guards,
the private thunk vector has no user-accessible reference or callback capable
of altering its length or later thunks during this invocation.

This is shell elimination with preserved demand. It is not demand elimination:
the owner's separate counters show more individual `force` function entries in
B because four field demands are now made explicit. Counts alone cannot decide
whether removing constructors, projection, and scheduler frames pays for that.

## Independent executed observations

- **99 complete-state points across all four artifacts.** Sizes
  0, 1, 2, 3, 7, 15, 16, 31, 32, 63, and 64 combine with nine seeds covering
  zero, small values, both sides of the signed-word boundary, and U32 maxima.
  The separate reference recurrence uses BigInt word arithmetic and compares
  every slot of all four 128-word arrays. It does not call the emitted helpers.
- **12 complete native schedules across all four artifacts.** Separately
  instrumented copies record every allocation, read, and write, including
  allocation identity, index, and value. They match the independently calculated
  source schedule exactly at six sizes and two seeds. Returned roles are
  `[a, b, cur, prev]`. Every event is retained; these copies are never timed.
- **24 freshness and alias scenarios.** Repeated calls have distinct handles
  and storage. Public zero and subsequent nonzero rows preserve the expected
  role permutations. A later write through a saved handle appears through all
  matching record aliases.
- **39 ordered public-boundary scenarios across all four artifacts.** Raw,
  forged, and constructed callbacks save an unforced result across Array.get,
  Array.set, or cell replacement; the changed helper must actually execute.
  Saved bounces are forced repeatedly. Public rows receive shared handles,
  shared backing stores, proxy storage, and foreign array getters. Object and
  Array prototype marker observations include helper mutation during forcing.
- **Two expected-failure witnesses per artifact.** Eagerly executing a delayed
  fourth-field write changes an intervening alias read from 0 to 9. Omitting
  the zero-row swap changes handle-role identities even when all array contents
  are numerically equal. Both bad transformations are rejected by the controls.

These are overlapping scoped observations, not additional unique frontend tests.
The owner's 28-point oracle, 257-boundary suite and operation counters are useful
separate evidence and are not claimed as independent reviewer executions here.

## Remaining proof boundary

No arbitrary callback, foreign input container, or unknown primitive enters the
admitted path. Arbitrary mutation of Array allocation/indexing intrinsics remains
outside the experiment's stable-intrinsics contract. Prototype marker tests
verify explicit fallback behavior; they do not establish all possible JavaScript
metaprogramming equivalences. The diagnostic's fully forced Dp return is for
observation and does not admit general escaping container results in production.

The next production proof should keep locality, demand, and escape as separate
facts. A local constructor can still contain a delayed write. A scalar result
does not by itself prove that a callback or container never escaped. A shared
bounded analysis can reuse the existing region traversal and exact-entry guard,
but widening its scalar type predicate alone would be unsound. A second
structurally different fixture and a general source-derived transformation are
required before promoting these handwritten generated-code changes.

## Smallest general production boundary

Static follow-up, requested while the owner performs the clean timing window:
the first production extension need not implement a general ownership system.
Keep public roots scalar in and scalar out. Admit only a closed, first-order
expression grammar: existing scalar operations, canonical Array<U32> allocation,
get/set, nonrecursive single-constructor records of admitted values, and the
canonical Array<U32> & U32 tuple returned by get. Reject global container values,
function values, foreign calls, callbacks, unknown native operations and partial
private applications. By induction over this grammar, every container argument
of every private helper originates inside the root. Internal aliases are valid.
The original runtime representation and demands can remain initially.

The reusable code and precise blockers are:

| Existing machinery | Required extension and boundary |
| --- | --- |
| `j_region_expr`, `j_region_bindings`, `j_region_args` | Reuse their bounded traversal, parallel-RHS environment discipline, original-term typing and dependency collection. Introduce a narrowly defined admissible local-data type predicate; do not replace public scalar admission with it. |
| `j_region_capture_eligible` | Split three decisions currently conflated: scalar root admission, private helper signature admission, and runtime definition snapshot eligibility. A container helper needs a snapshot even though its public inputs cannot enter a private root. |
| `j_region_prefix` / `j_region_match` | Add single-constructor elimination. Initially require that the Mat consumes the last ordinary function argument. Then consume the entire specialized constructor field telescope and map all field binders to private projection slots. Reject eta-short arms and function-valued fields. |
| `j_specialize`, `j_arm_type`, `j_projection_arm` | Reuse constructor parameter specialization and full-telescope checks. Do not equate constructor fields, function parameters, and public callback arity. |
| `j_primitive_definition` | Model native Array identity checks on its provenance/telescope discipline, adding the one erased element parameter. Reject foreign or user-shadowed definitions and non-U32 element types. |
| `j_apply_args_head`, `j_app_type` | Retain erased argument semantics: statically check/substitute U32, emit null without evaluating that erased expression, and preserve its runtime slot. Array.new/get have three slots; Array.set has four. |
| `j_constructor_mode`, `j_ctor_thunks` | Reuse the exact tail constructor scheduling. Do not make a private helper's constructor eager merely because its surrounding graph is local. |
| `JCall`, `j_region_return` | Add an explicit demand contract. The current scalar-only JCall returns an already computed value and never forces it; `j_region_return` emits with tail=False. A container helper must preserve its original delayed tail result, while a non-tail caller forces that result before the next argument or RHS. A plan-level force node or equivalent explicit rule is needed. |
| Nat worker machinery | Reuse countdown structure, fresh per-iteration aliases and self-transfer. Its public signature must remain scalar; private loop eligibility needs a separate local-data signature check. Do not accidentally admit foreign arrays to the public successor callback. |
| Snapshot/entry runtime | Reuse exact single-use entry and dependency guards; add definition-time snapshots for the admitted native descriptors and record helpers plus the existing Array-marker refusal. Snapshot actual descriptor metadata. |

The arity distinction is observable in this fixture: cell has three semantic
arguments, but its public wrapper is `fn(2, ...)` and returns a one-argument
record matcher. Its private worker may accept all three arguments directly.
Runtime guard validation must compare the saved public descriptor's actual
arity, not require it to equal the private worker's arity. In a record match,
one argument is replaced by its field telescope only for analysis of that arm;
those field binders must not become extra public or private call arguments.

The Tuple type also prevents treating every record as a nullary named ADT.
Canonical Sigma has four type/quantity parameters; specialize its constructor
telescope first, then validate its two concrete fields. The current terminal
record predicate deliberately rejects parameterized types and requires a Data
kind. Dp is a Type containing arrays. Widening that predicate globally would
silently change several unrelated public admission paths.

This staged extension first captures the measured setup/helper benefit with
ordinary records and exact demand. Shell replacement can then be a separate
plan transformation at proved demand/elimination pairs. General demand
elimination is a later step: a local, first-order type whitelist establishes
non-escape, but does not establish that a delayed mutation may move across
another local read. These are the two distinct proof obligations.
