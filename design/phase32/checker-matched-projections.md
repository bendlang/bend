# Match the projection binding before confirmation

Prospective amendment after the four-role fields screen, 2026-09-30.
The first fields-only screen improves lookup by1.76–1.85× and infer_ref by1.50×,
with disjoint field-only ranges, but it also routes projection calls through
private descriptors. Isolate that routing from the callback-body change.

Add a fifth `captured` variant. It uses exactly the same private projection fn
wrappers and internal call binding as `fields`, but retains each original
`project(...).slice()[i]` callback body. Both retain ordinary callOwned/apply,
force and layouts. All earlier four variants remain byte-identical. Comparing
captured/fields now differs only in the11 private projection callback bodies.
The original baseline/captured comparison diagnoses any binding-only effect;
it is not silently assigned to projection copying.

Replay all complete oracles and public isolation controls before timing. Bind
the exact earlier four hashes, new fifth hash, full callback replacement
inventory and controls. Retain the old screen, its original drift/outliers and
public-input counterexamples. A root-reserved confirmation may compare captured,
fields and combined with longer warmup; no whole-request or public ABI claim
follows, regardless of result. The isolated worker boundary remains a separate
future proposal in implementation/phase32/checker-production-boundary.md.

## Post-interruption confirmation protocol

The resumption keeps all five existing artifacts unchanged. After the new
controls establish that captured/fields differ only in eleven callback bodies,
`checker-matched-plan.py` freezes all five roles for three rotating fresh-process
trials per workload. Each child warms for at least1.5seconds, then records five
approximately200ms samples. This is a longer confirmation, not a guarantee of
steady state: report all ranges and half-sample drift, and explicitly qualify
any remaining drift/outlier. Analyze captured/fields for the projection-only
effect, baseline/captured for binding changes, and fields/combined for the
incremental direct-call effect.

Root must reserve the exclusive CPU before timing. Children run serially, use
512MiB V8 old-space allowances and the retained20second timeout, with a240second
campaign deadline. An old-space allowance is not an RSS cap. Root checks process
and cgroup memory headroom and may abort if unsafe; preserve any partial run
without selecting only its completed fast samples. Five-role correctness
controls use a separate768MiB allowance because their isolation comparisons
load several modules into one process. No compiler build overlaps these runs.
