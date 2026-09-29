# Parser stage information-loss experiment

The unchanged compiler cannot distinguish a previously completed ordinary row
body from a parenthesized body at the same position in its raw tree. TypeScript
requires different first-error order for those two cases. This falsifies the
proposal to reconstruct every checkpoint on rejected paths while keeping the
successful raw AST entirely unchanged.

Eight independent fixtures / 16 observations are frozen in
`selfhost/build/phase16/rejected-stage-controls-01`. The unchanged checked marked
candidate has 8 exact matches / 8 differences. Both reference and candidate
correctly reject every fixture in the parse phase; each side completes 16 requests
with zero worker failures, timeouts or errors. The exact differences concern
which error must appear first, not permissive acceptance.

The four-way witness distinguishes an earlier global-head match from later
syntax/pattern failures, both grouped and ungrouped. Prior invalid local/row
patterns independently establish parse-time checkpoint precedence. Completed
body/group controls show the earlier global-match error once there is no later
parse failure. Exact vectors: `rejected-stage-baseline-01/selected/paired.json`.

Six direct controls on the real Bend workers pass in `rejected-stage-direct-01`:
f_scope_body retains the raw Match and its parse-time checks; f_scope crosses the
flattening boundary; the corresponding earlier/later selection differs; an
earlier body pattern Error remains detectable. Saved raw successful bodies are
identical after deleting only numeric ids and source-coordinate fields. The
probe invokes existing compiler workers; it does not install a JS replacement
for compiler semantics or claim a completed frame resolver.

The raw-group census on final compact API 35044ae6…5315 also passes. Base has 302
f_group calls and the 668,185-UTF16-unit assembled compiler has 84; neither has a
raw Local/Match/Parallel at that checkpoint. A wrapper restricted to such bodies
would allocate zero additional wrapper/list nodes on those two inputs. This does
not measure dispatch cost, allocation in other programs, or speed.

Evidence and conclusions:

- Frozen plan: `experiments/phase16/P16-rejected-stage-boundary.md`.
- Probe tools: `selfhost/tools/performance/phase16/rejected-stage-*`; exact
  consumed copies and identities are retained in their output directories.
- Oracles: `rejected-stage-baseline-01`; synthetic worker tests:
  `rejected-stage-direct-01`; counts: `rejected-stage-group-census-01`.
- Follow-up proposal: `design/phase16/group_checkpoint_boundary.md`, including
  actual initial producer/consumer sites and seven raw-shape audit sites.

No compiler source changed. No FGroup marker or full failure-frame transport has
been implemented. All probe producers are closed. The marker alternative is now
concrete enough for scope/cost review against the larger contextual-parser option.
