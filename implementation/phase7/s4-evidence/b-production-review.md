# S4 B independent production review

Scope: independently compared the complete A02/B01 production sources and the
saved B patch. This reviewer did not author B. No compiler, API, benchmark or
production edit was run for this review. Candidate root:
`selfhost/build/phase7/s4/candidate-b01-project`.

**No semantic defect found in the bounded patch.** Approval here is for the
source reasoning, subject to the root-owned checked build, full-result controls,
frontend preservation and performance/memory gates. The earlier author-written
`b-independent-review.md` is correctly labeled as an author source review and
independent review of the controls; it is not this second-author review.

## What changes, and what the comparison proves

The 59-module manifest is unchanged. Independent comparison confirms 17 deleted
definitions and no new definition. All 61 datatype declaration blocks are
unchanged. Among 42 changed surviving bodies, 38 consist only of the named
selector/list-operation substitutions; four require the semantic reasoning
below: `f_error_term`, `f_error_defs`, `f_graph_load`, and `f_main_order`.
The two restored `fpe_*` laws change signature placement, not their bodies.

Every changed module's before/after hash matches
[the B01 inventory](b01-source-counts.json). A residual-name scan found none of
the 17 retired identifiers in the selected production modules or B01's current
host/tools/tests (`.bend`, `.mjs`, `.js`, `.ts`, `.json`, excluding source
experiments). The scan inspected 355 tool files and 569 test files. Historical
generated artifacts and experiment evidence are not external API roots. B01's
tools and tests source copies are byte-identical to A02's; the new comparison
controls live separately in the maintained repository.

### Canonical graph traversal

`f_graph_load` now calls `fs_load(..., FSeed{"", Nil{}})`. The retained worker
`fs_source` checks, in order, an existing error, absent/empty source path and
active-stack cycle before `fs_cached`. Therefore any source reaching seed
selection has a nonempty canonical path and cannot match the disabled empty
seed. Its `fs_inject` branch is unreachable for ordinary graph loads.

With that branch excluded, the remaining worker reproduces the retired graph
worker: same source lookup; cached namespace check; parser/parsed-source reuse;
left-to-right import recursion and failure propagation; alias processing;
definition append direction; loaded-path/count entries; final result validation
and freshening. The seed value is passed unchanged through recursion. Existing
trace wrappers continue to use the graph and sources actually loaded.

The real seeded entry points still validate source name, nonempty path and exact
text before enabling a seed. The separate legacy `f_load` algorithm is retained;
it is not redirected to canonical graph loading. The empty-seed proof depends
on the retained missing-source check, so its comment and the explicit empty-path
controls are meaningful compatibility protection.

### First-error projection

For an `Error` term, the old string walk returned its name without visiting its
children. The existing structured walk returns that same nonempty error term,
or an empty-name `Absent` sentinel when the name is empty. Projecting `nm`
therefore preserves both the string and the deliberate child-skip behavior.
For other terms, both walks select the first nonempty error among ordered
children. For definitions, both scan type, then value, then nested constructors,
then later definitions. Induction over those finite typed lists establishes
the exact string projection, including empty errors and nested constructors.

No location-selection or error-rendering code changes. The retained public/
historically probed names `f_error_term` and `f_error_defs` now project the shared
walk. New forward laws for `fpe_term` and `fpe_defs` preserve their exact
unrestricted inputs/results; they are needed because the frontend callers
precede their definitions in the assembled order.

### Common operations and the unused checker wrapper

`f_dn/f_dt/f_dk/f_dx` select the same `KDef` fields as `dn/dt/dk/dx`.
`f_len` and `terms_len` have the same structural recursion and U32 addition.
`f_concat`/`norm_join` and `f_defs_append`/`norm_defs_join` preserve element types,
unrestricted arguments, order, and the right-list tail. In particular legacy
loading still joins imported `defs` **before** its current `book`; canonical
graph finishing still appends new definitions after `prior`.

The membership replacement correctly maps `(name, seen)` to `(seen, name)`.
Finite-string equality is symmetric, so `has_name` preserves membership and
`f_main_order` preserves first declaration order and deduplication. It does not
replace that order with a hash/index order. `check_events` has no remaining
production or scanned external reference; authoritative checker APIs remain.

This reasoning concerns the typed compiler ABI, not arbitrary hostile JavaScript
objects or cyclic/malformed host graphs. The controls separately cover trusted
direct-API parsed records whose text and cached result intentionally disagree.

## Complexity and dependency cost

Two duplicate implementations are actually retired:

1. The ordinary canonical module-graph recursion now shares the seeded worker.
2. The legacy string-only embedded-error recursion now projects the structured
   first-error walker.

Eight duplicate small utilities are also retired: four selectors, list length,
two typed concatenations and name membership. The seventeenth removed function
is an unused checker projection. These are **17 fewer private function
interfaces, not 17 fewer major compiler concepts**. Graph loading, seeded cache
invalidation, error selection, freshness, aliases, the legacy loader, checking,
all public representations and both backend models still exist.

There is a dependency tradeoff. Ordinary graph loading now depends on
`load/seed.bend`, which already depends on graph finishing; the frontend string
error aliases now depend on the structured walk owned by `load/graph.bend`.
Callers also reuse concatenation from `core/normalize.bend`. These changes reduce
parallel implementations, but do not improve every file-level dependency or
review-context measure. The two forward laws cost four net physical lines and
the disabled-seed explanation costs one, already included in the net counts.

The new ordinary path tests seed predicates even when disabled. The structured
error walk produces `Absent` term sentinels where the old no-error walk produced
empty strings. Generated-code optimization may reduce that allocation, but
source reasoning cannot establish runtime or RSS neutrality. The serial raw/
parsed graph and accepted/rejected full-host gates remain required; no speedup
is claimed from the smaller source.

## Counts and evidence limits

B alone removes **190 physical lines / 163 nonblank lines / 4,594 bytes**:
14,857 / 12,668 / 474,656 → **14,667 / 12,505 / 470,062**. Definitions change
1,450→1,433; laws 799→789; datatypes remain 61. The 27 removed blank separators
are source-size savings, not concept savings. Signature/header replacement costs
and the added comment are included; no required work is moved to host code.

Against S0, the same 59 production modules are 1,842 physical lines, 1,298 nonblank
lines and 39,875 bytes smaller. The remaining gap to 8,254 lines is **6,413**;
the 50% milestone is unachieved. C was rejected and contributes no saving.

[The independent context recount](context-counts.md) retains the original S0
sets and separately includes whole files that now own their former roles.
Its role-preserving parser set grows from 5,716 to 5,928 physical lines despite
the same-path subset shrinking. This is not uniform review-context reduction.
Task sets overlap and cannot be summed into a whole-compiler complexity score.

The improved whole-result controls cover changed loading/error contracts and
compare ordered books/traces, including cached-result/text disagreement and
visible seed selection. Their baseline-only smoke is not candidate evidence.
Root-owned B build/control/frontend/performance/release results must be reported
by exact artifact identity when available. A02's successful B1→H→H proof must
remain attributed to A02; this source review does not establish a B01 fixed point.
