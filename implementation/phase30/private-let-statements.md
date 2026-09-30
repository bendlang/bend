# Private scalar Let statement ablation

The [frozen design](../../design/phase30/private-let-statements.md) now has a
correctness-checked generated-JavaScript pair. A separate longer-warm original
program comparison confirms1.123× faster execution with stable timed halves.
Production promotion remains separate. No compiler or runtime source changed
for this isolated experiment.

The attempt12 original Mandelbrot module changes seven lexical helper copies:
three `bkt`, three `pix` and one `rpix`. These contain twelve top-level source Let
bindings in total. Each becomes ordered fresh temporary declarations followed by
a nested block of source binders. Primitive arithmetic expression slices, direct
private calls, helper parameters and names remain. Existing loop helpers, public
entry/fallback bodies, runtime code and descriptor guards are byte-identical.
The patch manifest reconstructs the exact original module by offset. These are
static syntax counts, not measured dynamic calls or heap allocations.

| Module | SHA-256 |
| --- | --- |
| Actual12 original Mandelbrot | `dbd065e8888b757edbfe49cb707682f4d7c0924ab37a6d4f1e94022e84ea3b3e` |
| Private Let statement variant | `ba7b2008d06d459a6293231651ebf2750a62669e66435bf96da5378500f49292` |
| Actual12 scalar fixture, unchanged on both sides | `990a2a7568cdb40541883237b97e008ee785a8d8e890400b9890fe21274204f5` |

The small scalar fixture has no eligible top-level private source Let expression.
Its derived module is exactly byte-identical, so it does not provide a distinct
performance comparison. The experiment does not rewrite primitive IIFEs or
change the fixture to manufacture an opportunity.

All acquired controls pass:

- Seven independent synthetic scope/order/number examples on both sides,
  including parallel and nested shadowing, a later argument throw, preserved
  primitive IIFE arithmetic, negative zero and NaN: fourteen observations.
- Six malformed or unsupported syntax shapes refuse the derivation.
- Seventy-four independent original/tree numeric points on both modules,
  including the complete original benchmark points.
- One hundred thirty paired public boundary traces and four safe depth-entry
  sentinel observations.
- Eighty-five additional paired descriptor, prototype, copying and runtime-marker
  boundary observations.

Independent static review identified an overly strict comment rejection before
the first acquisition. The derivative now permits exactly the existing
`/* primitive */` marker, which its inherited parser masks, and still refuses
unrecognized comments and lexical features. No failed executable attempt was
discarded or needed for this correction.

Raw derivations are `selfhost/build/phase30/inspection-private-let-whole-01/`
and `inspection-private-let-helper-01/`. The control launcher, consumed tools,
generated diagnostic modules and results are under
`inspection-private-let-controls-01/`. The three control children took about
0.93 seconds combined on CPU7; this describes acquisition cost while other
independent work was allowed, not a controlled performance measurement.

`inspection-private-let-plan-01/{screen,confirm}.json` freezes two clean timing
points: unchanged original Mandelbrot `bench(2,0)` and the existing depth5 tree
adapter. Both retain complete output expectations. No diagnostic instrumentation
or sentinel module appears in these configurations.

## Controlled timing

The root-granted screen, `private-let-screen-01/`, suggests improvement on both
points but retains continuing baseline warmup:

| Screen point | Baseline median ms [min,max] | Statement median ms [min,max] | Timed-half changes |
| --- | --- | --- | --- |
| Original `bench(2,0)` |0.412178 [0.409995,0.412658]|0.356862 [0.354285,0.356876]|baseline−13.5…−14.9%; candidate+5.2…+10.3%|
| Depth5 tree |0.0316045 [0.0315386,0.0319303]|0.0249569 [0.0248900,0.0252940]|baseline−13.6…−15.9%; candidate+1.3…+2.7%|

The lead therefore froze a [separate fifteen-second-warmup
confirmation](../../design/phase30/private-let-long-warmup.md) for the original
program, retaining the existing three-second configuration unexecuted. Its
three samples use a three-call warmup floor and one-second timed target. The
new plan is `private-let-long-plan-01/long-warmup.json`; raw results are
`private-let-long-confirm-01/report.json`.

The longer window measures baseline0.267175486ms
[0.263129553,0.269023447] versus statement0.237969817ms
[0.237571818,0.238472759]: **1.1227× faster,10.93% less time**, with disjoint
sample ranges. Baseline half changes are+0.540%,−0.952%,−0.107%; statement
changes are−0.365%,+0.209%,+0.177%. The supervised comparison took130.49seconds.
These ranges are sample extrema, not confidence intervals.

This supports a small ordinary-private-helper statement emitter. It does not
justify applying the rule to public callbacks or changing generic expression
emission. The [minimal implementation supplement](../../design/phase30/private-let-emitter-supplement.md)
proposes one return emitter that reuses existing binding/context helpers. The
maintained compiler still needs its own checked emission and gates before any
release claim. Do not multiply this isolated gain into earlier tree ratios or
substitute the short-window medians for the longer-window baseline.
