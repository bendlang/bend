# General compiler demand and projection ablations

Four checked compiler versions isolate the local-data optimization. All use the
same public record and Array representations and keep generic public callback
fallbacks. The preserved [prospective plan](../../design/phase31/local-data-ablation-timing.md)
compares actual compiled output on the complete canonical edit-distance pair and
a structurally different one-array fold. These are compiler implementations,
not the earlier handwritten JavaScript prototypes.

- Checked04 proves a closed private helper graph and bypasses generic calls.
- Checked05 completes private returns eagerly, preserving demand order. Using
  the ordinary non-tail emitter also adds force to formerly tail private calls;
  this cost is deliberately visible in the ablation.
- Checked06 removes force from private calls whose returned values are proved
  already complete. Public forcing remains.
- Checked07 directly reads the known local record/Tuple fields, retaining fresh
  parameter aliases and their order. It eliminates projection/slice/spread;
  ordinary storage, native operations and record construction remain.

Each step freshly emits the exact fixed pair source and distinct fold source.
Primary controls compare six pair indices against a BigInt oracle, complete
physical arrays and all 328,966 native operations, plus 17 public mutation/entry
cases. The fold covers 40 scalar points through n257 and two delayed-write fault
witnesses; n4096/seed17 additionally passes on all six timed compilers with result
2339999928. Independent reviewers check full pair schedules, constructor marker
hooks, aliases, nested records and private worker ASTs before timing.

At checked07, the original diagnostic observer fails because the optimized
program no longer calls `project(Dp)`. The failed run and old tool are retained.
The declared replacement captures original allocation handles instead; after
256 even rows physical IDs1/2/3/4 are a/b/prev/cur, and the exact native schedule
independently requires the final distance read from ID3. The revised observer
passes on unchanged program bytes. This is a measurement-tool correction, not
an ignored result mismatch.

Separate instrumented complete-pair counts:

| Operation | Checked04 | Checked05 | Checked06 | Checked07 |
| --- | ---: | ---: | ---: | ---: |
| Generic apply | 1 | 1 | 1 | 1 |
| Force entries | 65,797 | 328,453 | 1 | 1 |
| Project | 328,450 | 328,450 | 328,450 | 0 |
| Build | 65,792 | 0 | 0 | 0 |
| Ctor | 66,049 | 66,049 | 66,049 | 66,049 |
| Fn / partial / jump | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 |
| Root guard | 1 | 1 | 1 | 1 |

All retain four allocations, 262,401 reads and 66,561 writes. These counts identify
removed work, not its CPU share. Instrumented modules never enter timing. Full
receipts and consumed tools are under `selfhost/build/phase31/local-data-*`.

The frozen two-case/six-role plan is `local-data-ablation-plan-01/transfer.json`.
It uses unchanged five-sample original-program transfer rules: fresh processes,
rotating variant order, CPU3, at least three warm calls and one second of warmup,
then a calibrated 300ms measurement target. The exclusive comparison completed
in 121.36 seconds, including its launcher. All results and input identities are
in `local-data-ablation-transfer-01/report.json`; its raw inputs include the
actual emitted modules, original baselines and independent correctness receipts.

## Actual compiler speed

Milliseconds per complete operation; brackets show the range of five fresh
process samples. These timings use ordinary uninstrumented generated modules.

| Compiler | Full 256 × 256 pair, p0 | One-array fold, n4096 / seed17 |
| --- | ---: | ---: |
| Installed17 | 490.4827 [482.5796–490.7654] | 11.93035 [11.79824–12.20136] |
| Checked04: closed local calls | 61.5286 [60.6409–62.5624] | 1.97108 [1.94662–1.98623] |
| Checked05: completed private returns | 45.6756 [45.3344–46.0850] | 1.37150 [1.35489–1.42322] |
| Checked06: remove redundant force | 44.9537 [44.8340–45.3969] | 1.33568 [1.32630–1.38964] |
| Checked07: direct known-field reads | 16.8592 [16.5660–17.3913] | 0.67510 [0.67163–0.68525] |
| Pinned TypeScript | 1.23401 [1.21986–1.26479] | 0.039891 [0.039142–0.040178] |

Checked07 is **29.09× faster than installed17 on the full pair**, with a remaining
**13.66× TypeScript gap**. The independent fold is **17.67× faster**, with a
**16.92× TypeScript gap**. These are two local-array kernels, not a claim about
all programs or compiler self-compilation. The earlier setup-heavy one-row
prototype and checked04-only comparison remain separate measured windows.

Completing private returns saves 25.76% on the pair and 30.42% on the fold, even
though that first implementation increases redundant force calls. Removing the
forces gives only an apparent 1.58% and 2.61% additional improvement, with
overlapping sample ranges; this window does not establish those small increments.
Direct field access saves 62.50% on the pair and 49.46% on the fold relative to
checked06, with disjoint ranges. Avoiding the generic projection's copy and
spread is the largest measured incremental improvement after closing the call
graph. It does not eliminate record or native-result allocation.

Half-sample drift limits the interpretation. Checked07 pair halves vary by
+0.60% to +6.99%; its fold halves consistently improve by 8.95% to 9.62%, so the
fold is still warming after this protocol's one-second minimum. The large gains
and field-access ablation remain disjoint, but these numbers are protocol results,
not fully settled steady-state estimates. Other pair variants stay within 2.55%
where two halves exist; installed17 takes one timed call per sample, so it has
no within-sample drift statistic. Checked05/06 fold include +6.92%/−7.71% outliers,
which reinforce the caution about their small overlapping increment.

## Final regression canaries

The final confirmation uses five fresh samples, at least 100 warm calls and
three seconds of warmup, with the same CPU, rotating order and 300ms measurement
target. `canary07-confirm-01/report.json` completed in 187.35 seconds including
its launcher, immediately after the ablation in the same exclusive window.

| Canary | Installed17 ms | Checked07 ms | Change | TypeScript ms |
| --- | ---: | ---: | ---: | ---: |
| Scalar region, zero loop work | 0.004535 | 0.004717 | +4.01% | 0.0000965 |
| Scalar region, n8192 | 0.136819 | 0.137732 | +0.67% | 0.098795 |
| Complete generic row, n32 | 0.419449 | 0.440599 | +5.04% | 0.008402 |

The zero-work and generic-row sample ranges are disjoint: respectively
0.004495–0.004556 versus 0.004687–0.004752ms, and 0.414574–0.424166 versus
0.437380–0.448807ms. These are measured regressions, so this candidate does not
earn a blanket no-regression claim. The n8192 ranges overlap
(0.136212–0.137510 versus 0.137274–0.138496ms), and all selfhost samples at that
point retain about 2–4% within-sample warming; the small difference is unresolved.
The generic-row candidate is stable within −0.55% to +0.53% between halves,
versus −2.81% to +2.23% for installed17. Zero-work candidate drift is
+0.99% to +2.32%, similar to installed17. The longer protocol resolves the
earlier severely warming generic-row screen rather than erasing its result.

The generic row intentionally returns a public Dp container and therefore does
not enter the private scalar-result region. Its regression needs separate
explanation. Extra guard work or module-wide exact-call registration are
hypotheses at this point; the current controls do not isolate them. A subsequent
[frozen one-change diagnostic](generic-registration-diagnostic.md) isolates an
unused exact-call registration and reproduces 96.97% of the generic-row excess
time in its own long-confirmation window. That result explains the tradeoff
without changing or weakening checked07's public entry safety.

The original no-material-regression criterion remains failed. Any checked07
promotion follows the explicit [admission amendment](../../design/phase31/admission-tradeoff.md)
as a known tradeoff, subject to the remaining release gates; it is not recorded
as satisfying the original performance condition.

## Next hypotheses, not implemented here

1. Emit ordered local declarations for return-position record unpacking. The
   checked07 worker still creates an immediately invoked arrow around direct
   field reads. Straight declarations could shorten generated code and make
   optimization easier, although V8 may already remove that function. Preserve
   fresh aliases and left-to-right field demand; compare this alone before any
   allocation change.
2. Fuse a known native-result producer with its private consumer. The complete
   pair still produces 262,401 Array.get result tuples. A private worker whose
   final parameter is such a tuple could accept its array handle and scalar
   value directly, avoiding the tuple allocation. This needs a new proof of
   argument evaluation order, delayed demand and alias preservation, and the
   same full native schedule and hostile public-boundary controls. The current
   counter results identify an opportunity, not its achievable speedup.

Both are general compiler transformations; neither requires changing the Bend
algorithm or public runtime representation. Original-program throughput,
compiler emission cost and broad conformance remain separate release gates
owned by the phase report.
