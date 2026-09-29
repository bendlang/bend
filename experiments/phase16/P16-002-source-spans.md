# P16-002: explicit source ranges, metadata ablation

Prospective plan frozen before source edits/builds. Owner: source-spans agent.
The [design](../../design/phase16/source-spans.md) records the exact representation,
propagation, source ownership, scope, alternatives and falsifiers.

Hypothesis: two explicit primitive source-range fields can supply the invariant
needed for exact checker locations without a material successful-path penalty.
The first candidate tests only representation cost: all origins remain absent,
all diagnostics and six-field compiler semantics must remain unchanged.

Baseline: Phase15 combined-02, API `b8d658c5`, pin `b2111cf`. Compare the candidate
from its immutable snapshot with that baseline; do not consume or modify the
unrelated Phase6 candidate payload. CPU2 correctness is authorized after root's
baseline timing window. No timing without a separate exclusive resource grant.

Required gates: genuine checked B1, unchanged maintained v5 helper, all 36 focused
observations complete and equal baseline (known exact TS failures retained),
direct absence/rebuild/semantic-projection controls, explicit source/host patch,
cache/graph/line-count census, then a frozen same-input ABBA cost pilot. Preserve
failed builds, tool versions, validation outputs and every timing sample.

Do not start full parser instrumentation before the metadata-only result is
reviewed. Outcomes belong in
[the implementation report](../../implementation/phase16/source-spans.md).
