# Phase28 prospective warmup follow-up

Recorded 2026-09-30T05:17:24.487553+00:00.
Selected all four cases the audit flagged for repeated greater-than10%
within-block changes; selection occurred after the original results.

Frozen after the first nine library cases completed and before any longer-warm
acquisition. The original raytrace and application timing remain in progress.
No compiler, fixture, argument, output or original harness bytes change.

Independent readback finds consistent within-block changes in four cases:
selfhost Mandelbrot's second half is about15% slower, tree-bitonic about40%
slower, morning about15–21% faster, and four Map/Set samples about59–64% slower.
All correctness, input identities and timing arithmetic pass. These measurements
remain valid for their stated window; they do not establish stabilized throughput.

After the complete original campaigns, repeat ALL four flagged cases, in order
mandelbrot, tree-bitonic, test-morning-program, test-map-set-ops. Preserve exact
source/module/argument/oracle bytes. Change only warmup to at least100 calls AND
3000ms; keep the300ms calibration target,1M cap, five fresh processes per side,
alternating serial CPU3 order, Node24,4MiB stack,1GiB heap and120s deadline.
Record mechanically derived runner/launcher bytes and parent hashes. Do not edit
the running original harness, discard samples or pool the two protocols.

The check asks whether increased warmup changes those ratios and reduces the
observed phase changes. It does not promise JIT convergence or prescribe100 calls
for the expensive ray tracer. Report both windows, actual durations, remaining
drift and first-call results. If drift persists, retain that limitation explicitly.
