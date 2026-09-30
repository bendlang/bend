# Ordinary scalar roots: generated-output experiment

The generated-output experiment confirms a 1.338× gain on the original small
program when both ordinary roots are admitted, and a 1.869× gain on the recolor
leaf. On the checked lexical-only attempt08, adding a guarded closed scalar region to ordinary `pix`
and `rpix` callbacks passes 92 independent oracle points and 225 ordered boundary
observations across all four variants. Instrumentation confirms less application
machinery. The short screen has substantial warmup drift in several variants;
the long confirmation establishes the scoped gain. No compiler integration is
claimed by this report.

The prospective design is
[ordinary-scalar-root-regions.md](../../design/phase30/ordinary-scalar-root-regions.md).
This experiment changes generated JavaScript only. The compiler, runtime,
original benchmark and independent oracle remain separate inputs.

## Acquisition and provenance

`transfer-08/report.json` under `selfhost/build/phase30/` contains ten successful
checked original-program emissions and exact scalar executions against their
saved Phase29/pinned-TypeScript points. Its outer acquisition receipt,
`transfer-08-outer/run.json`, records 70.76 s on CPU4. This is acquisition cost,
not a compiler-throughput comparison.

The ordinary-root experiment consumes the actual checked Mandelbrot output at
`transfer-08/mandelbrot/candidate.mjs`. The derivation verifies its checked
receipt, source and attempt08 identity, and requires lexical private declarations
in the existing `mit` region. It cannot silently consume the old dictionary
candidate. Exact hashes, original/replacement definitions and consumed tools are
in `prototype-lambda-01/derive.json`.

Four outputs share the same runtime and checked source: baseline, `pix` root
only, `rpix` root only, and both roots. The derivation copies the existing private
lexical primitive helpers and the exact BigInt `mit` loop. It rewrites only
exact saturated calls inside the selected closed regions. It preserves the
ordinary public callback kind and arity, consumes exact-entry permission before
reading the original slots, and checks primitive inputs and live descriptor
snapshots after those reads. Unprivileged and guard-failing paths retain the
original generic expression, including `pix`'s tail bounce.

The `pix` closure has six guarded descriptors; `rpix` has eight. Unselected
public callback bodies stay unchanged. Newly needed descriptor captures are
explicit in the derivation. No terminal `hchunk` region, counter conversion,
arithmetic simplification or tree-recursion transformation is combined here.

## Independent values and host boundaries

`prototype-lambda-controls-01/report.json` records 92 independent oracle points:
escape-time and recolor results across zero/short iteration counts, grid and
U32 boundary indices, two palettes including overflow values, and both small
whole-program points. Each point passes in all four modules. The oracle uses
ordinary signed arithmetic and a palette array; it consumes no generated
expression text.

The same receipt records 225 complete ordered boundary comparisons, each across
all four modules. These include every guarded global as a getter, replacement
or proxy; descriptor code/arity/environment/bound hooks; in-place code changes;
saved partials; raw entry and attempted forged permission; slot getter order,
reentry, mutation and exceptions; copied-vector proxies; over-saturation;
coercible/boxed or invalid scalar inputs; later-call mutation; and public arity,
callback length, name and constructibility.

New-expression raw entry is checked explicitly. `pix`'s generic callback can
return a bounce object; `rpix`'s scalar return makes a JavaScript constructor
return its fresh instance. Both behaviors agree with the unchanged callback.
The independent reviewer also reviewed the proposed boundary statically before
derivation. Standard host intrinsics remain the declared scope.

The derive and control acquisitions each took less than one second on CPU5.
Their separate outer receipts are `prototype-lambda-derive-01-outer` and
`prototype-lambda-controls-01-outer`. These are not clean speed measurements.

## Mechanism counts

`prototype-lambda-counts-01/report.json` contains separately instrumented copies
for both whole-program points and the two scalar leaves. These modules must
never be timed. For original `bench(2,0)`:

| Administrative event | Baseline | `pix` only | `rpix` only | Both |
| --- | ---: | ---: | ---: | ---: |
| Apply | 21,068 | 16,972 | 15,180 | 13,132 |
| Function/partial descriptors | 12,858 | 9,274 | 10,554 | 8,762 |
| Descriptors with bound arguments | 10,532 | 7,460 | 8,996 | 7,460 |
| Jump | 3,603 | 2,579 | 2,323 | 1,811 |
| Force | 17,465 | 14,393 | 12,857 | 11,321 |
| Projection | 1,546 | 1,034 | 1,034 | 778 |
| Build / constructor | 8 / 8 | 8 / 8 | 8 / 8 | 8 / 8 |
| Closure guards | 512 | 512 | 512 | 512 |

The guard count does **not** fall in this experiment. The old guard checks five
descriptors; the new roots check six or eight. The saved application work must
therefore outweigh the larger guard cost. Counters alone cannot establish that.
The removed projections are native scalar/Nat administrative work, not a changed
record representation. These named events are not a total allocation count.

## Frozen timing and possible implementation

`prototype-lambda-plan-01/screen.json` and `confirm.json` freeze the comparisons.
They compare the four variants plus pinned TypeScript on unchanged original
`bench(2,0)`, and separately compare a dynamic recolor leaf at seven iterations
and index 4095. The identical leaf wrapper converts its iteration argument to
BigInt and supplies an eight-scalar palette. The expected result comes from the
independent control receipt. Clean timing requires the parent's exclusive CPU3
grant; instrumented outputs are excluded.

The first clean screen is retained at `lambda-screen-01`, with an 18.05 s outer
launcher receipt. Its medians in milliseconds are:

| Point | Baseline | `pix` only | `rpix` only | Both | TypeScript |
| --- | ---: | ---: | ---: | ---: | ---: |
| Original `bench(2,0)` | 10.107814 | 9.300827 | 9.215790 | 7.981239 | 0.047489 |
| Recolor scalar leaf | 0.012797 | 0.012921 | 0.007287 | 0.007246 | — |

The whole-program baseline range is 10.08479–10.15166 ms; both roots range
7.94751–7.99582 ms. Both roots' within-process halves differ by at most 1.1%,
but the other whole variants drift by roughly −8–9%, +28–32% and −14–15%.
The leaf has even stronger warmup drift: the `pix` variant's second halves are
about 87% slower; the `rpix` and both variants' second halves are 19–24% faster.
These screen medians are not settled ratios.

The unchanged long configuration subsequently passed at `lambda-confirm-01`,
with a 190.32 s outer receipt:

| Point | Baseline | `pix` only | `rpix` only | Both | TypeScript |
| --- | ---: | ---: | ---: | ---: | ---: |
| Original `bench(2,0)` | 9.089539 | 7.329478 | 7.621259 | 6.793730 | 0.045390 |
| Recolor scalar leaf | 0.011516 | 0.007884 | 0.006168 | 0.006163 | — |

On the original point, the baseline range is 8.96578–9.14139 ms and both roots
range 6.76436–6.92702 ms. The 1.338× gain has disjoint sample ranges. Whole-program
halves are mostly within 2.3%, with one baseline sample at −3.34% and one both-root
sample at +4.78%. All leaf halves are within 2.32%; its 1.869× gain also has
disjoint ranges. The `rpix`-only and both-root leaf ranges overlap, as expected
when `rpix` already privately contains `pix`.

This is an incremental gain on the lexical-only candidate. It is not measured
on top of the separate terminal-record compiler extension, and the two ratios
must not be multiplied to predict a combined result. The original program still
performs substantial generic tree-recursion work. A larger tree region is a
separate prospective experiment with its own proof and evidence.

If a clear gain survives long confirmation, the conceptual compiler change is
one ordinary-lambda entry into the existing region traversal. Reuse helper
analysis, shared budgets, lexical spelling, primitive input and descriptor
guards, and the original callback fallback. Do not add a second call ABI or a
benchmark-name recognizer. Ordinary Nat parameters are unprojected inputs, so
their guard includes the largest immediate Nat; the predecessor-specific strict
upper bound used by the existing successor callback does not apply.

The initial production profitability boundary should be conservative: require a
proved nested Nat loop within the helper closure. Both measured roots satisfy
that condition. Trivial ordinary scalar wrappers could lose to the new guard
cost; acyclic F32 or other ordinary regions need a separate experiment.

## Actual compiler integration

The production ordinary-root rule was subsequently implemented and checked in
attempt11 on top of the terminal-record attempt10 compiler. Its separate
immutable plan is `ordinary-compiler-plan-11/confirm.json`; actual emissions and
control receipts are under `ordinary-compiler-controls-11/`. The coordinator
executed the frozen long protocol in `ordinary-compiler-confirm-11`, with the
outer launcher receipt retained (63.935 seconds, all outputs correct).

| Original `bench(2,0)` variant | Median ms | Range ms |
| --- | ---: | ---: |
| Checked terminal attempt10 | 4.995417 | 4.920979–5.008208 |
| Checked ordinary-root attempt11 | 3.633858 | 3.570331–3.851380 |
| Pinned upstream TypeScript | 0.045407 | 0.045327–0.045718 |

This directly measures a **1.375×** incremental gain on the combined terminal
compiler, with disjoint ranges. The remaining ratio is **80.03× TypeScript** for
this original small point. Baseline half-window changes stayed within 0.83%;
candidate changes were mostly within 0.36%, with two samples at −2.93% and
−6.06%; TypeScript stayed within 0.46%. These measurements replace any estimate
formed by multiplying gains from separate earlier ablations. Broader release
integration and the proposed binary-tree extension are separate gates.
