# Independent attempt05 integration results

Attempt05 repairs all five independently retained Nat-worker scheduling and
live-self counterexamples against the preworker compiler. Its ordinary
host-boundary and numeric controls pass. A separate reflection check found an
arrow-versus-ordinary callback-kind difference; that has a tested runtime repair
queued for a later checked build. Attempt05 is therefore experimental evidence,
not a fully consolidated release.

The preworker reference is the checked Mandelbrot fixture in
`selfhost/build/phase29/prototype-01/unchanged.mjs`, produced by Phase27 attempt02
and used during Phase28. The new checked fixture is
`selfhost/build/phase30/fixture-region-05/candidate.mjs`. Their input fixture
hashes agree. Synthetic emitter suites load the immutable attempt APIs, Base,
driver and runtime recorded in each attempt manifest.

| Independent suite | Result | Raw evidence under selfhost/build/phase30 |
| --- | --- | --- |
| Actual region admission/refusal | 22 books, 13 executions pass | review-scalar-compiler-admission-02 |
| Ordinary host ABI, effects, errors and independent arithmetic | 130 ordered observations, 72 numeric runs pass | review-scalar-compiler-run-03 |
| Exact entry, reentrancy and cleanup | 9 pass | review-scalar-entry-01 |
| Earlier Nat-loop counterexamples | All 5 repaired | review-nat-loop-scheduling-02 |
| Actual arm emitter/runtime integration | 72 historical and 22 additional observations pass | review-arm-05 |
| Ambient prototype diagnostics | 16 cases across three generations; all values/errors agree, effect counts differ | review-prototype-effects-01 |
| Callable reflection | Two matcher callback-kind differences found among five cases | review-callable-shape-01 |

The first broad preworker comparison intentionally failed on the raw
Object.prototype.bounce effect trace after 128 passing controls. That receipt,
`review-scalar-compiler-run-02`, is retained. The subsequent ordinary-ABI run
explicitly excludes the ambient-prototype section and records that flag; those
cases are evaluated separately, without normalizing their traces or claiming
full ambient-prototype equivalence.

The three-way diagnostic distinguishes inherited exclusions from the new
correction. On the fixed two-iteration input:

| Prototype property | Preworker reads | Phase29 reads | Attempt05 reads |
| --- | ---: | ---: | ---: |
| Object.request | 21 | 18 | 21 |
| Object.bounce / Object.build | 90 each | 32 each | 44 each |
| Boolean.bounce / Boolean.build | 14 each | 0 each | 0 each |
| Number.bounce / Number.build | 53 each | 21 each | 21 each |
| BigInt.request | 5 | 2 | 5 |

Other tested prototype-property cases agree. The new generic fallback restores
the request-read counts; inherited elimination of administrative applications
still changes bounce/build observations under monkeypatched standard prototypes.
Values and exception results agree across all 16 cases. This remains outside
the standard-intrinsic contract, and is not labeled a full conformance pass.

The callable-kind finding is separate and repairable. The matcher callback was
an anonymous one-argument arrow originally; the first shared entry wrapper made
it an ordinary constructible function with an own prototype property. Name and
length did not change. A prospective amendment now preserves arrow mode for
matcher1p and ordinary-function mode for Nat successor callbacks. Exact runtime
component substitutions into the immutable emitted modules pass all five shape
checks and nine entry controls; the new core also passes all seven prebinding
scopes. Those are explicitly diagnostic derivatives, not new compiler builds.
Receipts: review-callable-shape-02, review-scalar-entry-02 and
review-prebind-entry-03. The lead must repeat checked integration and measure
the shared entry dispatch before promotion.
