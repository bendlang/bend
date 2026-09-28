# P9-002: bounded checker work

2026-09-28. This report covers three small source changes and the subsequent
chronological-cache investigation. The initial experiment was
recorded in [P9-002](../../experiments/phase9/P9-002-checker-work.md) before any
candidate build. Root committed the [design](../../design/phase9/checker_speed.md)
as `e7b2846` before edits. Measurement and release promotion are separate gates.

## Changes and invariants

1. `check_lam_q` now checks a lambda domain's kind only for an explicit Many
   lambda against a Lone goal. That is exactly the special case in pinned
   upstream `term_check`. Ordinary lambda checking consumes an already validated
   goal. The promotion check, unsafe mode, body check and usage closing remain.
2. Public `compare` tests `norm_exact` before discovering a fresh binder bound.
   Exact equality needs neither fresh binders nor normalization. The unequal
   path computes the same conservative bound and enters the same comparison
   worklist. It does not repeat the initial exact traversal. `norm_compare`
   remains unchanged, including the native show caller's explicit fresh bound.
3. `infer_var` binds `ctx_get` once and reuses its result for the missing-binding
   decision and successful inferred type. Context representation and usage
   accounting are unchanged.

The lambda invariant is not a claim about every arbitrary private `check` call.
Passing an invalid, unvalidated function goal with a Many function-valued domain
changes the old defensive rejection: the optimized private entry accepts the
ordinary lambda. Public `check_book` still rejects that invalid signature before
its body. Both observations are retained as boundary controls. This aligns the
entry's prerequisite with upstream; it does not authorize bypassing signature
validation. Definitions validate their type in `check_definition_result` and
`check_definition_type`; inferred application telescopes, substituted codomains,
and generated match goals inherit typing from their validated types.

The combined change adds one physical/nonblank production line and 166 bytes:
the 59 assembled modules move from 14,977/12,779 lines to 14,978/12,780, and
489,150 to 489,316 bytes. Kernel is 1,187 → 1,188 lines; normalizer remains 531.
No new production function, representation, cache, traversal or ABI is added.
This is removal of repeated work, not a source-size reduction claim.

## Frozen ablations

Evidence root: `selfhost/build/phase9/checker-work-01/`. The baseline project was
frozen before other agents' Phase9 source changes. Each ablation changes only its
named factor; `combined-project` contains these three changes and no descent or
runtime work. `manifest.json` records all 59 baseline module identities and exact
replacement texts. `checker-prepare.mjs` reproduces these projects without
editing live source.

All five artifacts below are genuine pinned-upstream checked B1 builds, each
with its own `api.mjs.bootstrap.json` and immutable workflow snapshot. Rebuilt
baseline bytes match installed Phase8 release07 exactly. These are not generated
JavaScript patches, private H images, or fixed-point claims.

| Artifact | API SHA-256 |
| --- | --- |
| Baseline | `e928f77778de9dc72267e26b6a7ccb029cac318ccd35dd8f9248da1c6374bbe4` |
| Lambda | `545bd9e2bc93debde018b4b6ae5743dd78466a069366a5770e580b98f19e5bc8` |
| Exact conversion | `d619b6047b85926558e136da37147dea93342b6f878afb98eac72d54f8015713` |
| Context lookup | `57a59b203bc9f79721da3687b58db00f2ee12eb6646e90c5f4f54781b908e8b3` |
| Combined | `9778713ffc5ffaf670f115acc8b66aae50e2d9647c682158258565c8ac4ed2e9` |

Upstream is immutable `b2111cf43244e65f76ddc278ee695e669f720cbf`, under
`.bootstrap/upstream-phase8`. Commands use absolute Node v24.18.0, CPU1, 4096 KB
stack and 4096 MB heap. Builds and controls ran while other correctness/profile
work could use other CPUs, so their durations are not speed measurements.
Workflow records bind Base, runtime, host, harness, source, compiler and API.

## Correctness observations

Each B1 ran the same 21 maintained developer controls plus 19 upstream checker
fixtures: quantity and kind rejection, erased access, unsafe mode and trust,
beta/annotation cases, nominal/eta equality, dead defaults and mutual datatypes.
For every candidate, all 40 full result objects equal the unchanged B1's result
objects after removing only host provenance. Diagnostic text, phase, checked
flag, acceptance, trust metadata, exit and output remain compared. All 40 also
match TypeScript's semantic status/phase/acceptance/trust metadata.

The original strict gate is **30/40**, for baseline and every candidate. Its ten
failures are pre-existing diagnostic differences; across the whole selection
there are 22 exact upstream discrepancies, including parse-diagnostic wording.
The first `lambda-01/validation-001` nonzero result is retained unchanged, as are
all later strict gate results. No fixture oracle was weakened or stripped.
Separate `*-observations.json` records establish semantic agreement and exact
preservation against baseline; they do not relabel the strict failures as passes.

Supplemental components independently check the complete frozen source and
export private checker/normalizer workers. They are clearly labeled components,
not the B1 API. Gates are the unchanged 43 kernel and 31 normalization controls,
plus 19 new boundaries: divergent exact terms with distinct binder IDs, unused
divergent sibling demand, arity before field demand, high free-ID capture,
dependent alpha conversion, removed constructors, directional kinds, explicit
fresh conversion, nearest/deep/unbound context lookup, erased use, safe/unsafe
promotion, and the invalid public signature described above.

Root independently reviewed all three edits and their callers. The review
confirmed signature validation uses the same unsafe mode before a definition's
body, the promotion check remains, explicit `norm_compare` callers are
unchanged, and lookup reuses the same nearest binding/error/usage result. No
blocking static issue was found; the private unvalidated-goal boundary remains
an explicit limitation. All five components passed all 93 assertions each
(43 kernel, 31 normalization, 19 boundaries), with unchanged bound inputs. These
are 93 distinct assertions repeated across five variants, not 465 distinct
tests. As expected, the invalid private goal is rejected by baseline/exact/lookup
and accepted by lambda/combined; the public invalid signature is rejected by all.

## Reproduction and preservation

Tracked tools under `selfhost/tools/performance/phase9/`:

- `checker-prepare.mjs`: baseline freeze and independent source variants.
- `checker-component.mjs` and `checker-controls.mjs`: checked private controls,
  exact commands, compiler/source/helper hashes, logs and changed-input checks.
- `checker-observations.mjs`: full baseline observation preservation plus pinned
  reference semantic metadata; original strict results remain independently visible.
- `checker-micro.mjs`: uninstrumented operation size series using the five
  checked component APIs. Its original frozen worker is retained with the run.

Example after preparing a fresh evidence directory:

```sh
/home/ai/.nvm/versions/node/v24.18.0/bin/node selfhost/tools/performance/phase9/checker-prepare.mjs NEW_DIRECTORY
/home/ai/.nvm/versions/node/v24.18.0/bin/node selfhost/tools/development/workflow.mjs run NEW_DIRECTORY/lambda.json NEW_DIRECTORY/lambda-01
```

The latter returns nonzero for the retained strict diagnostic differences.
Inspect its build and validation reports before any preservation comparison.
Run the baseline through the same workflow using `baseline-project` as its
configured project; compare observations with `checker-observations.mjs`.

Large ignored artifacts require root's phase archive or regeneration using the
pinned upstream and exact frozen baseline. A local ignored path alone is not
durable preservation. Root owns the archive inventory and final release decision.

## P9-002 operation measurements

`selfhost/build/phase9/checker-micro-01/` preserves 20 fresh workers: four
forward/reverse sweeps over five variants, 15 size cells per worker, three timed
samples per cell (900 samples). Each cell warms for at least 150 ms and ten
calls, then targets 50 ms per sample. Input construction, goal validation,
imports and full result checks are outside timing; result consumption is inside.
The script verifies the full expected result before and after measurement and
checks that inputs and bound artifacts remain unchanged. All 20 workers pass.

These are CPU1 operation measurements during permitted CPU0/CPU3 work, not an
exclusive whole-compiler comparison. The table uses the median of four matched
sweep speedups, each calculated from its worker's three-sample median. The full
sample vector is retained; twelve samples from four workers are not twelve
independent processes.

| Operation | Sizes | Isolated change speedup |
| --- | --- | --- |
| Exact equal constructor chains | 32 / 128 / 512 | 1.39× / 1.37× / 1.37× |
| Nested lambdas with Bool domains | 4 / 16 / 64 | 3.79× / 3.12× / 1.72× |
| Four lambdas with function-domain depth | 4 / 16 / 64 | 11.94× / 18.40× / 28.26× |
| Successful deepest context lookup | 16 / 128 / 1024 | 1.49× / 1.94× / 1.90× |
| Missing context lookup, negative control | 16 / 128 / 1024 | 1.00× / 0.91× / 0.98× |

At the largest sizes, matched-sweep ranges are 1.34–1.53× for exact conversion,
1.67–2.01× for lambda depth, 20.72–35.05× for complex lambda domains, and
1.83–2.20× for successful lookup. Missing lookup at 1024 ranges 0.968–1.010×;
the 128-entry control is noisier (0.683–1.028×). Whole-worker peak RSS ranges
138.1–144.4 MiB across all variants; this establishes no allocation improvement.

The large lambda-domain number measures **body checking after goal validation**.
`check_book` still pays signature validation, so 28× is not a definition-level
or compiler-wide gain. Exact comparison and lookup retain linear scaling; these
changes primarily remove repeated work. The combined component shows the same
mechanism pattern, with matched largest-size medians 1.43× exact, 1.75× lambda
depth, 25.51× complex-domain body checking and 1.92× successful lookup.

Root then reserved an exclusive CPU1 window, pausing other compiler work. The
prepared `exclusive` mode completed in 18.79 seconds with eight fresh workers,
six cells and three samples each (144 samples), all verified. Evidence is
`selfhost/build/phase9/checker-micro-exclusive-01/`. It compares baseline with
P9-002 combined; it does not include the subsequent cache or compact-Nat fixes.

| Exclusive operation | Matched median speedup | Four-sweep range |
| --- | ---: | ---: |
| Exact chain, 512 | 1.37× | 1.35–1.61× |
| Lambda depth, 64 | 1.73× | 1.58–1.98× |
| Four lambda bodies, domain depth 64 | 29.74× | 25.62–32.07× |
| Complete `check_book` for that synthetic definition | 1.57× | 1.42–2.07× |
| Successful lookup, 1024 | 1.94× | 1.90–1.98× |
| Missing lookup, 1024 | 1.009× | 1.001–1.012× |

The complete-book counterpart includes signature validation and substantiates
the body-only caveat: a roughly 30× body-check improvement becomes approximately
1.57× for this synthetic book. It remains an operation workload, not the complete
compiler source or generated-program throughput. Root's final controlled
full-source comparison is decisive. No speed ratio is derived from concurrent
build or full-source preflight durations.

## P9-005: the uncached chronological history

The [prospective follow-up](../../experiments/phase9/P9-005-chronological-cache.md)
was written before its counter experiment. Reading the cache flow found that
`done` retained its full-source BookCache correctly, including template checking.
The separate chronological `seen` list had no cache. Law-fill signature equality
in `event_error` receives `seen`, so non-exact, alpha-equivalent signatures caused
repeated scans of every earlier declaration and body. TypeScript-style equality
shortcuts cannot bypass those scans when binder IDs differ syntactically.

Root's independent profile attribution supports this mechanism on the real
compiler source: the reviewer attributed 33.66% of weighted baseline samples to
`norm_max_term`/`norm_max_defs` below `compare` inside `dg_suffix_events`. This is
inherited instrumented profile attribution, not a controlled speed ratio. The
local counters below independently verify the concrete call path on small books.

`checker-bound-counts.mjs` instruments a disposable generated-JS copy; its
original remains untouched. It counts full-book bound scans and structural term
nodes traversed by those scans. The uninstrumented API checks the same inputs;
all outputs agree and inputs remain unchanged. Counters are never timed.

| Alpha-renamed law-fill pairs | Original scans | Corrected scans | Original term-node visits | Corrected visits |
| --- | ---: | ---: | ---: | ---: |
| 4 | 5 | 1 | 117 | 43 |
| 8 | 9 | 1 | 307 | 79 |
| 16 | 17 | 1 | 927 | 151 |

Original comparisons include 4/8/16 uncached, Def-headed books; every corrected
comparison sees a BookCache. The sole remaining full scan computes the bound for
the entire immutable input once. Counter runs are retained as
`chronological-counts-01` (original checked component), `-02` (first actual-B1
candidate), and `-03` (corrected actual-B1 candidate), under `selfhost/build/phase9`.

The source fix creates one immutable empty cache carrying that bound. It seeds
the globally declared `done` book and chronological `seen` history independently.
Persistent updates do not share declarations between them. One `dg_seed_books`
helper serves normal checking and the verified-prefix route; the original exact
prefix guard and fallback remain. This also permits the existing indexed name
lookup in `seen`; the counter reduction does not partition the total benefit
between faster name lookup and fewer bound scans.

The first checked candidate (`chronological-cache-01/checked-01`, API
`2c71746779972e8750111227f37b59494a3f559432053a7ed96793161b2e2e4f`)
preserved all 40 selected observations but failed one new adversarial control.
After a prior Bool declaration, a raw empty constructor name was mistaken for
the empty name of an internal cache index node. Parsed source forbids empty
constructor names; nevertheless, the previous raw-book API accepted this input.
`controls-01/report.json` retains the exact success-to-rejection counterexample.
This candidate was not applied to production.

The corrected candidate filters BookCache metadata in `constructor_exists`,
while continuing to inspect ordinary datatype children. Root approved this one
additional kernel guard before its isolated edit. The final artifact is:

- Attempt: `selfhost/build/phase9/chronological-cache-02/checked-01`.
- Genuine B1 API: `4acd7244f1a937cf38fc985ce3154c35c9f334a73049d86eb745b7e9376e67d3`.
- Checked source: `8cac7fd5c6d1bc07242460b724a32cf3e7472d80ddf0e8714fee2ccc80aad6b5`.
- Full observation preservation: 40/40, against the P9-002 combined B1, with the
  same 22 upstream exact discrepancies and ten strict diagnostic failures.
- Additional actual-B1 controls: 14/14 full result matches, including the raw
  empty-name witness, duplicate law/definition/constructor refusal, changed
  signature, future safe/unsafe bodies, internal metadata spelling, original-book
  return values, exact-prefix success and mismatch/future-use fallback.
- Checked supplemental component: 43 kernel + 31 normalization + 19 boundary
  assertions pass; all bound inputs remain unchanged.

The independent reviewer confirmed map separation, bound validity and prefix
fallback, independently identified the empty-name hazard, and reviewed the
correction. After these gates and root authorization, only the tested
`produce.bend` and constructor guard were applied. Preimage checks established
that neither owned file had changed since the P9-002 snapshot, and the result was
byte-verified against the checked candidate. `production-application.json`
records this. Root's subsequent compact-Nat kernel changes are separate work;
this investigation performs no further production edits.

Against P9-002, this follow-up adds 12 physical lines, ten nonblank lines and
345 bytes, including one helper that shares setup. Its isolated 59-module source
is 14,990 physical / 12,790 nonblank lines and 489,661 bytes. These are isolated
candidate counts, not the final integrated compiler's footprint.

Decision: promote this bounded source fix to root integration. The counter
growth changes from repeated-prefix scanning to one whole-input scan; no timed
law-fill or whole-compiler gain is claimed yet. The additional isolated law-fill
timing series is deferred to root's decisive integrated measurement rather than
delaying the full correctness gate. Full frontend, full-source checking and
controlled timing of the integrated release remain root's pending gates.

## Decision and measurement

All source candidates survive the focused public and private gates. The tested
combined kernel/normalizer bytes were applied to live source, with byte identity
recorded in `production-application.json`; no other production files were edited
by this investigation. Recommendation: retain these bounded changes through
integration and controlled measurement. Operation measurements support the
specific removed-work mechanisms; no compiler throughput claim is made from a
removed call, build duration, microbenchmark or source inspection. Root's
controlled full-source measurements and broader gates determine release promotion. The work does
not replace substitution, binders, linked-list contexts or weak-head evaluation,
and cannot by itself assign a causal share of the previous 73.20× checking gap.
