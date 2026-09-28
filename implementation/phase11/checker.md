# Phase11 checker investigation

**Root accepted telescope sharing for integration; the exact-comparison
candidate is deferred.** Both isolated changes passed scoped correctness checks.
Telescope sharing improves the targeted checked-source workload; initial exact
reuse adds a helper for little profile exposure and regresses the smallest
synthetic case. Delayed weak-normalizer fallback and context demand changes
remain unimplemented. No production source or distribution was edited by this
investigator, and no whole-compiler gain is attributed to these candidates.

The [prospective plan](../../experiments/phase11/P11-003-checker.md) records the
hypotheses before probes. Baseline is Phase10 `5f561c4`, selected API
`ff876a357db2d44d3e1fbd37ab694a16d2fa0f47d60c9d500603e634c8c645f9`, against pinned
upstream `b2111cf43244e65f76ddc278ee695e669f720cbf`. Historical Phase7 semantic-
value and generic-walker failures remain rejected; Phase9/10 wins are baseline
behavior, not new results.

## Source comparison and first discriminators

The current pinned TypeScript implementation provides useful local ownership
examples without requiring another evaluator architecture:

- `term_check` binds one filled constructor telescope and uses it for the
  match-arm context and goal. Bend `check_mat_ctr` fills the same telescope
  independently for `mat_lhs` and `mat_goal`.
- TypeScript's `term_compare` starts with pointer identity. Bend's stronger
  structural `norm_exact` check must retain its demand semantics, but its initial
  false result is accidentally recomputed: `compare` enters `norm_cmp_loop`,
  whose `norm_cmp_quick` checks the same App/Ref/Var pair again.
- TypeScript `ctx_dead` exits on the first live empty datatype. Bend uses eager
  disjunction, including the Efq caller. This needs a divergent-tail demand
  boundary before any change; it was not implemented here.
- TypeScript's `term_wnf` delays rebuilding a stuck reference call through
  `lhs.t`. Bend `norm_ref` eagerly constructs `norm_apply(t,args)` as fallback
  for every unfolding. Avoiding that work requires explicit delayed state or a
  closure, with its own representation/cost and stuck-term obligations; it was
  counted but not redesigned.

Three cheap instrumented probes retain actual generated-helper observations:

| Evidence directory | Observation |
| --- | --- |
| `checker-counts-01` | Unequal opaque Apps with equal Wrap prefixes at depths 0/4/16/64/256 call `norm_exact` twice on exactly the same original pair. `norm_exact_head` entries are 6/14/38/134/518. All results are false. |
| `checker-tele-counts-01` | Three valid source programs define Box families with 1/4/16 parameters and one matcher. They parse/load/check successfully; each matcher invokes the identical telescope-filling call site twice, supplying 2/8/32 parameters in total. |
| `checker-fallback-counts-01` | Saturated constant functions at arities 0/1/4/16/64/256 each rebuild one fallback, traversing that many supplied spine arguments, although the returned constructor does not use the fallback. |

All paths above are under `selfhost/build/phase11/`. These are disposable
instrumented views of the actual recorded Phase10 API, with exact hooks and
unchanged-original-byte checks. They are not source candidates, timings,
allocation measurements or B1 proofs. The telescope probe uses valid checked
source; conversion and fallback probes use finite raw terms with known outcomes.
Every input and tool identity is retained.

Root's fresh `current-profile-01/owners.json` limits the expected significance:
`norm_exact_lists`/`norm_exact_head` together have about 0.076% lexical exclusive
samples, `tele_fill_head` 0.689%, and `norm_ref` 0.617%. These are not inclusive
caller costs. GC/runtime shares are unassigned; no fractions of them are borrowed
to predict a checker speedup.

## Isolated actual source ablations

`checker-candidates-01/manifest.json` freezes exact preimages, replacement text,
helpers, module identities and separate projects copied from Phase10's immutable
snapshot. No live source changed.

**Telescope sharing** introduces `check_mat_filled`. The original missing-
constructor refusal remains first; only its successful branch computes the
filled telescope and passes it once. The helper uses that value for the same
lhs and arm goal, preserves checking order, and preserves default-arm checking,
usage merging and errors. This follows the existing pure telescope invariant;
there is no cache or new representation.

**Initial exact reuse** introduces `norm_cmp_start`. `compare` still tries exact
syntax first and computes the same fresh bound on false. The helper preserves
bound calculation before weak evaluation, then enters the existing normalized
head comparison. Subsequent worklist pairs retain quick checks and alternatives.
Exact divergent terms still terminate before evaluation. The change is correct
under the scoped controls, but measured usefulness is insufficient to promote it.

| Variant | Physical / nonblank delta | Bytes | Helpers | Selected B1 derivative SHA-256 |
| --- | ---: | ---: | ---: | --- |
| Exact | +12 / +11 | +327 | +1 | `5239e55223c3489ae006883827ebc7cd3f6941fbf963fe67b0190898fe0f9e2b` |
| Telescope | +14 / +13 | +266 | +1 | `3affa725aa7d1d21afed9008a2a60acecd69a4d37d9ff009fa1a96b3b359d766` |
| Combined | +26 / +24 | +593 | +2 | `961716501dda6b36df902554bb6a84a7cd7ea09f756ffd364846f6d8c7521d6e` |

Each is genuinely checked by the maintained workflow and has its own original
B1 sidecar, frozen source/tool snapshot and equality-derivation record. None is
a self-hosting fixed-point claim. They are at `checker-candidates-01/{exact,
telescope,combined}-01/`.

The recommended frozen kernel file is
`checker-candidates-01/telescope-project/src/check/kernel.bend`, SHA
`f6fd9983d3cf52006031cd3c898f37bd4d3388323ee889946cb5ba9a4db7c4cd`.
Its Phase10 preimage is
`568265ba77770de398f3610ab4854eb8a8ae4ace1832c1b803a8ad68d80417f9`.
Root must verify the preimage or apply only the exact recorded hunk if other
kernel changes intervene. The normalizer candidate is deliberately not included
in this recommendation.

## Correctness gates and retained failure

All three genuine B1 candidates pass the maintained 21 observations. Complete
candidate result objects match the Phase10 baseline exactly, including diagnostic
text and acceptance/trust metadata (`checker-candidates-01/observations.json`).
The same 12 exact TypeScript differences remain. This is selected preservation,
not full conformance or a claim that the exact diagnostic gate has become clean.

Supplemental components separately check the complete frozen source and expose
private APIs. Baseline and all three candidates each pass the same 43 kernel,
31 normalization and 19 adversarial assertions: **93 distinct controls**, not
372 distinct tests. The boundaries cover divergent reflexivity, an unused
later divergent field, arity-before-demand, fresh-ID capture, alpha conversion,
removed constructors, quantity direction, context lookup and kind promotion.
Public invalid-signature rejection and the previously documented private
unvalidated-goal prerequisite remain unchanged.

The first component setup failed before launching a compiler: maintained
workflow snapshots contain selected fixtures, not `tests/kernel.mjs` and
`tests/normalize.mjs`. `component-baseline.stderr`, `component-exact.stderr`,
`component-tool-01.mjs` and `component-setup-failure-01.json` remain under
`checker-candidates-01/`; partial `checker-component-*-01/` inputs are retained.
The corrected tool freezes the unchanged maintained tests beside each component
and hashes both original and copied files. All corrected results use fresh
`checker-component-{baseline,exact,telescope,combined}-02/` directories. No failed
attempt is relabeled as a pass.

## Bounded operation screen

`checker-micro-01/report.json` records eight serial fresh workers in
baseline/exact/telescope/combined/combined/telescope/exact/baseline order on CPU2.
These are actual independently checked component APIs. Each cell has 100 ms
warmup and three samples targeted at 40 ms. Each variant contributes two fresh
processes, with each worker's sample median entering the reported ratios.
Inputs/outputs are verified and results consumed. Other compiler jobs may run on
other CPUs, and early/late samples show warming variation. This is a directional
concurrent screen, not a controlled whole-compiler benchmark or RSS measurement.

The matcher input is parsed checked source with 1/4/16 datatype parameters.
The body-only lane reuses a previously validated goal; the complete-book lane
includes declaration and signature checking. Parsing/setup is outside timing.

| Workload | Size | Exact speedup | Telescope speedup | Combined speedup |
| --- | ---: | ---: | ---: | ---: |
| Unequal App with equal prefix | 16 | 0.782× | 1.051× | 0.909× |
| Unequal App with equal prefix | 128 | 1.082× | 1.010× | 1.079× |
| Unequal App with equal prefix | 512 | 1.095× | 1.037× | 1.111× |
| Validated matcher body | 1 | 1.065× | 1.192× | 1.356× |
| Complete book | 1 | 0.987× | 1.023× | 0.885× |
| Validated matcher body | 4 | 0.964× | 1.245× | 1.239× |
| Complete book | 4 | 0.999× | 1.087× | 1.086× |
| Validated matcher body | 16 | 1.009× | 1.707× | 1.786× |
| Complete book | 16 | 1.035× | 1.359× | 1.489× |

Ratios greater than one are faster. Small differences, including changes in the
unchanged-operation control lanes, should not be treated as reliable benefits.
The telescope candidate has a consistent positive direction on its intended
body workload and a substantial large-parameter complete-book result. Exact
reuse mostly leaves complete-book cost unchanged and regresses the smallest
synthetic conversion. Its additional helper is not justified by this evidence;
it and the combined variant remain unpromoted.

Root accepted the telescope-only source hunk after reviewing these results and
owns its combined broad correctness and controlled final timing gates. There is
no independently measured whole-source gain
for this helper, nor any claim of reduced peak RSS, compiler size or emitted
program runtime. No further checker expansion or CPU job is pending.

The separate read-only review of the maintained v4 choice derivative and scope
guard is recorded in [call_review.md](call_review.md). Source, tools and evidence
for this checker investigation are frozen; no further compiler job is pending.

The subsequent [long-string resource-boundary replay](checker-stack.md) confirms
that choice-v4 alone removes the observed stack overflow for the fixed upstream
6000-character fixture at the same 4 MiB stack limit. It does not change the
telescope-only decision for this report's source ablations.
