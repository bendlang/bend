# P7-A03 — One scope traversal serves multiple binder operations

- Owner: root; independent reviewer: research_staging_ir (independent source review).
- Started/completed bounded trial: 2026-09-27; original plan preserved in commit `4b2e4c7`.
- Objective: a smaller, simpler, more capable Bend compiler with fast iteration.
- Correctness: checked stage0 component; 965 observations pass.
- Measurement: corrected valid-arity workload: freshening +18.6–22.6%, shifting +81.2–81.7% time.
- Decision: reject runtime generic traversal.
- Design: [architectural experiments](../../design/phase7/architectural_experiments.md#a03--one-description-of-binding-scope).

## Claim and cheapest disproof

The named design section supplies the mechanism, deletion/replacement boundary,
related research, scope, initial test and tentative unearned size target.

Invariant: Preserve allocation order, simultaneous-let scopes, metadata, beta rebuilding and stack safety for each claimed operation.

Stop condition: Only one realistic operation benefits, total replacement grows without retiring a mechanism, or ordinary binders require bespoke escape paths.

## Controlled setup

Baseline S4 B02 commit `22f6e8e21be5390d50831f9cbe4aab1147ff217d`;
pinned upstream `6018e28ecc67cf1fffc0c20c64b11023474c2df8`.
No production/default edits for this research slice. Capture exact source/API,
Base, tools, fixtures, commands and outcomes in a fresh evidence directory.
Root serializes builds and measurement. The shared design specifies provenance,
correctness, timing, cost accounting and publication gates.

## Results and review

The optimistic replacement adds 22 physical / 15 nonblank lines / 510 bytes.
A single frame shares a loop but adds mode/shape/sentinel conventions; existing
renaming, FFresh and definition-list machinery remain. The first malformed-arity
measurement is preserved separately. No production source is changed.

[Detailed results](../../implementation/phase7/architecture-evidence/binding-schema/report.md).
[Comparative decision](../../implementation/phase7/architecture-report.md).

## Preservation

Sources, controls and reports are tracked under
`implementation/phase7/architecture-evidence/`. The shared
[verified evidence capsule](../../implementation/phase7/architecture-evidence/README.md)
retains raw attempts, failures and generated outputs.

