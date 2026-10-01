# Phase34: generated-program diagnostics alongside bounded timing

Current compiler remains installed Phase32 checked03; Phase33 supplies fresh
fixed-input execution comparisons. Its broad gaps remain concentrated in generic
paths. Add repeatable diagnostics, not another compiler change. Preserve the
existing timing protocol and fast budget, all prior evidence and 103 unrelated
files. Read profiles together with generated source before proposing optimizations.

## Interface and boundaries

Add `diagnose.py` with the same catalog, sets, explicit cases, frozen reference and
prepared candidate selection. It can instead consume `--from-run DIR` to profile
the exact copied artifacts from a completed timing run. Add an explicit combined
`run.py --diagnostics all --diagnostic-budget 60` path. Diagnostic wall time is a
separate stated budget; no profiler runs during timing, and no profiled duration
becomes a performance ratio. Existing commands retain their behavior.

Every diagnostic run performs a true JavaScript AST census and compares TypeScript,
Bend baseline and optional candidate. Use Node's embedded Acorn, fail clearly if
unsupported, record parser/source/Node hashes, and never evaluate analyzed modules.
Record function/source ranges, call targets, allocation and control-flow sites,
closure/trampoline/BigInt syntax, normalized token forms, and definition mappings.
Separate known source definitions from shared runtime/Base code. Mark inferred
boundaries and unmatched/uncertain names rather than claiming a complete source map.
Generate JSON, Markdown and escaped standalone side-by-side HTML with source text.
Static sites do not establish dynamic frequency, allocations or semantic equivalence.

CPU profiles and sampled allocation profiles run separately in fresh serial
processes. Import, first-call validation and explicit warmup occur before profiler
start. Check every profiled result. Preserve raw Chrome/V8 profiles, weighted
self/inclusive frames, source locations, sample counts, exact profiling settings,
resource receipts and sampled-allocation limitations. Never add inclusive costs
across overlapping frames. Join locations to AST function/definition ranges;
retain unmapped runtime/GC/harness samples and low-sample warnings.

Use the existing shared execution lock, process-tree RSS and headroom limits,
explicit heaps and a total diagnostic deadline. Stop on errors, provenance changes,
interruption or budget exhaustion; retain partial artifacts and missing coverage.
Original timing success and later diagnostic failure must be distinct outcomes.
No kernel memory guarantee or universal steady-state claim is made.

## Validation and findings

Test invalid syntax without execution, strings/comments versus actual AST nodes,
function mappings, HTML escaping, artifact tampering, profiling boundaries,
wrong-result rejection, sample aggregation including recursive stacks, combined
command sequencing, unchanged timing ratios, partial diagnostic reports and
portable use without ignored compiler trees. Root alone runs all processes.

Run full-corpus static analysis, selected fast CPU/allocation checks and then broad
profiles including the slow originals within a justified budget. Reuse Phase33
uninstrumented timings; rerun only focused timing needed for integration checks.
Rank opportunities by current sampled costs, structural differences and cheapest
counterexample/control. Historical guarded-leaf regressions remain constraints:
counts removed are not evidence of a speedup. Preserve raw evidence, update the
README/design/report/experiment frontier, commit and push; post no PR comments.
