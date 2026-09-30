# Direct statements for private scalar helpers

The checked compiler's private Let emitter reduces original Mandelbrot execution
time by **12.63%**, from 0.246549 to 0.215416 ms, with stable, disjoint samples.
Pinned TypeScript takes 0.045613 ms in the same window, leaving a **4.723×** gap.
This compiler change adds eight source lines and one function.

The earlier isolated generated-JavaScript experiment justified this change:
after a separately frozen 15-second warmup, that comparison measured 0.237970 ms
versus 0.267175 ms, an 11% saving. Keep the prototype and actual compiler windows
separate; the compiler result also includes the preceding frame-reuse change.

Attempt14 implements the [private-only proposal](../../design/phase30/private-let-emitter-supplement.md).
One return emitter unwraps annotations and emits a tail chain of scalar Lets as
blocks. It reuses the existing value, binder and context helpers. All parallel
RHSs execute in the original environment before any new source binder exists;
the body sees fresh immutable aliases. Terminal expressions still use `j_expr`.
The change does not route ordinary public callbacks through this rule, alter
nested-loop bodies, or introduce another purity analysis or runtime operation.

The region proof admits only scalar RHSs, so the new administrative assignments
cannot infer names for anonymous function or class values. The separate generic
Let experiment must handle that wider case explicitly. Independent source review
confirmed the private implementation matches its narrower proof and experiment.

The genuine checked build and 36 focused exact cases completed in 38.643 seconds.
This is an acquisition duration, not comparative compiler throughput. Attempt14
API is `ade96ba48b05ba116430f57e433d8fbdbd76646b61f5e9d53cf34a4c4a9da76d`;
its checked parent is `cb2a5555e8ad6afc51e3bc778242e26334f11c40b720028650b8b4c0525f2deb`.
Runtime remains `a3547a8854b45c65fd804f106868dc28540118b611d85fe99ba0e3d199c66ef0`.
This is the existing guarded profile6 derivative of a genuine checked bootstrap,
not a new self-reproduction claim.

Canonical compiler source now has 16,836 physical lines, 14,377 nonblank lines,
649,526 bytes, 1,852 definitions, 640 laws, 70 types and 66 manifest modules.
The change adds eight physical lines and one function. Against the Phase29 start,
the phase has added 629 physical lines (3.88%); it has not reduced source size.

Raw evidence: `selfhost/build/phase30/private-let-long-confirm-01`,
`build-launch-14`, `attempt-14`, and `metrics-14.json`.
Actual-output controls and the paired actual13/14 measurement are recorded
below. Final integration remains separate; Phase29 is still installed.

## Actual emitted code and controls

The checked original Mandelbrot output is
`selfhost/build/phase30/private-let-region-14b/candidate.mjs`, SHA-256
`5beb848e33306470aa9ddd8f160067b3b1ebfbc4181601a27a9d1b8fbfb064c9`.
The independent `inspect-private-let-actual.py` tool reconstructs the complete
expected output from checked attempt13. It changes only seven ordinary private
helper bodies: three copies each of `pix` and `bkt`, and one `rpix`, twelve Let
bindings in total. It uses the maintained `$v<number>` temporary spelling and
nested outer/inner blocks. The reconstructed entire module is **byte-identical**
to the compiler's actual14 output. Primitive expressions and all code outside
those seven body spans therefore remain unchanged.

`selfhost/build/phase30/inspection-private-let-actual-14/derive.json` retains the
checked source/API/runtime/Base identities, exact patches and expected module.
The actual13/14 whole-program controls pass:

| Evidence under that directory | Result |
| --- | --- |
| `oracle/report.json` |74 independent numeric points on both modules,130 paired public boundary traces and4 safe depth sentinels|
| `boundaries/report.json` |85 additional paired prototype, metadata, copying and runtime-marker traces|

The separately checked scalar fixture output at
`inspection-private-let-helper-14b/candidate.mjs` is exactly byte-identical to
its attempt12 emission:
`990a2a7568cdb40541883237b97e008ee785a8d8e890400b9890fe21274204f5`.
This confirms the intended no-op on helpers without an eligible Let chain.
Fresh actual14 controls under that directory pass146 ABI observations,72 scalar
observations and9 exact-entry observations (`scalar-controls/report.json` and
`entry-controls/report.json`). Its first acquisition omitted the required output
directory; the host `ENOENT` and exact command are retained separately at
`inspection-private-let-helper-14/acquisition-failure.json`. No compiler defect
or successful emitted module is inferred from that setup failure. The prototype
agent likewise retains its separate first Mandelbrot launcher failure before14b.

`inspection-source-trees-final-14/controls/report.json` renews the source-level
Bool/Nat tree and conservative-refusal fixtures: all11 admission decisions,
270 independent numeric points across retained TypeScript/attempt11 and fresh
attempt14 modules, and6 paired live-owner/saved-partial observations pass.
The unchanged source and saved references remain bound to their original checked
receipts. This is backend coverage, not a new whole-frontend percentage.

`scalar-scaling-plan-14/plan.json` binds the final checked scalar fixture to the
same Phase29/TypeScript source references and counts0/128/1024/8192. Its
`public-check/report.json` passes all12 exact side/point observations, which
enables the frozen `confirm.json`. Scaling timing is still pending; the
byte-identical earlier helper windows retain their original acquisition labels.

## Actual compiler execution comparison

The prospective [actual timing design](../../design/phase30/actual-private-let-timing.md)
and `private-let-compiler-plan-14/long-warmup.json` bind the exact checked13 and
checked14 emissions, the same canonical source, pinned TypeScript, independent
whole-module reconstruction and semantic controls. The runtime, guards and all
code outside the seven private helper bodies are unchanged.

`private-let-compiler-long-confirm-14` completed in 193.64 seconds under the
exclusive CPU3 window, with other agents' acquisitions paused. It used the
unchanged separately derived actual-tree runner: three fresh-process samples,
15-second minimum warmup, three-call floor, 100 ms calibration and one-second
measured target. Every invocation checks the complete scalar result of original
`bench(2,0)`, `887240761`. Diagnostic modules are excluded.

| Compiler output | Median ms | Sample range ms | Half changes |
| --- | ---: | ---: | --- |
| Checked13, frame reuse | 0.246549 | 0.241968–0.246742 | −0.19%, −0.80%, −0.46% |
| Checked14, plus private Let statements | 0.215416 | 0.212437–0.217529 | −0.51%, −0.09%, −0.05% |
| Pinned TypeScript | 0.045613 | 0.045491–0.045953 | +0.91%, −0.39%, +0.42% |

Actual14 gives **1.1445× throughput**, or **12.63% less time**, than actual13 on
this original program and input. The remaining **4.723× TypeScript gap** is a
direct same-window comparison. Do not multiply the isolated prototype or frame
ratios, generalize this one point to all generated programs, or interpret it as
compiler checking throughput. The separate original-program matrix and compiler
cost checks remain required for final release reporting. Exact process outputs,
config/module identities, first calls, memory observations and both measured
halves remain in the raw report and adjacent launcher receipt.
