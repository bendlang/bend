# Phase16: exact conformance through shared causes

Prospective design, frozen before compiler changes or candidate execution.
The user authorizes continued work toward full conformance with low checking
cost and simple implementation, including commits, pushes and compiler evidence
archives to `rom1504/bend`, branch `selfhost/bootstrap`. No older time budget is
renewed. Outcomes belong in implementation reports; failed attempts remain failed.

## Baseline and meaning of completion

Start at `2ab7b1499668762f3a2c6dea9997669054c5718d`, installed Phase15
`combined-02`, API `b8d658c564226a52764a435df86059aa3cea6b0c428bbde5341a62c2253c2e2d`.
Keep upstream `b2111cf43244e65f76ddc278ee695e669f720cbf` and its TypeScript sources
unchanged. The previous evidence archive and all 75 unrelated Phase6 files remain
immutable; the latter stay unstaged.

The preserved full frontend vector has 459 exact differences: 122 parse and
337 check observations, across 337 fixtures. All measured behavior axes agree;
the remaining differences include diagnostic text. Shape classifications are
166 legacy/unstructured, 153 snippet-only, 55 same-expectation/detail, 43 other,
26 computed-match legacy, nine location/span and seven caret differences. These
are triage categories, not proof that one patch fixes each category.

Our immediate full-conformance target is zero exact differences across all
2,996 pinned parse/check observations, while retaining all 1,001 positive type
acceptances, 482 validation refusals, 11 exact trust refusals and the four expected
later-emission outcomes. Diagnose the three known paired backend differences
separately and fix supported backend behavior where a compiler defect causes
them. A zero frontend difference count is not universal language, GPU, device,
proof-kernel or backend conformance. Unsupported external capabilities remain
explicit; never rename them passes.

## Stage0: evidence before edits

Verify the actual installed release and its checked lineage. Bind the preserved
reference/candidate vectors and record every dirty-file identity. Run a fresh
controlled comparison against pinned TypeScript on the same assembled source,
with the existing measurement worker, CPU0, fresh processes, 4 MiB stack and
4 GiB heap. Both named Bend baseline variants deliberately refer to the same
immutable installed attempt: this supplies four baseline samples and two TS
samples using the established serial matrix. Validated Bend Base caches are
prepared outside timing; TS checks Base; OS caches are not flushed. No other
compiler, profiler, archive or heavy analysis job overlaps the timing window.

Independently inspect our code and pinned TypeScript for every remaining family.
Record exact affected IDs, first-error precedence, observed terms and source
coordinate contracts. Cheap paired witnesses must distinguish competing causes
before a broad edit. Retain strict strings and paths; classification never changes
the oracle. Read-only inspection and writing prospective plans may overlap timing.

## Stage1: independent shared corrections

Three owners prepare isolated source copies with explicit file manifests:

1. Checker diagnostic production: replace shared legacy/error detail causes,
   including computed matches, using existing structured diagnostics. Preserve
   evaluation demand, checked terms, original failure order and proof handling.
2. Source spans: correct snippet and caret provenance through existing source
   mapping/rendering contracts. Prefer one shared rule over special cases. Test
   multiline source, tabs, supplementary characters, EOF, synthetic terms,
   imports and absent spans. No fixture-name or expected-text lookup tables.
3. Parser diagnostics: reconcile token descriptions, grammar/error ordering and
   remaining parser text with pinned behavior. Reuse the shared renderer and
   existing token representation; do not introduce a second parser or host-side
   TypeScript fallback.

Initial investigations get a ten-minute review, then bounded implementations
with regular evidence checkpoints. Owners never edit overlapping production
files concurrently. Root reviews and combines separate patches. After the
baseline timing window, independent correctness jobs use CPUs1–3. Full sweeps
belong to integration, not every wording edit.

For each candidate, freeze a hypothesis and expected change domain before
execution. Use a genuine checked B1, the maintained 36 focused cases, and a small
strict paired selection covering its family plus precedence/boundary controls.
Fixture-only iterations reuse the frozen attempt. Preserve failed selectors,
builds, probes and histories, with original exit statuses and consumed tools.

## Stage2: converge and simplify

Integrate independently validated corrections in small sequential waves. Run the
complete frontend inventory against the unchanged reference and Phase15 baseline;
require no lost exact matches, no new behavior/output differences, no incomplete
observations, input drift or resource failures. Every changed observation needs
an explanation grounded in source changes, including changes still nonexact.
Reclassify remaining failures and repeat by shared cause until the stated target
is reached or a concrete external limitation is established. Do not stop merely
because the first wave improves the count.

Remove helpers/legacy branches made redundant by each correction, only after
their behavior is covered. Count physical/nonblank lines, bytes, definitions,
laws, types, modules and maintained host/helper changes separately. Source begins
at 15,288 physical lines, 13,059 nonblank, 503,048 bytes, 1,499 definitions,
790 laws, 63 types and 59 modules. A new abstraction must replace duplication or
explain a real invariant. Small necessary growth is reported rather than hidden
through formatting. Prior 50%/75% reduction targets are not excuses for weakening
functionality.

## Stage3: performance and release protection

Keep successful compilation fast: diagnostic-only work should be lazy and avoid
extra successful-path traversals or allocations. Compare operation counts where
that claim is non-obvious. Freeze final artifacts and run an exclusive same-source
TS–baseline–candidate–candidate–baseline–TS matrix using unchanged resource and
cache policy. Explicitly review any host differences. A measured regression above
3% triggers investigation and a confirming comparison; do not promote a material
unexplained slowdown. A few samples describe this workload, not a universal bound.

Avoid an unrelated optimization rewrite. If the diagnostic design imposes a cost,
first remove its repeated work. Larger speed work requires a fresh installed-image
profile and a separate falsifiable plan. Do not resurrect the rejected Phase12
stack/demand changes or deferred Phase13 rewrite without addressing their evidence.

Before promotion run applicable backend compile-and-execute gates, standalone
frontend component checks, maintained helper/historical replays, fresh long-string
and exact 53/60-request histories, plus ordinary and relocated CLI checks including
native execution. Retain genuine checked B1, guarded derivative and historical
self-emission identities separately. No new self-emitted fixed point is required
for diagnostic changes.

## Stage4: usable release and durable report

Promote one validated compiler with its previous release preserved. Update the
compiler guide linked from README, architecture, conformance, implementation report,
ledger and steering with exact coverage, speed, complexity and remaining limits.
Checkpoint designs and completed findings through authorized commits/pushes.

After producers close, preserve exact tools, inputs, artifacts, histories, failures
and raw comparisons. Reuse existing content-addressed capsules for shared objects.
Record derived-cache omissions and external prerequisites explicitly. Independently
verify all archived bytes and full recovery, including the exact fixture symlinks;
reuse the reviewed narrow recovery policy instead of silently weakening path rules.
Keep evidence publication separate from compiler correctness. Standing user
authorization includes these project-scoped archives; no renewed push approval
is needed absent a new automatic approval rejection.
