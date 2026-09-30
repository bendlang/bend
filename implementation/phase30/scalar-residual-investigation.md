# Diagnose the gap between prototype and checked emitter

The actual checked helper confirmation gives 0.0378 ms for attempt07, compared
with 0.00171 ms for TypeScript. The earlier literal-shift private prototype
takes about 0.0072 ms. These outputs differ in entry protection, helper spelling
and callback structure, so that discrepancy is a question, not an attribution.

The [residual ablation](../../design/phase30/scalar-region-residual-cost.md)
derives exact variants from actual07. One bypasses only the dependency guard
under unchanged descriptors; it is diagnostic and cannot be promoted. Another
outlines the 1,046-byte generic fallback into a private function taking saved
slots. Each of the four modules passes 121 independent scalar points.
The outlined variant also passes 146 ABI/effect/prototype observations, 72
scalar-oracle executions and nine entry/reentry controls against unchanged07.
Independent static review found no additional boundary issue. Timing is pending.

The separate [CPU profile](../../design/phase30/actual-scalar-profile.md)
samples 30,000 checked calls after at least 5,000 warmup calls and one second.
It contains 7,796 samples. About 41.4% are attributed to `enterExact`, exclusively
at its `return inner(a,entered)` call site. This can include inlining or host
profiler attribution effects; it does not mean token checks consume 41.4%.
The worker and private helper frames also receive substantial samples, while
the named dependency-guard frames are a smaller share. These are samples of
one instrumented workload during other acquisitions, not a timing comparison.

That observation motivates two additional independent lifetime interventions:
hoist the private worker implementation while keeping fresh public callbacks,
or fuse each fresh registered public callback with its implementation. The
[prospective contract](../../design/phase30/registered-worker-entry.md) preserves
entry permission, callback shape and per-partial mutation. Their derivation and
controls belong to the independent reviewer. Neither implementation should be
combined with lexical helpers or outlining before its own measurement.

Evidence: `residual-01`, `residual-check-*-01`, `residual-abi-01`,
`residual-entry-01`, `profile-scalar-01` and their launcher receipts under
`selfhost/build/phase30`. Raw modules, profile and consumed tools remain available
for campaign preservation. No production change follows from profiling alone.
