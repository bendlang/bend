# Phase30: direct generated code

Agent-generated campaign, started 2026-09-30 07:28 UTC. Work exceeded the
requested seven-hour minimum. Checked17 is installed and passes release
verification and all 42 ordinary/relocated CLI checks.

The installed compiler is checked attempt17, following the held14 matrix and
the checked15 runtime repair at[4e5b7fe](https://github.com/rom1504/bend/commit/4e5b7fe). The
[consolidated report](generated-program-performance.md) records its source,
mechanisms and current release status; the [decision table](decisions.md)
separates promoted, deferred and rejected experiments.

It adds owned fresh argument vectors, exact private entry, constant scalar
shifts, lexical scalar regions, terminal records, ordinary roots, a bounded
private scalar tree, reused traversal frames and private-helper Let statements.
**14 was held:** the broader matrix found roughly20–25% regressions on several
generic workloads despite the large scalar gain. The seven-way confirmation
isolated constructor-matcher overhead: delayed application cuts row time26.29%
and recovers Phase29 speed. Checked16 also removes64 implementation lines,
eight functions and the obsolete arm-prebinding module. Checked17 then adds the
measured registration flag:5.57% less RLE time and5.38% less complete-row time,
with registered scalar controls overlapping. Its actual outputs match the tested
modules byte for byte. The consolidated default now installs that checked
artifact; the previous Phase29 default is preserved in release history.

The completed17 matrix measures original Mandelbrot at **0.212798 ms versus
Phase29's 21.379050 ms: 100.47× faster**, with **4.63× TypeScript overhead**.
The scalar helper at 8,192 iterations is **186.39× faster than Phase29 and
1.376× TypeScript time**. Generic edit distance and ray tracing improve 5.67%
and 3.42%, but still cost 391.54× and 299.07× TypeScript time. RLE remains 2.70%
slower than Phase29. Ordinary compiler checking takes 4.22× TypeScript time.
The [full timing report](final-timing-17.md) includes ranges, warmup drift and
separate compiler costs; no combined average or multiplied gain is claimed.

All ten original libraries compile and produce their checked results. Fresh17
also passes the focused, selected upstream, primitive/worker,23-library,
compiler-component and HVM integration scopes. The16 whole frontend renewal passes
3,026 main and 196 broader exact observations, with the explicit module-layout
migration independently reviewed;17 reuses it under exact input-identity proof.
Actual17 self-emission matches the tested flag module, and fresh positive/cache
preparation passes on its17 pipeline. The separately measured actual H17 request costs 5.002× its genuine
TypeScript-produced parent of the same Bend source. Both sides still warm within
trials; this is not a comparison against the handwritten TypeScript compiler. The81-row backend pilot now matches all historical
observations:54 interpreter/JS rows are fresh17,27 native/check rows explicitly
reuse16, with69 passes,8 expected refusals and4 shared failures kept separate.
The full17 matrix, separate H17 timing, installation and 42-step CLI validation
are complete.

- [Actual helper measurements](checked-helper-timing.md)
- [Original-program and compiler-cost integration measurements](final-timing.md)
- [Renewed16 measurements](final-timing-16.md)
- [Selected17 measurements](final-timing-17.md)
- [Final17 diagrams and exact plotted samples](final17-figures/report.md)
- [Selected17 release and validation scopes](release-17.md)
- [Independent selected-release review](independent-release-17.md)
- [Renewed frontend observations](frontend-renewal.md)
- [Independent module-layout review](frontend-layout-independent-review.md)
- [Bounded self-emission and its validation scope](bounded-self-emission.md)
- [Warmed generated compiler versus genuine parent](warmed-generated-compiler-cost.md)
- [Current17 generated-compiler comparison](warmed-generated-compiler17.md)
- [Renewed selected backend observations and environment boundary](backend-pilot-renewal.md)
- [Final17 backend renewal:54 fresh and27 reused observations](backend-pilot-renewal-17.md)
- [Checked16 diagrams and exact plotted samples](final16-figures/report.md)
- [Registration-dispatch experiment and controls](registration-dispatch.md)
- [Independent empty-registry transition controls](empty-registry-independent-review.md)
- [Final source review](final-source-review.md)
- [Remaining optimization hypotheses](remaining-hypotheses.md)
- [Independent retirement of arm prebinding](retired-arm-independent-review.md)
- [Held14 comparison figures and exact plotted data](held14-figures/report.md)
- [Generic matcher registration investigation](partial-prebinding-registration.md)
- [Private-helper Let statements in the checked compiler](private-let-compiler.md)
- [Broader Let statements: deferred](general-tail-let-statements.md)
- [Fixed scalar guard lists: below promotion thresholds](scalar-guard-fixed-lists.md)
- [Helper hoisting: no settled gain](hoisted-private-helpers.md)
- [Owned native-call ladder: prototype only](closed-owned-native-calls.md)
- [Preservation scope and prerequisites](evidence/README.md)
- [Compiler implementation and actual terminal controls](terminal-compiler.md)
- [Independent lexical controls](independent-integration-08.md)
- [Independent terminal admission and budget controls](independent-terminal-admission-09.md)
- [Ordinary scalar root experiment](ordinary-scalar-root-regions.md)
- [Runtime method-read experiment](exact-entry-call-read.md)
- [Corrected-runtime constructor-arm retry](exact-constructor-arms-retry.md)
- [Actual ordinary-root compiler and measurements](ordinary-compiler.md)
- [Actual tree compiler and complexity](scalar-tree-compiler.md)
- [Actual tree timings and retained warmup drift](actual-scalar-tree.md)
- [Checked-source tree result and refusal coverage](source-scalar-tree-controls.md)
- [Combined integration gates](final-integration.md)
- [Reusable tree-frame experiment](scalar-tree-frame-reuse.md)
- [Closed owned edit-distance row experiment](closed-owned-row.md)
- [Exact-entry state slots: mixed small benefit, deferred](scalar-exact-entry-state.md)
- [Independent tree admission and shared-header regressions](independent-tree-admission-12.md)
- [Tree prototype and warm-up limits](pure-scalar-tree-region.md)
- [F32 guarded entry: rejected regression](f32-ordinary-root.md)
- [Number-counter retry: small gain, deferred complexity](private-counter-lexical-retry.md)

The checkpoints below retain the order of the investigation; their earlier
pending/rejected states are superseded only where a later report says so.

- [Prospective design](../../design/phase30/direct-generated-code.md)
- [Starting artifacts and protected files](start-state.json)
- [First hypothesis](../../experiments/phase30/P30-001-direct-entry.md)

The baseline is Phase29 at77aecb2; pinned upstream is0187512. The links below
retain earlier experiments and their original artifact/protocol scopes.
No PR comment is part of this campaign.

- [Paired generated-code inspection](code-comparison.md)
- [Private edit-distance mechanism and retained failure](prototype-findings.md)
- [Fresh argument ownership: first checked implementation](owned-arguments.md)
- [Independent semantic review](semantic-review.md)
- [Prospective scalar-region review](region-semantic-plan.md)

- [Region experiments and measurements](direct-region-findings.md)
- [General compiler implementation plan](../../design/phase30/scalar-region-compiler.md)
- [Independent private-plan review](region-private-plan-review.md)
- [Native IR reuse audit](native-ir-reuse-audit.md)
- [Five inherited loop counterexamples](nat-loop-scheduling-review.md)
- [Corrected entry contract](../../design/phase30/scalar-region-entry-correction.md)
- [Runtime entry controls and diagnostic limitation](scalar-entry-runtime.md)
- [Array-call experiment: guarded bypass is slower](native-array-calls.md)
- [Numeric counter experiment: defer a marginal gain](private-counter-representation.md)
- [Record loop investigation](record-carrying-nat-loop.md)
- [Bounded bootstrap diagnostics](bootstrap-diagnostic-bound.md)

- [Early compiler checkpoint and retained recipe rejection](compiler-checkpoint.md)
- [Constant native shifts](constant-native-shifts.md)
