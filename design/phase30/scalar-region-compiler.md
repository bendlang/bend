# General closed scalar regions in the JavaScript backend

Prospective implementation plan, 2026-09-30. The disposable region experiment
confirms 2.679× on original Mandelbrot `bench(0,0)` after long warmup; per-call
guards regress 53.8%. That comparison changes both guard frequency and the
scope of eliminated calls. It justifies a compiler experiment, not promotion.

## Admission and representation

Extend the existing admitted Nat countdown worker. Keep its public Zero/Succ
matcher, successor partial descriptor, original argument-vector reads and
fallback loop. After full entry, validate native scalar state and the complete
helper dependency closure once, then execute a private version of the same loop.
No input coercion is allowed in the guard. The original fallback uses the slots
already read; it must not reread observable argument accessors.

Admit a bounded acyclic graph of nonforeign, nontemplate scalar helpers. Their
parameter prefixes consist only of live lambdas and exhaustive native Boolean
matches. Remaining expressions may contain scalar variables and literals,
annotations, parallel lets, existing identified scalar primitives and exactly
saturated admitted helper calls. Reject arrays, records, strings, callbacks,
computed globals, arbitrary matchers, recursion and unknown expressions. Preserve
the existing self-tail application spine of the Nat worker. Use explicit lazy
`kc` fences before recursive recognition. Cap helpers, depth and visited nodes.

Reuse KTerm only in private emitter copies: JSlot is a numeric positional
parameter, JCall a proven helper call, and JIf a native Boolean choice. Preserve
validated scalar annotations so let contexts retain types. Finish ordinary
checking, annotation and reachability before creating these nodes; never put
them in the public book. Existing primitive and let emitters remain authoritative.
The native IR is unsuitable here because its bodies already contain C and its
word representation discards scalar distinctions; see the native reuse audit.

The private plan contains rewritten Zero/Succ bodies and transformed helper
definitions. Emit one private helper table per admitted loop closure outside
the callback, so no helper descriptor is allocated per loop entry or iteration.
Retain the same BigInt counter, immutable iteration aliases, argument sequencing,
next-state temporaries and Zero-arm computation.

## Definition capture and guards

Capture original helper descriptors when their pure wrappers are constructed,
before assigning them to G. Never take the first public call as an origin. A
cheap scalar-signature superset limits registry work without a whole-program
prepass. Capture returns the same descriptor and uses a private null-prototype
table; public descriptor shape and identity remain unchanged. Missing snapshots
and forward references not yet initialized decline the fast path.

At entry require own G data bindings and original descriptor identity, arity,
code, null environment and empty bound-vector identity. Reject metadata
accessors without invoking them, replaced bindings, callable `.call` overrides
and altered descriptor prototypes. Preserve the documented standard-intrinsic
contract; explicitly test primitive-prototype hook witnesses and either reject
them with the guard or document their excluded scope. No admitted operation may
mutate the guarded state during the synchronous region.

## Validation and measurement

Build a fresh checked B1; first emit the exact small Mandelbrot fixture and
original `bench(0,0)`. Inspect that nested helper calls are private and all
fallback bodies remain. Compare independent scalar oracles, 50,000 iterations,
partial/saved descriptors, mutation before first call, later-declared helpers,
slot/metadata/G getters, invalid scalar inputs, code.call overrides, parallel
lets and branch-specific binders. Include renamed and structurally different
sources plus scalar-returning foreign and recursive rejection cases.

Only after those checks, freeze outputs for exclusive serial CPU3 screen and
long-warm confirmation against Phase29 and pinned TypeScript. Record startup,
generated size, compiler acquisition, source lines and concepts separately.
Run broader backend integration once a candidate survives. Preserve every failed
attempt. Phase29 remains installed until the complete candidate is reviewed.

Root owns worker/emitter integration and checked builds. Analysis agent owns the
new region analysis/lowering module. Review agent owns runtime snapshot guards
and independent boundary controls. Prototype agent owns exact-arm integration.
These source edits may proceed concurrently; performance measurements may not.
