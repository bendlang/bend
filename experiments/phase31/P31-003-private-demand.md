# P31-003: fully demanded private results

Status: prospective; checked04 measurement is running before source changes.

[Design](../../design/phase31/private-demand.md) and
[independent bounded proof](../../design/phase31/fully-demanded-private-results.md).
Checked04's actual full pair executes one application but still65,792 builds,
66,049 constructors and65,797 force entries. These counts do not establish CPU
shares. Hypothesis: completing private returns at their existing demand boundary
removes build thunks/scheduling without an effect-order or representation change.

First ablation: private return emission uses ordinary eager constructor code,
retaining existing JCall force wrappers. Second ablation: omit those wrappers only
after every admitted private exit is shown fully demanded. Public generic bodies
and inert terminal records preserve their existing scheduling. Require identical
complete-state and native-event schedules on the original pair, nested records,
Array-free Sigma guards and the distinct first-field-write fold. Keep negative
witnesses. A frozen same-window timing determines promotion, not counts alone.
