# P22-001: authoritative contextual frontend

Decision: investigate and implement under the user's current authorization.
Correctness: starting Phase21 gates only; no Phase22 candidate validated yet.
Measurement: starting Phase21 comparison only; no Phase22 speed claim.

Hypothesis: real lexical state and semantic validation at parser checkpoints
close the remaining acceptance/first-error families while allowing retirement
of deferred duplicate scope/flattening work. A new accepted-invalid neighbor,
changed binder capture, reordered error, or unretired parallel implementation
falsifies the corresponding correctness or simplicity claim.

Plan: [contextual conformance](../../design/phase22/contextual-conformance.md).
Starting evidence: [Phase21 release](../../implementation/phase21/group-range-release.md),
[comma controls](../../implementation/phase21/group-comma.md),
[private contextual research](../../implementation/phase19/saved-row-group-frontier.md).

First discrimination: original group/body-comma versus completed nested group,
earlier invalid-pattern versus later syntax, and simultaneous parallel RHS scope.
Then the existing broader196, independent controls and maintained36. Full frontend,
actual backends and controlled cost belong at integration, not every edit.

Owner: root integration; contextual source and independent controls are delegated
with separate file ownership. Outcomes and rejection reasons will be linked here.
