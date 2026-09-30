# Generated H versus the genuine checked parent on one small request

The separately granted clean comparison passes. On the frozen small checked-
library request, H's median two-call trial mean is **7,609.354ms**, versus
**1,460.836ms** for the genuine TypeScript-produced parent of the same Bend
compiler: **5.2089× more request time**. Trial-mean ranges are disjoint.
This compares two JavaScript implementations of the same Bend compiler source;
the reference is **not the upstream compiler written in TypeScript**.

One warm request was fixed in advance. The parent still becomes11.11–11.51%
faster between its two timed requests, while H becomes4.39–5.92% slower. The
consistent fresh-process difference establishes this warmed-once protocol's gap,
not converged throughput or a ratio for every compiler workload. It does not
identify the fractions spent in generated dispatch, records, ABI or cache work.

All values below are milliseconds. Fresh-process trials alternate parent/H,
H/parent, parent/H; the table groups the two sides within each trial.

| Trial | Implementation | Warm | Timed1 | Timed2 | Two-call mean | Timed2 versus1 |
|---:|---|---:|---:|---:|---:|---:|
|1| Genuine checked parent |2219.822|1549.640|1371.290|1460.465|−11.51%|
|1| Generated H |9151.217|7494.368|7823.181|7658.775|+4.39%|
|2| Genuine checked parent |2206.349|1548.490|1373.182|1460.836|−11.32%|
|2| Generated H |9099.578|7390.448|7828.260|7609.354|+5.92%|
|3| Genuine checked parent |2211.491|1549.755|1377.544|1463.649|−11.11%|
|3| Generated H |9007.557|7359.341|7767.052|7563.196|+5.54%|

Parent trial means range1460.465–1463.649ms; H trial means range7563.196–
7658.775ms. These are sample extrema, not confidence intervals. Peak observed
child RSS is429904KiB for the parent and502756KiB for H. No90-second child
deadline fired; all six children exited0 without a signal or captured host error.

The measured boundary is normal `D.inspect(source,{mode:'library',api})` with an
already loaded API. It includes discovery, checking, emission, normal cache
reads/validation and H's real positional-to-named ABI adapter. Import, ABI
validation, separate Base preparation and output hashing/persistence are outside
the request timer. Node24.18.0, exclusive CPU0, 4MiB V8 stack and8GiB heap allowance
are identical; the heap allowance is not an RSS cap. No other acquisition or
benchmark ran during this slot.

All **18 outputs**—six warm and12 timed—match the independently retained hash
`0266dc1197e354ddf3eb0652c95c7cbea2f071fd587ff325b22cd515accfad25`.
Preparation separately executed this Nat/U32 program to8 on both implementations
and bound genuinely validated caches under each actual API hash. Cache bytes
remain unchanged before/after each trial. Source/fixture identities come from
the [bounded self-emission](bounded-self-emission.md).

Compared compiler identities:

- Genuine parent: `60aa968ffcedb7a02a220b58a51396dd036d0d8b1f39f1b3def3f6b4248d6469`.
- Original H: `21b53c697c7dce78bb2d7ee2977dc77659fc9f9c66878f54106a8509987001ab`.
- Same Bend source: `678bafd61cff715c3ee2012ef3840ddfe99a2aeb1d81b5345fb3c6e6bfc1757e`.

Canonical evidence under `selfhost/build/phase30/` is
`generated-compiler-cost-plan16b/plan.json`,
`generated-compiler-cost-prepare16b/report.json`, and
`generated-compiler-cost-measure16b/report.json`, including every child request,
worker report, log, cache identity and consumed tool. The earlier
`generated-compiler-cost-prepare16` pipe-capture EPERM failure and consumed worker
remain retained;16b switched only tiny-program capture to the reviewed file-
descriptor method before obtaining this measurement.

H remains an experiment artifact. This result does not install it, establish a
fixed point, renew full H conformance or measure historical self-emission speed.
The next useful discriminator is separate untimed phase/ABI attribution; the
adapter already uses cached lazy views, so whole-graph copying cannot simply be
assumed. P30-030's prepared registration-free dispatch experiment is another
isolated hypothesis, not a cause established by this measurement.
