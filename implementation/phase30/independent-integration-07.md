# Independent attempt07 semantic checkpoint

The actual checked attempt07 passes the bounded independent integration suite
against the preworker compiler. The five earlier Nat-loop scheduling/live-self
failures are repaired, matcher callable kinds are restored, and exact-arm
widening remains rejected. This is a semantic checkpoint for clean measurement
and broader integration, not a release or full backend-conformance claim.

| Suite | Passing result | Raw directory under selfhost/build/phase30 |
| --- | --- | --- |
| Actual j_library region admission/refusal | 22 books, 13 executions | review-scalar-compiler-admission-03 |
| Nat-loop historical counterexamples | 5 repaired | review-nat-loop-scheduling-03 |
| Ordinary host ABI, getter/effect/error order | 130 observations | review-scalar-compiler-run-04 |
| Independent scalar arithmetic and long loop | 72 runs, including 50,000 iterations | review-scalar-compiler-run-04 |
| Exact entry, reentry and exception cleanup | 9 observations | review-scalar-entry-03 |
| Actual matcher-arm emitter/runtime | 72 historical plus 22 additional observations | review-arm-07 |
| Callback callable kind and reflection | 5 comparisons | review-callable-shape-03 |

The arithmetic/host comparison uses the same checked Mandelbrot source through
the preworker Phase27 attempt02 and the new attempt07. The new module is
`fixture-region-07/candidate.mjs`; its emission receipt records source, compiler,
runtime and Base identities. Synthetic emitter controls use the actual immutable
attempt APIs and runtimes; they do not claim source-checker admission for malformed
or intentionally cyclic books. Rejected cyclic/foreign books are never executed.
Every suite retains consumed tools and exact inputs or hashes in fresh directories.

The exact-entry controls include same-vector raw reentry from slot getters,
nested exact then raw invocation, environment reentry, code.call hooks and
evaluation order, and token cleanup after throwing getters. The arm suite
continues to select ordinary emission for all five count-equals-total cases.
Reflection confirms the original anonymous one-argument arrow matcher callbacks
and ordinary-function leading lambdas retain their own properties and
constructibility. Function source text is not treated as an ABI promise.

The runtime-only inherited prebinding repair also passed seven ordered/raw-entry
scopes before this checked build. Its actual core component is frozen in
attempt07; the broader arm suite above validates that runtime through real
compiler output. Earlier counterexamples and unsuccessful attempts remain
unchanged.

Two limits remain explicit. First, ambient standard-prototype monkeypatching
does not have full effect-trace equivalence. The three-way diagnostic in
`review-prototype-effects-01` retains all 16 cases across preworker, Phase29 and
attempt05 without normalization: values/errors agree, while several inherited
administrative bounce/build getter counts differ. The ordinary ABI suite marks
that section as separately evaluated and excluded from its pass count. Second,
a malformed host descriptor's noncallable code.call can report the engine's
local identifier `code.call` instead of `f.code.call`; exception class and getter
ordering agree. The raw receipt remains a mismatch and the accepted scope is
documented in [scalar-entry-runtime.md](scalar-entry-runtime.md). Neither limit
changes a Bend diagnostic or the checked source-language results covered here.

All review executions are finished and CPU6 is idle. No clean timing, promotion,
commit or push was performed by the reviewer. The lead owns the next measurement,
broader integration and consolidation decisions.
