# P7-A02 — First-order semantic values replace syntax reduction

- Owner: research_binders_semantics; independent reviewer: research_staging_ir; root reviews timing and artifacts.
- Started/completed bounded trial: 2026-09-27; original plan preserved in commit `4b2e4c7`.
- Objective: a smaller, simpler, more capable Bend compiler with fast iteration.
- Correctness: checked component; 100 selected controls pass, but a final admitted All-domain demand witness still fails.
- Measurement: candidate05 normalization screen: beta chain 46.7% less time, closed data 3.415× time, median process peak RSS about 1.95×.
- Decision: reject as a general evaluator replacement; preserve the narrower closure hypothesis.
- Design: [architectural experiments](../../design/phase7/architectural_experiments.md#a02--a-first-order-semantic-value-machine).

## Claim and cheapest disproof

The named design section supplies the mechanism, deletion/replacement boundary,
related research, scope, initial test and tentative unearned size target.

Invariant: First-order Data closures, parallel-let scope, lazy demand, shared argument forcing and alpha/eta conversion within the declared slice. Unsupported syntax is explicit.

Stop condition: Sharing expands, unused arguments are forced, conversion differs, or replacement machinery cannot retire an evaluator family.

## Controlled setup

Baseline S4 B02 commit `22f6e8e21be5390d50831f9cbe4aab1147ff217d`;
pinned upstream `6018e28ecc67cf1fffc0c20c64b11023474c2df8`.
No production/default edits for this research slice. Capture exact source/API,
Base, tools, fixtures, commands and outcomes in a fresh evidence directory.
Root serializes builds and measurement. The shared design specifies provenance,
correctness, timing, cost accounting and publication gates.

## Results and review

The final prototype costs 547 physical / 454 nonblank lines / 19,316 bytes,
69 definitions and 12 datatypes, plus 194 physical lines of retained helper
blocks. It covers an empty-book subset, not the old normalizer/graph contracts.
Successive stronger gates expose metadata, shape and short-circuit demand bugs.
After corrections, 100 selected controls pass; a final All-domain comparison
still diverges where the baseline returns false. The separate codomain probe
times out on both variants and is inconclusive. Failures remain preserved.

[Detailed results](../../implementation/phase7/architecture-evidence/semantic-values/report.md).
[Independent review](../../implementation/phase7/architecture-evidence/checked-output/semantic-values-independent-review.md).
[Comparative decision](../../implementation/phase7/architecture-report.md).

## Preservation

Sources, controls and reports are tracked under
`implementation/phase7/architecture-evidence/`. The shared
[verified evidence capsule](../../implementation/phase7/architecture-evidence/README.md)
retains all seven component attempts, both candidate05 demand suites, final
candidate07 residual probes and candidate05 normalization measurements. Later
conversion fixes do not relabel the measured API.

