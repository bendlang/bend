# S2: one authoritative loader trace for source provenance

Status: designed before implementation. Baseline: S1 commit `af3c639`,
15,961 physical lines / 13,343 nonblank lines / 494,957 bytes.

## Decision and revised scope

The broad S2 proposal is not funded by the S0 audit. Explicit first-order term
variants would still need generic traversal, administrative forms and public ABI
adapters. The pinned language provides neither automatic field projections nor
destructuring function parameters. Removing 82 accessor lines does not establish
a net saving. Do not introduce a second term representation to satisfy that plan.

The historical numeric-provenance candidate adds 292 Bend and 52 host lines,
retains origin recovery, and has no completed accepted-cost gate. Its point spans
also do not replace the public token-range and final-core-route contract. It is
not adopted here. Direct spans and explicit variants remain deferred hypotheses.

Instead consolidate the existing provenance orchestration in
`selfhost/src/diagnostic/frontend.bend`. Both public source-loading APIs will use
the existing `FLoadTrace` and its declaration counts to align final definitions
with their defining modules. Retire duplicate module reparsing and event/source
alignment. The ordinary compiler already uses the trace path for rejected terms.

This is an evidence-driven revision of S2, not completion of the original term
migration or its 13,500-line forecast. The original 50% and 75% milestones remain
unchanged and unachieved. Later phase allocations need their own concrete budgets;
do not transfer these 139 gross lines into a second phase's savings.

## Implementation and cost gate

1. Delegate `f_load_origins_for` through `f_load_graph_trace` and the existing
   filtered trace implementation.
2. Share that implementation with unfiltered `f_load_origins`, using an explicit
   Boolean selection argument. An empty string is a valid filter value and must
   not become an all-definitions sentinel.
3. Delete `fp_graph`, `fp_result`, `fp_modules`, `fp_module`, `fp_module_parsed`,
   `fp_event_sources`, `fp_join`, `fp_defs`, `fp_defs_source`, `fp_graph_for`,
   `fp_result_for`, `fp_defs_for` and `fp_defs_source_for`: 139 existing lines,
   137 nonblank lines and 3,844 bytes. Optionally replace the private 9-line reverse
   helper with the existing `List.reverse` if its order and type are verified.
4. Keep six-field `KTerm`, origin construction/UTF-16 conversion, structural
   location matching, loader results, checker behavior, runtime and host ABI.

Count all added helpers, selector arguments and compatibility handling. Promotion
requires at least **99 net physical lines and 2,444 bytes removed**, fewer nonblank
lines, no new datatype, and retirement of the alternate provenance orchestration.
This sets a revised S2 ceiling of **15,862 lines / 492,513 bytes**. No source code
may be moved outside the compiler count. Test/evidence costs are recorded separately.

## Validation and negative controls

Freeze the S1 checked API and source. Build a fresh genuine checked candidate and
its maintained equality derivative in `selfhost/build/phase7/s2/`; retain failures.
Compare every exported function and unchanged generated function bodies where
possible, without treating source-size equality as behavior evidence.

Run existing component checks, particularly `frontend/origins.mjs` and
`diagnostic-reuse.mjs`. Compare baseline and candidate complete provenance objects
for unfiltered and filtered APIs: every definition, empty and unknown filters,
imports/diamonds/aliases, law/fill events, valid parsed-source handoff, Unicode,
repeated equal terms, beta substitution and constructor paths. Include parse
failures, duplicate declarations, cycles and missing imports. Compare trace and
seeded trace routes where supported. These cross-version comparisons must preserve
ordered origins, final terms, UTF-16 token ranges, routes and loader errors.

Run the maintained focused end-to-end suite and ordinary check/interpreter/JS
smoke. Native execution is required if native generation changes; unchanged
reachable native/JS code must be demonstrated before narrowing that gate. Current
Clang absence is not a passing native execution result.

Measure affected public provenance calls serially with alternating baseline and
candidate order, fixed Node/CPU/input and warmups. Check accepted and rejected
driver paths; a >5% stable regression or >10% memory/size growth rejects promotion.
If an unaffected request path is proven byte-identical, reuse its behavior evidence
with that explicit scope rather than inventing a new speed ratio. A source-only
check is not a fresh B1→H→H fixed-point proof; representation integration and the
milestone retain that separate gate.

## Completion

An independent reviewer checks deletion scope, filter/trace edge cases and exact
net costs. After gates pass, install the validated release, verify its source
binding, update the compiler guide and phase ledger, and write
`implementation/phase7/s2-report.md` with evidence and limitations. Commit and push
before S3 begins. If equivalence fails, fix the candidate or reject it; do not
weaken the public provenance contract to obtain a line reduction.
