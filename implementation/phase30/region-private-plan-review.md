# Review: private emitter nodes and original descriptor capture

Prospective static review of the proposed general scalar-region implementation.
No compiler execution or production correctness claim follows from this file.

## Capture at definition construction

Capture the freshly emitted function descriptor before assigning it to G, and
return that exact object from the capture helper. Lazy first-call capture is
unsafe: a host could alter code or bound arguments before the first call and
the cache would mistake the altered descriptor for the compiled original.

Store metadata in a private table with no prototype; do not add properties to
the public descriptor. Capture its original object, own scalar arity, code,
null environment and empty bound vector. The entry guard subsequently checks
the G own data property and descriptor metadata against that snapshot, including
the code function's call/prototype behavior. Capturing metadata does not itself
prove that the function is pure or safe to inline.

A useful narrow implementation registers a cheap superset: ordinary,
nonforeign, nontemplate definitions with a pure leading Lam/Mat wrapper and a
bounded native-scalar signature. The independent region analysis still proves
their bodies and dependency closure. This avoids either registering every large
compiler function or introducing a whole-program registry prepass merely to
identify exact capture sites. Computed zero-arity globals and native runtime
entries need not be registered in the first implementation: helper admission
rejects them, and reviewed primitive calls are emitted directly.

Forward references do not require lazy snapshots. All ordinary definitions and
their captures are constructed during synchronous module initialization before
normal library invocation. If a required definition was omitted, conditionally
skipped or otherwise has no snapshot, the region guard declines. It must not
capture the current G entry as a recovery shortcut. Last-definition behavior
must stay aligned with the actual emitted G assignment if a supported emitter
can emit a name more than once.

Pure Lam/Mat wrapper construction has no user computation. The wrapper must not
invoke a zero-arity initializer or execute an arm to obtain its snapshot. This
keeps new capture work to ordinary private allocations and own-data reads under
the standard-intrinsic/prototype assumptions.

## JCall, JIf and JSlot boundaries

Small emitter-only nodes can reuse the existing primitive and let emitters
without replacing the compiler core. They should be created only in a private
fast-path copy after ordinary checking, annotation, reachability and relevant
lifting/admission. The original KDefs and fallback bodies remain unchanged.

JCall records a proven private callee and its exactly full scalar arguments.
JIf records a native Boolean decision and same-typed scalar branches. JSlot
records a numeric generated parameter slot, not arbitrary JavaScript source.
The dependency closure and scalar types belong to the private plan; they must
not be rediscovered by ordinary global reachability from unfamiliar tags.

Type information must survive rewriting. Existing let context construction uses
j_type on each RHS. An unknown JCall would otherwise produce Absent and could
alter later application/type-dependent emission. Wrap rewritten nodes in their
validated scalar annotations or explicitly extend j_type for the private
nodes. Do not rely on an ignored type merely because one fixture still emits.

Audit traversal boundaries before using ordinary subst, normalization,
freshening or lifting on these tags. A pass that only recognizes core tags may
silently skip private-node children. Substitute source parameters to slots
before introducing JCall/JIf unless generic traversal is verified. Keep the
loop's own self-tail App/Ref spine in the shape expected by existing Nat-loop
lowering; only admitted helper calls become private direct calls.

The private plan must distinguish region-local helper references from ordinary
global references. Direct helper code has no per-call guard, so a missed callee
dependency or accidental residual dynamic call invalidates the closure proof.
Unknown/private-malformed plan shapes must decline during construction, not
emit null through a generic unknown-tag fallback. Depth, node, parameter and
dependency budgets remain explicit.

## Reviewable tradeoffs

Definition-time snapshots add startup allocations and metadata; a cheap scalar
signature filter limits that cost without a global rewrite. Three private
emitter nodes add a small backend representation but may avoid duplicating
arithmetic and let emission. Their value depends on replacing duplicated work,
not merely concealing it behind new tags. Report source growth, generated size,
startup and guard cost separately from loop speed.

Additional controls should cover mutation before the very first call, forward
helpers declared after the loop owner, missing snapshots, renamed functions,
typed lets whose RHS is a private call or conditional, parallel let shadowing,
and branch-specific parameter binders. Inspect the emitted fast path for any
remaining unguarded G lookup. Preserve the same public descriptor keys, arity,
bound ownership and direct invocation behavior without requiring function source
text equality as an external ABI guarantee.
