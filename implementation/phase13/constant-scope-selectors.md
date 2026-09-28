# Phase13 selector fusion around unchanged constants

The [prospective experiment](../../experiments/phase13/P13-006-constant-scope-selectors.md)
permits one narrow extension to the frozen selector rule: single initialized
`const name = expression;` declarations remain at their original positions.
Only their own initializer equals token is exempted from the existing write
guard. The entire initializer, including callbacks, is still scanned. Destructuring,
multiple declarators, owner-parameter shadowing and all existing forbidden writes
or control forms remain refused. No const is moved or captured.

The isolated implementation is
[rewriter-selector-const.mjs](../../selfhost/tools/performance/phase13/rewriter-selector-const.mjs).
It preserves the previous public transform interface and uses the existing shared
module view and version5 prerequisites. The earlier selector helper and all of its
attempts remain unchanged. The completed actual-rule inventory selects a single
combined image containing only admitted members of the seven planned checking
owners. Independent controls precede resource screening and timing. The paired
pilot records 10.56% less process time; the final decision defers promotion.

## Actual inventory and frozen combined image

`selfhost/build/phase13/rewriter-selector-const-inventory-01/report.json` records
118 syntactic candidates passed to the real extended helper: 29 owners accept
86 selector removals, and 89 refuse. The manifest-selected combined image contains
only six of the seven checking owners named in the prospective plan:

| Owner | Removed selectors |
| --- | ---: |
| `norm_eval_node` | 5 |
| `check_node` | 6 |
| `norm_match` | 2 |
| `norm_args` | 1 |
| `ffw_walk` | 4 |
| `infer_node` | 10 |

`core_subst_stable` passes the extended declaration scope but still has no admitted
selector condition, so it is excluded. Other inventory successes are not added.
Every refusal and successful per-owner report is retained. The original single
normalizer image also reproduces byte-for-byte under the extended helper.

`selfhost/build/phase13/rewriter-selector-const-combined-01/manifest.json` binds
the six-owner, 28-selector image:
`7eca544a1f2e3ab637064533117f290bd576c5774d111a619fdd12755817c81e`.
Its helper is
`071f5b05b5c5afecd598258153d69f2c1d639a09c4ee952b1c33f24c0f0a2e75`;
the genuine Phase12 checked parent, released baseline, runtime and Base are
unchanged. The preparer binds the completed inventory and verifies that the
selected names are exactly the accepted members of the planned checking list.
This is an identified derivative, not a new checked bootstrap.

The extended helper has 106 physical lines / 7,354 bytes versus the preceding
selector's 92 / 6,352: an increase of 14 lines / 1,002 bytes. This excludes the
still-required shared representation, version adapter, frozen historical helper
and controls. It is not a maintained complexity reduction.

## Operation controls

The unchanged selector counter runs against the combined manifest in
`selfhost/build/phase13/rewriter-selector-const-counts-01`. All valid two-module
graphs with 4, 16 and 64 definitions per module load and check exactly as the
released baseline. Counters instrument actual selected-family arrow creation,
Unit construction, message/array creation, calls and dispatches.

At 64 definitions per module, loading removes 1,052 closures, Units, messages,
arrays and dispatches; checking removes 5,931 of each. Check dispatches fall
60,344 → 54,413, and consumed argument slots fall 70,287 → 64,356. Every removed
selector saves one of each counted operation, with no new capture slots.
These are operation results from instrumented images, not elapsed-time or
allocated-byte measurements.

## Independent correctness and resource gates

The independent reviewer reports passing actual-transform controls:

- `control-const-inherited-01`: 30 paired observations and 22 retained refusals.
- `control-const-01`: 42 paired observations covering 14 scenarios with three
  selected tags, and 23 new refusals. These include throwing/delayed initializers,
  TDZ reads, sibling/nested shadows and writes inside initializer callbacks.
- `control-const-bodies-01`: 52 exact surviving arrows, two surviving containers
  with declared nested rewrite sites, 28 removed intermediate arrows and ten
  unchanged constants with their nearest-arrow ownership preserved. All
  unselected functions remain exact.

The combined image rederives exactly. The fresh and paired 53/60-history gate
passes at unchanged 4 MiB stack and 4 GiB heap in
`selfhost/build/phase13/measure-const-history-01/report.json`. These observations
still do not establish general stack equivalence.

## Controlled timing and decision

Root's exclusive CPU0 ABBA in
`selfhost/build/phase13/measure-const-pilot-01/report.json` passes all four complete
same-source checker observations with identical results. Fresh Node 24.18.0
processes use unchanged host/runtime/source and separately validated API-specific
Base caches. Process wall includes startup, verification and capture; request
time wraps the unchanged adapter probe, including lazy API loading. Cache
preparation and transformation remain outside measurement; OS caches are not
flushed. Other intentional compiler/archive jobs were paused.

| Mean of two samples | Phase12 baseline | Six-owner candidate |
| --- | ---: | ---: |
| Process wall | 27.3622 s | 24.4740 s |
| Request | 26.2075 s | 23.3271 s |
| Maximum observed RSS | 1,341,740 KiB | 1,334,972 KiB |

The candidate uses 10.555% less process time and 10.991% less request time. This
is a useful scoped result, but it misses the roughly 20% promotion target. The
self-contained feasibility helper still adds 239 physical lines / 7,010 bytes
over the maintained helper, so the alternative speed-plus-simplicity criterion
is not established either. Root defers production integration and further
expansion. Phase12 remains installed; no new TypeScript comparison, complete
frontend/backend gate, generated-user-code gain or release claim follows.

The separate [maintained-helper feasibility](rewriter-maintained.md) tests whether
the shared recognizers can replace duplicated machinery in one self-contained
file, with exact authentic historical replay. Experimental dependency totals
must not be mistaken for a finalized production implementation cost. The bounded
replay succeeds, including all authentic versions 1–5 and exact new-image bytes;
it does not substitute for the conditional integration gates that were not run.
