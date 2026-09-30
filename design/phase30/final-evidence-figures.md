# Reproduce final execution summaries and figures

Prepare the tool during the clean timing window, but do not import matplotlib,
load plotting libraries or generate artifacts until the lead releases it. This
is analysis of retained results; it must never run a compiler or benchmark.

`inspect-final-figures.py CONFIG NEW_OUTPUT` consumes an explicit final attempt
manifest, the ten final original-program comparison reports, the final helper
scaling report and its final-image checked emission receipt. An optional input
is the existing actual11-to12 tree operation-count report. Optional historical
timing reports carry explicit labels and remain in a separate summary section;
they never enter final figures or combine with final ratios. Paths in CONFIG
are relative to that file unless absolute.

The tool verifies hashes of the primary reports, their configuration/module
identities, successful complete observations and exact expected outputs. It
recomputes per-call medians and extrema from the samples and cross-checks the
stored summaries. For each original program it verifies that all three checked
emission receipts name the same source and that the candidate receipt belongs
to the selected final attempt/API/runtime/Base. The scalar receipt must likewise
belong to that attempt and match the exact measured candidate bytes. If the
scaling window measured an earlier compiler image that emitted byte-identical
code, preserve that measured image identity and report the separate final-image
byte-equality evidence; never silently relabel the earlier acquisition.

Each side retains median/minimum/maximum, every timed sample, first-call values,
import times, peak RSS, repetition counts and each timed half's call count and
duration. A half-drift percentage compares time per call, allowing uneven half
sizes. A single-call timed sample has no half-drift estimate; record null instead
of inventing zero drift. Same-window ratios use the three side medians from the
same case/report. No previous isolated gains are multiplied into a final ratio.
Keep ratio directions explicit, including candidate/TypeScript slowdown and
Phase29/candidate improvement. Do not calculate an unexplained overall average.

Write machine-readable JSON, a side-level CSV and a sample-level CSV. Include
window/report/config/module/source hashes, selected compiler identity, protocol,
all warnings and the plotting tool/environment identities. Preserve incomplete
or inconsistent input as a failed generation receipt instead of drawing a
partial figure from the surviving cases.

Generate standalone SVG and PNG with matplotlib's noninteractive Agg backend:

1. Grouped log-axis bars of Phase29 and final candidate execution time divided
   by same-window pinned TypeScript execution time, for all ten original points.
   Mark TypeScript's1× reference. Error bars are conservative ratios of sample
   extrema, not confidence intervals. Mark windows with absolute half drift
   above10%; display the exact drift values in the tables.
2. A separate helper-only cost-versus-iteration figure for0,128,1024,8192, using
   the same fixture source and seed524800. Use an explicitly labeled symmetric
   log x-axis so zero remains visible and a log cost axis. Show sample min/max;
   connecting lines are guides only. Zero follows a different real branch, so
   do not fit or assert a common affine intercept. A finite difference between
   medians at1024 and8192 may be reported separately as an estimate per added
   iteration, without extrapolation to other programs or compiler throughput.
3. If requested, a separately labeled historical actual11→12 chart of named
   administrative event counts for original `bench(2,0)`. Aggregate guard-entry
   dictionary counts explicitly; keep all other named counters separate. These
   are instrumented event counts, not CPU shares, total allocation counts or
   final-image performance.

Use readable labels, units, input-point scope, image/window identities and
captions. Save source text as selectable SVG text. Record matplotlib/Python
versions and source hashes, include a standalone generated report with tables
and figure links, and recheck consumed inputs after writing the figures. The
lead owns the final campaign narrative and decides which figures to link there.

Configuration template (fill exact final paths after measurement):

```json
{
  "candidateManifest": "../attempt-13/attempt.json",
  "originalReports": ["../final-original-mandelbrot/report.json"],
  "scalingReport": "../scalar-scaling-confirm-13/report.json",
  "scalingCandidateReceipt": "../final-scalar-source-13/candidate.mjs.json",
  "treeCounts": "../tree-compiler-counts-12/report.json",
  "historicalReports": []
}
```

The originalReports list must contain all ten distinct original case IDs; the
one-item example above is a placeholder, not an executable final configuration.
