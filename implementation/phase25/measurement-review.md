# Phase25 independent measurement review

**No blocking flaw was found in the completed paired acquisition or runtime
comparison.** The large observed gaps survive inspection of the raw samples,
normalization, generated identities and result checks. They measure warmed
execution of these generated benchmark exports, **not compiler throughput or the
speed of a complete self-emitted compiler**.

Review scope: read-only inspection of `campaign.py`, `emit.mjs`, `execute.mjs`,
`corpus-01`, `calibration-01` and `timing-01`. This reviewer authored the corpus and
its scalar specifications, but did not implement or run the root-owned emission,
calibration or measurement harness. No compiler, benchmark or CPU3 diagnostic was
rerun during review. The [machine audit](measurement-review.json) records exact
checks, the raw timing report hash and all 45 point summaries.

## What was verified

- All 23 source pairs completed checked emission, producing 46 retained modules.
  All 127 selected observations per side match their independent expectations and
  their peer exactly, including all 45 benchmark points.
- All **450 comparative samples** completed with exit 0, no recorded runtime
  failure, empty stderr, the declared Node flags and CPU3 affinity. No failed or
  outlying timing sample was omitted. There are five samples per side per point.
- Every retained timing checksum independently recomputes to
  `expected * repetitions mod 2^32`. The harness additionally checks every single
  result is an exact U32 scalar and equals the expected result inside the loop.
- Every timed module hash still matches its observed identity. All captured
  acquisition inputs remain unchanged. The timing report binds the exact frozen
  schedule, which binds the exact corpus manifest. Each repetition count matches
  the schedule for that side.
- The prescribed order alternates upstream/selfhost versus selfhost/upstream
  across the five repetitions. Root campaign child intervals do not overlap.
  The recorded comparative window is **2026-09-30 00:35:13–00:38:37 UTC**.
- Recomputing medians from every raw sample, then normalizing by each side's own
  repetition count, reproduces every reported ratio. The comparison does not
  incorrectly divide totals from unequal iteration counts.

## Timing boundary and calibration

Compilation is outside execution timing. Module import, warmup and overall process
wall are recorded separately. The timed loop includes the exported generated
function, its input construction, all kernel work, scalar type/result assertions
and checksum accumulation. It is a warmed **public export call** measurement,
not an isolated inner operation or a pure allocation measurement.

Each fresh child warms the selected input for **at least 100 ms and eight calls**.
Actual warmup counts range from **8 to 556,184**, and durations from **100.0 to
638.1 ms**. The corpus uses one constant size/seed point within each child; the
optional alternating-input facility was not selected. This is valid for the stated
repeated-input workflow, but does not establish performance under a changing
compiler workload, cold startup, or a particular steady-state JIT tier.

Calibration is retained separately and never enters the comparative samples.
Different per-side repetition counts were prospectively selected to target 150 ms
and frozen before measurement. Counts remain constant across each side's five
samples. Different warmup/iteration histories can produce different JIT and GC
histories; that limit is explicit. The comparison is not an equal-work-duration
memory experiment. Peak RSS includes import, warmup and timing and must not be
presented as kernel allocation volume or live-heap size.

Actual comparative blocks last **54.03–227.39 ms**, within the prospective
approximately 50–250 ms target. The minimum is the upstream trivial control,
which reaches the one-million-call cap. None of the headline gaps arises from a
sub-millisecond reference block or timer resolution. No manual collection or
profiler/counter instrumentation is present in these timing children.

## Findings that survive the raw-sample challenge

Values below are medians of time per public `bench` call, in microseconds.

| Point | Upstream-generated | Our-generated | Observed ratio |
|---|---:|---:|---:|
| Host boundary, size 0 / seed 17 | 0.0542 | 0.1323 | 2.44× |
| String equality, 256 / 17 | 523.97 | 603.64 | 1.15× |
| String equality, 1024 / 18 | 2,136.41 | 2,236.43 | 1.05× |
| Boolean choice, 256 / 17 | 32.23 | 418.18 | 12.98× |
| Boolean worker, 256 / 17 | 1.425 | 540.06 | 378.90× |
| Boolean worker, 1024 / 18 | 5.605 | 2,902.46 | 517.85× |
| Pinned U32 table, 32 / 17 | 0.3016 | 531.18 | 1,761.26× |
| Pinned U32 table, 256 / 18 | 1.9306 | 2,737.44 | 1,417.89× |
| Pinned U32 wide match, 256 / 17 | 0.9388 | 1,348.69 | 1,436.63× |
| Pinned U32 wide match, 1024 / 18 | 3.6397 | 5,801.53 | 1,593.94× |

The observed minimum-selfhost/maximum-upstream envelopes for the four numeric
pattern points remain **1,363× or larger**. The envelopes are extrema of these
samples, not statistical confidence intervals. The smallest numeric-pattern
lower envelope is still well above the largest ordinary-point upper envelope
(approximately 587× for the Boolean worker). Thus numeric pattern lowering is
robustly the largest ratio family in this selected corpus. Close ordering within
that family or among ordinary cases should not be overinterpreted.

Many ordinary points are approximately 20–200× slower, but that phrase must not
hide the actual range: membership includes a 6× point; closures/choices are around
13–15×; scalar arithmetic reaches 234×; Boolean workers reach 518×. String equality
is **near parity within 5–15%**, not identical speed. No universal generated-code
factor or geometric average over this hand-selected corpus is justified.

The trivial control's approximately 54 ns versus 132 ns exposes an ABI/host floor.
It cannot explain hundreds or thousands of microseconds of added runtime in the
other cases. Do not subtract it numerically: it is another independently compiled
program with potentially different inlining/JIT behavior. Its presence strengthens
the diagnosis that large gaps are inside emitted work while leaving tiny-kernel
absolute ratios boundary-sensitive.

## Source equivalence, workload shape and attribution

The Boolean-choice and Boolean-worker sources implement the same recurrence:
return the seed at zero; otherwise add 3 to an even accumulator or 5 to an odd
one, with U32 wrapping, and decrement Nat fuel. Their correctness points and
runtime inputs match. The explicit worker is much cheaper in upstream output but
is slower in our output on these points. This supports investigating emitter
scheduling, arity and dispatch rather than assuming that a source-level worker
pattern that accelerates upstream-built B1 also accelerates self-emitted code.
The source pair is a mechanism comparison across separately acquired points;
the timing evidence alone does not assign all of the contrast to one instruction.

The two benchmark points generally change **both size and seed**. They are two
workload observations, not a controlled scaling ladder. In particular:

- Membership changes from a full miss at size 32 / seed 17 to an early hit at
  size 256 / seed 18. Construction remains inside both calls.
- String hashing/scanning switches Unicode versus ASCII; string equality switches
  a late mismatch versus equality. These points do not isolate input length.
- The term substitution witness has binder-shadowing behavior dependent on seed.
- The wide-literal timing points use the default arm of the pinned matcher;
  special zero/wide/max arms are covered by correctness vectors, not by those
  timed inputs. The dense table includes its explicit arms and default behavior.

Input construction and repeated traversal are intentionally part of each export.
There is no basis here for saying one primitive operation alone is 1,700× slower.
Static emitted structure, operation counters and CPU/allocation diagnostics can
identify the mechanism, but those separate acquisitions must bind these exact
modules and preserve output checks. An associated hot pattern is not a measured
speedup from an optimization that has not yet been implemented.

The campaign's own logs establish serial sampling and the requested affinity.
They do not independently prove the absence of unrelated system work or resource
interference. Record root's coordination separately; do not upgrade this to
whole-machine isolation. Five samples on one machine are a bounded comparison,
not a cross-platform or statistical guarantee.

No compiler production source, ordinary release, native C output, backend
conformance total or self-emitted fixed point changes as a consequence of this
measurement. The current 2.985× compiler-checking ratio remains a different
measurement on a different program and must not be combined with these ratios.
