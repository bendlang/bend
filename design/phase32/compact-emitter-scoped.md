# Scope query reuse to emission, then stop on a negative screen

The first memo screen preserves every complete observation but loses13.1% on
the small source,6.65% on Mandelbrot and8.81% on edit distance. Its diagnostic
wrappers replace `wnf` globally, including checking when their cache is inactive.
That mechanism does not isolate the prospective emitter-local optimization.

This second saved-code experiment starts from the exact unmodified checked07
API. It changes eight function bindings only while the ordinary
`j_library_selected` export executes, restoring every binding in `finally`.
There is no global hook, checker wrapper, semantic checkpoint or retained cache.
The queries and complete identity keys are those in
[the first design](compact-memo-prototype.md). Resolve trampoline results before
caching; cap all query tables together at4,096 entries per emission, then keep
using the original functions for new keys. Tables die when emission returns.
This is a private immutable-input experiment, not a public host-API cache.

Preserve the complete original API hash and appended bytes. Serial workers
first compare all15 existing positive, body/signature/coordinate/import/error
requests against original full observation, dependency and output-byte hashes.
Each worker has a768MiB V8 heap,4MiB stack and90second outer deadline; run only
after the lead grants the one heavy-work slot. One worker at a time, no cached
semantic worlds and no old all-family diagnostic wrappers are loaded.

Only after correctness passes, freeze a clean baseline/candidate/candidate/
baseline screen. Each fresh process executes small, Mandelbrot and edit-distance
requests twice: first triad is priming, second triad is timed. Include every
normal request cost, emitted bytes, cache hits/entries and peak RSS. Verify
source, driver, original API, derivative, runtime, Base/cache, worker and Node
hashes before and after. CPU2; each child90seconds, whole screen180seconds.
Advance only for at least3% median improvement on both larger programs, disjoint
ranges on one, and no greater5% small-source regression. Two samples per arm are
an inexpensive screen, not a promotion measurement. A negative result closes
this query-identity hypothesis rather than motivating a larger cache.

No production source or installed release changes. A surviving result still
needs public getter/proxy/reentrancy review and a trusted private entry before
any maintained bootstrap derivative can safely adopt it.
