# Current full-source checking cost

The installed Phase8 compiler checks its complete assembled source in **205.26s**
mean process wall time; pinned TypeScript takes **2.80s**. That is **73.20× slower**
for this workload. The request-only ratio is **113.11×**. This is a substantial
remaining gap, not an optimization success claim.

This measures parsing, ordinary checking, specialization and declaration-trust
reporting. **It does not measure JavaScript/C emission or full compilation**, so
it is not directly comparable with the historical 6.03× full-compilation result.
The short development workflow uses upstream to build a checked Bend candidate,
then runs the candidate on focused cases: one migration attempt took 26.94s for
bootstrap plus 21 paired controls. Full self-checking is an integration gate.

| Variant | Samples | Mean request | Mean process wall | Maximum RSS |
| --- | ---: | ---: | ---: | ---: |
| Pinned TypeScript | 2 | 1.805s | 2.804s | 411.9MiB |
| Installed checked Bend B1 | 2 | 204.200s | 205.260s | 1605.6MiB |

Actual process order and times: TS 2.774s, Bend 204.721s, Bend 205.800s, TS 2.834s
(rounded; exact values are in [checking-cost.json](checking-cost.json)). The
four requests all accept the source's types, report the expected unsafe trust
refusal, and agree on the complete unsafe-definition set. There are no timeouts,
crashes or changed identities. Each child has a 600-second deadline.

## Controls and timing boundaries

The [prospective recipe](../../experiments/phase8/P8-003-current-check-cost.md)
was written before preflight and committed before the controlled run. The run
uses final release07, API `e928f77778de9dc72267e26b6a7ccb029cac318ccd35dd8f9248da1c6374bbe4`,
source `0f5425ac8a2298f444b0907632088b406da61420407331e80708d9fea6a47822`,
canonical b2111cf Base and the release's frozen host/runtime. Node 24.18.0 runs
fresh processes pinned to CPU 0 with a 4MiB stack and 4GiB heap. All other intentional
compiler jobs were stopped for the 01:59:20–02:06:17 UTC measurement window.

TypeScript creates a fresh book and checks Base each time. Bend uses its
separately validated disk Base cache, including decoding/validation in the
request. OS caches are not flushed. These are normal selected workflows, not
identical cache work or isolated checker kernels. Request timing wraps the
adapter's probe and includes lazy compiler loading; process wall additionally
includes startup, identity hashing and result capture. Adapter-module import
itself is outside request timing. Two samples each on one host provide a
descriptive ratio, not a confidence interval.

Raw requests/results, supervision logs, frozen measurement worker and all bound
inputs are under `selfhost/build/phase8/check-cost-controlled-01/`, retained in
[the migration capsule](migration-evidence/README.md). The maintained
[runner](../../selfhost/tools/performance/phase8/check-compare.mjs) verifies the
genuine checked attempt and input bytes before and after each observation.

## What the profile establishes

Separate concurrent preflight observations take 3.33s/245.26s. They are retained
but excluded from the controlled comparison. A separate wrapper profile observes
the unchanged checked API on the same source: 221.37s total, with 183.69s inside
`check_book_diagnostic_from_exact_prefix`, 22.76s in graph loading/elaboration,
6.59s in source parsing and 5.43s in specialization. Timers can nest; they must not
be summed into an additive decomposition. This identifies checking as the main
region to investigate, not a specific proven cause.

Read-only inspection also finds that new generated `$String$eq$` still calls
`$String$cmp$`. The historical guarded equality transformation is not compatible
with this new body and was not applied blindly. Adapting that proven optimization
is a bounded next hypothesis, followed by profiling conversion, context lookup
and allocation inside the checker. No speed estimate is credited before a
checked candidate, semantic controls and a repeated controlled comparison.

The unchanged-source emitter experiment is separate: it improves old-Base parsing
about 1.52× and 60 tiny declaration checks about 1.45× versus the old S4 release.
Those operation gains do not establish a whole-source speedup. Compact literals
are a separate promising correctness/performance direction; generic binder and
semantic-value prototypes remain unpromoted because their earlier controls
showed regressions.
