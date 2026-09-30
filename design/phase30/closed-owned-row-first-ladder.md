# First bounded closed-array row ladder

This freezes the first acquisition requested after the broader
`closed-owned-edit-distance-region.md` proposal. Production compiler source is
unchanged. Use the canonical editdist source verbatim, with one appended checked
`row.probe(n: U32, seed: U32) -> Dp` definition. It converts n to Nat, generates
two n-element sequences into fresh 128-slot arrays with the existing `gen`,
initializes n+1 previous-row entries with `init`, creates a fresh zero current
row, and runs the unchanged source `row(n,0,seed & 3,state)`.

The admitted diagnostic domain is n <= 64 and immediate U32 seed. Public calls
outside that domain take the original body. Both checked attempt12 and pinned
TypeScript compile the exact same file. Complete-array observation occurs only
after the returned Dp is fully forced. This diagnostic record result exposes
state for oracles; it does not broaden the proposed scalar-returning production
pair admission rule.

Four candidate-runtime variants use byte-identical original public row/cell
definitions and the same public probe ABI:

1. Checked baseline.
2. Exact guarded private probe, a private copy of the original row trampoline,
   and private acyclic cell calls. Projection, field-vector slice, cold matcher
   behavior, Array native calls, minimum/Bool calls and build/force are retained.
3. The preceding variant with private minimum and Bool helpers using unchanged
   primitive expressions on proved local scalar values.
4. If straightforward, replace only the private row trampoline with a BigInt
   loop. Force each private cell at the original non-tail demand point, use
   fresh iteration aliases, preserve U32 index increment and execute the original
   public zero-row arm to perform the final swap. The public row is unchanged.

All optimized variants have a single identical entry guard over row.probe,
prng, gen, init, row, the five cell helpers, umin, umin.go, b2u, and Array.new,
Array.get, Array.set. Capture these exact original descriptors once at module
initialization after the original definitions, before any exported invocation.
Reject any replacement, accessor, descriptor change or runtime prototype marker
hook. Never first-use capture. The private paths cannot expose any container or
invoke foreign code before finishing under that guard.

Keep original cold cell bodies as private helper fallbacks. No public helper is
redirected into a private path. Reentrant slot/env reads happen before the guard;
raw, forged, hooked, constructor and oversaturated probe entries use the generic
body. Direct public row/cell tests must remain identical on foreign arrays.

Independent Python full-array expectations use the source xorshift recurrence,
complete initial arrays and scalar dynamic-programming recurrence for n in
0,1,2,7,16,32,64 and seed in 0,1,17,4294967295. Additional host controls inspect
fresh storage across calls, four distinct handles, untouched input arrays,
retained prev/cur aliases and next-operation visibility. Hash all exact source,
emission, derivation and control tools. Counters and diagnostic copies are never
timed. Keep the same representative row32 seed17 point after semantic checks.

Stop expansion and retain evidence if closure, identity or delayed field forcing
cannot be established. Native-call replacement, gen/init private loops and full
pair optimization remain later ladder steps, not part of this bounded task.

Independent review requires the local proof to cover deferred fields through
complete public forcing. The admitted exact probe therefore explicitly returns
`force(privateExpression)`: every local Dp build and Array.set field bounce is
finished before the guarded callback returns. This moves forcing across the
exact callback return only on a path with no later outer metadata read and no
host observer between the original return and public force. Raw/new/overapplied
callbacks retain the original deferred generic expression. No private build may
escape and later bypass a changed global outside the guard's lifetime.
