# Fresh installed profile and list-removal census

API44094e58 passes the unchanged full-source check observation: typing succeeds
and trust refuses the1660 unsafe definitions. The CPU0 Node24.18 profile and
separate counter probe both close normally. No compiler source, installed image
or cache changed. [Exact receipt](installed-profile.json) binds the tools, raw
profile, failed first counter attempt and successful correction.

The current profile assigns13.72% of exclusive signed sample time to run_loop,
9.47% to GC,2.96% to validateSpanBook,2.95% to f_eq,2.89% to index_remove,
2.17% to dn,2.09% to f_find and1.61% to lookup. These are concurrent diagnostic
samples, including startup and input verification, not a controlled benchmark.
One negative10µs delta remains in the raw profile and signed totals. Physical
caller stacks identify book_put for28 index_remove samples and leave280
unattributed; the counter experiment resolves that limitation.

| Removal caller | Calls | Nonempty cells visited | Retained Con sites | After first removal |
| --- | ---: | ---: | ---: | ---: |
| Cached book_put | 3,674 | 7,276,076 | 7,272,402 | 780,500 |
| Index leaf | 25,451 | 5,175 | 0 | 0 |
| Uncached book_put | 0 | 0 | 0 | 0 |
| Short-book final selection | 0 | 0 | 0 | 0 |

Every cached replacement removes exactly one definition in this workload; its
largest input has2194 entries. Index buckets contain at most one entry here,
so collision handling is not the source of this rebuilding. The retained
suffix is10.73% of retained construction sites; most rebuilt cells precede the
replacement. Counts denote executed source construction expressions, not V8
heap objects: JIT escape analysis may eliminate physical allocations.

The smallest next experiment is an explicit Bool worker for the existing filter,
preserving full duplicate removal, list order and demand. It may remove generated
branch closures/dispatch, but2.89% is only directly attributed sample time; shared
GC and run_loop cannot be assigned wholesale. Stopping at the first match needs
a stronger uniqueness invariant than the public filter promises, and would still
leave most rebuilding. No speed gain is established by this report.

Hash update accounts for6.57%, but6.44 percentage points belong to the measurement
worker's identity verification outside the request. Only0.0914 points directly
show validateSpanCache,0.0182 host hashing and0.0181 module evaluation. This
profile does not justify removing cache validation or claiming6.57% compiler
request savings.

Counter attempt01 passed the module namespace where the host expects its default
API object, correctly failed the complete observation assertion, and remains
failed. Version02 changes only that injection and saves the raw result before
assertions. Its complete driver observation equals the ordinary baseline after
excluding the adapter-only provenance field. The counter artifact is explicitly
instrumented, not a checked production image; the unchanged current Base cache
is an input under the host's existing explicit API-injection interface.

The previous controlled10.95s compiler process and observed35.17s checked-build
plus36-control loop measure different work. The latter includes pinned TypeScript
bootstrap and validation, so a faster Bend request would not shorten the entire
edit loop proportionally. No heap profile was needed to identify this caller.
