# Final execution evidence report template

This is a preparation template, not a measured result or release statement.
The generated report from `inspect-final-figures.py` will fill the final image
identity, exact retained timing windows, measured tables and figure links.

Selected final compiler: **[attempt and API/runtime/Base hashes]**.
Original-program windows: **[ten explicit report paths and hashes]**.
Helper scaling window: **[report path, measured image and final-image byte-equality
receipt if these are different acquisitions]**.

![Final original-program TypeScript slowdown](original-program-slowdown.svg)

Caption: complete exported original-program points, fresh rotating serial CPU3
processes and the retained transfer protocol. Ratios compare sides within each
program's own window. Sample-extrema envelopes are not confidence intervals;
marked windows retain their observed warmup drift. These selected points are not
a production-workload distribution or a compiler-throughput result.

![Scalar helper cost by iteration count](scalar-helper-scaling.svg)

Caption: separate checked scalar fixture, seed524800 and counts0/128/1024/8192.
The zero branch is real and different. Connecting lines do not assert an affine
cost model. Report the1024-to8192 finite-difference estimate separately, if used.

Optional historical mechanism figure: actual11→12 named administrative event
counts. State its exact input and instrumented module identities. These events
are not CPU shares, final-image counters or total heap allocations.

Attach `summary.json`, `summary.csv`, `samples.csv` and the generation receipt.
Keep superseded or longer-warm historical windows under their own explicit
labels. Do not multiply their ratios or substitute them into final-window rows.
