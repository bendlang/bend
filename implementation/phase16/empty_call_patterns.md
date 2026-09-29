# Empty ordinary calls in patterns

The isolated correction adds 28 exact matches across 82 paired observations,
with no lost exact match. It fixes the bound/unbound distinction for ordinary
empty named calls, including nested calls, aliases, match rows and constructor
fields. It does not fix the remaining chronology, marked-call or offload cases.

The pinned TypeScript parser builds an application only for supplied arguments.
An empty call preserves a bound Var, while an unbound Var switches to its Ref
fallback. Both retain the original head span. Our raw Call representation lost
that distinction during pattern conversion. The new helper consults the existing
lexical environment only for eligible empty calls. Bound heads become pattern
variables with the original syntax occurrence identity; unbound calls retain
their scope/template/alias path and use the head range for rejection.

The one-file change in `src/front/elaborate.bend` adds 11 lines / 838 bytes. It
introduces no host rule, global traversal, IR field or alternative scope system.
No performance result is claimed.

| Gate | Result |
| --- | --- |
| Genuine checked B1, guarded derivative, maintained focus | Pass; 36 focused controls, 2 inherited exact differences |
| Frozen wave9 baseline / candidate, identical 82 observations | 20 exact → 48 exact; 28 new, 0 lost |
| Existing 50 chronology oracle observations | All retained; 4 new exact empty-call observations, 30 chronology differences remain |
| New 32 boundary observations | 28 exact; marked bound acceptance and offload diagnostic remain (2 each) |
| Existing independent demand controls | 4/4 pass; ordinary lambda/pattern paths perform zero environment lookups |
| Worker health | Each baseline/candidate/reference run has 82 requests, zero failures, timeouts or worker errors |

The selection deliberately is not marked fully passing: the remaining 34 exact
differences remain visible. Every primitive change from baseline moves toward
the pinned reference. The root owns full-corpus integration and promotion.

The first controls/baseline attempt incorrectly expected a bound `+x()` to be
rejected during parsing; its unannotated RHS also produced an unrelated checker
failure. Controls02 annotates the RHS and uses the confirmed acceptance oracle.
The first attempt and consumed tool are preserved. This revealed a separate
marked-pattern gap; the ordinary-call change does not bypass datatype/quantity
semantics to conceal it.

Reproduction and handoff:

- Frozen plan: `design/phase16/empty_call_patterns.md` and
  `experiments/phase16/P16-empty-call-patterns.md`.
- Source: `selfhost/build/phase16/empty-call-pattern-source-01/project`, parent
  `wave9-source-01/project`; exact delta `elaborate.patch` and `manifest.json`.
  Candidate elaborate SHA256:
  `338673ae059ab7f7a99096d70f692d15102759ec0545eede3a6324e0e0ada279`.
- Build: `empty-call-pattern-checked-01`; comparison:
  `empty-call-pattern-baseline-02`, `empty-call-pattern-validation-01`.
- Fixtures: `empty-call-pattern-controls-02`; inherited fixtures remain bound to
  their original `parser-checkpoint-controls-03` paths and bytes.
- Demand: `empty-call-pattern-demand-01`; full counts, exact gains, primitive
  changes, process health and hashes: `empty-call-pattern-audit-01.json`.
- Preparation, baseline and audit tools:
  `selfhost/tools/performance/phase16/empty-call-pattern-*`. Each executed
  preparation/runner is retained beside its output. All jobs are closed.

The next chronology step remains the reviewed design of a failure-only lexical
transport covering all enclosing frames, not a special case for the remaining
maintained monad fixture.
