# One repeated stop-set computation, and why it is not shipped

The typed driver computes `j_stops(contextBook)` to prune reachable definitions,
then computes it again for annotation using the same `contextBook`. The earlier
instrumented trace puts each call near100ms on the three selected sources. This
suggests reusing an existing local value rather than adding a normalization cache
or another IR. [Prospective experiment](../../design/phase32/compact-stop-reuse.md).

The private actual07 prototype wraps only the external stop-set API entry. Each
successful request must call it exactly twice with the identical book; the first
call computes the result and the second returns that value. Every request drops
the retained book/list afterward. All15 complete observations, dependencies and
output hashes match the previously verified original07 baseline. The13 successful
requests each avoid one computation; the two checker errors call it zero times.
The15.7s candidate acquisition peaks at434,848KiB. The reused baseline is explicit.

A fresh baseline/candidate/candidate/baseline screen includes the ordinary checked
library request. Each process primes small/Mandelbrot/edit distance, then executes
that triad once more. There are two timed observations per role/case:

| Source | Original07 median ms | Reuse prototype ms | Change | Ranges |
| --- | ---: | ---: | ---: | --- |
| Small |875.663|737.803|−15.74%|Disjoint|
| Mandelbrot |1313.232|1296.114|−1.30%|Overlap|
| Edit distance |1122.858|943.309|−15.99%|Disjoint|

The Mandelbrot candidate spans1087.44–1504.79ms and is not a demonstrated gain.
The screen's prospective requirement of at least3% on both larger programs
therefore **fails**, despite promising small/edit results. These are private
screen measurements, not a released compiler-throughput improvement. Raw evidence:
`selfhost/build/phase32/compact-stop-correctness-04/report.json` and
`selfhost/build/phase32/compact-stop-screen-04/report.json`.

There is also a concrete correctness boundary. Checking whether the caller
omitted `options.api` does not establish ownership: for checked B1, exported
`loadApi()` returns the imported module's mutable default object. A caller may
change its callbacks and later call ordinary `inspect()` without injecting an
API explicitly.

The proposed two-line conditional was tested as a saved driver derivative only:
record `ownsApi = api == null`, then use the existing stop list when `ownsApi`.
Six controls compare the original and conditional drivers with injected callback
observers, injected stop-list mutation, and mutation of the default-loaded API.
All injected cases retain this trace and produce identical successful outputs:

```text
stops → foreign check → stops → annotation receives a fresh list
```

For the default-loaded API, a wrapper retains the first stop list. The intervening
foreign-check wrapper marks that list as mutated. The original driver computes
a fresh list for annotation and succeeds. The conditional derivative instead
produces:

```text
stops → foreign check → annotation receives the mutated list → error
```

All six controls pass their exact expected traces; the intentional bad candidate
returns `P32_MUTATED_STOPS_REUSED`. Successful outputs all hash-match. This proves
the proposed ownership test insufficient; it is not a speculative risk. Evidence:
`selfhost/build/phase32/compact-stop-boundary-plan-05/report.json`, with the exact
rejected conditional patch in `changes.json`. The control peaks at440,712KiB RSS.

**Decision:** leave the production driver unchanged. A future source-only private
entry or capability proving immutable, unexposed compiler functions/data could
make the one-value reuse legitimate, but that architecture is outside this
bounded experiment. No public mutation behavior is weakened and no unmeasured
throughput gain is attributed to the Phase32 release.
