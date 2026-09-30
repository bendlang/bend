# P30-030: exact dispatch before the first registration

Correctness and the prospectively bounded performance criteria pass. The parent
selected the general flag for checked17; fresh integration gates remain separate
from the generated-JavaScript diagnostic measurements below.
The [prospective design](../../design/phase30/registration-free-exact-dispatch.md)
separates a registration-free diagnostic from a general monotone flag. The latter
skips `WeakSet.has` only before the first successful `exactCode` registration,
after the original selected `f.code` read. Its registered path is otherwise
unchanged. The direct diagnostic cannot be used where a worker may register.

All four immutable derivatives pass complete Acorn parsing, conservative binding/
escape analysis, exact inverse reconstruction and byte-identical generated
suffix checks. Only the declared runtime spans change:

| Checked16 artifact | Actual registration call sites | Quoted generator strings | Available variants |
|---|---:|---:|---|
| Original RLE roundtrip |0|0|unchanged, direct generic helper, general flag|
| Scalar helper fixture |3|0|unchanged, general flag|
| Original Mandelbrot |5|0|unchanged, general flag|
| Generated compiler H |0|2|unchanged, direct generic helper, general flag|

The two H strings belong to its JS emitter; they describe future output and do
not register callbacks in H's own execution. The auditor rejects registration
helper or WeakSet escapes/shadowing and dynamic lexical execution. These are
static call-site facts, not execution counts or measured cost shares.

The RLE gate passes **33 complete-state observations**:11 independently computed
inputs across unchanged/direct/flag modules, comparing the complete run pairs,
expanded Lists, run counts, digest, public go result and fixed original11 result.
It also passes **22 ordered host observations** across all three modules,
covering ordinary/proxy/object code, custom/throwing/noncallable method lookup,
method-before-env order, code-read counts, reentry and partial/exact/oversaturated
application. The direct variant's control copies do not expose registration.

Independent reviewer gates pass:

- **22 fresh-module transition scenarios**, including registration by first/
  second code getters, bound/arity/slice effects, late method/env registration,
  raw/partial/oversaturated entry, same-vector reentry, throws, callback shape,
  owned calls and another module's separate registry.
- **146 public ABI plus72 scalar observations** on the registered helper.
- **Nine exact-entry/reentry/restoration observations** on that helper.

The standard-intrinsic scope includes unmodified WeakSet methods. Public
descriptor, method and environment mutations remain covered; the experiment
does not silently exclude those public boundaries or restore eager prebinding.

## Manually derived H functional transfer

The **general-flag H diagnostic** passes two separately bounded functional gates.
Its actual SHA is
`a7ffece566086a00c7b8224680ab320f1933e7ae7663fc765ed20eea5c8cdeb5`,
2,446,379bytes. It is a manually changed derivative of original H, never a checked
attempt, new compiler self-emission or installed compiler.

The first gate genuinely checks Base and creates a cache under that exact new
API hash. The second validates the same cache unchanged, reproduces original H's
complete positive8/negative-check observations, and emits byte-identical positive
JavaScript. Both preserve the frozen driver and ABI adapter. CPU7 acquisition
takes21.095s and17.325s for the respective supervised children,40.450s for the
outer launcher; the90-second caps do not fire. These overlapping correctness
durations are **not a speed comparison** with original H or its TS-produced parent.

## Evidence and prospective decision

All paths below are under `selfhost/build/phase30/`:

- `registration-dispatch16-{rle,helper,mandelbrot,h}/derive.json`: exact source,
  checked receipts, AST proof, runtime edits, parser/tool identities and outputs.
- `registration-rle-controls16/report.json`:33 complete-state and22 host cases.
- `review-registration-transition-16/report.json`:22 independent transitions.
- `review-registration-abi-16/report.json`:146+72 independent observations.
- `review-registration-entry-16/report.json`:nine independent entry cases.
- `registration-h-functional16/{plan.json,execution/report.json}`: explicit
  manual-diagnostic admission, actual-hash cache and positive/negative oracle.

Separate outer launch receipts and consumed tools remain beside these artifacts.
No failed compiler/program observation occurred in this acquisition. Static
inspection fixed the test's native Tuple decoding before its first execution.

Before any timing, root selected a criterion of at least5% RLE median reduction
for the **general flag**, with disjoint five-sample ranges, and no registered
helper/Mandelbrot slowdown above3% beyond sample variation. A winning direct-only
diagnostic cannot justify promotion. The existing RLE regression and original16
matrix stay intact; timing and any production change require separate decisions.

The earlier lexical inventory finds no registration expression in the other
eight non-Mandelbrot original modules either. Unlike RLE/H, those eight have not
received this new executed binding audit. They are potential transfer coverage,
not additional proved derivatives or performance results. Even a proved empty
registry would establish eligibility, not a speedup on those programs.

## Clean performance decision

All measurements use the frozen `registration-timing-plan16c`. The first short
screen is retained at `registration-screen16/report.json`: RLE16/flag drift by
66–119% between halves, the helper by−8–11%, and the row by−46–49%. Its apparent
gains are inconclusive; the decision uses the subsequent confirmations.

| Scoped point | Unchanged16 median ms [min–max] | General flag median ms [min–max] | Result |
|---|---|---|---|
| Original RLE roundtrip |.04850821229 [.04827164430–.04871886772]|.04580811594 [.04574567252–.04628917090]|5.566% less time; disjoint ranges|
| Registered scalar helper |.006965073193 [.006942706431–.007214057985]|.006964857573 [.006942807578–.007004751789]|−.003%; overlapping ranges|
| Generic complete-state row |.4460979465 [.4431044116–.4595128841]|.4221063021 [.4169716839–.4236853371]|5.378% less time; disjoint ranges|
| Original Mandelbrot,15-second warmup |.2123098575 [.2084150776–.2159391264]|.2110293705 [.2080174148–.2119227872]|.60% less time; overlapping ranges|

RLE flag half changes are−.43…−.97%. The helper's are.084…2.523%, versus
.016…2.282% for16. Row flag halves change−1.277…+2.578%, versus+.022…+4.320%.
Mandelbrot flag halves change−1.830…+.695%, versus−.388…+.850%. Every output
check passes. The registered negative controls stay within the prospective
3% boundary. The optional row additionally passes56 full-state observations.

The direct-only RLE diagnostic reaches.04661181249ms, a3.91% reduction; it is
not selected. In the same RLE confirmation, Phase29 is.04427851548ms and pinned
TypeScript is.00056281090ms. **The general flag remains3.45% slower thanPhase29**
on this point. This repair therefore explains part of the prior residual loss;
it does not establish an across-program win or eliminate the generated-code gap.

Canonical receipts are `registration-confirm-{rle,helper,row}16/report.json` and
`registration-long-mandelbrot16/report.json`. The latter's129.43s launcher is
separate from the helper42.69s and row43.20s launchers. Two metadata-only plan
failures remain: `registration-timing-plan16/failure.json` selected the wrong
maintained comparison-tool path, and `registration-timing-plan16b/failure.json`
required an optional byte-count field absent from otherwise matching gate
identities. Plan16c repairs binding only; it changes no module or observation.

Root selected exactly the three general-flag runtime edits under
[the conditional integration design](../../design/phase30/registration-flag-integration.md).
Checked17 must independently prove actual-output correspondence and renew its
affected gates before release. No compound runtime change is selected, and the
old16 full matrix remains immutable. A byte-identical actualH17 may reuse only
the manual-H functional gate's frozen16 driver/runtime-input scope; it does not
inherit the separately measured originalH ratio or claim a fresh17 pipeline.
