# Exact-state semantic reuse: prospective diagnostic

2026-09-30. Baseline `5f3015d`, actual checked07 API `d8f609c9…`.
Owner: reuse investigator. No production change or performance claim.

The existing persistent inspector already keeps a decoded immutable Base graph,
keyed by compiler/Base/source location and reread cache bytes. The current
`check_program_diagnostic` rechecks the whole world. `diagnostic/produce.bend`
explicitly rejects a source-only validated prefix: it cannot restore the live
specialization memo, checked outputs or fresh-name state. We preserve that rule.

Hypothesis: some complete `check_definition_world(world, definition, depth)`
queries repeat across small edits. Count complete arguments, not merely unchanged
source definitions. The world includes the full declaration book, memo, fresh
allocator and previously checked definitions; source coordinates remain included.
Exact key equality is necessary here, not proof that a weakened dependency key
would be safe. A second count of definition-only equality shows the misleading
opportunity that would result from omitting dependencies.

Derive an instrumented module from the frozen checked07 generated API, keeping
the original driver, runtime, Base and validated Base cache. Append wrappers to
named internal functions; the ordinary driver still discovers and checks each
request. Hash nested plain values by SHA256 with a request-local WeakMap to visit
each shared object once; cap at one million objects/request. Reject functions,
cycles and non-data values. Limit recorded rows to 10,000/request. These are
diagnostic counts, not timings. Preserve the exact original API bytes/hash and
the consumed derivative/harness/plan. Bound each producer to120seconds on CPU2;
retain any resource failure and do not silently drop it.

Use one fixed-path edit sequence: existing H positive source unchanged twice,
same-length body literal change, type error, restoration, signature change,
comment/source-coordinate shift and import/dependency change. Add original
edit-distance and Mandelbrot requests to avoid concluding from a tiny source.
For each request, compare full observations (including errors and dependency
paths) and emitted-byte hashes against the unmodified actual07 API in the same
host environment. Instrumentation must not substitute a positive parse for a
type-check. Report source/definition/state repeat counts separately.

If complete-key hits survive edits, a second frozen experiment may cache only
that complete immutable state and resolved result, verify exact structural
equality after hash lookup, and compare every result against full checking.
No origin stripping, body-only cache, API identity omission or reuse after cache
mutation is permitted. Measure key creation, memory and end-to-end edit latency
in a separately granted clean window before considering production. If hits
vanish or key construction dominates, reject this prototype and specify the
state/dependency interface that a future design would require. Do not rewrite
the checker to manufacture a hit.
