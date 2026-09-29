# Phase16: use the actual failing binder or proof range

Prospective bounded follow-up on the shared eight-field source. The source-span
owner's integration04 now makes 160 of 169 assigned checker observations exact.
Eight remaining rows originate in existing checker error producers: local-let
kind or quantity failures do not retain the local Bind range, and a non-equation
rewrite reports its whole Rwt instead of its proof. The ninth row, an erroneous
datatype note on an F32 literal, needs a real literal-versus-written-constructor
identity boundary and must not be guessed from source text or coordinates.

For local kind checks, pass the available Bind as the diagnostic site while
checking the same inferred type. Preserve the deepest original expected/observed
terms and context. Attach a site override and the Many-binder note only when the
error is the immediate kind check. Strengthen the existing predicate with equal
nonzero begin/end intervals when both original terms have ranges; if either has
no origin, retain its current structural predicate. Nested unrelated errors must
keep their own range and note. Existing All/lambda call sites retain their current
site to avoid changing already exact rows without evidence.

For local quantity closing, carry the existing checker environment and outer
context to check_let_done, and create its DTrace at the offending Bind. No new
source lookup or structural matching. Pinned uses_close checks parallel binders
in source order after the body succeeds; freeze and actually run a two-erased-
binder boundary before changing this order. If the old reverse accumulator
chooses the later binder, correct that through the existing close worker without
adding a second quantity checker or success-path list reversal.

For a rewrite whose inferred proof type is not Eql, produce the existing detail
under a trace of kid(Rwt,0), preserving the proof's real source interval. Do not
change checking order or re-infer the proof.

Own check/kernel.bend and diagnostic/trace.bend only, on a fresh isolated shared
source copy. Start with the eight corpus rows and six custom controls: local
Many-function note, nested undefined failure without an outer note, two erased
binder failures, body error before quantity closing, valid erased parallel lets,
and valid live parallel lets. Reuse the original nested equal-type note witness
and prior 84 observations. Baseline first, genuine checked B1, unchanged primitive
outcomes and no lost strict matches. Preserve the ninth literal-note gap and
coordinate its explicit syntax origin with the parser owner/root.

## Prospective control correction before implementation

The first two parallel-erased fixtures incorrectly wrote `-a -b`, which the
pinned parser rejects before checking. `parse_body` consumes one None prefix
for the whole parallel group, so controls02 writes `-a b`. Retain controls01,
the old-workflow/cache-v4 setup failure, and the completed probes whose selected
contract failed. Run controls02 against the unchanged shared integration04
before claiming source-order evidence or editing quantity closing.
