# Direct calls inside actual H17 structured helpers

The first bounded screen finds a small lookup benefit, not a general checker
speedup. Replacing exact unary projection calls with private direct callbacks
improves the cached lookup batch by1.086× and the uncached batch by1.060×.
A second structured helper, `infer_ref`, shows no demonstrated improvement.
These are private immutable-graph experiments; the installed compiler is unchanged.

The [prospective design](../../design/phase32/checker-direct-calls.md) uses the
actual H17 artifact from the Phase31 checker profile, not a synthetic rewrite
of its algorithm. Original H17 SHA is
`a7ffece566086a00c7b8224680ab320f1933e7ae7663fc765ed20eea5c8cdeb5`.
The entire original module remains a byte-identical prefix, including every
public G definition and default export. An appended separate namespace copies
14 definitions. The candidate changes26 saturated call sites to11 exact unary
record-projection callbacks. It retains argument arrays, `force`, `project`,
`slice`, constructor layouts, matchers and recursion through the original
trampoline. Baseline private copies retain the original calls.

## Selected correctness and independent challenge

`selfhost/build/phase32/checker-controls-02/report.json` closes PASS:

-312 complete lookup observations across original public/private entries,
  cached and uncached books, empty/duplicate/prefix/non-ASCII/astral names,
  absent names and the verified `costarring`/`liquid` FNV32 collision.
-30 complete KChecking observations across15 independent `infer_ref` cases:
  missing names, family refusal, demanded/erased references, different KTerm
  shapes, unfilled-law refusal, native/unsafe exceptions and filled success.
-9 public boundary observations preserve descriptor replacement, saved partial
  calls, raw/constructed callback behavior and record getter observations.
-The complete input graphs remain unchanged; successful lookup retains the
  original definition identity and checker results retain world identity.
-An executed wrong-projection-index derivative returns a missing definition
  instead of the expected complete definition and is rejected by the oracle.

The checker fixture/oracle constructs ordinary immutable constructor graphs
independently. Expected lookup uses first matching entries in a JavaScript list,
not the compiler's trie. Expected KChecking constructors and errors are written
from the branch contract. Full expected/public/private values are retained in
raw JSON; checks are not limited to a checksum.

Root independently reviewed the transformation and controls before timing. The
unary callbacks have no `this` dependency. The fixed original hash and complete
replacement inventory establish their original one-argument use here; the
scanner is not a general JavaScript optimizer and does not separately parse
argument cardinality. Generalizing this tool would require an AST/arity check.

The first controls run also passed. Its wrong-field witness was merely a
comparison of distinct records, so controls02 supersedes that weak witness with
an actually executed erroneous derivative; no compiler mismatch was hidden.
An initial Python parse error (`pass` used as a dict keyword argument) occurred
before derivation and is preserved at `checker-derive-failure-01/` together with
the consumed failed tool. The corrected derivation is `checker-direct-01/`.

## Public promotion has an explicit counterexample

A KDef kind getter can replace `G.dn` during lookup. Both unchanged original
public programs then observe the replacement and return a missing definition.
The unguarded private direct-call experiment returns the original definition.
The private baseline/direct difference is retained as an expected negative
witness. This is outside the trusted private experiment contract, and disproves
promotion of these callbacks behind only a once-per-public-entry guard.

No public ABI is weakened: the unsafe experimental behavior exists only on the
new diagnostic private exports. Original public definitions are byte-identical,
and no exact-worker registration or global runtime change is added. Private
success is not evidence for admitting arbitrary public recursive input types.

## First timing screen

The root reserved CPU3 exclusively. Two rotated fresh-process trials use Node
24.18.0, a4MiB stack and2GiB heap allowance. Each child builds the same128-entry
book fixture outside timing, warms for at least300ms, calibrates its batch
count, then records three approximately100ms samples. Each timed lookup batch
contains142 queries; each checker batch contains all15 oracle points. Full
values are checked outside the intervals. All warm/calibration/sample values,
RSS, exact tools/artifacts and half-sample drift are retained. Construction,
module import and verification are outside reported batch time.

| Complete batch | Original-call private copy | Direct-callback private copy | Speedup |
|---|---:|---:|---:|
|142 cached lookups|17.61570ms|16.22012ms|1.086×|
|142 uncached lookups|79.58548ms|75.10843ms|1.060×|
|15 infer_ref cases|0.662416ms|0.658699ms|1.006×|

Lookup ranges are disjoint in this short window. Cached baseline spans
16.85044–18.43734ms, candidate16.12615–16.29605ms; uncached spans
79.26993–79.82698ms and74.77861–76.46928ms. The second helper overlaps, with
half-sample drift as large as−26.23%/+21.34%, so its0.56% median difference
is not an established gain. Lookup half drift stays within approximately7%.
Peak RSS across children is about210–218MB; this is diagnostic process RSS,
not an allocation attribution.

The screen closes PASS in24.442s; `pass` records completed stable-input
observations, not an optimization admission. Raw evidence:
`selfhost/build/phase32/checker-screen-plan-02/plan.json` and
`selfhost/build/phase32/checker-screen-01/report.json`. Unexecuted plan01 is
retained because its prospective affinity wasCPU6; plan02 freezes the granted
CPU3 and binds the runner. No timed attempt was discarded or repeated.

## Decision and next boundary

Correctness: selected private/public isolation gates passed; public widening
has a counterexample. Measurement: small lookup-only signal in a short screen;
second helper inconclusive. Decision: no production promotion and no
whole-compiler speedup claim. A confirmation or a separate private-field-read
ablation must be frozen before further timing.

The smallest general production boundary remains internally produced data
inside an already closed graph, where no getters, callbacks or mutable public
function descriptors can be introduced between admission and use. Current
local-type admission deliberately refuses recursive KDef/List shapes. Broadly
removing that refusal would be a new proof obligation, not a consequence of
these timings. A host-facing projection fast path would need descriptor checks
at the actual invocation point after argument effects; its extra cost is not
measured here. Retain the original fallback until that cost and correctness are
established. Inclusive profile percentages must not be multiplied by these
helper ratios to predict request throughput.
