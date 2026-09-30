# Checked lexical helpers and nested terminal regions

The actual compiler now emits lexical private helper functions and can include
a proved nested Nat countdown inside a scalar region whose final result is a
flat record. Attempt08 isolates the lexical spelling change; attempt09 adds the
terminal-record and nested-loop admission. These are checked experimental
compilers, not yet the installed release. Actual terminal output now passes
longer-warm confirmation as described below.

The plans are [lexical integration](../../design/phase30/lexical-helper-integration.md),
[terminal extension](../../design/phase30/terminal-region-compiler-extension.md)
and its [initial field boundary](../../design/phase30/terminal-region-admission-boundary.md).
The isolated output experiments are reported separately in
[lexical-private-helpers.md](lexical-private-helpers.md) and
[terminal-record-region.md](terminal-record-region.md). Their prototype timings
do not substitute for actual compiler-output measurements.

## Implementation

The lexical change preserves `JCall` names and type lookup, replacing the private
dictionary and property calls with local function declarations. An identifier
encodes every source character as a delimited decimal codepoint, preserving case,
punctuation and Unicode without a name map or new IR field. The checked name
fixture and synthetic backend name controls cover the collision boundary.

The terminal extension accepts only parameterless, unrefined, nonnative Data
with one local constructor and at most 32 live, nondependent scalar fields.
Fields in the terminal constructor are immutable scalar variables or scalar
literals. The ordinary `build` and field thunks remain. Scalar checks at binding
RHSs and argument telescopes prevent records from becoming loop state or private
helper parameters/results. Computed deferred fields remain unsupported.

The existing Nat shape proof is shared by public workers and nested helpers.
A nested helper retains its Mat/Lam structure and uses the existing loop and
zero-arm emitter, including an explicit initial zero check and predecessor
setup. Its two arms share the enclosing active-name chain, completed-helper
cache, depth and fuel. A fresh nested analysis state would weaken cycle and work
bounds, so none is created. No runtime change, new IR node, analysis-state field,
record representation or pattern compiler is added by this extension.

Relative to the prior committed attempt07 source, the two changes together add
99 net physical Bend lines across three files: 11 for lexical spelling and 88 for
the terminal extension. The latter estimate includes extracting the existing
shape predicate rather than duplicating it. This is bounded additional compiler
functionality, not a claim of overall source-size reduction.

## Checked artifacts and semantic gates

Both attempts pass the 36 focused exact checks. Build plus focused validation
took 37.190 seconds for08 and 37.941 seconds for09. These are acquisition
durations, not comparative compiler-throughput measurements.

Attempt08 passes the original 22 admission books / 13 executions, 146 same-runtime
ABI/effect/prototype observations, 72 scalar-oracle executions and nine entry
controls. The real checked name fixture passes 45 numeric points; synthetic name
controls cover 18 distinct helper names and 15 loop executions. The initial
synthetic name fixture omitted required native Bool ownership and was refused;
that failure remains preserved before the corrected fixture. See
[independent-integration-08.md](independent-integration-08.md).

Attempt09's actual original Mandelbrot emission passes 200 independent full
histogram states and 129 public mutation, coercion, entry, overapplication,
callable-shape and field-forcing observations against08. Two instrumented internal
controls compare the original bounce and optimized delayed build, require eight
field thunks, and verify that a later invocation cannot overwrite saved fields.
The same controls check the original program's small outputs. Raw evidence:
`selfhost/build/phase30/terminal-compiler-controls-09/`.

Independent synthetic09 controls pass 41 admission/refusal books and 88
executions. Separate bounded probes refuse a depth-17 mixed graph, 33 helpers and
shared Zero/Succ fuel exhaustion. These are backend KTerm probes, not additional
frontend-conformance rows. More precise neighboring budget witnesses are pending.
The [static review](terminal-compiler-static-review.md) records the admission,
forcing and shared-state arguments with source hashes.

## Mechanism counts on actual output

Instrumentation is separate from timing. Counts describe named runtime events,
not total heap allocations or sampled CPU shares.

| Workload and event | Attempt08 | Attempt09 |
|---|---:|---:|
| Chunk64: generic applications | 2,242 | 3 |
| Chunk64: function descriptors | 1,281 | 2 |
| Chunk64: tail messages | 449 | 2 |
| Chunk64: delayed record builds | 1 | 1 |
| Chunk64: closure guards | 64 inner | 1 outer |
| Original `bench(2,0)`: generic applications | 21,068 | 12,112 |
| Original `bench(2,0)`: function descriptors | 12,858 | 7,742 |
| Original `bench(2,0)`: tail messages | 3,603 | 1,815 |
| Original `bench(2,0)`: delayed record builds | 8 | 8 |
| Original `bench(2,0)`: closure guards | 512 inner | 4 outer + 256 inner |

The larger remaining whole-program count motivates a separate ordinary scalar
function-root experiment; it does not weaken this extension's admission.

One small redundancy was retained in09: widening snapshot eligibility to Nat
signatures causes a scalar Nat worker to be captured twice at initialization.
Both captures record the same fresh descriptor, so the established behavior and
runtime observations agree. A later source cleanup can route the already-captured
worker directly to its G assignment. The record-valued owner is captured once.
This observation is not a measured performance explanation. Attempt10 removes
the redundant capture with a direct assignment of the already-captured Nat worker.
It passes 36 focused exact checks (38.747 seconds acquisition), and its helper
fixture is byte-identical to08. Its original Mandelbrot emission again passes
200 histograms, 129 boundaries and both internal delayed-build controls against08.
The09 source and evidence remain intact.

The frozen actual timing configurations are
`selfhost/build/phase30/terminal-compiler-plan-09/{screen,confirm}.json`.
They compare unchanged original program inputs and the same complete chunk
checksum used by the prototype. Installed release and broad conformance remain
separate promotion gates.

## Actual terminal timing

`terminal-compiler-screen-09` retains the short screen, including its warmup
drift. `terminal-compiler-confirm-09` uses five rotating fresh-process samples,
at least 100 calls and three seconds of warmup, then 300 ms timed targets on
exclusive CPU3. Its outer wall duration is 106.12 seconds. Every call checks its
complete result; diagnostic modules are excluded.

| Workload | Attempt08, ms | Attempt09, ms | Pinned TypeScript, ms |
|---|---:|---:|---:|
| Original small Mandelbrot | 8.99647 | 5.02145 | 0.0455015 |
| Complete histogram chunk64 | 0.998604 | 0.0262920 | Not measured |

The original program improves **1.792×**, with disjoint ranges of 8.88093–9.13034
and 4.99750–5.03987 ms. Its remaining TypeScript ratio is **110.36×**. Timed halves
differ by at most 1.62%. The chunk improves **37.981×**, also with disjoint ranges;
four candidate samples have half drift at most 2.14%, while one drifts −6.79%.
Keep that residual drift visible. The earlier screen suggested 40.7× and is not
the settled ratio.

The lexical helper spelling explains why this actual compiler chunk improves
much more than the earlier dictionary-shaped terminal prototype. The two effects
were first isolated, then measured in the actual implementation. The full program
still spends most of its time outside the optimized chunk; these results do not
claim a similar gain for other original programs or compiler throughput.
