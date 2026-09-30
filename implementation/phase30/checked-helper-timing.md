# Checked compiler emissions: Mandelbrot helper

Agent-generated controlled comparison. The kind-preserving checked attempt07
emits a helper that runs **10.447× faster than Phase29**, with longer-warm medians
0.394653→0.037776ms. It remains **22.130× slower than pinned TypeScript output**
on this selected 128-iteration helper. This is actual compiler output, not a
hand-edited JavaScript optimization or a compiler-throughput measurement.

## Frozen inputs and provenance

`selfhost/build/phase30/fixture-checked-plan-02` contains byte-identical copies of
six previously checked library emissions, their emission receipts, canonical
source and a plan with verified identities for attempts, checked parents,
guarded APIs, bootstrap/derivation reports, runtime, Base and driver. The source is
`selfhost/tools/performance/phase29/fixture-mandelbrot.bend`, SHA256
`5c1b7031be03394ea7bfc64358b6db167711765e187e32d06f65a9f06bba3c7d`.
Pinned TypeScript is commit `018751270e800bc222a93dad7f257083ee53a5f7`.
The earlier five-way plan01 remains unexecuted and unchanged.

| Variant | Output hash prefix | Runtime hash prefix | Meaning |
|---|---|---|---|
| phase29 | 4f5b099ece77 | 40823818afd5 | Earlier installed compiler |
| owned_attempt01 | aa89f312a173 | b62b509094eb | Owned argument transfer |
| region_attempt05 | bb541094f091 | 1a1609cc8eee | Scalar regions plus repaired scheduling |
| region_literal_attempt06 | 16c74050d91c | 1a1609cc8eee | Adds literal shifts |
| region_literal_attempt07 | 8e9317debb12 | a3547a8854b4 | Also preserves callable kinds |
| typescript_pinned | 752a5711b92b | Embedded upstream support | Pinned reference |

Earlier runtime identities differ and remain explicit. Attempt05 versus06 holds
the repaired runtime constant while adding literal shifts. Attempt07 includes a
separate callable-kind correction, so its identity is not silently merged with06.
The planner runs no compiler or generated program; it verifies receipts and copies
bytes. Scoped validation receipts are linked in the plan, not presented as full
backend conformance or an independently checked mathematical kernel.

## Controlled measurements

One dynamic `bench(128,524800)` call must return 128. The lead grants exclusive
CPU3 timing after other CPU jobs stop. Analysis explicitly confirms it was idle
throughout the first screen, including the brief interval before its explicit
acknowledgement. All generated program executions use Node24.18.0, a 4MiB stack,
1GiB heap, sanitized environment and the frozen Phase29 paired protocols. No
instrumentation, acquisition, profiling or other agent CPU work overlaps them.

The screen uses three process samples and the existing short warmup. Confirmation
uses five process samples, at least 100 warmup calls and 3,000ms warmup per process,
and the frozen approximately 300ms sample target. No inputs, controls or protocol
are retuned after observing the screen.

| Variant | Short median ms | Longer-warm median ms | Long first-call median ms |
|---|---:|---:|---:|
| Phase29 | 0.420485 | 0.394653 | 6.439 |
| Owned01 | 0.366504 | 0.354289 | 6.256 |
| Region05 | 0.076240 | 0.061682 | 2.403 |
| Region + literal06 | 0.043113 | 0.037427 | 2.266 |
| Region + literal + kind07 | 0.042856 | 0.037776 | 2.299 |
| TypeScript | 0.001756 | 0.001707 | 0.756 |

Literal shifts improve the longer-warm median another 1.648× compared with
region05. Attempt06 and07 ranges overlap; the small median difference is not
evidence of a performance change from preserving callable kinds. Phase29 versus
attempt07, and region05 versus06, have disjoint five-sample ranges.

The screen intersects substantial lifecycle drift: region05's second halves are
14–15% slower, whereas literal06/07's are 17–19% faster. Both windows survive.
All confirmation halves differ by less than 2.96%, and every expected output
matches. This supports the longer-warm scoped comparison without claiming that
all programs, first calls or arbitrary workload sizes achieve the same speedup.

Raw results are `fixture-checked-screen-02` and `fixture-checked-confirm-02`, with
complete per-process stdout/stderr and adjacent launcher receipts. The screen
costs 11.788s end to end; confirmation costs 126.487s. Those outer durations describe
the iteration loop, not generated-program throughput. A selected full-iteration
Mandelbrot helper is useful for diagnosis; representative original-program
measurements remain a separate required transfer check.

## Actual lexical-helper compiler, attempt08

A new frozen plan, `fixture-lexical-plan-08`, compares actual checked emissions
of Phase29, attempt07, attempt08 and the pinned TypeScript compiler on the same
source and `[128,524800]` point. Attempts07 and08 have the same runtime bytes;
attempt08 changes private helper spelling from dictionary properties to lexical
functions. This is the compiler implementation of the earlier disposable
spelling experiment, not a modified output substituted for a compiler result.

The plan verifies checked emission, API, bootstrap, scoped validation and runtime
identities, and retains the actual08 independent admission, ABI, exact-entry and
lexical-name receipts. Those are distinct from the earlier disposable-prototype
controls. The maintained timing protocol and exclusive CPU3 conditions are the
same as above.

| Actual emission | Short median ms | Long median ms | Long sample range ms |
| --- | ---: | ---: | ---: |
| Phase29 | 0.428489 | 0.396238 | 0.394495–0.415475 |
| Attempt07 | 0.043913 | 0.037481 | 0.037166–0.038873 |
| Attempt08 | 0.013574 | 0.009997 | 0.009921–0.010193 |
| Pinned TypeScript | 0.001759 | 0.001705 | 0.001699–0.001726 |

Attempt08 is **3.749× faster than attempt07**, **39.635× faster than Phase29**,
and **5.862× slower than TypeScript** at this helper point. The sample ranges
are disjoint. Every long-run half differs by at most 1.69%. The short window has
large opposite lifecycle drift again: attempt07 improves 19–21% within each
process, while attempt08 slows 44–50%. Preserve the short result, but use the
long confirmation for the scoped ratios.

The finding is that lexical private functions allow much better optimized warm
code than calls through a private dictionary, despite identical primitive
expressions, guards and semantics. The experiment establishes the effect of
that spelling change; it does not independently identify a particular V8 pass
or prove that property lookup time alone explains it.

Raw results are `fixture-lexical-screen-08` and `fixture-lexical-confirm-08`, with
outer launcher costs 8.13 s and 84.72 s. The ten original libraries were also
reacquired and checked at `transfer-08`; their performance comparison remains
separate. The helper result must not be presented as a uniform speedup over all
generated programs.
