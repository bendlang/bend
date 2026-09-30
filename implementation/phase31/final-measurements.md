# Phase31 final07 measurements

The unchanged original four-pair edit-distance program is **26.83× faster than
Phase30-17**, while taking **14.28× TypeScript time**. All three original program
points and all18 normal checked-library compilation observations passed their
exact output checks. This is a controlled result for the named workloads, not a
universal generated-program or compiler-speed ratio.

The prospective [integration plan](../../design/phase31/final-integration.md)
and [frozen binding](../../selfhost/build/phase31/final-plan-07/plan.json) identify
checked07 API `d8f609c99b3acef932f90040d0c6152c96605493bef926e46f25559ac125029b`
and runtime `4121f338a7e4e115bae557343cd3d194a26ed26589bc47d82094969284181e10`.
The root granted one globally exclusive window: three serial CPU3 program
comparisons followed by serial CPU0 compilation-cost samples. Other builds,
profiles, acquisitions and packing were paused. All four commands finished
within their frozen bounds. Subsequent conformance acquisitions began only after
that window was reported closed.

## Original generated programs

Every row uses the original source, public export, documented-small argument
and complete expected result. Edit distance includes four independent256×256
pairs, all arrays/setup, batch combination and checksum; it is not the faster
private one-pair diagnostic. RLE is the small original round-trip program.

| Original program | TypeScript median ms | Phase30-17 ms | Final07 ms |07 time change vs17|07 / TS time|
|---|---:|---:|---:|---:|---:|
| Mandelbrot `bench(2,0)` |0.045421|0.212826|0.203686|−4.29%|4.484×|
| Edit distance `bench(2,0)` |4.959950|1900.374599|70.817425|−96.27%|14.278×|
| RLE `main.out()` |0.0005964|0.046524|0.045167|−2.92%|75.733×|

All three use the maintained transfer protocol: five rotating fresh process
samples per implementation, at least three warm calls and1000ms warmup,100ms
calibration,300ms timed target and120-second child caps. Exact return assertions
remain inside every invocation. Post-run checks verified all45 timed records'
completion, CPU3 affinity, warmup minima, first result and repeated checksum.
Original saved reference/candidate input hashes remain guarded by the harness.

| Program | Phase30-17 sample range ms | Final07 sample range ms | TypeScript range ms |
|---|---:|---:|---:|
| Mandelbrot |0.210693–0.241861|0.201120–0.210109|0.045321–0.046546|
| Edit distance |1895.980–1918.316|67.314–71.742|4.903755–5.107149|
| RLE |0.046293–0.046669|0.044878–0.045696|0.0005914–0.0006091|

Keep the drift observations with these ranges. The edit-distance baseline needs
only one timed invocation per sample, so it has no within-sample half comparison.
Candidate07 uses five calls per sample; its second-half per-call time increases
2.72–4.24%, median3.89%. Mandelbrot17 includes one sample whose second half is
9.06% faster; the candidate median half change is−0.68%. RLE TypeScript includes
one +7.53% half change; its median is+1.43%, while candidate median is−1.24%.
These are the prescribed finite-window results, not proven converged throughput.
The edit-distance gain is large despite these limitations. Small differences
must not be extrapolated to other programs or interpreted as an isolated causal
effect of a particular compiler edit.

Cold execution remains separate: median first calls (excluding module import)
for edit distance are TS25.674ms,17 2119.058ms and07 107.507ms. Mandelbrot first
calls are5.773/10.573/11.618ms; RLE0.514/3.241/3.190ms in the same order.
Module-import time, every sample and RSS remain in the raw reports. Improvements
in warmed Mandelbrot do not imply improved first-call latency.

Raw reports:
[Mandelbrot](../../selfhost/build/phase31/final-plan-07/original-timing-plan/mandelbrot-timing/report.json),
[edit distance](../../selfhost/build/phase31/final-plan-07/original-timing-plan/editdist-timing/report.json),
[RLE](../../selfhost/build/phase31/final-plan-07/original-timing-plan/test-rle-roundtrip-timing/report.json).
The corresponding launcher receipts retain28.618s,82.981s and28.670s campaign
walls. Other seven original programs were not renewed in this subset. The
separate zero-entry/generic-row regressions and registration experiment remain
visible in the [admission amendment](../../design/phase31/admission-tradeoff.md);
this table does not cancel those observations or establish no regressions.

## Normal checked-library compilation

The [cost campaign](../../selfhost/build/phase31/final-plan-07/compiler-cost/report.json)
passed all18 observations: two identical sources, three rotating fresh samples
per side, unchanged Phase30 worker,CPU0,4MiB stack,4GiB heap and180s child cap.
Normal `D.inspect(source,{mode:'library'})` includes each Bend image's existing
validated Base pipeline and lazy API loading. TypeScript uses its normal
`book_nil`/`book_load`/`book_valid`/`js_lib` sequence after explicit host imports.
No checking, emission, API or cache shortcut was introduced. All18 emitted files
were rehashed against independently acquired output bytes after the campaign.

| Normal request | TypeScript ms | Phase30-17 ms | Final07 ms |07 vs17|
|---|---:|---:|---:|---:|
| Mandelbrot |340.456|1777.163|1790.128|+0.73%|
| Edit distance |314.330|1562.096|1669.866|+6.90%|

Mandelbrot's17/07 ranges overlap:1774.165–1806.319ms versus1781.048–1794.959ms;
the small median difference is inconclusive. Edit distance's ranges are disjoint:
1559.113–1570.977ms versus1668.745–1671.242ms. Its normal compilation request
is measurably more expensive in this three-sample comparison. This acquisition
does not attribute the increase to an individual analysis pass.

Explicit host imports cost about270ms for TypeScript and15ms for either Bend
driver. Since Bend API loading stays inside the request, report both boundaries:

| Host import + normal request | TypeScript ms | Phase30-17 ms | Final07 ms |07 / TS|
|---|---:|---:|---:|---:|
| Mandelbrot |610.789|1792.502|1805.712|2.956×|
| Edit distance |582.463|1577.702|1685.218|2.893×|

Request-only07/TS ratios are5.258× and5.312× respectively. Those are different
workflow boundaries, not conflicting estimates of one stage. Full supervised
process medians additionally include startup,954-input identity validation,
output persistence and postflight checks:07 6399.371ms and6285.561ms, versus17
6385.902ms and6150.220ms. They are not ordinary CLI latency estimates. Candidate
median peak RSS is502,504KiB/501,040KiB;17 is501,968KiB/499,308KiB and TypeScript
484,896KiB/482,136KiB. All caches stayed validated and unchanged under the worker
protocol. The outer campaign completed in127.580 seconds.

The [machine-readable summary](../../selfhost/build/phase31/final-measurements-07/summary.json)
retains all statistics, half-drift observations and receipt hashes. These data
do not establish a new self-emitted H result, fixed point or broad backend
conformance. They measure the actual checked compiler's emitted programs and
its normal checked-library requests separately.
