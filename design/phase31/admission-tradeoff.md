# Phase31 admission amendment after the final canary

This amendment is written after checked07's frozen long canary and before the
registration diagnostic and original-program/cost comparisons complete. The
original final-integration design and all consumed plans remain byte-identical.

The original P31-002 criterion required no material generic/scalar regression.
Checked07 does **not** satisfy that criterion: zero-work scalar entry regresses
4.01% (about0.18 microseconds), and a complete generic row regresses5.04%, both
with disjoint ranges. This is a failed performance condition, not failed semantic
correctness and not a no-regression pass. The actual full pair and separate fold
improve29.09× and17.67× under their frozen protocol.

Static inspection finds two costs. All private entries now validate Array
prototype markers, including array-free Sigma; weakening that check has an
independent semantic counterexample. Separately, the old row module contains no
registered exact workers. The new module registers pair and batch, so all its
generic calls perform the existing WeakSet membership check even when row.probe
does not invoke either root.

The [registration diagnostic](generic-registration-diagnostic.md) tests that
second explanation by adding one unused valid registration to old output. It
retains complete arrays, aliases and public boundaries. Neither unsafe guard
removal nor a hidden runtime-marker property is proposed for production.

If that controlled experiment supports attribution, the root may select07 as
an explicit speed/coverage tradeoff, subject to original-program transfer,
separate compiler-cost measurement and all correctness/release gates. Such a
selection supersedes the original performance criterion; reports must state the
exception and both regressions prominently. If attribution fails, keep promotion
held while investigating. Broader measured regressions require their own review
and cannot be excused by this row diagnosis.

The rationale is user-directed generated-program improvement with maintained
correctness and limited complexity. Adding a new descriptor ABI or speculative
cache merely to hide a small entry/fallback cost would need a separate proof and
measured benefit. Those changes are outside this amendment. Future work should
include modules mixing generic and specialized code, because absence-of-worker
canaries alone miss the registration cost.

## Decision after the remaining measurements,2026-09-30

The registration diagnostic meets its frozen criterion and explains96.97% of
same-window row excess. Original edit distance improves26.83×; Mandelbrot and
RLE retain their prior performance in the measured window.

Normal checked edit-distance compilation adds107.770ms (+6.90%) with disjoint
request ranges. The root explicitly accepts this additional compiler-cost
regression alongside the entry/fallback tradeoffs: the measured four-pair output
saves about1,830ms per execution. This is a workload-specific utility decision,
not a compiler-throughput improvement or a universal break-even guarantee.
Mandelbrot request ranges overlap, so its +0.73% median shift is unresolved.

Selected07 remains subject to all correctness/release gates. Preserve the
original failed performance condition and all frozen inputs. The
[final measurement report](../../implementation/phase31/final-measurements.md)
retains all timing boundaries, original-program drift and complete output hashes.
