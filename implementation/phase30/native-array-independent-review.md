# Array marker callbacks and the closed-region boundary

The new direct-native owned-row variant passes 54 additional independent paired
observations. A retained counterexample demonstrates why its added Array
prototype refusal is necessary. These are disposable output experiments; no
compiler or maintained runtime changed.

`review-owned-native-markers-01` compares the unchanged probe with
`prototype-owned-native-01/private_native.mjs`. It passes 12 request/bounce/
build/code marker logging, throwing and mutating cases, plus 15 native
code/arity/env/bound/call changes before the first probe use. The before-first
controls use fresh module instances and require the altered behavior to be
observed. `review-owned-native-deferred-01` passes the previous 27 independent
raw/constructed deferred-result, saved-bounce, aliased/proxy/foreign-array and
Object-prototype observations with the new native variant.

A tuple-only Array.prototype.bounce getter replaces G.umin after the region's
initial snapshot guard and changes its scalar result. The original public code
observes the replacement. The older private-row variant bypasses it and produces
different complete arrays. That old artifact explicitly assumed ordinary Array
intrinsics; this witness lies outside its frozen claim and is retained without
rewriting the old evidence.

The new native variant checks for these Array prototype markers before private
entry. It therefore falls back for the whole probe and matches the original
values and ordered trace. Retaining force at the native Array.get demand point
is necessary but would not by itself fix the stale-dependency problem: the
getter can execute arbitrary code and invalidate a one-time closure guard.

The direct native substitution otherwise retains the original arrayfill/get/set
implementations, four root allocations, all private read sites and the setter
inside its original Dp field thunk. Public definitions and gen/init remain
unchanged. The full root result is forced before private execution ends. Native
operation counters and performance measurements belong to the prototype owner's
separate reports, not to these independent reviewer executions.
