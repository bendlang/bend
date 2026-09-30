# H17 checker profile within the real request

Prospective diagnostic, 2026-09-30, after the completed
[outer attribution](../../implementation/phase31/h-attribution.md). The parent
permits one bounded CPU 2 profiling acquisition overlapping correctness work.
No clean comparative timing or production change is authorized by this plan.

The outer trace places about 77–80% of later request time inside the generated
`check_program_diagnostic` invocation. Source inspection shows that this export
calls `dg_check_world`, including initial bound/declaration processing and a
definition-event loop, followed by completion. Its `validated` parameter is
currently unused. This is an observation, not permission to skip Base checking:
world-dependent definitions, event ordering and cache validity must be proved
before reusing semantic results.

Phase 30 CPU profiles concern the local array-row and scalar fixtures. Their
apply/force and call-site observations cannot be assigned to today's checker.
Node's built-in Inspector CPU profiler, already used by the maintained Phase 30
tools, needs no installation and can preserve a standard `.cpuprofile` artifact.

Derive the exact successful Phase 31 H-attribution worker into a fresh path.
Keep the immutable H17, parent provenance, driver, ABI adapter, Base, source,
actual-hash cache, expected output and normal three-request sequence unchanged.
Profile only the second request, after one ordinary warm request, using a
1,000-microsecond sampling interval. Use the same 90-second child and
110-second outer deadlines on CPU 2, with total new artifacts below 40 MB.

Add monotonic `process.hrtime.bigint()` timestamps to the existing trace events.
Retain profiler start/end clock anchors and check that they agree with the V8
profile time domain; reject incompatible timestamps. Select the samples within
the exact `check_program_diagnostic` invoke→decode interval using cumulative
profile `timeDeltas`. Do not silently map an unaligned timeline.

Aggregate sampled self frames by runtime function and generated source location.
For H source lines starting `G["name"]=`, map the location to that definition;
retain line, column, function name, URL and source excerpt to expose uncertainty.
Also report inclusive occurrence on sampled stacks, clearly separate from self
samples. Trampolines and JIT inlining can obscure logical Bend call chains;
sampled runtime dispatch cost is not proof of which tiny runtime operation
causes it. Garbage-collector samples do not represent all allocation cost.

Verify all three output hashes and full observations and unchanged cache/inputs.
Retain the full original/derived worker, patch, profiler data, complete traces,
commands and receipts. A profile is a prioritization diagnostic; no H/parent
ratio, speedup, stable CPU fraction or compiler promotion follows from it.
Recommend a next ablation only when the observed hot frames and relevant source
agree, and preserve unresolved attribution rather than inventing counters.
