# Confirm private tree frame reuse after longer warmup

The frozen frame-reuse screen passed every output check. Its original-program
median improved from 0.376582 to 0.361615 ms, but the baseline and candidate still
had different within-process drift. The earlier actual12 tree experiment also
needed longer warmup before its whole-program rate stabilized. Keep the short
screen unchanged; it is screening evidence rather than settled throughput.

Before execution, freeze a separate comparison of the same checked actual12
baseline and the same disposable frame-reuse output on original Mandelbrot
`bench(2, 0)`, expected `887240761`. Bind the original derivation, full-state,
boundary and mechanism-control receipts and both exact uninstrumented modules.
No source, emitted output, case, input, result check or intrinsic assumption
changes. Do not include the depth-five wrapper in this follow-up.

Use the existing separately derived `tree-compiler-plan-12` longer-warmup
comparison and launcher without editing them: three independent samples per
variant, at least 15 seconds of warmup with a three-call floor, 100 ms calibration
and a one-second measured target. This keeps fresh processes, rotating serial
CPU3 order, complete per-invocation output checks, first-call observations, both
measured halves and complete process receipts. Hash the exact derived runner,
launcher, execution helper, configuration and origin files in the new plan.

Run only under the parent's exclusive timing grant. Report medians, ranges and
both-half drift even if the longer warmup does not settle the measurement. Do
not alter the retained short screen, current maintained timing protocols or
earlier actual12 comparison. A positive result here concerns private frame
storage lifetime on this one program; it does not by itself authorize production
integration or establish a representative-program gain.
