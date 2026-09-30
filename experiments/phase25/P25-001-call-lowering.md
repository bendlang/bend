# P25-001: matcher boundaries add executed call machinery

Owner: root; corpus: history_speed; structure: history_complexity.
Status at freeze: investigate; correctness and timing unmeasured.

Hypothesis: small programs whose functions match before accepting further live
arguments expose systematic partial-application/dispatch overhead in self-emitted
JS compared with upstream direct workers. Check identical typed source at multiple
runtime sizes/seeds, inspect generated structure, then count and profile executed
machinery. Absence of the structural/dynamic difference falsifies this mechanism
for a case. Correlation alone does not measure a hypothetical optimization.

No semantic transform is authorized by this hypothesis. Demand/error order,
partial applications and stack behavior remain protected. See the frozen
[design](../../design/phase25/generated-code-analysis.md) for identities,
resources, gates and preservation; outcomes belong in
[the report](../../implementation/phase25/generated-code-analysis.md).
