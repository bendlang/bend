# Marked-variable quantity in patterns

The isolated correction adds 12 exact matches across 114 paired observations,
with no lost exact match. It reuses the existing marked-expression scope worker
and translates its FUnboundVar result into a fresh Many pattern binder. Datatype
and Error outcomes remain authoritative; ordinary term semantics are unchanged.

TypeScript's marked-expression Var(-1) is an invalid reference in term position,
but parse_bind converts it to a new quantity-Many binder in pattern position.
Bend's FUnboundVar already represents the term case. The missing conversion was
at the pattern boundary, not in the checker or diagnostic printer.

The source change adds 8 lines / 548 bytes across elaborate.bend and one existing
parallel.bend call site. The already available book is passed through f_patterns;
only marked Ref/FAliasRef/empty-Call syntax invokes the existing scope worker.
Ordinary patterns retain their previous lookup behavior. Relative to wave9, this
candidate also includes the separately validated ordinary-call correction.

| Gate | Result |
| --- | --- |
| Genuine checked B1, guarded derivative, maintained focus | Pass; 36 focused controls, 2 inherited exact differences |
| Identical baseline/candidate selection | 59/114 → 71/114 exact; 12 new, 0 lost |
| Direct demand/identity/quantity controls | 6/6 pass |
| Ordinary-pattern/lambda lookup demand | Zero environment lookups, unchanged |
| Marked binder identity and range | Fresh syntax occurrence id and full marked range retained; quantity Many |
| Marked term behavior | FUnboundVar retained, not converted to a binder |
| Process health | Every reference/candidate run has 114 requests, zero worker failures, timeouts or errors |

Bound, nested, qualified and alias marked-call patterns now accept. A marked
binding of an affine Token reaches the exact intended checker rejection because
Many requires Data. Bare `+List` previously parsed as a binder; it now correctly
rejects through existing datatype semantics. All changed primitive observations
move toward the pinned reference.

The selection remains deliberately incomplete: 43 exact differences are visible
(30 chronology, 2 offload, 10 marked-error formatting, 1 pre-existing marked-term
width). This is neither full conformance nor a throughput result. Root owns the
full integration, backend and cost gates.

The first control selection incorrectly applied a checker-refusal acceptance
oracle to its parse lane. Controls02 assigns separate IDs to the accepting parse
and rejecting check observations for those two files. The fixtures and compiler
outcomes did not change. Baseline01 and its consumed tool remain preserved;
controls02 has valid pinned-reference expectations for all114 observations.

Evidence and handoff:

- Proposal and implementation freeze: `design/phase16/marked_pattern_quantity.md`,
  `experiments/phase16/P16-marked-pattern-quantity.md`.
- Source: `selfhost/build/phase16/marked-pattern-source-01/project`, parent
  `empty-call-pattern-source-01/project`; two exact patches and manifest beside.
- Checked attempt: `marked-pattern-checked-01`; derived API SHA256
  `faa44fb20cc10e228ea37539f472c3ac43f1fbcb6963e213d88a60b18b0cb246`.
- Fixtures/baseline/candidate: `marked-pattern-controls-02`,
  `marked-pattern-baseline-02`, `marked-pattern-validation-01`.
- Direct controls: `marked-pattern-demand-01`; exact gains, primitive changes,
  health, source cost and identities: `marked-pattern-audit-01.json`.
- Reproduction tools: `selfhost/tools/performance/phase16/marked-pattern-*`.
  All compiler producers are closed; original and corrected attempts retained.

Chronology remains a separate reviewed architecture experiment. Its next
synthetic stage will distinguish `f_scope_body` parse checkpoints from enclosing
match flattening, before any parser callback wiring is considered.
