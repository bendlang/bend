# Private checker projection experiment

The matched confirmation isolates a1.44–1.76× private-helper improvement from
removing record projection copies. All five frozen variants pass the selected
complete-value and public-isolation controls. Binding-only comparisons overlap;
the substantial projection-only differences remain disjoint. These results
identify an opportunity inside an owned-data boundary, not a safe public fast
path. No production checker, installed compiler or public ABI has changed.

## What is compared

Every artifact contains the complete original H17 module as an identical
2,446,379-byte prefix, SHA
`a7ffece566086a00c7b8224680ab320f1933e7ae7663fc765ed20eea5c8cdeb5`.
Only appended diagnostic exports reach the private copies. The transformation
copies14 lookup/index/infer_ref definitions and recognizes11 unary projections
with26 saturated call sites. Runtime forcing and recursive trampolining remain.

| Role | Projection call | Projection callback |
|---|---|---|
|baseline|Original mutable G binding, generic application|`project(owner,value).slice()[i]`|
|direct|Captured private callback, retained force|Original project/slice|
|captured|Private descriptor, generic application|Original project/slice|
|fields|Same private descriptor, generic application|`value.a[i]`|
|combined|Captured private callback, retained force|`value.a[i]`|

The fields/captured artifacts differ in exactly the11 callback bodies and no
other byte. This matters: baseline/fields also changes the binding namespace.
The original four-role screen alone cannot attribute its entire improvement to
removing projection copies. Each private callback is limited to the fixture's
ordinary, finite, immutable constructor graphs; these assumptions are absent
from the public structured-input contract.

## Earlier screen, retained without upgrading its claim

The four-role screen used two rotated fresh-process trials,300ms warmup and
three approximately100ms samples per trial, with complete values checked outside
the intervals. Each lookup batch contains142 queries over a128-entry book;
infer_ref contains15 independently predicted success/error cases.

| Complete batch | baseline ms | direct ms | fields ms | combined ms |
|---|---:|---:|---:|---:|
|Cached lookup|17.651891|16.386199|9.544898|9.161812|
|Uncached lookup|79.333684|76.406948|45.187357|42.953975|
|infer_ref|0.685162|0.656377|0.456034|0.441869|

Baseline/fields ratios are1.85×,1.76× and1.50× respectively. Ranges are disjoint
for that comparison, but namespace binding is a confound and warmup is short.
Combined cached lookup has a34.90% half-sample drift; infer_ref has large drift
and outliers, including combined samples between0.4300 and0.8036ms. These are
not steady-state claims. The screen completed in48.833seconds. Peak child RSS
was213–222MiB depending on role/workload; it is not an allocation attribution.
All raw samples are retained in `selfhost/build/phase32/checker-fields-screen-01/`.

## Matched correctness and failure preservation

`checker-matched-controls-01/report.json` closes PASS with780 lookup observations,
75 infer_ref observations,9 public boundary cases and3 executed negative
witnesses. Complete values, successful definition identity, retained world
identity and unchanged input graphs are checked. The data includes duplicate,
missing, prefix, non-ASCII and astral names and the verified FNV32 collision
`costarring`/`liquid`. Expected lookup uses an independent list oracle, not the
compiler's index implementation. Selected checker results and diagnostics are
constructed independently from the branch contract. The exact captured/fields
eleven-body difference is asserted before observations.

The resumed controls ran alone under a768MiB V8 old-space allowance, a40second
deadline, a1GiB supervised process-tree RSS ceiling and a2GiB available-memory
floor. The supervisor observed146.8MiB peak summed RSS and completed in2.23seconds.
Those controls are acquisition observations, not program-speed measurements.

The negative witnesses remain decisive:

-A kind getter can replace G.dn during lookup. The original public entry sees
 the replacement; the captured private callback does not.
-An unselected field getter can mutate the selected name while `.slice()` reads
 every field. A private direct read omits that effect.
-An actually executed wrong-projection-index derivative fails the complete
 independent lookup oracle.

All original public variants retain the expected public observations. Their
unchanged behavior does not make the new private exports safe for hostile data.
Neither public record layout nor a once-per-entry descriptor check closes the
callback/mutation gap. See the [production-boundary audit](checker-production-boundary.md).

`checker-fields-controls-01` remains a failed attempt. Its observation helper
returned live getter-bearing values and the live event array. Repeated
`assert.deepEqual` comparisons themselves invoked baseline getters more times,
making later role comparisons fail. The sole correction in controls02 snapshots
the returned value through JSON and then copies events before comparing. Both
consumed tools and the original failure are retained; no compiler bytes changed.
The prior derivation syntax error and the weaker initial wrong-field witness
also remain documented in the [direct-call report](checker-direct-calls.md).

## Confirmation and decision

The [matched plan](../../design/phase32/checker-matched-projections.md) freezes
three rotated trials of all five roles,1.5seconds warmup, five approximately
200ms samples, one512MiB-old-space child at a time. The existing runner enforces
20seconds per child and240seconds overall. V8 old-space is not an RSS limit;
root separately checks available memory and serializes all heavy jobs. Timing
requires an exclusive CPU reservation. The raw plan is
`selfhost/build/phase32/checker-matched-plan-01/plan.json`.

The confirmation completed all45 serial children and225 samples in181.616seconds.
The outer supervisor observed267MiB peak summed process-tree RSS. All output
hashes agree within each workload. Import, fixture construction and full-value
verification remain outside timed batches. Medians include every sample:

| Complete batch | baseline ms | captured ms | fields ms | combined ms | Captured/fields |
|---|---:|---:|---:|---:|---:|
|142 cached lookups|18.582333|18.349123|10.410435|9.650954|1.763×|
|142 uncached lookups|85.603287|84.463429|52.285481|48.910855|1.615×|
|15 infer_ref cases|0.674029|0.679846|0.472667|0.446305|1.438×|

Matched projection removal saves43.26%,38.10% and30.47% of those batch times.
The captured/fields sample ranges are respectively18.143–18.776 versus
10.315–11.611ms;83.614–85.297 versus51.628–56.343ms; and0.67446–0.74520 versus
0.46510–0.54071ms. All three are disjoint. Merely changing the projection binding
has overlapping ranges in all workloads, with median changes of−1.26%,−1.33%
and+0.86%. Thus binding does not explain the large field-copy effect.

Direct callbacks after field removal save a further6.45%/5.58% on uncached lookup
and infer_ref with disjoint ranges. Cached lookup's apparent7.30% overlaps and
is not separately established. The combined private variant is1.93×/1.75×/1.51×
the original-call private baseline in this window; these ratios are not products
of the earlier screen's medians.

Longer warmup reduces some earlier instability but does not establish converged
throughput. Fields uncached lookup has half-sample drift from−14.18% to+6.53%;
fields infer_ref reaches+13.34%. Captured infer_ref includes a+6.25% last-two
versus first-two sample drift in one process. The direct-only uncached role
has a96.47ms outlier and−13.43% process drift. All remain in the results.
Peak child RSS is225–249MiB across the five roles and workloads; this remains
diagnostic memory use, not an allocation attribution.

The [machine summary](checker-matched-summary.json) audits every expected
trial/workload/role, exact child-result hashes, identical complete-output hashes,
all sample counts and comparison arithmetic. Raw plan, observations and bounded
outer receipt remain under `selfhost/build/phase32/checker-matched-*`.

Correctness: selected private and public-isolation gates pass, while two explicit
host-input witnesses prohibit public widening. Measurement: a matched1.44–1.76×
helper gain with retained drift and no whole-request result. Decision: retain
the experiment; defer production admission until a closed data/callback boundary
and complete request gates exist. No measured helper ratio can be converted to
a full checker/request ratio using overlapping inclusive profile percentages.
H17 is also distinct from the installed checked-B1 implementation.
