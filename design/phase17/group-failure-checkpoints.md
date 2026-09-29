# Failure checkpoints after the FGroup ablation

Prospective proposal only. No compiler implementation is authorized by this file.
The concrete parent is group-source-02/project, checked as group-checked-01;
its cheap gates and exact costs are recorded in implementation/phase17/group-boundary.md.
The installed compiler remains unchanged. This proposal targets the two main
monad observations and the saved16 stage observations, with the broader saved
pattern/chronology controls guarding lexical context and first-error order.
It does not address the separate checker same-body live-instance chronology gap.

## Decision

Retain a small explicit checkpoint program only when a parser callback is about
to propagate an Error. Keep FParsed's two fields, successful output and ordinary
parser signatures unchanged. The enclosing callbacks already hold the left
term, earlier arguments, patterns, telescope or completed rows which are about
to be discarded. Capture those values there, instead of threading a lexical
context through the104-function transitive parser call graph.

The necessary new work is not another marker tweak. A complete implementation
is estimated at250–400 physical lines across roughly10 files, including laws,
helpers, rejection branches and the module handoff. This is an estimate, not a
measured reduction. It must be split into a small resolver proof and reviewed
wiring. A def-only patch would conceal the same bug under a lambda or row scope.

## Explicit program and reusable owners

An Error can carry a ParseDeferred child containing the original structured
leaf and a nested checkpoint program. The outer tag stays Error, so existing
propagation continues to work. Its name retains the original legacy fallback;
ids, quantities and source coordinates keep their existing meaning. Frame tags
and children carry metadata explicitly. No diagnostic-string parsing, source
rescan, origin ordering or generated-id inference is permitted.

The minimal semantic operations are:

| Operation | Payload and behavior |
| --- | --- |
| BeforeTerm | Earlier completed term, then continuation. Scope it with f_scope in the current environment, select any structured fpe_term error, otherwise continue. This is a term boundary and may lower a completed grouped body. |
| BeforeBody | Earlier completed raw row body, then continuation. Replay its parse checkpoints without flattening the enclosing Local/Match/Parallel body. FGroup explicitly crosses the term boundary inside that body. |
| Open | Actual immutable binder list and a nested program. Extend via f_pattern_env or the same f_vars convention used by the enclosing declaration; the outer continuation retains its original environment. |
| Patterns / Names | Actual left terms, RHS terms, and continuation. Check left expression checkpoints and RHS terms in source order; reuse f_patterns, f_valid_patterns_mode and f_pattern_env, then enter the continuation. Names is the existing typed/parallel names-only restriction. |
| Lambda | The actual Lam/FLambda binder and operator cursor, then a pending body. Reuse the eligibility decision in f_scope_lambda_eligible without invoking f_scope_lambda_var's body flattening on an incomplete body. |

BeforeBody and Lambda must be explicit operations, not inferred flags hidden in
an existing term field. Telescope, All/Exists, rewrite and do scopes compose
BeforeTerm/Open rather than require separate interpreters. Exact helper names
proposed for the prototype are f_reject_wrap, f_reject_resolve,
f_reject_before_term, f_reject_before_body, f_reject_patterns and
f_reject_lambda. A returned Absent means no earlier checkpoint error; an Error
is a selected structured leaf. Continuations are immutable data, not callbacks
stored in semantic core terms.

One small shared extraction is required in validate.bend: the unsupported-pattern
fallback must receive the actual environment or its already scoped observed term.
Today f_valid_pattern prints f_scope(p, Nil{}, book); that loses enclosing binders
for computed patterns. Keep all ordinary Var/Ctr/quantity/constructor decisions
in f_patterns/f_valid_patterns_mode. Do not introduce another pattern checker.
Likewise extract the binder eligibility/result from f_scope_lambda_eligible;
do not duplicate qualified-alias lambda rules in the new resolver.

## The important unresolved cost/complexity boundary

Calling fpe_term(f_scope_body(body, env, book)) blindly is insufficient.
f_scope_local_valid and f_scope_parallel_valid validate patterns before scoping
RHS terms. Pinned parse_body parses RHS terms before parse_patt. A completed
nested group can therefore contain an earlier semantic frontend error which
must win over a bad outer pattern. Fixing that by adding a whole-tree scan to
every successful local would put new cost on the hot path.

The proposed failure-only BeforeBody adapter has exactly three structural cases:

- Local: left term checkpoint, RHS term checkpoint, existing pattern validation,
  then the continuation body under the resulting pattern environment.
- Parallel: left terms and RHS terms in source order, existing names-only pattern
  validation, then the continuation body under all resulting binders.
- Match: completed head-term checkpoints, then each row's existing pattern
  validation and body checkpoints under that row's environment. Never call
  f_flat/ff_flat on this unfinished outer Match.

Every other node is a completed term and delegates to BeforeTerm. Thus FGroup
uses its existing scope consumer; completed lambdas/do/annotations use their
existing owners. The adapter returns only a selected error; it does not build a
second scoped body, choose constructors, lower sugar, generate fresh identifiers,
reduce terms or implement lexical lookup. This is the smallest currently known
ordering adapter. It is still new traversal logic and must earn its complexity.
If the prototype needs another raw body case with new semantic behavior or
reimplements one of the existing owners, stop and compare a shared traversal
refactor/contextual parser instead. Do not silently grow this into a second body
interpreter.

## Concrete failure capture sites

These are rejection branches or delimiter-failure sites. Ordinary successful
branches retain their existing construction. The list is an audit map of45
callbacks, not a claim that all45 need separate helpers or signature changes.

| Source file | Existing functions and retained data |
| --- | --- |
| declarations.bend | f_let_value retains left term before a failed RHS; f_let_body retains left/RHS before continuation failure. f_match_head retains prior heads. f_case_pat/f_case_pats/f_case_body retain heads, completed rows, earlier patterns and current row environment. f_def_base/f_def_type/f_def_body retain completed telescope/type and open the proper definition parameters. f_tele_type retains prior cells before the failing cell's domain. f_law_type/f_law_end retain prior clauses. f_type_kind/f_type_ctor retain family parameters and completed constructor prefixes. (14 sites.) |
| parser.bend | f_expect, f_args_base/f_arg_next, f_grow_args and f_tuple retain completed terms before delimiter/argument failure; f_binary distinguishes lambda binding from ordinary earlier-LHS checkpoints; f_all_body opens its binder only after the domain; f_brace_left/f_group_ann and f_equation/f_equation_type retain their completed earlier terms; f_matcher_arm/f_matcher_tail retain prior arms. (13 sites.) |
| parallel.bend | f_parallel_pat/f_parallel_value/f_parallel_body retain prior left/RHS values; f_typed_let_try retains the typed-local left/type ordering and names-only mode. (4 sites.) |
| sugar.bend | f_do_annotated/f_do_value/f_do_tail/f_do_return retain monad types, earlier type/value and the bind scope; f_do_types retains completed type arguments. f_rewrite_proof/f_rewrite_motive/f_rewrite_body retain the proof, motive-only _/proof binders and scope closing. f_law_where retains the temporary refinement binder. f_group_namespace preserves the earlier completed group before an annotation failure. (10 sites.) |
| literals_arrays.bend | f_array_type/f_array_size and f_index/f_index_value preserve earlier element/type/index/value terms. (4 sites.) |

Callbacks which merely propagate an already wrapped error need no edit. Existing
constructors which bury a failed child inside All/Lam/FDo/Tuple must instead
return a wrapped outer Error on that rejection branch; otherwise an enclosing
callback would mistake the partial shell for a completed term. This canonical
error-transport invariant is itself a direct gate, not an extra whole-tree scan. A
callback must not add the same prefix twice. List accumulators are restored to
source order using the existing list conventions; new frames are allocated
only in the selected rejection branch. Allocation/visit counters must confirm
that claim rather than infer it from lazy-looking source syntax.

The module boundary retains FRawResult until selection. Keep the public
f_source_body/FResult and trusted FParsedSource contracts unchanged. Add a
private raw ordinary-source worker beside f_body_header, route ordinary
f_complete_aliases through it, and render only after resolution. Refactor the
existing f_graph_finish/f_graph_finish_module selection into a private result
which explicitly includes the selected structured prefix error (Absent if none)
and the already completed prefix book. The public wrapper preserves its current
fallback behavior. This must be one completion walk, not complete-prefix replay.

Resolve pending frames only if that prefix selected no error. Use the existing
f_alias_term once for raw pending terms, the current namespace/resolved aliases,
and the chronological family/template scope from the already completed prefix.
Never add the incomplete current definition to lookup. Preserve the current
skip-global-freshness rule on a rejected declaration stream. An earlier loaded
module or completed declaration error wins before the pending current frame.
Use existing source-interval ownership and fpe_source_render on the selected
leaf. Trusted parsed sources already contain a caller's rendered error and are
not reinterpreted by this path.

## Why this covers the concrete witnesses

In monad_do_destructure the outer local's left term is the completed FDo
expression, its RHS is p, and its continuation produces the later return error.
f_let_body currently discards the first two terms. The new Patterns frame keeps
them; the existing f_scope_do lowers the actual FDo under the enclosing lexical
scope, and the existing pattern refusal prints Result.bind with its real range.
That refusal precedes the later return error. No FDo-specific rejection or
fixture spelling is needed.

For the16 saved stage observations, a completed ungrouped prior row body uses
BeforeBody and therefore does not flatten its enclosing global match. A prior
FGroup uses BeforeTerm and does flatten. Current-row patterns are checked before
the pending row-body failure, and ordinary locals are checked before their
continuation failure. Closing-delimiter failures retain the completed group as
a term checkpoint even when f_group_finish was not reached. The same ordering
also preserves an earlier syntax/RHS error rather than replacing it with the
later pattern error.

## Stages and gates

1. Freeze a synthetic resolver experiment first, estimated80–130 lines plus
   tests. Use actual parser-produced terms and the existing scope/pattern owners;
   do not wire parser callbacks or graph completion yet. Demonstrate all five
   operations, both directions of RHS/pattern/error ordering, both grouped and
   ungrouped row cases, and lexical opening/closing for every inventory row.
   Reject the prototype if BeforeBody requires semantic duplication.
2. After review, wire module handoff and the core local/row/definition callback
   captures. The main monad2 and saved16 stage rows must become exact, with all
   current196 rows retaining previous exact/primitive agreements. Report the
   partial inventory honestly; do not present def-only coverage as complete.
3. Wire the remaining lexical/transparent callbacks only after frozen paired
   controls exist for lambda, All/Exists, telescope, law/refinement, do, rewrite,
   parallel, annotation/argument/array and module-alias boundaries. Both order
   directions and valid siblings are required. Preserve known unrelated gaps.
4. Genuine checked B1, maintained36, saved114 pattern observations, the full
   stage/group controls and complete successful lowered-book equality precede
   root full-corpus/backend checks. Record no deferred-frame allocations or
   resolver calls for Base and complete compiler source. Probe-only counters and
   deliberately failing later checkpoint sentinels must also prove that a
   selected earlier error stops demand; preserve both branches of every ordering
   control and do not time the instrumented artifact. Only root may grant
   the exclusive same-source cost gate; neither fixture time nor overlapping
   correctness runs establish a speed result.

Estimated complete production delta:250–400 lines, roughly15–25 small workers
including laws, five checkpoint-operation families (six frame tags including separate Patterns/Names), and one
private structured module-completion result. No FParsed layout change or104
parser-signature migration is planned. If actual work exceeds400 added lines,
requires broad successful-AST changes beyond FGroup, or adds a second graph walk,
stop for a fresh architectural comparison. The separate checker specialization
chronology remains a different task; this parser transport cannot fix it.
