# P7-A03 — One scope traversal serves multiple binder operations

- Owner: root; independent reviewer assigned at result review.
- Started: 2026-09-27; prospective plan, no outcome yet.
- Objective: a smaller, simpler, more capable Bend compiler with fast iteration.
- Correctness: unchecked; no prototype result at this design checkpoint.
- Measurement: not run.
- Decision: investigate.
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

No run yet. Preserve attempts and counterexamples; report unsupported boundaries
and replacement infrastructure. No promotion or source saving is credited here.

## Preservation

This plan is tracked. Result sources, controls and reports will live under
`implementation/phase7/architecture-evidence/`; large raw artifacts need a
verified archive or a complete regeneration recipe with named dependencies.

