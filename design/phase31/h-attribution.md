# Phase 31: attribute the generated compiler's small-request cost

Prospective diagnostic design, 2026-09-30. No performance result is implied.
The parent grants acquisition on CPU 2; this is not an exclusive timing window.

The Phase 30 [H17 comparison](../../implementation/phase30/warmed-generated-compiler17.md)
measures the real `D.inspect(..., {mode:'library', api})` request with an
already loaded API and checked, compiler-specific Base cache. It does not
separate ABI conversion from generated execution. This investigation keeps
that request and the exact positive-output oracle, adding diagnostic events.

## Frozen scope and derivation

- Genuine parent: `60aa968ffcedb7a02a220b58a51396dd036d0d8b1f39f1b3def3f6b4248d6469`.
- Actual H17: `a7ffece566086a00c7b8224680ab320f1933e7ae7663fc765ed20eea5c8cdeb5`.
- Expected JavaScript: 70,084 bytes, SHA
  `3beb60a3eca3b3356d5a228033baf191530abe4378cf5b74c2eff082ca0ca8aa`.
- Reuse the immutable Phase 30 plan, driver, ABI adapter, source, runtime,
  Base and prepared cache identities. Verify them before and after each run.
- Derive a fresh worker from `inspect-generated-compiler-cost-worker.mjs`
  with exact, count-checked replacements. Preserve that original worker,
  derivative, derivation patch and input identities in fresh Phase 31 paths.
  Do not modify any compiler, adapter, driver, prior plan or prior result.

Enable the existing `BEND_TYPED_TRACE` option. Intercept each stderr write at
entry using `performance.now()` and retain its complete original text; forward
the write normally. This captures existing ABI `encode`, `invoke`, `decode`
and `return` events without changing the adapter. Wrap each host-facing API
export with enter/leave events, preserving arguments, returned values, `this`
and exception propagation. This exposes the genuine parent's calls, whose
named-field ABI needs no adapter, and checks the H adapter's outer boundary.

For each implementation run one fresh process, the same separate Base
preparation, then three normal requests (first warm, next two diagnostic).
Check every output hash and full observation, and check that each real-hash
cache remains byte-identical. Keep all trace and process output. Use the prior
Node, stack and heap settings, CPU 2 and a 90-second child deadline; an outer
110-second deadline bounds each single-variant supervisor. Total new evidence
must remain below 40 MB. No controlled performance ratio will be calculated.

## Attribution and limitations

Pair each API entry with its leave, and each H ABI event quartet by name/order.
Within a request report elapsed wall intervals for encode→invoke,
invoke→decode, decode→return, and the rest of each API call. Report time outside
all API calls separately, plus per-export counts, totals and ABI counter deltas.
Check interval coverage and reject incomplete or misordered traces rather than
silently dropping them. Save individual requests; do not average away warmup.

These are instrumented elapsed intervals, including possible GC and scheduling
delays. Tracing itself adds allocation, formatting and output overhead. Lazy
ABI views can allocate during later host traversal, so decode→return alone is
not all conversion work; counter growth between calls helps expose that scope.
The host remainder includes filesystem/cache parsing, orchestration, lazy view
access and diagnostic overhead. It is not a pure host-code CPU measurement.
No fraction transfers automatically to larger requests or cold compilation.

The intended discriminator is coarse but useful: if generated invocation
dominates repeatedly, prioritize the costly exports and their generated
representation; if encoding repeatedly rebuilds large host graphs, test a
request-local prepared representation with explicit mutation/identity rules;
if host gaps dominate, inspect cache and lazy-view traversal first. Recommend
the next experiment only after observing a consistent mechanism. A clean
timing claim would require a separate uninstrumented plan and parent grant.
