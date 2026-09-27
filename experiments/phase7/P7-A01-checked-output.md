# P7-A01 — Checked terms replace annotation replay

- Owner: research_staging_ir; independent reviewer: root (independent controls, timing and source-boundary review).
- Started/completed bounded trial: 2026-09-27; original plan preserved in commit `4b2e4c7`.
- Objective: a smaller, simpler, more capable Bend compiler with fast iteration.
- Correctness: genuine checked B1 and 21 focused controls; 148 direct-output assertions pass.
- Measurement: serial ABBA: compile preparation 16.85–17.67% faster; check-only 25.39–25.45% slower, RSS +44.74–46.36%.
- Decision: continue mechanism; reject unconditional Candidate01.
- Design: [architectural experiments](../../design/phase7/architectural_experiments.md#a01--successful-checking-produces-executable-checked-terms).

## Claim and cheapest disproof

The named design section supplies the mechanism, deletion/replacement boundary,
related research, scope, initial test and tentative unearned size target.

Invariant: Preserve successful types, quantities/uses and errors; failed structured results remain exact. Chronological checking remains authoritative. Direct emission is only for the declared supported slice.

Stop condition: A candidate that needs the old annotation traversal for its claimed slice, changes rejection order, or cannot account for dependent template/book updates.

## Controlled setup

Baseline S4 B02 commit `22f6e8e21be5390d50831f9cbe4aab1147ff217d`;
pinned upstream `6018e28ecc67cf1fffc0c20c64b11023474c2df8`.
No production/default edits for this research slice. Capture exact source/API,
Base, tools, fixtures, commands and outcomes in a fresh evidence directory.
Root serializes builds and measurement. The shared design specifies provenance,
correctness, timing, cost accounting and publication gates.

## Results and review

Candidate01 adds 23 lines and five helpers; no pass is retired. Direct output
executes nine program pairs identically. Let/match/rewrite reconstruction and
template-instance ownership remain unresolved. The next discriminator is output/
discard policy before allocations, not a global replacement.

[Detailed results](../../implementation/phase7/architecture-evidence/checked-output/report.md).
[Comparative decision](../../implementation/phase7/architecture-report.md).

## Preservation

Sources, controls and reports are tracked under
`implementation/phase7/architecture-evidence/`. The shared
[verified evidence capsule](../../implementation/phase7/architecture-evidence/README.md)
retains raw attempts, failures and generated outputs.

