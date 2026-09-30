# A final bounded-capacity ablation

The emission-scoped4,096-entry candidate passes15 complete request observations.
Both original programs saturate the cap; the earlier unlimited diagnostic used
about6,700and9,000 total entries. Before observing the scoped timing outcome,
freeze one16,384-entry successor. Its only API-byte change is the integer cap;
query families, keys, timing boundaries and restoration are identical.

Use the same768MiB heap and serialized process-tree supervisor. Verify and reuse
the unmodified07 baseline's15 observations from scoped correctness02, then run
one fresh higher-cap candidate through every one of those cases. This saves an
identical baseline rerun while preserving exact observation/error/dependency/
output comparisons. The report must mark the reused baseline explicitly.

Only if that comparison passes, use the same four-process baseline/candidate/
candidate/baseline screen and prospective thresholds as the4k variant. This
experiment measures capacity separately; it does not change production cache
policy or authorize a public host-API cache. Report entry saturation and memory
alongside speed. If neither bounded candidate meets the threshold, close this
query-identity cache campaign without pursuing a larger IR or unbounded table.
