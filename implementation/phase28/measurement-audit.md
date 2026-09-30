# Phase28 independent measurement audit

**PASS.** Independently reconstructed all 206 processes: 140 library timing samples, 28 checks, 28 calibrations and 10 complete application processes. All 8,650 window checks and 437 cross-window checks pass. No generated program or compiler was executed by this reviewer; this audit reads the saved raw evidence.

The [machine-readable audit](measurement-audit.json) records identities, every sample, recomputed medians/ranges/ratios, calibration counts, timed halves and preserved acquisition outcomes. No timing sample was removed or replaced.

## Checks performed

- Matched every report row to its raw launch JSON and stdout; checked empty stderr, successful exits, deadlines, Node binary identity, stack/heap flags and CPU3 affinity reported by every library child. Complete application launches use the recorded CPU3 taskset command; they do not instrument affinity internally.
- Verified exact arguments, complete first results, every timed/calibration checksum, fixed repetitions per variant, calibration doubling/stopping rules and the 300ms target formula. Recomputed all median/minimum/maximum values and both first-call and warmed ratios from raw values. First-call summaries use the five timing processes per variant, separately from check/calibration processes.
- Verified original warmup floors of three calls AND one second, follow-up floors of 100 calls AND three seconds, and that subprocess wall time covers the recorded import, first-call, warmup and measured work. A target duration is not a hard duration floor; expensive calls use one repetition, so those samples cannot provide two halves.
- Verified source bytes against pinned Git objects, appended wrappers, unchanged mixed tests/application, checked emission receipts, output/module hashes, Base, compiler API/runtime/driver and host identities. Follow-up configurations and emitted bytes match their original cases. The derived runner and launcher equal the prescribed byte transformations exactly.
- Found all planned launch directories and all 618 launch/stdout/stderr files. Every child interval is disjoint in the recorded campaigns; the original libraries finish before the application, which finishes before the follow-up. This is evidence of serial execution, not proof of isolation from unrelated machine activity.

## Warmup sensitivity remains visible

The follow-up was planned after the first nine cases, selecting all four with repeated greater-than-10% changes between timed halves. It preserves the original measurements. These are results after specified warmup windows, not demonstrated steady-state throughput. Five observations and observed ranges do not constitute statistical confidence intervals.

| Case | Original selfhost/upstream | Longer warmup | Candidate second-half / first-half, original | Candidate second-half / first-half, longer |
|---|---:|---:|---:|---:|
| mandelbrot | 1391.14× | 1271.44× | 1.152–1.157 | 0.989–1.002 |
| tree-bitonic | 111.39× | 100.38× | 1.384–1.415 | 1.107–1.143 |
| test-morning-program | 67.06× | 60.60× | 0.787–0.852 | 0.855–1.000 |
| test-map-set-ops | 107.32× | 82.37× | 1.000–1.644 | 0.825–0.873 |

Ratios between halves divide their per-call costs, including unequal half lengths. Longer warmup removes the greater-than-10% flag from all Mandelbrot samples. Bitonic retains a 10.7–14.3% slower second half in all five samples; morning retains one 14.5% faster second half; Map/Set changes direction, with all five second halves 12.7–17.5% faster. The phase changes are measured observations; this audit does not assign them individually to JIT compilation, garbage collection or another cause. The performance deficit remains large under both protocols.

## Distinct execution boundaries

The original ten library pairs all return their frozen expected complete scalar or string values. Their first-call ratios and warmed ratios are deliberately separate. Emission acquisition times are descriptive and excluded from these runtime comparisons; none of these runs measures self-emitted compiler H throughput.

The HVM mini application has exactly matching 42-byte stdout in all ten fresh processes. Its median whole-process time is 69.2099ms upstream and 200.9292ms selfhost, a 2.903185× ratio. That includes startup, the respective CommonJS/ESM loader, computation, output and exit. Emitted bytes are unchanged when the upstream host filename is corrected to `.cjs`. The printed normal form agrees with the embedded-program description; the 79-interaction count remains a differential oracle.

The two rejected raytrace wrapper attempts and the original HVM host-extension failure remain visible as acquisition outcomes (five failed variant processes across three failed attempts). Final paired inputs cover all eleven selected programs; there is no survivor-only aggregate. Benchmark checksums are the programs’ full observable outputs, not independent validation of every internal pixel or collection element. Tiny mixed tests, the Mandelbrot strip and fixed raytrace probe traversal retain their documented scope. This audit supports publishing the bounded comparison with its ranges and warmup caveats; it does not renew the full conformance inventory or claim a universal production-program ratio.
