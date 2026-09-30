# Phase25 dynamic-evidence and claim-scope review

Result: no blocking issue found in the final report, reproduction guide, root
README addition or compiler-guide section. This review checks the report against
the final diagnostic acquisition and trace summary; it does not rerun benchmarks
or establish new conformance. The reviewer authored `diagnostics.mjs`, so this is
separate review of the root-owned report/acquisition, not independent authorship
of the instrumentation.

- Final dynamic claims use `diagnostics-02`: all18 processes exited0 and reported
  success. The first launcher's exit2 outcomes remain disclosed and excluded as
  healthy diagnostic outcomes. Instrumented timings do not enter clean ratios.
- Per-benchmark counters are correctly normalized from ten calls, independently
  of the different CPU/allocation repetition counts. The scalar, match/arguments
  and Boolean-worker values match the retained counts. The numeric-pattern
  constructor totals are8,481 =33×257 and33,792 =33×1,024.
- The report correctly treats73–87% runtime-frame CPU attribution as sampled
  evidence, not an exclusive causal decomposition or recoverable speedup bound.
  Allocation findings distinguish cumulative sampled allocation from retained
  memory; upstream counter zeroes do not establish allocation-free execution.
- The string-equality counterexample and Boolean-source reversal are retained.
  The proposed numeric-pattern and known-worker changes are hypotheses for
  separate ablations; no whole-kernel gain is promised from either alone.
- The reconciled trace summary contains eight exit0 processes, including the two
  retained original parser failures. All four candidate steady windows have zero
  deoptimizations; the five upstream events name the tracing harness `run`.
  Raw GC counts are not compared across unequal call counts.
- Microkernel execution, compiler throughput, module import and future full H
  behavior remain explicitly separate. Changing size and seed together is
  disclosed as input diversity; wide-pattern timed default-arm coverage is
  distinguished from special-arm correctness observations.
- The focused example's expected result24,132 matches the retained
  `pinned-u32-table-1` config. Its5.37s result includes calibration and timing
  processes but excludes building a compiler or re-emitting changed source.

The final claims are bounded by selected JavaScript programs and finite scalar
observations. Neither the report nor the new documentation presents this analysis
as a compiler optimization, a current full-H benchmark or expanded backend
conformance.
