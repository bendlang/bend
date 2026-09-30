# Confirm actual-call lookup on the small edit row

Freeze this amendment after `exact-call-screen-01`, before deriving new modules
or running controls. The original edit-distance call costs roughly 2.4 seconds.
The general screen consequently used single-call samples and took 199.33 seconds;
its candidate was 1.070 times faster, with disjoint ranges. A long confirmation
with a 100-call minimum would be inappropriate for this point. Preserve the
screen and its coarse sampling; do not treat missing within-sample halves as
evidence of absent drift.

Reuse the exact attempt07 original edit-distance module and the frozen
`invokeExact` replacement from `inspection-exact-call-01`. Append the already
used row fixture adapter from `prototype-record-loop-guard-01/unchanged.mjs` to
both images, replacing only their default export. It builds the same input
arrays, invokes the unchanged public `row`, and serializes every returned array.
No cell, array, loop, source algorithm, input size or runtime function changes
besides the already reviewed `invokeExact` ablation are allowed.

Validate every retained independent full-state point from
`prototype-02/points.json`, and ordered row public-boundary observations. The
previous 146 ABI, 72 scalar, 9 exact-entry, 91 focused invocation and 121 scalar
point observations remain linked evidence for the identical frozen runtimes;
do not rerun the multi-second original benchmark during these controls.

Use the existing row32/seed17 point for paired screen and longer-warm
confirmation under an exclusive timing grant. These measure the small generic
row, not the complete edit-distance program. If full-program confirmation is
later warranted, use a transfer protocol that explicitly budgets a small number
of full calls rather than the microbenchmark call floor. Keep the helper's
unchanged result and its short-window drift in the report as well.
