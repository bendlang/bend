# Reuse the already computed emission stop set

The earlier API trace contains a simpler opportunity than an analysis cache.
The typed driver calls `j_stops(contextBook)` once to prune reachable definitions
and again to annotate them. `contextBook` is unchanged. The instrumented calls
take about100ms each on all three selected inputs; those are inclusive diagnostic
costs, not an isolated speed forecast.

Test this at the existing private actual07 experiment boundary. For each normal
library request, wrap only the external `j_stops` API entry. Capture its first
argument identity and fully returned value. On the second call, require exactly
the same book identity and return the captured stop list; refuse a third call.
All other exports are the unmodified genuine actual07 API. No internal compiler
function, IR, semantic check, Base cache or output path changes. Drop the captured
book/list immediately after the request. This models reusing the existing local
variable; it is not a general-purpose or persistent query cache.

Reuse the verified original15-case full observation oracle from scoped memo
correctness02, then run one fresh candidate through those15 cases. Failed checks
must execute zero stop calls, successful selected emission must execute two
external calls but one actual computation, and each reused book must be identical.
Compare complete diagnostics, dependency lists and output hashes. Only after
equality passes, freeze the same four-process serial screen with768MiB heaps,
the same three priming/timed sources and thresholds. Record both stop calls and
the computation avoided; no inference from the older instrumented trace alone.

Production would be a one-line driver change from a repeated call to its existing
`stops` local. The lead must review the public injected-API contract: arbitrary
`options.api` callbacks may be impure or mutate their input. A private experiment
with the exact known Bend API does not establish compatibility with those hosts.
No production file is changed by this investigator.
