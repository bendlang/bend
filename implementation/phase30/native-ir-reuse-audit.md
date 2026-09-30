# Can the native backend supply the direct JavaScript region?

Agent-generated static audit for Phase30. No compiler/native code was changed,
and no program or benchmark was run for this audit. Source identities and counts
are retained in `selfhost/build/phase30/inspection-native-01/report.json`.

**Recommendation: reuse the checked KTerm core and current JS expression/loop
emitters. Do not route this optimization through the existing native IR.** The
native implementation is useful prior art, but its final representation already
contains emitted C strings and native scheduling/ownership operations. It is not
a ready-made language-independent execution plan.

## What the native representation actually contains

The six requested modules total904physical lines,776nonblank lines,120definitions
and12data types. Counts are physical source, not a complexity or reuse score.
The wider native directory has2,092physical Bend lines at inspection.

| Module | Physical lines | Existing responsibility | Direct reuse for this JS region |
| --- | ---: | --- | --- |
| `ir.bend` | 25 | Segment/parameter/frame/program records with string bodies | No structured expression/statement body to retarget |
| `bridge.bend` | 456 | Core→C continuation segments, liveness, ownership, runtime heap/closures | Small pure KTerm sequencing helpers only |
| `direct.bend` | 88 | Exact saturated leading-lambda calls and beta reduction | Useful rules; stops at the same matcher boundary |
| `erase.bend` | 83 | Remove erased arguments/fields/annotations and encode constructor identity | Different public ABI; initial scalar region should keep existing typed core |
| `pattern.bend` | 141 | Collect native Nat chains and emit flat C word tests | Collection is mostly reusable; emitted branches are C-specific |
| `emit.bend` | 111 | Heap/register/stack/task code, segment switches, runtime insertion | No useful direct scalar-JS emitter |

`N_Segment` records a function name, parameters, result count, frame metadata,
body String, references and execution flags. `NC_Code.body` is also String. By
this point a match is already text such as `if (...)`, a call is a register setup
plus `WL_JMP`, and a return is `WL_RETN`. The JS emitter cannot recover typed
control flow from these records without parsing C or replacing the bridge's
body representation.

`nc_params` gives every environment binding `N_W64`; its source scalar kind is
not retained there. `nc_compact` turns non-String literals into `NWord`, including
F32's bit representation. Native Booleans are immediate0/1 (with native_bool also
handling packed representations), Nat is a native word, and general values have
heap/ownership semantics. Our private JS region needs Number U32/F32, Boolean,
and BigInt Nat with the existing checked primitive behavior. Choosing between
these from a uniform native word would require new type/provenance metadata.

## It does not already solve full match-aware arity

`nd_arity` handles known native/foreign arity; otherwise it counts consecutive
leading Lam nodes. `nd_extend` adds a direct entry only when `nd_bindings` finds
such a prefix. A source helper beginning with Mat has zero leading-lambda arity.
A helper with two lambdas followed by a Boolean matcher has a direct arity of two,
not three. That is deliberate evaluation-boundary preservation.

Consequently, the native pass does not already produce the direct forms needed
for `b2u`, the complete `sel.go`, `mit`, edit-distance record chains or raytrace's
trailing Boolean matcher. It would need the same new full-parameter/match analysis
that a minimal JS region needs. The existing native direct pass is not a shortcut
around the main proof obligation.

`NCall` and `NMatch` are internal KTerm tags used during lowering, rather than
complete serialized IR nodes retained in `N_Segment`. `nc_sequence` introduces
left-to-right Lets and variables around argument work. Then native lowering
consumes those tags while emitting C. Tail control uses the native register
trampoline; it is not the positional JavaScript function/for-loop structure we
want V8 to optimize.

## Reuse that is genuinely available

The useful ideas are already expressed over KTerm:

- `nd_head`/`nd_args` recover an application spine, but JS already has
  `j_call_spine`; use one appropriate existing implementation rather than add a
  parallel spine abstraction.
- `nd_beta` uses substitution for variable arguments and a Let for non-variable
  arguments, making evaluation-once explicit. This is useful when lowering a
  proven pure helper, provided binder freshness and parallel Let scope remain.
- `nc_mklet`/`nc_sequence` model left-to-right evaluation before a direct call.
  The JS backend already emits exactly ordered argument expressions and the Nat
  worker already has next-value temporaries, so they may be unnecessary for the
  initial region.
- `np_level`/`np_collect` produce Nat decision rows containing original arms,
  residual counters and fallback information before C emission. This collection
  could become a shared pure analysis when a future JS optimization needs full
  Nat decision chains. It does not help the present Boolean-only helper closure.

These are tens of lines of useful pure analysis, not hundreds of lines of ready
JS backend logic. Extracting a shared helper is worthwhile only if both real
consumers become simpler. Importing native modules into JS just to reuse a small
traversal would increase coupling without removing the missing analysis.

Native erasure physically drops erased binders and arguments, whereas the JS
public descriptor ABI retains null slots. The initial region rejects erased
slots, so no erasure pass is required. Retaining annotations until scalar
admission also lets existing JS native-identity checks remain authoritative.

## Compare implementation surfaces

The following are planning estimates, not measured patch sizes or commitments.
They include proof/guard logic; tests and documentation are additional.

| Approach | Likely new/change surface | Concepts added or changed |
| --- | --- | --- |
| Local typed KTerm region + JS reuse | Roughly180–350 Bend lines and40–100 JS guard/runtime lines | Bounded pure helper closure, one entry guard, private direct-call and Bool-branch lowering |
| Retarget existing native segments | Several hundred lines just to replace C-string bodies; plausibly500–1,000+ changed/new Bend lines before equivalent JS guards | Structured expression/statement IR, target-specific ownership/layout separation, native and JS renderers, scalar type restoration, two backend integration boundaries |
| Copy a second scalar JS emitter | Initially looks small, but duplicates primitive arithmetic, scopes and matches | Two implementations of numerical/Let semantics; avoid unless shared emission proves impossible |

A target-neutral native/JS IR could ultimately consolidate substantial code, but
that would be a separate architectural project with native correctness gates.
The904lines inspected are not a unit that can simply be shared: much of their
behavior is explicitly native and should remain so. The current fast-iteration
objective favors proving the small region first.

## Concrete least-duplication route

Keep scalar closure qualification over the annotated checked core, with bounded
node/definition fuel and native identity checks. Reuse `j_primitive_code` for
arithmetic rather than native intrinsic C templates. Lower only admitted exact
calls and native Boolean matches to compiler-internal private-call/branch intent.
Feed their children back through existing JS expression emission so nested calls
inside arithmetic are handled. Reuse the Nat worker's original argument reads,
immutable aliases, next-state temporaries and loop/Zero handling.

Either a small JCall/JIf-like internal form or an explicit private-call emission
context can carry this intent. The first makes the transformed subset inspectable;
the second needs context plumbing through primitive operands and Let bodies.
Neither requires a new public term format, native segment renderer, scalar value
representation or whole-backend rewrite.

The public fallback and snapshot linkage remain JS responsibilities: capture the
admitted live G bindings/descriptor/code identities only after public definitions
exist; check them once after all original arguments are consumed; reject ordinary
mutation/accessors/host objects; keep the old loop as fallback. Private helpers
must form a closed synchronous scalar graph, so accepted execution cannot change
that snapshot. The native backend has no mutable exported G analogue and provides
no existing proof or guard for this boundary.
