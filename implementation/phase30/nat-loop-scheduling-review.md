# Existing Nat-worker scheduling and live-self gap

Independent actual-emitter controls found a correctness gap in the existing
Phase29 Nat worker, inherited by Phase30 attempt03. It is separate from the
new helper-closure admission tests. The older compiler used for Phase28
measurements is Phase27 attempt02; both actual j_library APIs emit the same
small synthetic Nat/U32 loop, using their own frozen runtimes.

`selfhost/build/phase30/review-nat-loop-scheduling-01/report.json` preserves the
full books, generated modules, input hashes and five concrete differences.
`review-nat-loop-scheduling.mjs` can rerun the same controls in `repaired` mode
against a future candidate, requiring exact equality instead of retaining the
counterexamples. No closed evidence was changed.

## What differs

The original fully entered successor callback computes its first next-state
arguments and returns a bounce for the next recursive call. The optimized
callback eagerly executes the remaining iterations and final Zero arm. Usually
public call immediately forces either representation, hiding that distinction.
Generic apply's oversaturation path has observations between callback return
and forcing: it rereads the copied vector length before deciding whether to
force and apply remaining arguments.

The witness supplies a custom slice result whose length getter records those
reads. All five observations differ:

- Ordinary oversaturation: the optimized loop executes a second step before
  the post-body length read, while the original executes it after that read.
- Length-getter mutation: changing G.step on that read changes the original
  remaining step from increment-one to increment-ten. The subsequent expected
  overapplication error names scalar 18 originally and scalar 9 in attempt03.
- Length-getter exception: both throw the same sentinel, but attempt03 already
  executed the second step that the original never executes.
- Direct raw callback invocation: originally it returns a bounce after one
  step; attempt03 returns a scalar after two. Forced results agree, but the
  raw scheduling boundary and prior effect trace differ.
- Live self replacement: the first helper call replaces G.loop. The original
  evaluates the already captured next target, then sees the replacement on the
  following recursive lookup and returns 1009. The optimized loop skips those
  lookups, runs all three increments and returns 10.

The copied vector is reached through actual runtime apply, not by substituting
an imitation runtime. The loop callback is actual emitted code. Synthetic IR
isolates the backend boundary; this report makes no new source-checker claim.

## Repair constraints

Delaying the entire callback into a private bounce is insufficient: it would
move the original first-step effects past the same length read. A continuation
repair must compute the original first step first, preserve its target lookup
before argument effects, then defer later work. Guards must run when the
continuation is forced, because the intervening length getter may mutate G or
descriptor metadata. Failed guards must resume the actual already captured
target and arguments, not re-evaluate source expressions.

The live-self gap is broader than cold oversaturation. An optimization that
skips recursive lookups needs a proof that the helper region cannot mutate
G.self and that the original self binding/descriptor has not changed. Existing
generic fallback loops cannot satisfy that proof when arbitrary helper calls
remain. A raw callback must retain its original deferred-return behavior.

An alternative under review is to permit only fully pure closed scalar loops
entered by the exact-saturation runtime application path. Unknown/cold/raw entry
would use the original generic body. This requires a private entry witness tied
to both actual callback identity and its argument vector, guards for callback
call hooks, and the self descriptor in the dependency snapshot. A reentrant
global depth flag alone is not sufficient. Neither repair is yet validated or
promoted by this report.

## Selected correction under implementation

The lead selected the exact-entry approach. Failed purity plans now decline the
Nat worker entirely; admitted plans retain an original generic callback fallback.
The recursive owner's descriptor joins the original helper snapshots, including
the empty-helper case. A runtime-created callback consumes an entry token tied
to its code identity and argument-vector identity before any slot getter runs.
Only exact-saturation apply can create this token, after evaluating the original
code.call and environment in their original order. Cold oversaturation remains
unchanged. Finally restores the previous token even on exceptions.

Static review found no blocker in that shape. A global depth flag would have
been insufficient: slot getters can reenter the same callback with the same
vector. The consumed bit must prevent that nested raw entry from obtaining the
outer permission. Owner/helper guard failures and raw entry execute the original
generic tail body using already read slots, preserving delayed recursion.

`review-scalar-entry.mjs` is prepared to compare the actual repaired output with
the preworker checked Mandelbrot module. Nine controls exercise environment
getters, code metadata reads, code.call hooks and ordering, reentrant same-vector
raw entry, nested exact then raw entry, and cleanup after exceptions. The
broader execution suite now includes owner mutations and capture checks. The
admission suite now expects unsupported plans to emit no Nat-worker marker and
an empty pure helper closure to remain eligible. These revisions are prospective;
earlier results preserve their exact consumed tools. No repaired-artifact pass
has yet been claimed here.

The later actual attempt07 now passes all five retained counterexamples in
`review-nat-loop-scheduling-03`, with zero differences from the preworker output.
Nine actual entry/reentrancy cases pass in `review-scalar-entry-03`. The full
bounded review and remaining scope limits are consolidated in
[independent-integration-07.md](independent-integration-07.md).
