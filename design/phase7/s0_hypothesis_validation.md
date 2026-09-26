# S0: validate the simplification hypotheses without implementation changes

Status: authorized, read-only investigation. Baseline commit `fc509f4`.
This is the first phase of the [sequential simplification design](compiler_simplification.md).
The compiler remains at 16,509 physical / 13,803 nonblank lines and 509,937 bytes.

## Questions and method

1. Which obsolete implementations can S1 actually delete, including laws, exclusive
   types and helper functions? Trace callers, public roots, string references,
   tests and historical tools. Count exact deletion units and replacement cost.
2. Can explicit terms and retained provenance support S2's allocated reduction?
   Compare concrete removable accessors/origin machinery against new node fields,
   constructors, traversal cases, ABI support and bridge costs. Read prior failures.
3. Which checker facts are authoritative, and which change after specialization?
   Separate the already tested structured-error candidate from unproven retention
   of dependent types across changed books and binders.
4. Do identified, non-overlapping opportunities support the proposed 50% and 75%
   budgets? Unmeasured rewrites are opportunities, not credited savings.
5. What files and contracts are required to review the three fixed changes:
   parser first-error choice, dependent application checking and constructor
   lowering across JS/native? Count whole-file context sets consistently.

Two independent agents inspect retirement and representation/provenance while
the integrator checks baseline identity, checker/backend contracts and context
accounting. This is parallel review within S0, not overlapping implementation
phases. No agent may change compiler/runtime/host/harness/configuration code or
create a prototype/instrumented compiler during this phase.

Use the existing source recount and release verifier. Read-only inline scripts
may inspect/hash/count source and write audit outputs outside maintained code.
Run no new full conformance, full-source timing or self-reproduction when exact
artifact identities already bind the retained evidence. Historical results remain
historical, and missing current toolchains are recorded separately.

## Evidence and decision rules

Each hypothesis gets: source units; exact current size where countable; consumers;
replacement obligations; conservative net saving or explicit unknown; falsifier;
supported/contradicted/unresolved verdict. Count each deletion in one phase only.
Source reduction estimates cannot count excluded legacy files, moved logic,
minified formatting or removed tests as compiler simplification.

S0 succeeds by producing an honest audit, even if it rejects the provisional
allocation. S1 may start only after the report and review close S0. Any revised
intermediate target must be justified before implementation; the overall 50%
and 75% objectives and functionality contract remain unchanged.

Deliver the report and machine-readable baseline/context/deletion evidence under
`implementation/phase7/`. Preserve the interrupted campaign's steering snapshot,
then update current steering to this authorized sequential campaign. Commit and
push this checkpoint and the completed S0 evidence before S1 source edits.
