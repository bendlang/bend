# Count current declaration replacement work before choosing a correction

The fresh installed CPU profile attributes 2.889% of signed exclusive samples
to index_remove and its generated reconstruction thunk. Most physical stacks
lose the outer caller, so they cannot distinguish book replacement from hash
collision buckets or short-book final selection. GC is material, but a broad
heap sample is less decisive than a bounded entry/construction census here.

Use a new instrumentation-only copy of the exact API44094e58. Add counters only
at its four existing external index_remove call sites and its existing Nil,
remove and retained-Con branches. Carry one diagnostic record and an explicit
after-first-match bit through its existing recursive calls. Keep all original
comparisons, projections, recursive demand and returned list constructors.
Record roots, empty/nonempty visits, removed matches, retained Con construction
sites and retained cells after the first removed match, separately for cached
book_put, uncached book_put, index_leaf and book_final_legacy. Missing routes or
unfinished roots invalidate the census. These are executed original constructor
sites, not physical V8 allocations; instrumented time is not a speed result.

The worker uses the existing host's explicit inspect(...,{api}) diagnostic
injection with the counter API. Its original API path remains the source of
the original current Base-cache identity. No cache is modified, relabeled or
regenerated: the same currently validated cache is a frozen input to this
counter-only experiment. Record that distinction explicitly; the instrumented
image is not a checked production artifact. All host/runtime/source bytes stay
unchanged. Compare the full returned observation to the ordinary profile result,
excluding only the adapter-added hostProvenance field because the worker calls
the unchanged driver directly. Verify input identities before and after.

Freeze the counter tool and worker before execution; retain the full instrumented
API and exact patch. CPU0, Node24.18, stack4MiB/heap4GiB, ordinary identical
Phase21 source. No compiler source edit, build, installation or optimization is
authorized by this census. A proposed suffix shortcut must still preserve
duplicate removal, first-definition precedence, list order and lazy demand.
