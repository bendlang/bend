# S4 frontend/book audit: bounded consolidation, not a 50% plan

Read-only against S3 `8cc51c1`. No compiler, build, prototype or benchmark was
run, and no compiler/host/test/configuration file was edited. This report and
[the exact inventory](frontend-book-inventory.json) are the only outputs.
The inventory records declaration ranges, block/module hashes, callers,
conservative external roots, and the continuation-helper census.

There is a defensible **205-line candidate** preserving current public entry
points, plus **270–443 potential additional lines** from a bounded set of
whole-expression continuation helpers. Neither has been implemented or validated.
Even the optimistic combined 648 lines would leave **6,785 of the remaining
7,433 lines** needed for the 8,254-line milestone. This audit does not substantiate
S4's original target. These are structural reductions, not comment removal,
signature reformatting, or compiler logic relocated into JavaScript.

## Concrete units, ordered by structural value

All counts below include full laws, `@unsafe` markers and declaration boundaries.
The inventory gives inclusive line ranges against the recorded source hashes.
Net physical estimates assume caller replacements remain on their current lines;
new explanatory comments, adapters or test/tool work must be charged separately.

| Unit | Exact removable declarations | Projected net Bend lines | Decision |
| --- | --- | ---: | --- |
| Share canonical graph loading | `f_graph_source_load`, `f_graph_cached`, `f_graph_parsed`, `f_graph_imports`: 61 physical / 53 nonblank / 2,224 bytes | 61 | Strongest structural trial |
| Share embedded-error selection | `f_error_terms`, `f_error_more`, `f_error_def_next`, `f_error_defs_more`: 40 / 32 / 836; simplify retained `f_error_defs` by four lines | 44 | Strong bounded trial; preserve exact error ordering |
| Reuse existing selectors/length | `f_dn`, `f_dt`, `f_dk`, `f_dx`, `f_len`: 52 / 42 / 790 | 52 | Straightforward caller substitution |
| Reuse existing list/name operations | `f_concat`, `f_defs_append`, `f_main_seen`: 39 / 33 / 663 | 39 | Straightforward substitution, including argument order |
| Retire post-S3 unused wrapper | `check_events`: 9 / 7 / 184 | 9 | Unrooted after S3; source-only deletion candidate |
| **Total** | No new datatype or public entry-point removal | **205** | Requires fresh correctness/cost gates |

The source declaration bytes above are gross deletions, not a claimed net byte
delta: replacements and changed caller identifier lengths must be recounted.

### One canonical graph traversal: 61 lines

The unseeded graph implementation and `fs_*` implementation independently repeat
source lookup, existing-error propagation, nonempty-path validation, cycle checks,
namespace-cache checks, parse handoff, and recursive import traversal. Their order
and expressions match except for the seeded implementation's optional Base
injection. This is actual algorithm duplication.

Keep `f_graph_load(path, ns, sources, graph, stack)` and route it to the existing
`fs_load` with `FSeed{"", Nil{}}`. Delete only the four unseeded helpers listed
above. Keep both public graph APIs, both trace APIs, both seed APIs, `FSource` /
`FParsedSource`, `FGraph`, `FLoadTrace`, parsed results and all host capability
selection unchanged. No new loader mode or closure field is needed.

The disabled seed cannot inject: `fs_source` rejects an empty source path before
`fs_cached`; the injection predicate requires equality with the empty seed path.
The valid-seed wrapper's exact source-text/path test remains unchanged. Trace
declaration counts, final freshening, source-order events, aliases and dependency
position remain owned by the same existing functions.

None of the four deletable names has an external tool/test/doc reference in the
scan. `f_graph_load` remains a compatibility/internal entry point. The trial must
compare complete ordered books and trace records for raw and parsed sources,
valid/stale/unused Base seeds, aliases/diamonds, cycles, absent source/path,
namespace conflicts, partial failures and duplicate declarations. Include a
`Base`-named source with an empty path to falsify accidental disabled-seed
injection. Measure accepted unseeded loads: the shared implementation adds the
small seed predicate on cache misses, so zero runtime cost is not assumed.

### One embedded-error traversal: 44 lines

`f_error_*` returns the first error string. Existing `fpe_term`, `fpe_terms`,
`fpe_def` and `fpe_defs` select the same first error term to recover source
location. The latter traversal already handles the former's unusual semantics:
an `Error` with an empty name is skipped without searching its children, and
ordinary terms search children in order. Definitions search type, value,
constructors, then later definitions.

Retain `f_error_term(t)` as the projection `nm(fpe_term(t))`, and retain
`f_error_defs(book)` as `nm(fpe_defs(book))`. The absent sentinel has an empty
name. This removes the four redundant recursive helpers and shrinks
`f_error_defs`, without inventing a new error-carrying result type. Keep
`f_validate_result` and the `fpe_find` owner-index path unchanged. The latter is
still needed to associate the selected error with the correct trace module.

`f_error_term` has a live non-walker caller in namespace parsing.
`f_error_defs` is referenced by the historical embedded-parser-order probe, so
retaining these projections avoids breaking it. The other four names have no
external references. Existing graph errors must continue to win before embedded
errors, embedded errors before graph freshness errors, and source refinement
must only render a term whose message matches the already selected error.

Reuse the existing embedded-parser-order controls and full frontend vector,
including earlier/later declaration errors, malformed types and bodies together,
nested constructor errors, empty-name errors with nonempty erroneous children,
unmarked errors before marked errors, duplicate-name errors, Unicode locations,
and raw versus parsed source handoff. Compare exact partial books as well as
messages. No earlier short-circuiting of the parser/elaborator is proposed.

### Shared primitive operations: 91 lines

The corrected S0 pool is still **52**, not 62: `f_dv` was already removed by S1.
Substitute `f_dn→dn`, `f_dt→dt`, `f_dk→dk`, `f_dx→dx`, `f_len→terms_len`.
Their argument/result types and field/list behavior match; none is an external
root. No public `KDef` or `KTerm` representation change is needed.

Additionally substitute `f_concat→norm_join`,
`f_defs_append→norm_defs_join`, and
`f_main_seen(name, seen)→has_name(seen, name)`. The two append operations preserve
order and use the same recursive structure. Both membership operations compare
complete strings and stop on the first match. These three removed helpers have
no external roots. This removes duplicate operations, not three major compiler
concepts. Do not substitute `f_find→lookup`: their `Missing`/`Absent` failure
sentinels and the core indexed-book contract differ.

### New dead code: nine lines

The conservative lexical closure finds 1,450 production definitions, 288 external
roots and 1,449 reachable functions. Only `check_events` is newly outside the
closure. Its law at `check/kernel.bend:453–457` and definition at `1009–1012`
total nine lines. S3's public String APIs now project the detailed worker directly.
There is no external reference to this helper. As in S1, an arbitrary custom
all-definition export is not the maintained public API contract; retain the
documented/selected checker entry points and verify exported roots afterward.

## Why the legacy-loader 92-line pool is not credited

S0's corrected gross 214-line pool consists of 52 selectors, 92 legacy-loader
declarations and 70 error traversal/validation declarations. This audit credits
52 and 44 respectively, and **zero** for replacing the legacy loader wholesale.

The old `f_load` remains selected by the host and is a fallback in both the host
and `selfcheck.mjs`. Its implementation is not merely an alternate spelling of
canonical graph loading:

- It keys `seen`/cycles by module name, while graph loading keys by path and
  enforces one namespace per source file.
- Missing-source and cycle error strings differ.
- It reparses source text through `f_parse_at`; graph loading consumes a supplied
  `FParsedSource` result through `f_parse_source`.
- Old per-module elaboration sees its family-book set differently from the
  graph's source-order `f_module_defs` scope/visibility construction.
- Dependency assembly, intermediate failure books and freshness checks differ.

A wrapper `f_load = f_load_graph` would change an exported function's behavior.
Current hosts choosing `f_load_graph` first do not prove equivalence for direct
`f_load` callers or older artifacts. Preserving the fallback does not require
keeping duplicate seeded/unseeded canonical graph algorithms, so the 61-line
unit above is independent. Either retain legacy semantics, or explicitly design
and validate a narrower compatibility contract before crediting its deletion.

## Continuation-helper census

There are many helpers whose signature transports values solely to bind or
destructure a computed result. Body-local binding/destructuring can remove such a
helper's law/function boundary while keeping its body. The inventory separates
single *textual call occurrences* from single caller functions, excludes external
roots, and records indirect recursion separately.

| Private helper class | Helpers | Complete declarations | Overhead ceiling before local bindings | After one local per argument |
| --- | ---: | ---: | ---: | ---: |
| Nonrecursive, whole function result | 9 | 89 | 69 | 53 |
| Nonrecursive, whole existing case/block result | 11 | 142 | 110 | 66 |
| Nonrecursive, nested/branch call | 46 | 470 | 368 | 275 |
| In a recursive cycle, whole function result | 15 | 180 | 148 | 89 |
| In a recursive cycle, whole existing case/block result | 14 | 186 | 144 | 80 |
| In a recursive cycle, nested/branch call | 86 | 1,023 | 823 | 514 |

The 2,090 declaration lines in this table are **not removable code**: most helper
bodies remain in their caller. The overhead estimate is the removed law/definition
boundary plus replaced caller-expression line, minus all retained body lines.
The last column also charges one binding line per parameter. Both are source
estimates; comments, type annotations, temporary variables, name capture, runtime
cost and compiler acceptance still need validation.

Start with the 20 nonrecursive whole-expression cases: for example
`f_char_decoded→f_char_literal`, `f_float_read→f_float`,
`f_adt_fill→f_adt`, `f_main_result_names→f_main_names`,
`f_let_body→f_let_value`, `f_fresh_result_end→f_fresh_result`, and
`f_graph_finish_alias→f_graph_finish`. They offer 119–179 lines under those
binding assumptions. This keeps each computation at its existing evaluation
point and gives a small pilot with a clear inverse diff.

The 29 whole-expression helpers in indirect recursive cycles include
`f_tele_at→f_tele`, `f_top→f_tops`, parser continuation stages and freshening
worklist stages. A sole caller can often absorb them without inventing recursion:
calls back into the surviving function remain. However, tail position, worklist
state, stack behavior and affine sharing need separate review. Do not call these
nonrecursive helpers or mechanically inline direct self-recursion.

The combined 49 whole-expression cases have 288–471 lines under the two
accounting assumptions. Three overlap the structural pool above:
`f_error_more`, `f_error_def_next` and `f_graph_source_load`.
Removing those credits leaves **46 helpers / 270–443 additional lines**.
Helper-law deletion also overlaps any separate typed-definition signature
proposal; those savings must not be added twice.

The other 132 cases occur inside constructor arguments, nested calls or lazy
`f_choose` branches. They receive **zero** budget here. Hoisting their work above
a branch could evaluate rejected alternatives or change first errors, and a
lambda with an arbitrary match block is not assumed to be supported. Replacing
these expressions needs a supported structured branch/body slice and its own
proof/cost accounting. A large raw helper count is not evidence of a 1,000-line
safe reduction.

## Book/result transport and common body destructuring

`f_graph_result` presently applies embedded-error validation, graph freshness
checking and global freshening, then `f_graph_result_at` refines the chosen error
against the original graph and trace. The public `FResult` exposes the freshened
partial book even on failure, while location recovery needs the pre-freshening
terms. Combining these stages must retain both identities, first-error priority
and exact partial output. `FParsed` carries token remainder; `FRawResult` retains
structured parser errors until source rendering; `FGraph` carries dependency
trace state. These records do different jobs. No whole-record deletion is
supported by merely observing repeated `match FResult` expressions.

Local continuation fusion, such as `f_fresh_result_end`, can remove forwarding
without changing those contracts and is counted above. A new universal result
record would add adapters and migration paths; it has zero separate deletion
credit here. Likewise, source-position `KTerm.id` and binder IDs cannot be
collapsed simply to reduce field-access code.

The 15 core `KTerm`/`KDef` field selectors occupy 150 declaration lines. A lexical
call scan finds their use in 609 production functions. Replacing selectors
globally with body destructuring would add bindings in many consumers, and some
selectors remain tool/test/probe roots. Therefore this is not a 150-line free
pool. Local destructuring may improve a heavy consumer's readability or avoid
repeated selection, but needs net accounting and should not replace short,
shared accessors everywhere. The duplicate frontend selectors are the supported
exception because equivalent core operations already exist.

## Host and lineage constraints

`loadApiForIdentity` already chooses named B1 versus positional H representation
once and wraps positional APIs through the shared `createCompilerAbi` boundary.
Compiler phases retain their graphs; host-visible views preserve identity and
are read-only. The separate exported `convertCompilerAbi` is an eager graph-copy
utility with deep/shared-graph tests and historical references; it is not the
same operation as the lazy read-only view. No host boundary savings are credited
without preserving those contracts and genuine B1/H artifact lineage.

Keep old loader/checker capability fallbacks and compiler/source-bound Base
cache validation. Bootstrap identity and release checks establish which compiler
was actually run; deleting them would reduce evidence rather than compiler
concepts. No production work should move into the host to meet the Bend line
target. All trials remain subject to the sequential design/build/report workflow,
whole-result equivalence, full frontend preservation, controlled cost gates and
the milestone's genuinely checked self-reproduction/release requirements.

## Scan limits and useful falsifiers

The inventory scans all 59 manifest modules. The dependency graph masks quoted
strings, character literals and comments, conservatively collecting function
identifiers; external roots come from 1,076 listed text files under `selfhost/`
and `docs/`, including historical tools, with build/distribution/dependency trees
excluded. This is lexical evidence, not a Bend parser or name-resolution proof.
It can over-retain a name found in comments or a shadowed local. A public/dynamic
caller absent from this scope would falsify a deletion candidate.

Promotion must also reject a new parser/checker acceptance, changed first error
or location, changed ordered book/trace, missing export, lost parsed-source/seed
fallback, unchecked lineage, deep-term/stack regression, or a net cost increase
after replacement code is counted. Fresh measurements may reject any candidate;
the 7,433-line gap is not permission to remove a live contract.
