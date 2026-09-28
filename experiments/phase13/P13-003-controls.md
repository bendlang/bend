# P13-003 — Independent controls for explicit branch captures

- Owner: independent semantic reviewer; implementation owner is separate.
- Started: 2026-09-28. This is the frozen prospective plan, before probes.
- Objective: improve compiler throughput without changing accepted programs,
  diagnostics, evaluation demand or the supported stack boundary.
- Correctness: static analysis only; no candidate accepted or tested yet.
- Measurement: none. Root owns profiles and controlled performance comparisons.
- Decision: investigate a bounded structured-rewriter pilot.
- Report: [controls.md](../../implementation/phase13/controls.md).

## Claim and counterexample boundary

The proposed transformation replaces eligible literal branch arrows by named
worker functions with explicit captured values while retaining the existing
`run_tail` / `run_loop` boundary. The hypothesis is narrower than general closure
conversion: selected branch bindings are initialized, immutable lexical values;
their references can be supplied as worker parameters without changing demand.

Baseline is released Phase12, pinned upstream b2111cf, selected API
`0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697`.
Maintained helper SHA256 is
`84a065f61b9c6c6c1ebd8cdfe10dca1a8017f40d19302a84515e1c3a2cc356d9`.
These identify a checked-B1 derivative, not a self-hosted fixed point.

The cheapest falsifiers are a capture read before initialization, a captured
binding changed before trampoline demand, incorrect nested scope resolution,
forced work in an unselected branch, or changed call-stack behavior. Reject or
skip unsupported sites explicitly; do not silently reinterpret them. Preserving
abstract values on pure examples is insufficient for promotion.

## Static obligations before any candidate execution

1. Resolve each identifier occurrence to a lexical binding. Handle nested arrow
   parameters, local declarations and block scopes; distinguish property keys,
   noncomputed member names, labels and strings from variable references.
2. Capture only initialized bindings that cannot be written before or during
   deferred branch demand. Parameters require a write check too. A `const` whose
   declaration occurs after a stored jump is insufficiently initialized at the
   capture site. Generated SCC state parameters are mutable; immutable aliases
   must be analyzed as separate bindings.
3. Evaluate the condition exactly once before capture construction; build only
   the chosen branch's packet. Capture identifier values, not evaluated member
   projections, calls or other expressions taken from the worker body.
4. Preserve the branch's actual Unit argument, selected-only effects/exceptions,
   nested closure behavior, recursive boundary and public forcing. `run_tail` is
   unary; any packet/unpacking convention must have an explicit reviewed shape.
5. Refuse unsupported lexical/control constructs: `this`, `arguments`,
   `new.target`, `super`, dynamic evaluation, captured writes or an unknown AST
   shape. No direct recursion may replace a deferred call as an incidental edit.
6. Generated worker names cannot collide with declarations, parameters, locals
   or exports. Do not introduce public roots or alter their arity/marshalling.
7. Bind the exact runtime, source artifact, structural parser, transform and
   helpers. Preserve explicit historical versions 1–5 if the pilot advances to
   a maintained derivative. Do not hand-edit generated output to make tests pass.

## Planned controls after root releases a CPU slot

Use original versus transformed generated syntax and actual compiled compiler
APIs, with exact input/transform/output identities. Record expected refusal or
unchanged skipping separately from successful lowering.

- Positive captures: zero/one/many values, same object in multiple positions,
  shadowed names in nested arrows, transitive free variables and a returned
  closure whose environment remains alive after its worker returns.
- Ordering: condition side effects/throw, both truthy and falsy host values,
  selected and unselected throws/divergence, Unit uses, nested choice, object
  getters left in the selected body, partial public application and extra args.
- Refusals: mutable parameters/locals, writes in nested closures, later `const`
  initialization, destructuring or unsupported syntax, runtime/helper shadowing,
  name collisions, `this`/`arguments`/`new.target` and escaped/protected bindings.
- Trampoline: returned raw jump, nested choices, 100,000 tail steps and a chosen
  branch which returns a function; report private raw-message representation
  changes separately from public forced observations.
- Real stack gates: fresh long-string check plus both retained exact 53- and
  60-request histories at 4 MiB, preserving predecessor digests and resource
  settings. Phase12's matched-history failures remain required counterexamples.
- Actual selected frontend observations and kernel/normalizer demand controls
  appropriate to the candidate's affected sites. Root owns full corpus,
  source-checking/backend measurements and release gates.

Initial work is static only while root profiles. Later tiny probes use the
assigned CPU and unique output paths; announce compiler launches. Preserve all
launch failures, refusals, timeouts and candidate failures. Existing runtime,
Base, helpers and source bodies remain immutable. Tests establish bounded
evidence, not universal stack safety or compiler equivalence. No normalizer
proposal is revived by this investigation.

## Decision and preservation

The named-worker pilot proceeds only if the implementer can state an explicit
capture/call convention and the guards reject the cheapest witnesses. If a
broader scope analysis or runtime redesign is required, stop and report that
cost instead of adding exceptions. Keep this plan unchanged; put outcomes,
independent review and retained evidence in the implementation report.
