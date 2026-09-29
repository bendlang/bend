# Phase22: one contextual frontend, exact conformance, bounded cost

Status: authorized investigation and implementation, 2026-09-29. This document
is the prospective plan; outcomes belong in `implementation/phase22/`.

The user asks us to pursue full conformance while improving speed and
simplicity. The reference remains upstream `b2111cf43244e65f76ddc278ee695e669f720cbf`.
The starting release is Phase21, API `44094e58cb0ef033e2c08c2827565e859c3594b3136868d4f821262145aea7f0`.
Its measured checking cost is 10.95 seconds versus 3.44 seconds for TypeScript;
its observed checked-build plus36-test edit loop is35.17 seconds. The latter is
a distinct, uncontrolled workload that includes a pinned-TypeScript bootstrap.

## Goal and evidence boundary

Close all known supported frontend differences, starting with acceptance and
first-error ordering, and challenge the result with independent neighboring
cases. Main2996 retains two diagnostic differences. The broader196 has139 exact
observations and57 differences across29 fixture IDs:55 diagnostic differences
and two acceptance differences. The newer C1 controls reveal related acceptance
problems; overlapping suites must not be summed. Keep every known discrepancy
visible even when its original fixture oracle is weaker than exact agreement.

Zero differences across the tested corpus means full agreement on that corpus,
not universal language equivalence. GPU execution, independent proof validation,
and a new self-hosted fixed point are separate, unestablished claims. A passing
frontend must also preserve ordinary interpreter, JavaScript and CPU-native
behavior before installation.

## Architectural hypothesis

The current raw parser consumes syntax before a later scope/pattern traversal
knows enough to reject it. It also loses whether a body has completed inside an
inner group. That creates wrong acceptance and first-error selection. A raw-tag
comma guard rejects valid completed groups; correcting Parallel lowering alone
can turn a parse discrepancy into a false checked acceptance.

Put each semantic decision at the actual parser checkpoint with the real lexical
environment, declaration/alias scope, fresh identity state and returned cursor.
Use the existing pattern and flattening owners. Preserve the distinction between
an unfinished Body and a completed expression; coordinates do not encode it.
Constructor arguments precede constructor-name resolution, row arity precedes
pattern validation, local RHS expressions precede binder validation, and those
binders open before the body and close before siblings. All parallel RHS values
use the pre-binding environment. Do termination follows the reference grammar.

Private Phase19 stages1–4 demonstrate parts of this contract, but are incomplete
and based on an old source. Selectively reuse their evidence and useful workers;
do not copy their old checker or install unsupported-only experimental entry
points. The production route must have one semantic authority. Successful Core
must contain no private syntax markers or raw Parallel nodes.

## Sequential integration milestones

1. Freeze the installed identities, maintained source census and protected
   unrelated Phase6 paths. Freeze independent controls before reading candidate
   outcomes. Profile the installed checking workload concurrently on a separate
   core; profile instrumentation is not a speed measurement.
2. Migrate the smallest coherent body/group checkpoint slice into the production
   route on a private source snapshot. Preserve valid nested tuples, lambda and
   annotation scopes, constructors, quantities, parallel bindings, and do-block
   termination. Start with the existing saved counterexamples and36-test gate.
3. Complete the remaining contextual boundaries shown by the broader196 and
   independent controls. Remove the superseded scoping/flattening responsibility
   as each route becomes authoritative. An added prototype with no retired path
   remains research, not a simplicity success. Avoid fixture-specific diagnostics.
4. Integrate one candidate only after full result-vector comparison, source-origin
   and binding checks, actual program execution, fresh/history controls, and the
   main2996 gate. Report exact, diagnostic and acceptance changes separately;
   investigate every new difference. Repeat broad gates only after meaningful
   candidate changes or an identified unresolved concern.
5. Freeze the candidate and compare identical-source TypeScript/parent/candidate
   checking serially under the existing resource/cache policy. Install only after
   correctness, cost and independent review pass. Update the compiler guide,
   README, conformance record, architecture and experiment frontier together.

## Performance and simplicity requirements

Fresh CPU/allocation attribution comes before a runtime optimization. The first
bounded hypothesis is unnecessary declaration-list rebuilding alongside the
existing index. Its old profile is not current evidence. Measure callers and
rebuilt cells if it remains material; preserve duplicate ordering, malformed-input
demand and cache boundaries. A source-only prefix cache cannot replace live
checker memo/output/freshness state.

The other opportunity is eliminating duplicated frontend traversal during the
semantic migration. Do not promise a percentage before attribution. About10% of
the starting process time is outside the request; lazy API loading is inside the
request, so this is only a bound on outside-request savings.

The starting maintained census is15,900 physical /13,546 nonblank lines,
577,159 bytes,1,660 definitions,719 laws,67 types in59 modules. Track these same
memberships, plus each new state/protocol and retired semantic owner. Removing a
duplicate implementation is the objective; moving lines to a helper or adding a
second parser is not reduction. No50% whole-compiler target is implied by this
bounded frontend migration.

Use the established serial TS/B/C/C/B/TS screen after all heavy work stops. A
repeatable process or request regression over3% requires attribution and a
correction before promotion; noisy near-neutral results require additional
paired samples, not a claimed speedup. Keep peak memory visible. A correctness
fix can be evaluated separately from a speed candidate; do not bury a cost
regression in a combined result.

## Execution and preservation

Root owns design, integration, final verification and documentation. The parser
owner changes only private numbered source snapshots; the controls owner writes
independent frozen controls; the performance owner profiles unchanged artifacts
first. CPU3 is parser work, CPU2 controls, CPU0 profiling. Exclusive measurement
requires all other compiler work to stop. Use genuinely checked B1 builds and
the unchanged guarded v5 derivative; no unchecked JavaScript implementation.

Preserve original failed attempts, fixture bytes, commands, identities and raw
statuses. Reuse the existing experiment tools where their contracts apply; avoid
creating a parallel harness. Commit explicit owned paths. The75 unrelated Phase6
paths remain unchanged. Publication is still subject to the earlier automatic
approval rejection; local commits must not be described as pushed.
