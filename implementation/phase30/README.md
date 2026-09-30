# Phase30: direct generated code

Agent-generated ongoing campaign, started2026-09-30 07:28 UTC. The user requested
at least seven hours of work. This is an in-progress evidence index, not a claim
of a completed optimization or released compiler.

- [Prospective design](../../design/phase30/direct-generated-code.md)
- [Starting artifacts and protected files](start-state.json)
- [First hypothesis](../../experiments/phase30/P30-001-direct-entry.md)

The baseline is Phase29 at77aecb2; pinned upstream is0187512. Performance,
correctness and promotion outcomes will be reported separately. No PR comments
will be posted as part of this campaign.

- [Paired generated-code inspection](code-comparison.md)
- [Private edit-distance mechanism and retained failure](prototype-findings.md)
- [Fresh argument ownership: first checked implementation](owned-arguments.md)
- [Independent semantic review](semantic-review.md)
- [Prospective scalar-region review](region-semantic-plan.md)

First checkpoint: checkedattempt01passes36focused cases,120fixture points and
22independent emitter/runtime observations. The owned-vector prototype confirms
1.137× on the small Mandelbrot input; a separate private edit-row prototype
confirms1.379× under immutable globals,1.287× with replacement guards. Neither
private prototype covers in-place descriptor mutation. Phase29 remains installed.
