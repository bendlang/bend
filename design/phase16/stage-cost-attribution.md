# Attribute the complete checking cost before another optimization

The first populated-span comparison costs10.17% and the first wave4 comparison
11.88% more than Phase15. Three local scan/copy/width changes do not recover it;
an existing-index template-membership candidate is flat too. Sampled CPU owners
do not clearly identify which complete stage grew, and fused workers can hide
the logical helper calls (the first membership counter measured an eliminated
binding). Stop guessing at isolated functions until the stage boundary is known.

Run Phase15 and corrected wave4 on identical final wave4 compiler source, CPU0,
in four fresh processes ordered B–C–C–B, with all other compiler jobs closed.
Use each verified frozen host and separately validated API-bound Base cache.
After the normal host import, measure API loading and wrap each public compiler
entry point only to record elapsed time/call count. Pass the copied wrapper object
to the host's ordinary inspect API. Preserve arguments, return values, exceptions,
capabilities and all host source/cache checks. Do not change a compiler/host file.

Aggregate only actual host-to-compiler calls: raw/indexed parsing, graph loading
and elaboration, checking, TODO scanning, specialization, trust reporting, and
other public calls. Internal recursive calls are not intercepted. The remaining
request time is host work (filesystem/hash/source-range/cache validation plus
instrumentation overhead); it must stay visible rather than being assigned to
the checker. Preserve exact results and artifact identities, ordinary type/trust
checks and unsafe-definition sets. This instrumented attribution is diagnostic;
the uninstrumented matrices remain the authoritative speed comparisons.

Select the next bounded change from the largest reproducible added stage. If
checking itself dominates the delta, investigate allocation/metadata propagation
there; if loading/host validation dominates, inspect its traversals/retained
graphs. Do not use this probe to weaken any provenance or source-origin guard.
