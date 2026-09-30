# Separate scalar entry cost from loop cost

The selected helper's absolute TypeScript ratio includes a live-closure guard and
public entry. It does not directly measure the cost of one private loop iteration.
Before choosing another numeric representation or larger lowering pass, compare
the same checked helper at 0, 128, 1024 and 8192 iterations. Use the existing
center seed 524800, which decodes to cr=ci=0: the independently visible recurrence
keeps zr=zi=esc=0 and increments the U32 result once per iteration. Every expected
result is therefore the supplied iteration count in this bounded set.

Compare immutable Phase29, actual Phase30 checked output and pinned TypeScript
emissions of exactly the same fixture, verifying checked receipts and source/Base
identity. Use the maintained five-sample confirmation protocol on each point.
The old8192 point is still suitable for this protocol; preserve timeouts or drift
rather than silently lowering its call floor. If that premise fails, stop and
freeze an amended protocol separately. No runtime instrumentation or deleted
guards belong in these timed files.

Report absolute medians/ranges and timed halves at every size. A difference in
medians between8192 and1024 can estimate incremental cost per additional loop
iteration, but label it as a finite-difference estimate, not a CPU attribution or
confidence interval. The zero point has its real branch behavior; it is an entry
cost control, not a promise that all nonzero costs decompose into one affine line.
Do not extrapolate the measured slope to compiler throughput or other programs.

This investigation changes no compiler code. Freeze its config after the final
candidate choice so its image labels cannot silently move during measurement.
