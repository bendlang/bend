# H17 small-request attribution

**Generated invocation dominates this diagnostic; ABI conversion does not.**
In the two requests after the first warm request, H17 spends 97.1% and 97.6%
of instrumented request time between the adapter's `invoke` and `decode`
events. `check_program_diagnostic` alone occupies 76.8% and 79.8% of the full
request. This supports inspecting generated checker code before introducing
another ABI cache.

This follows the frozen [design](../../design/phase31/h-attribution.md), with
CPU 2 acquisition allowed to overlap correctness work. It is **not a clean
performance comparison**, a new H/parent ratio, or a steady-state result.
Trace formatting, allocation and stderr output perturb execution, and elapsed
intervals may include garbage collection and scheduling delays.

## Exact request and checks

Both fresh processes retain normal `D.inspect(source,{mode:'library',api})`,
their real-hash validated Base caches, the original 190-byte fixture, Node
24.18.0, 4 MiB stack and 8 GiB heap allowance. The genuine parent is SHA
`60aa968ffcedb7a02a220b58a51396dd036d0d8b1f39f1b3def3f6b4248d6469`;
actual H17 is
`a7ffece566086a00c7b8224680ab320f1933e7ae7663fc765ed20eea5c8cdeb5`.
Imports, separate Base preparation and result verification remain outside
each request's interval.

All six requests match the entire expected observation and the 70,084-byte
JavaScript SHA
`3beb60a3eca3b3356d5a228033baf191530abe4378cf5b74c2eff082ca0ca8aa`.
Both caches and all bound inputs remain unchanged. Each request makes exactly
29 host-facing API calls. Both children exit successfully within their
90-second deadline; no timeout or capture overflow occurs. The experiment
reuses the prior positive-program execution oracle; it does not separately
execute these six identical outputs.

The worker derives from the maintained Phase 30 worker through nine exact,
count-checked replacements. No compiler, driver or adapter changes were made.
It enables existing ABI phase traces, timestamps stderr writes with
`performance.now()`, and adds API enter/leave events for both implementations.
Complete traces, original and derived workers, patch, scripts, plans, hashes
and process receipts are retained. An initial bare `node --check` invocation
found no Node on PATH; the explicit pinned Node syntax check passed before
acquisition. This was a preparation command failure, not a compiler failure.

## Diagnostic intervals

All values are milliseconds. The host remainder is total request time outside
the API wrappers. H's wrapper column includes small intervals surrounding
the four ABI trace boundaries.

| Implementation/request | Total | Encode | Invoke | Immediate decode | Wrapper | Host remainder |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Parent, first warm | 2,218.908 | 0 | 2,059.621 | 0 | 0 | 159.287 |
| Parent, diagnostic 1 | 1,568.472 | 0 | 1,434.908 | 0 | 0 | 133.564 |
| Parent, diagnostic 2 | 1,378.363 | 0 | 1,251.300 | 0 | 0 | 127.063 |
| H17, first warm | 8,862.465 | 123.243 | 8,578.769 | 1.405 | 0.854 | 158.195 |
| H17, diagnostic 1 | 7,344.105 | 70.823 | 7,134.205 | 1.310 | 0.803 | 136.964 |
| H17, diagnostic 2 | 7,463.258 | 53.160 | 7,282.301 | 1.342 | 0.707 | 125.748 |

The parent needs no positional/named-field adapter. Its Invoke column is the
outer API duration; H's Invoke column isolates the interval inside its
existing adapter. These are not identical instrumentation paths, so no ratio
between them is inferred.

| H17 generated export | Diagnostic 1 invoke | Diagnostic 2 invoke |
| --- | ---: | ---: |
| `check_program_diagnostic` | 5,638.492 | 5,957.227 |
| `f_graph_trace` | 604.371 | 496.926 |
| `j_library_selected` | 175.790 | 144.351 |
| `reach_book` | 159.693 | 150.964 |
| `driver_emit_owned` | 146.940 | 134.296 |
| `f_complete_seed` | 133.892 | 118.377 |
| `f_complete_source` | 130.024 | 127.550 |

Each H request encodes **168,603 objects**, unwraps 38 existing views and creates
16 immediate output views. `f_complete_seed` accounts for 84,283 encoded objects
and `check_program_diagnostic` for 84,281. Despite that count, encoding occupies
only 0.96% and 0.71% of these later instrumented requests. There are another
129 view creations between API calls per request. Lazy proxy access belongs
to the host remainder, so immediate Decode is not all ABI-related work.
The summarizer verifies each H call's complete ordered quartet and the
nonoverlapping interval accounting; it does not discard unmatched events.

## Next falsifiable hypothesis

The next compiler-throughput experiment should isolate
`check_program_diagnostic` on the same loaded book and inspect its generated
record, call and normalization behavior. Its source calls `dg_check_world(book)`
and completion logic; the large checked Base is still part of the surrounding
request. The present observations do **not** establish which checker operation
dominates, nor justify skipping any checking. A bounded CPU profile or separate
operation-count build should discriminate normalization, lookup and record
administration before a production optimization.

An ABI cache might remove some work, but the direct encoding interval here
cannot explain the multi-second gap. Cache changes should wait unless a
different, explicitly measured workload exposes a larger cost. This conclusion
applies to this exact small library request and current H17 image only.

Raw paths under `selfhost/build/phase31/` are `h-attribution-plan-01/`,
`h-attribution-parent-01/` and `h-attribution-h17-01/`. Each run has its own
`report.json`, `result.json`, `summary.json`, consumed worker/runner and full
process logs. Maintained derivation, runner and summarizer are in
`selfhost/tools/performance/phase31/h-attribution-*`.
