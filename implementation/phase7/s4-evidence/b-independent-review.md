# S4 B source and control review

Scope: read the committed B design, A02/B01 source diff, shared primitive
implementations, assembler visibility rules and
`selfhost/tests/frontend/shared-operations.mjs`. This reviewer implemented B01;
the independent portion is review of the root-authored controls, not a second
author's approval of the production patch. No heavy compiler job was run.

**Finding:** no semantic defect found in the bounded B01 change. The source is
ready for the planned candidate builds and cross-version gates; the small
baseline smoke below is not candidate correctness or release approval.

## Source obligations and actual cost

* `f_graph_load` delegates with an empty disabled seed. Existing `fs_source`
  tests prior error, missing/empty source path and active-stack cycle before
  `fs_cached` can match a seed. Since a surviving source path is nonempty, it
  cannot equal this seed's empty path. Cached namespace checks, import order,
  graph finishing and final freshening retain their existing implementations.
* `nm(fpe_term(...))` and `nm(fpe_defs(...))` retain the old first-error order:
  types before values, then nested constructors, then later definitions.
  An empty-name `Error` skips its own children and lets its parent scan later
  siblings; both it and the absent sentinel project to the empty string.
* Shared selectors, list concatenation and list length retain the same field,
  list element types, unrestricted `+` binders and `List<&2,...>` quantities.
  Their bodies are the same structural operations. `has_name` takes the list
  first, so the replacement explicitly reverses argument order. It retains
  first-match Boolean membership. The legacy `f_find` missing sentinel and
  legacy `f_load` contract were not replaced by indexed lookup or graph loading.
* Surviving definitions retain `@unsafe`; 17 removed markers correspond to the
  17 retired definitions. The new earlier calls into `fpe_term` and `fpe_defs`
  require their restored forward laws. Their exact typed binders/results are
  preserved, and their fills use bare parameters. All 48 new lexical dependency
  edges were checked: the only three forward edges target these two laws and
  the already-declared `fs_load`. No new undeclared forward edge was found.

The two restored laws cost **4 physical lines net** after replacing their
typed definition headers. The disabled-seed comment costs **1**. The actual
reduction is therefore **190 physical / 163 nonblank lines / 4,594 bytes**, to
14,667 / 12,505 / 470,062. There are 1,433 definitions and 789 laws. The 27-line
difference between physical and nonblank savings is blank separators and earns
**no complexity credit**. No packed signature, body, or binder contributes to
the reduction. See `b01-source-counts.json` and `b01-shared-frontend.patch`.

## Controls reviewed and gaps closed

The original tests compare exact ordered named-field results, not just success
flags or diagnostic substrings. Their explicit expected errors prevent the
baseline from silently establishing the wrong branch for empty paths, cycles,
namespace conflicts and direct nested error traversal. The private-function
exposure appends exports of existing checked bodies without rewriting them.
Whole books and traces cover term/definition fields and declaration order.

Review identified and closed three gaps in that test file:

1. Direct graph/error inputs were shared across API calls without mutation
   checks. They now have checks immediately after each API call.
2. Name membership lacked a law/fill pair. A new fixture checks both whole
   results and the explicit unique order `Flag`, `pick`, `main`.
3. A seed equal to reparsing cannot establish whether seed insertion happened.
   A visibly marked book now checks exact seed use and rejection on changed
   text, changed path, disabled seed and unused Base, in raw and parsed modes.

At the other reviewer's request, two further controls deliberately mismatch
`FParsedSource` text and its cached parse. Invalid text with a successful cached
parse must succeed; valid text with a cached parse error must reject. Both
compare exact graph, trace, main names and input identity. These controls and
the marked seed are explicitly **trusted direct-API contracts**; they are not
evidence that the driver should accept an unvalidated persisted cache. Real
cache identity/invalidation remains covered by maintained cache tests.

Exact original test bytes were retained as
`selfhost/build/phase7/s4/b-controls-smoke-01/shared-operations-v1.mjs`, matching
that run's recorded test hash. The revised test and its hash are retained with
`b-controls-smoke-02/shared-operations-v2.mjs` and `report.json`.

The permitted small baseline-versus-itself smoke used CPU 1 and Node 24.18.0:

```sh
taskset -c 1 /home/ai/.nvm/versions/node/v24.18.0/bin/node \
  selfhost/tests/frontend/shared-operations.mjs \
  selfhost/build/phase7/s4/attempt-a02/api.mjs \
  selfhost/build/phase7/s4/attempt-a02/api.mjs \
  selfhost/build/phase7/s4/b-controls-smoke-02
```

It completed with **58 rows and 626 counted comparisons**, all passing. The
report's comparison counter does not include every direct assertion. An initial
unqualified `node` command failed before executing because Node was absent from
the shell's PATH; the explicit path above resolved it.

This smoke establishes that the new fixtures reach their asserted branches and
that the harness runs. It does not compare B01 yet. The focused fixtures do not
exhaust template counts, foreign declarations, quantity checking, native code,
provenance ranges or all malformed inputs. Those depend on the planned checked
build, maintained components and full frontend vector. Loader consolidation
also introduces a disabled-seed predicate on ordinary loads, so the separate
serial performance gate remains necessary even though source is smaller.
