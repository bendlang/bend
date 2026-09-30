# Independent review of selected07 release evidence

The performance, provenance and source-count evidence supports the reported
workload-specific gains and disclosed regressions. No blocking discrepancy was
found in this read-only audit. **Selected07 is installed and verified**, and all
required semantic admission and 42 ordinary/relocated CLI checks have closed.
The explicit native retry and performance exceptions remain part of that
conclusion. Earlier pending states below are retained as dated review history.

The reviewer authored the small local-type recognition module and earlier
independent semantic oracles. This review independently recalculates recorded
measurements and checks artifact identities; it is not independent authorship of
every compiler line or a new mathematical soundness proof. No compiler, benchmark
or behavioral test was executed for this audit.

## Identity and observation audit

The retained static scripts and results are under
`selfhost/build/phase31/review-release-01/`. `audit.py` checked **1,148 distinct
referenced files**, with no missing file, hash mismatch or assertion failure.
It inspected every recorded check/calibration observation and all **170 timed
observations** across local ablation, long canaries, registration diagnosis and
the three original program comparisons. It independently recomputed per-call
samples, medians, ranges, first-call medians and normalized half-sample drift;
verified CPU affinity, prescribed warmup minima and complete first results;
and checked each repeated checksum against the expected value and repetition
count. The unchanged executor asserts the complete expected result on every call,
so this evidence is stronger than a final checksum alone.

All **18 normal checked-library compilation observations** complete successfully,
remain checked, use their intended source and candidate, and reproduce the
independently acquired full output hashes. Request/import/process boundaries
and all published statistics were recalculated from those rows. This does not
repeat compilation or substitute a private compiler entry.

`provenance.py` separately checked 298 referenced files in the final artifact
chain, including frozen sources, the assembled source, original checked API,
derivation inputs and selected API. Its counts overlap the measurement audit and
must not be added into a unique-file total. The chain agrees with the draft
[release report](release-07.md):

| Artifact | SHA256 prefix |
| --- | --- |
| Selected API, guarded derivative version 6 | `d8f609c99b3acef9` |
| Genuine TypeScript-produced checked parent | `da90b03328759dd6` |
| Same assembled Bend source | `f253683ff97c55e5` |
| Embedded runtime | `4121f338a7e4e115` |

The full hashes are retained in `provenance.json`. Upstream revision remains
`018751270e800bc222a93dad7f257083ee53a5f7`. The record is a checked parent plus
the maintained derived-b1 transformation, **not** a fresh H self-emission or
fixed-point result. The earlier 55 runtime controls cover identical final07
runtime bytes through the separate [identity review](actual-local-data-review.md).

## Performance interpretation

The [final measurements](final-measurements.md) and
[local ablation](local-data-ablation.md) agree with the raw samples.

| Scope | Final07 median ms | Previous17 ms | Final07 / TypeScript |
| --- | ---: | ---: | ---: |
| Original edit distance, four complete pairs | 70.817425 | 1900.374599 | 14.278× |
| Original Mandelbrot | 0.203686 | 0.212826 | 4.484× |
| Original small RLE round trip | 0.045167 | 0.046524 | 75.733× |
| Separate full-pair diagnostic | 16.859167 | 490.482675 | 13.662× |
| Separate 4096-step fold | 0.675098 | 11.930349 | 16.924× |

The original edit-distance speedup is 26.83484458×, or **26.83×** to two decimals.
It includes four pairs, setup and checksum. The separate pair/fold gains are
29.09×/17.67×; they are not compiler-throughput improvements or a production
average. The three original programs are a preselected subset; seven other
original cases have no fresh Phase31 timing.

The finite-window caveats matter. The final fold still improves by 8.95–9.62%
between timed halves. The original edit-distance candidate gets 2.72–4.24%
slower between halves, while its slow baseline has only one timed call per
sample. Mandelbrot17 has a −9.07% warming outlier; RLE TypeScript has a +7.53%
half-change outlier. These do not erase the large disjoint edit-distance gain,
but prevent claims of universal or fully converged throughput. The small
05→06 increment remains unproven because ranges overlap. Warmed Mandelbrot
improvement does not imply a first-call improvement: its candidate first call
is about 11.62ms versus 10.57ms for 17.

Normal checked compilation is a separate result: request medians are
1790.128ms/1669.866ms for Mandelbrot/edit distance. Relative to17, Mandelbrot's
+0.73% shift is unresolved because ranges overlap; edit distance's **+6.90%**
cost is resolved by disjoint ranges, an additional 107.770ms. Request-only
TypeScript ratios are 5.258×/5.312×; host-import-plus-request ratios are
2.956×/2.893×. Different inclusion of host import and lazy API loading explains
the distinction. Full supervised process times include identity validation and
postflight and must not be described as ordinary CLI latency.

## Explicit admission exception

The original no-material-regression condition remains failed. The long canary
has +4.01% scalar zero-work cost (0.182 microseconds per call) and +5.04% generic
row cost (21.150 microseconds), with disjoint ranges. The separate registration
experiment meets its frozen criterion: one unused valid registration explains
96.97% of the same-window row excess, with candidate/diagnostic ranges overlapping.
This is a causal explanation of that row cost, not a safe optimization and not
an explanation of the scalar-zero cost.

The [dated admission decision](../../design/phase31/admission-tradeoff.md)
explicitly accepts the additional +6.90% compilation cost as well. I consider
the amended decision coherent with the user's generated-program speed goal:
the original four-pair execution saves about 1.83 seconds per measured call,
while compilation adds about 108ms for this source. That is a scoped utility
decision, not a universal break-even guarantee. The failed original criterion,
all three costs and the immutable plans remain visible. Neither the cause
diagnosis nor the much larger wins converts the old condition into a pass.

## Complexity and pending release gates

An independent recount of both immutable manifests confirms **17,014 physical /
14,529 nonblank Bend lines, 1,878 definitions, 640 laws, 70 types and 66 modules**
in 07. Against 17 this is +236 physical lines (+1.4066%), +202 nonblank lines,
+34 definitions and one module; law/type counts are unchanged. Runtime core is
245 lines, up 11. These are source counts, not a measured count of concepts or
generated image size. The bounded local-type proof, two private plan tags and
guard extension describe the actual conceptual additions; a line reduction is
not claimed.

At this review point the fresh final07 frontend gates have closed: **3026 main
and 196 broader exact observations**, zero differences and passing process health.
Their raw verdicts stay 2525 pass /497 observed /4 shared fail, and 195 pass /
1 observed. Exact agreement does not relabel those four failures as passing
tests. The explicit 60→65→66 manifest migration remains part of the frontend
comparison rather than a wildcard exclusion.

At the initial audit cut, the 81-row backend pilot was still running. Six inherited gates, the separately
amended 40+2 worker-admission controls and 22-component/HVM controls, then release
installation/verification and ordinary/relocated smoke receipts remain pending.
The extra renewals are justified by changed worker eligibility and module-wide
exact registration. Historical results do not stand in for their new receipts.
The optional 811 additional JavaScript rows remain deferred. Native/device
equivalence, genuine H07 throughput and a compiler fixed point are not established.

This report will receive a dated receipt-closure addendum once those gates finish;
the completed performance audit above does not depend on claiming them early.

### Backend environment failure observed during closure

The first backend pilot subsequently completed all 81 paired rows with exact
agreement, but **failed historical-outcome admission**. Its raw counts are
52 pass /8 not-applicable /21 fail. Seventeen rows in the 21-row `pilot-native`
batch failed to spawn the pinned Clang with `EPERM` on both compiler sides.
Matching environment failures do not satisfy the required historical native
execution outcomes. The failed campaign remains at
`final-plan-07/backend/pilot/report.json`, with `agreementComplete:false`.

The separately frozen `final-native21-retry-plan-07/plan.json` retries that whole
21-row batch in the approved execution context, expecting 17 passes and four
not-applicable observations. It was pending at this update. If it succeeds,
admission must explicitly combine the 60 unaffected original rows with the 21
retry rows, checking every historical observation field and unique id/lane key.
Although the failed campaign labels 64 rows accepted, four belong to the replaced
native batch; retaining all 64 and adding 21 would double count them. Neither a
successful retry nor the aggregate should relabel the failed first campaign.

### Native retry closure, 2026-09-30

The approved-context retry subsequently passed all 21 expected historical
observations: 17 passes and four not-applicable results. A separate read-only
audit, `review-release-01/backend-closure.py`, rehashed 509 referenced files and
independently formed the explicit 60+21 scope. All 81 id/lane keys are unique and
match the historical inventory; every reference/candidate verdict, complete
reference/candidate observation, exact-agreement flag and semantic-agreement
flag equals its historical row. Final composed classifications are **69 pass /
8 not-applicable /4 shared checking failures**. The independent result is
`review-release-01/backend-closure.json`.

The published `final-backend-closure-07/report.json` was then checked separately:
all 492 bound input identities match, its 81 complete historical rows agree, and
the 60/21 acquisition labels and original failed rows are retained. This check
is saved as `review-release-01/composition-check.json` and binds the published
report hash `623af3e81770b686196a738f36c6ea1f3c4eca54fc242c66ea8c35c0e3db0351`.

This closes the backend pilot's required observation scope through explicit
retry provenance. It does not change `agreementComplete:false` in the first
campaign or convert shared failures/not-applicable cases into passing executions.
The remaining inherited/component and release-installation gates are still
pending at this update.

### Remaining semantic gates closed, 2026-09-30

The six inherited gates and three additional scopes subsequently passed. The
independent `gates-check02.py` review rehashed 254 referenced files and checked
their completed observations against final07 bindings:

| Gate | Retained scope |
| --- | --- |
| Primitive values | 56,205 scalar checks |
| Nat workers | 3,759 scalar checks plus public-boundary observations |
| Nested Nat controls | 144 checks |
| Primitive recognition/refusal | 1,129 guards |
| Selected upstream JavaScript | 15 paired passes, zero differences |
| Corpus | 23 checked libraries and 127 exact values |
| Worker admission | 40 guards and two scope observations |
| Compiler component | 22 observations |
| HVM program smoke | Exact 42-byte stdout and empty stderr |

These counts overlap and must not be summed into a new conformance total.
The same audit also bound the completed main/broader frontend receipts and
preserved their raw pass/observed/fail classifications. Results and receipt
hashes are in `review-release-01/gates-check02.json`. The first static audit
script used the wrong corpus receipt key (`check` instead of `execution`);
that script and its schema-error record are retained. Correcting the reader
required no behavioral rerun or change to any original receipt.

All required semantic admission scopes are now closed. Installation verification
and the ordinary/relocated CLI smoke remain pending, so this update still makes
no completed-release claim.

### Installed release closure, 2026-09-30

Installation and release verification subsequently exited successfully. The
final smoke launcher and all **42 ordinary/relocated CLI assertions** passed,
with no changed ordinary inputs, relocated inputs or fixtures. The relocation
needed no upstream checkout. A final read-only review rehashed 347 referenced
files, checked every step's assertion and stdout hash, and independently compared
the installed release files and canonical checkout to the manifest.

Installed API `d8f609c99b3acef932f90040d0c6152c96605493bef926e46f25559ac125029b`,
assembled source and embedded runtime agree with selected07. The installed
manifest hash is `b338fb05d7c4b8898240679018fc5c83fc2aece41de9a8f937b7e688d6b78b68`.
The final receipt is `review-release-01/release-closure.json`; it binds the
installation, verification, smoke launcher, all-check report and release manifest.
No installer, compiler, CLI or behavioral test was rerun by this review.

This closes the review of the usable compiler version within the named scopes.
The original performance criterion remains failed under the documented admission
exception; the first native campaign remains failed; historical shared checking
failures and not-applicable rows retain their verdicts. Broad native/device
conformance, additional 811 JavaScript observations and new H throughput or
fixed-point claims remain outside this release evidence. All raw producers owned
by this reviewer are closed for the final evidence capture.
