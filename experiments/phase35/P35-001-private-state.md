# P35-001 — Remove temporary state inside a proved private loop

- Owner / independent reviewers: `phase35_vectors` / `phase35_research` and `phase35_regions`; root owns serial execution.
- Final evidence cutoff: 2026-10-01, installed checked09 and independently reopened preservation capsule. Earlier screens remain historical observations below.
- Objective: improve generated-program execution while keeping a short, bounded optimization loop.
- Correctness: checked09 final owner and scoped conformance gates pass; postinstall audit closes 15/15 groups, all 42 ordinary/relocated CLI checks and 225 canonical-file identities. Known shared failures and backend/GPU/proof-kernel limits remain unchanged.
- Measurement: full checked09 confirmation completes 15/15 points; pair 1.324×, fold 2.360× and edit distance 1.278× baseline. Profiles and 36 normal checked compiler-cost requests are complete. Earlier mechanism windows are never multiplied together.
- Decision: **promote selective implementation**. Checked09 is installed and verified; unrestricted helper inlining remains rejected. Compile latency and source/output growth are accepted explicitly in the [admission decision](../../implementation/phase35/admission-decision.json).
- [Design](../../design/phase35/private-state.md), [implementation report](../../implementation/phase35/private-state.md), [final admission policy](../../design/phase35/prospective-admission.md).

## Claim and cheapest disproof

**Hypothesis:** a guarded private countdown repeatedly constructs short vectors,
callback wrappers and BigInt predecessors that its consumer immediately discards.
Keep complete state in local fields, emit a vector result into fresh destination
slots, use an exact Number only for a predecessor that never escapes, and call
proved native get/set helpers directly. Keep the exported representation and
ordinary compiler paths unchanged.

**Invariant:** existing closed-region proof precedes every transformation. Helpers
are copied only when they return a private vector; each helper has a 2,048-visit
budget, depth eight, and complete fallback on exhaustion. At most 32 helpers are
admitted. Capture every argument before introducing callee positional names;
preserve read/write order and parallel-let scope. Compute every next field before
updating current state. Reify other vector uses as fresh snapshots, preserving
array-handle aliases. Initial zero and final result retain their original ABI.

The counter is a Number only when the Nat predecessor occurs exactly once,
as the first argument of its saturated self-tail call, in a private vector loop.
All descendant nodes are scanned, including annotations and copied bodies. The
existing private Nat bound below 2^48 makes conversion and decrement exact.
Conversion uses a captured Number intrinsic and happens after initial zero.
Other scalar loops, observed/stored predecessors and indirect aliases refuse it.

**Disproof:** changed complete state, event/callback order, alias snapshot, zero
identity, large-Nat boundary or public fallback; a missing actual admission
witness; resource refusal; or loss on independent scalar canaries. A passing
checksum alone is insufficient. The first discriminator rewrites frozen output,
avoiding a compiler rebuild while testing the mechanism; accepted source rules
must subsequently reproduce the gain through the actual checked compiler.

## Controlled setup

- Frozen Phase32 baseline and pinned TypeScript are the maintained
  [reference bundle](../../selfhost/tools/performance/programs/baseline/manifest.json).
  TypeScript pin: `018751270e800bc222a93dad7f257083ee53a5f7`.
- Canonical Base SHA256: `c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661`.
- Checked candidate source, runtime, API, Base and dirty overlay identities are
  frozen in each attempt manifest. Checked09 API begins `467bc7de`.
- Node 24.18.0; CPU3; serial fresh processes; 4 MiB stack; 1 GiB Node heap;
  supervisor RSS and host-available-memory limits retained in each receipt.
- Mechanism screens use three rotated rounds, with the maintained runner's
  explicit warmup/calibration/target settings. Compilation and diagnostics run
  separately from generated-program execution. Every role uses unchanged inputs
  and expected complete results; each ratio uses its own same-run baseline.

Use the [tool map](../../selfhost/tools/performance/phase35/README.md) for serial
reproduction and final owner controls. All evidence below is under
`selfhost/build/phase35/`; each directory retains consumed tools/configuration,
input/output identities and observations. Saved-output producers additionally pin
exact module/body hashes and are explicitly unchecked mechanism probes.

## Gates and observations

| Attempt / artifact | Correctness and scope | Measured result | Interpretation |
| --- | --- | --- | --- |
| `vectors`, inline screen | Both complete pair/fold points pass | Pair 3.89716→3.41842 ms; fold .237530→.157384 ms | Saved-output mechanism; vector allocation retained |
| `vectors`, scalar screen | Both complete points pass | Pair 3.93633→2.97609 ms; fold .238338→.128941 ms | Saved-output mechanism; local fields promising |
| `checked01` | Parser rejects computed match scrutinee | Failure after 3.12 s | Original proposal retained; fixed with named helper |
| `checked02`, `inline-core-screen-01` | Semantic controls pass; all eight screen points complete | Pair 3.88727→6.49923 ms; scalar canary .139860→.587179 ms; Mandelbrot .197276→.412532 ms | **Reject unrestricted inlining** despite fold improving .238938→.197910 ms |
| `checked03`, `scalar-core-screen-01` | Eight screen points complete; pair/fold complete-state and event gates pass | Pair 1.188×, fold 1.671×, edit distance 1.167×; scalar/Mandelbrot approximately unchanged | Restrict inlining to vector results and remove vector loop state |
| `regions-alias-controls`, `scalar-order-controls-02` | 40 oracle +4 mutation +3 negative alias checks; 14 order scenarios +2 negative witnesses pass | Semantic evidence | Preserves snapshots and all-argument capture before read |
| `number-screen-02` | Both complete points pass; screen01 configuration failure retained | Pair scalar 3.37020→Number 2.68776 ms; fold .142637→.109657 ms | Counter-only increments 1.254× /1.301× in this four-role comparison |
| Native-call ablation | Root's saved-output screen | Fold .110775→.088448 ms; pair ranges overlap around 2.975→2.937 ms | Remove get/set closure; leave Array.new ordering intact |
| `checked09`, `combined-screen-01` | All three selected points complete, three rotations each; owner gates were pending at screen cutoff | Complete pair **1.3095×**, fold **2.5699×** baseline | Historical combined screen; no isolated attribution or promotion from this screen alone |

Historical checked09 short-screen medians, in milliseconds per complete call:

| Point | Baseline | Candidate | TypeScript | Baseline / candidate | Candidate / TypeScript |
| --- | ---: | ---: | ---: | ---: | ---: |
| `local-pair` | 5.06961723 | 3.87132320 | 1.27984156 | 1.30953087× | 3.02484566× |
| `local-fold` | .377165542 | .146760873 | .071860642 | 2.56993253× | 2.04229838× |

Pair baseline range is 5.0197–5.6901 ms and candidate range 3.8234–4.1252 ms;
fold ranges are .3744–.3865 and .1390–.1645 ms. Earlier, shorter windows differ
materially. These medians do not establish stabilized V8 performance. The third
combined point is symreg and belongs to the independently tracked fold mechanism;
its improvement is not attributed to private vector state. Longer confirmation
was running at the short-screen cutoff; its final results appear below.

Checked03 allocation sampling separately fell from 8.019 to 6.425 MB for pair
and 652,893 to 431,062 bytes for fold; their private loops still dominated sampled
allocation. Sampling supported the next counter/wrapper probes but is not a
precise causal allocation census. Broad-inlining regressions are consistent with
copied bodies/IIFEs and code growth; no specific V8 failure is established.

## Independent audit

Research reviewed the original frozen row/fold reads, U32 wrapping, zero behavior,
row swap and array aliases; it required exact input hashes rather than matching
helper names alone. Both independent agents reviewed the scalar slots and counter
proof. Fresh destinations, callee scopes and terminal reboxing had no identified
static blocker. They requested real alias/nested fixtures and predecessor refusal
controls; those were mandatory and subsequently passed on the final selected API.

The implementation report retains parser/source-order/fixture failures and every
superseded producer. In particular, a numerical nested-fixture pass without both
actual scalarized loops was rejected as insufficient coverage. Source controls
must witness admission; generic fallback cannot certify the optimization.

## Decision and preservation

Promote vector-only inlining, scalar loop state, exact private countdown and
direct native get/set in the combined checked09 release. Reject broader copying.
Final-API owner controls, scoped conformance, full execution, normal checked
compiler costs and installed checks are complete. The
[performance admission](../../implementation/phase35/performance-admission.md)
retains the accepted +8.17% Mandelbrot, +30.09% symreg and +34.40% ray request
costs, +979 compiler lines and larger generated modules. Runtime gains do not
erase those costs or establish a faster stage-two compiler.

Tracked designs, patches, fixtures and tools preserve the mechanisms and failed
alternatives. The completed [capsule manifest](../../implementation/phase35/evidence/manifest.json)
and [capture receipt](../../implementation/phase35/evidence/capture.json) preserve
24,717 files in two volumes totaling 52,475,156 compressed bytes, with reopened
member/volume/logical hash checks and source rehash. Independent reopening also
passes. Working-tree base was `573284adc12cf6406ec584d00cb2d7ac90f072b6`;
the final commit and push remain root's pending consolidation steps.

## Later observation — full confirmation and generic-row investigation

`combined-full-confirm-01` completed all 15 maintained points in 518.338 seconds
using checked09, five rounds per point except three for ray. The isolated source
rules are now combined; these numbers therefore do not attribute gains to one
rule. Separate final semantic/provenance admission and installed checks have
subsequently passed; the exact scope is stated above.

| Point | Baseline ms | Candidate ms | TypeScript ms | Baseline / candidate | Candidate / TypeScript |
| --- | ---: | ---: | ---: | ---: | ---: |
| Complete pair | 5.046214 | 3.810242 | 1.245898 | 1.3244× | 3.0582× |
| Array fold | .330214 | .139925 | .040012 | 2.3599× | 3.4971× |
| Original edit distance | 20.700365 | 16.200974 | 4.971906 | 1.2777× | 3.2585× |

The full-run generic-row median appeared about 9.5% slower (.457966→.501585 ms),
which triggered the regression policy. Samples occupied two overlapping bands:
baseline [.494837,.499354,.454488,.455775,.457966], candidate
[.503366,.501585,.503745,.460601,.460034]. Paired rotation ratios had median
approximately 1.011; this is diagnostic, not a replacement aggregation rule.

Independent static comparison found the executed `row.probe`, generic row and
its emitted callees unchanged. Apart from unused foreign-path bindings, changed
program definitions are only `pair` and `batch`, which this wrapper does not call.
Runtime additions initialize host snapshots and capture `F32.to_u32`; no new
region guard appears in this generic-row hot path. Module growth may still affect
host compilation/layout, so static equality alone does not establish zero cost.

The unchanged five-rotation focused `generic-row-confirm-01` then completed in
17.957 seconds: baseline .453832 ms (.450830–.473224), candidate .455299 ms
(.452969–.461402), TypeScript .008466 ms. The candidate is 0.323% slower, with
overlapping ranges. The apparent 9.5% full-run regression was not reproduced;
retain both observations, label the original nonstationarity, and make no source
change on this evidence. This investigation does not remove the much larger
existing generic-backend gap to TypeScript.
