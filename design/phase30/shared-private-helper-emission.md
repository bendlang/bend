# Conditional backend integration of shared private helpers

This is an implementation proposal if the isolated hoist/deduplication timing
earns promotion. It changes the emitter's result plumbing, not the checked core,
region grammar, runtime or public guards. No production edit is part of this
document. The prospective output experiment is `hoisted-private-helpers.md`.

The current success points already possess the needed evidence: `helpers` in
`j_nat_loop_region`, `j_region_helpers(s)` in `j_tree_done` and
`j_region_root_done`. Each is the complete transitive closure selected by that
owner's existing bounded analysis. These points currently render declarations
inside their owner IIFE and discard the helper list. A later text scan or a
second analysis pass would reconstruct information that already exists.

## Return explicit emission data once

Introduce one emission result record, conceptually:

```bend
type JEmission is Data:
  JEmission{+body: String, +helpers: Map<&2,String>}
```

The map explicitly associates original helper names with their complete emitted
function declarations. It is ordinary Bend data, not a hidden host side table
or runtime registry. Existing `Map` already supplies String keys. Using emitted
fragments here is assembly of known emitter products, not parsing or rewriting
generated JavaScript. If the implementation chooses a small list initially,
keep the same abstraction and measure large-library scaling before promotion;
an unbounded linear search per occurrence can become quadratic.

Render each selected helper once at the existing success point, with exactly
the current `j_region_definitions` parameter and body emitters. The owner body
omits those local declarations but keeps its IIFE, `$guards`, scalarCapture,
exact callback and fallback bytes. Its helper map contains the complete closure,
including dependencies used only by another private helper. No helper analysis
is repeated to obtain this map. Per-owner admission still has its present
32-helper/depth/fuel bounds; sharing does not relax them.

Propagate this record through the existing priority chain: Nat countdown,
scalar tree, ordinary scalar root, then unchanged older emitters. A declined
worker uses an empty body and empty helper map, preserving the current empty
String sentinel convention inside the record. Foreign/native/ordinary fallback
emissions wrap their unchanged body with an empty map. Preserve the existing
conditional native `if(!Object.hasOwn(G,...))` prefix on the public body only.

Change `j_defs`' internal recursive fold to concatenate public bodies in their
current order and merge helper maps. After collection, `j_defs` renders unique
helper declarations once before all public assignments, followed by the saved
public bodies. Keep its outward String signature and the existing
`j_library_context`/`j_program_context` callers. This confines the new record to
global emission and worker-selection functions; `j_expr`, local/deep-lambda
emission, normalization and all source AST types remain untouched.

## Identity and failure behavior

For a duplicate name require equality of the complete rendered declaration,
including parameters and body. Name equality alone is plausible because each
helper is lowered from one checked definition in an empty owner environment,
but checking the exact emitted fragment preserves the experimental contract
and catches a future owner-dependent lowering mistake. Compare the already
rendered strings; do not re-render the first helper or invoke kernel equality
on private JCall/JSlot nodes. Those nodes deliberately never enter reduction.

A conflict must not silently choose either helper. The per-definition fold
still has the original KDef, so it can refuse that optimization and emit the
existing generic/U32/deep-lambda path for this definition, leaving the previously
accepted module helper map untouched. Perform the merge tentatively and commit
it only if the whole selected closure is compatible; this prevents orphaned
partial merges. Document and test this fallback with a direct emitter-level
conflict fixture. It should not require adding a diagnostic to normal user
programs or a new runtime guard.

Choose deterministic helper order explicitly. A map traversal can emit helpers
in deterministic String-key order without a second order list; ordinary function
declarations preserve forward references. This may differ from the prototype's
first-occurrence order, so measure the checked output itself. Keeping an extra
order list solely to reproduce incidental source positions is optional only if
measurement justifies it. Public assignment, capture and constructor metadata
order must remain unchanged regardless of helper order.

## Why sharing is valid

The existing private helper lowering starts with an empty owner environment and
turns explicit parameters into positional slots. Its local Let/loop bindings
remain inside the emitted function. It can refer only to standard primitives
and other collected private names. It cannot capture `$guards`, owner state or
G, or return a helper value. This invariant needs a backend assertion/test; the
disposable AST audit independently confirms it for the measured outputs.

Every private name remains the injective codepoint spelling already used by
JCall. There is no added lookup on a generated-code call path. Public guards
still include each owner's original reachable descriptors even though emitted
function bodies are shared. Replacing a public helper between calls therefore
selects the same generic fallback. Deduplication changes only unobservable
private function identities and JavaScript optimization feedback.

Module-level function declarations exist before evaluation. Bodies are reached
only from the existing deferred exact callbacks after all module initializers
complete. Do not replace them with eager helper evaluation or insert captures
before original G assignments. Both full-program and library modes must use the
same collected result, so the behavior does not depend on which host entry point
assembled the module.

## Cost and verification

Estimated implementation size is roughly 90–160 added lines and 25–50 changed
lines across the three worker producers and global emitter. This is one new
emission record and explicit merge plumbing, with no new term tag, optimizer,
analysis cache, runtime helper or public calling convention. Expect about
45–90 minutes for implementation plus focused checking, assuming existing Map
operations fit the fold; a fresh compiler build is about 40 seconds and the
focused output controls are short. This estimate excludes long timing and the
existing broad release gates.

The map approach stores unique emitted helper strings and avoids a repeated
analysis pass. Exact duplicate comparison costs linear time in the compared
fragment length, but repeated helpers were already rendered and stored inside
every owner before this change. Do not claim compiler-time improvement until
the controlled checked-library cost comparison measures it. Peak compiler
memory and output size should be reported alongside generated-program speed.

Verify all current region admission/refusal controls, module/helper name
collisions and forward references, repeated helper dependencies shared across
different owners, generic fallback after changed G metadata, and both library
and main assembly paths. Audit final emitted helper free variables and no-escape
uses with the retained AST tool. Compare repeated-body identity, initialization
counters, independent numeric oracles and ordered public boundary controls.
Then compare the actual checked candidate with its immediate predecessor using
the same timing points and adequate warmup. If the gain is modest or plumbing
becomes substantially larger than this estimate, keep the smaller local-emission
architecture and retain the experiment as evidence.
