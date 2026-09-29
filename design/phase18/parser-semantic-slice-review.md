# Phase18: independent review of the smallest parser semantic slice

Read-only review against installed Phase17 API `9b20de50`, its source
`selfhost/build/phase17/find-worker-source-01/project`, and pinned TypeScript
`b2111cf`. No compiler edits or new probes accompany this document. This is a
challenge to the proposed implementation scope, not a claim that a candidate
has passed. The cursor representation experiment is separate: its inert context
does not yet establish any lexical or semantic contract.

## Finding and recommendation

The two remaining main-inventory observations are the parse/check lanes of one
fixture, `check/monad_do_destructure.bend`. They do not by themselves justify a
complete contextual-parser migration. There is a smaller causal hypothesis:
after parsing a completed `FDo` on the left of an ordinary local assignment and
its RHS, refuse the impossible pattern before entering its continuation.

First challenge that hypothesis with a private, explicitly stopped raw-body
prototype and the boundary controls below. Reuse the existing scoper for lexical
context and lowering. Do not build another instruction language for replaying
errors. Conversely, do not describe a marker plus three edited callbacks as a
complete fix: preserving the stop through enclosing syntax and selecting earlier
errors are its principal implementation costs. If that transport starts requiring
a second semantic walker or a frame interpreter, prefer the shared contextual
parser proposed in [parser_state_options.md](parser_state_options.md).

A contextual parser has the clearer eventual ownership: resolve names and open
binders once, at the actual grammar checkpoint. Its minimum coherent semantic
slice is larger than the monad case. It includes names/calls, local and parallel
patterns, match rows, lambda/domain scopes, grouped-body completion, and do
construction. That is a separate architectural experiment, not a prerequisite
we have established for closing these two rows.

## Exact cause and saved evidence

The fixture contains:

```bend
  do Result<U32, U32>:
    p : U32 & U32 <- Done{(1, 2)}
    (a, b) = p
    return (a + b : U32)
```

Pinned `parse_term_do_stmt` treats `(a, b)` as the final expression of the do
block. The following `=` belongs to the enclosing `parse_body`: its proposed
pattern is the **whole completed bind expression**, not just the tuple.
`parse_body` parses the RHS `p`, calls `parse_patt` on that bind expression, and
rejects it before parsing the following `return`. The expected observation is:

```
Result.bind(&1, &1, U32, Pair(U32, U32), U32,
            Done{(1, 2)}, p => {(a, b) : Result<&1, &1, U32, U32>})
```

The diagnostic points at the first do statement, line 11. Installed
`f_let_value` instead calls `f_body(ts)` before any pattern validation;
`f_let_body` then propagates its Error and discards the completed left/RHS.
The reported error is therefore the orphaned `return` at line 13.

The complete saved rows are in
`selfhost/build/phase17/group-baseline-03/selected/paired.json`, and the installed
full-vector preservation is in `find-worker-frontend-01`. The group experiment
does not fix this: [its report](../../implementation/phase17/group-boundary.md)
records zero gains, 196 unchanged outcomes, and 68 retained differences. The
114-row pattern subcollection still has **43** strict differences. These are
broader evidence than the main inventory's two rows and must remain visible.

Eight saved stage fixtures have both lanes, with 8/16 exact observations:

| Saved stage fixture | Required checkpoint order | Current result |
| --- | --- | --- |
| `body-before-later-pattern` | Later row's pattern eligibility precedes flattening an earlier ungrouped row body | Different |
| `body-before-later-syntax` | Later row syntax precedes flattening an earlier ungrouped body | Exact |
| `group-before-later-pattern` | Completed parenthesized body flattens before later pattern | Exact |
| `group-before-later-syntax` | Completed parenthesized body flattens before later syntax | Different |
| `prior-local-pattern-before-later-syntax` | Earlier local pattern precedes later row syntax | Different |
| `prior-row-pattern-before-body-syntax` | Row pattern precedes its own body syntax | Different |
| `completed-body-flattens` | Completed declaration body reaches flattening | Exact |
| `completed-group-flattens` | Completed group reaches flattening | Exact |

Their sources are the frozen Phase16 `rejected-stage-controls-01/fixtures`
referenced by the Phase17 selection. A broad semantic change must retain all
four existing exact cases; a narrow FDo change need not claim the other four.

## Actual owner order

| Owner | Pinned TypeScript | Installed Bend |
| --- | --- | --- |
| Lambda | `parse_bind(left)`, open binder, `parse_block`, close | `f_rhs` parses the body before `f_binary`/`f_lambda_valid`; dotted eligibility waits for scope |
| Sequential local | Parse left, optional type, all RHS; validate pattern; open; parse continuation; close | `f_let_value` parses continuation; `f_scope_local` validates later |
| Parallel/typed local | Parse all left/type/RHS terms outside new bindings; names-only eligibility plus ordinary pattern checks; open all | `f_parallel_values` enters body first; `f_scope_parallel` supplies later checks |
| Match | Parse heads; row arity; validate/open row patterns; parse row body; close; next row; flatten only at enclosing body/term boundary | Arity is early; `f_case_pats` parses body before eligibility; `f_scope_rows` and flattening happen after parsing |
| Do | Parse header quantities, statement type/value; validate/open its binder; recurse; close; construct bind/pure/Ann | Parser builds `FDo`; `f_scope_do` later resolves header/type/value/body and supplies quantities |
| All/Exists | Domain completes outside new binding; open binder for codomain only | Raw constructor first; `f_scope_base` later opens it |
| Group | Complete body; flatten; optional annotation; closing delimiter | `f_group` reads annotation/delimiter before later scope/flatten; installed tree loses body/group boundary |
| Declaration | Open telescope as parsed; finish/flatten current body before next declaration | Raw `Body{Params,body}`; module completion later scopes completed prefix before choosing a later parser error |

An earlier source position alone does not determine priority. In particular,
the first two stage cases prohibit eagerly flattening every completed row.

## Narrow FDo checkpoint: viable invariant, nontrivial transport

Only propose a syntactic predicate for **completed FDo**, not a general blacklist
of `Local`, `Parallel`, `Match`, or arbitrary computed forms. The three FDo
lowerings are Ann, pure App, and bind App; a pure assignment continuation can
contain a Let. None is a Var, constructor, or literal pattern. This fact allows
the parser to stop without knowing constructor membership. It does not allow it
to skip earlier expression errors or invent the observed rendering.

At `f_let_value`, first preserve an actual RHS syntax failure. After a successful
RHS, construct the ordinary raw `Local{lhs,rhs,neverEnteredBody}` and stop before
calling `f_body`. A typed internal stop marker may identify the unentered
continuation. It must never be interpreted as a successful body, emitted term,
empty proof, or ordinary user Error. The rejection owner remains the existing
pattern validator after the relevant earlier prefixes have completed.

The normal scope walk can supply lexical context **if the enclosing raw shells
are retained**. Its existing FDo lowering handles the monad header quantities,
lambda binding, and exact ranges. A direct `f_scope(lhs, Nil{}, book)` is not a
general solution: outer binders, imported aliases, namespace qualification, and
shadowing change the observed term. Do not capture a formatted string early or
guess binders from source text.

The required protocol is explicit:

1. The parser reports a stopped partial body separately from success and ordinary
   syntax failure. Stop is O(1) to observe; repeatedly scanning whole growing
   subtrees for the marker is not an acceptable normal-path shortcut.
2. Enclosing callbacks preserve necessary lexical shells and do not consume
   further tokens after the stop. They may still select a syntactic checkpoint
   that upstream necessarily performed before entering the stopped child.
3. Declaration completion retains the completed declaration prefix separately
   from the unfinished current definition. Complete the prior prefix first;
   an error there wins. The current partial definition is diagnostic input,
   never another completed definition or loader cache entry.
4. Scope and select the stopped body under that prefix, its original parameters,
   resolved aliases and namespace. Earlier completed expression errors win;
   otherwise the impossible outer pattern is the selected error. The body
   marker is never visited as an expression.
5. If this process does not select a refusal, fail the internal contract. It
   must not publish a successful truncated book or resume after skipped text.

The existing raw Local/scoper cannot implement step 4 unchanged.
`f_scope_local` validates patterns before scoping the RHS; TS parses the RHS
before pattern conversion. A stopped-path adapter must first complete its
earlier left/RHS checkpoints and then invoke the same pattern validator. Also,
`f_scope_base(Body)` immediately invokes `ff_flat`; an unfinished enclosing Match
must not be flattened ahead of the stopped row's parse-time failure. A possible
shared factoring is to select scope/pattern errors before body flattening while
retaining explicit completed-group boundaries. This must be tested against the
saved stage pairs, rather than inferred from a preorder Error scan.

Parenthesized `Local`/`Parallel`/`Match` forms are excluded from the simple
predicate because their completion can itself fail before outer eligibility.
Trusted raw zero-head Match can also lower directly to its row body; current
surface zero-head mismatches are not evidence of a legal upstream form. Never
turn those existing cases into a claimed impossible-pattern proof by tag alone.

### Unavoidable callback audit for the narrow marker

The producer and declaration sink are only the endpoints. These are actual owner
functions requiring an audit; not every listed function necessarily changes:

| Area | Functions / hazard |
| --- | --- |
| Producer and local shells | `f_let_value`, `f_let_body`, `f_statement`, `f_typed_let_try`, `f_parallel_values`, `f_parallel_body`: no later body parsing; retain enclosing bindings |
| Lambda/operator/group | `f_rhs`, `f_binary`, `f_grow`, `f_grow_base`, `f_group`, `f_group_namespace`, `f_expect`: do not replace stop with missing delimiter or parse another operand |
| Arguments and compound atoms | `f_args`, `f_arg_next`, `f_grow_args`, tuple/brace/array/index callbacks: retain prior siblings without reading later ones |
| Match rows | `f_case_pats`, `f_case_body`, `f_match_cases`: retain prior rows and current binders; do not visit later rows or flatten unfinished Match |
| Do/domain/rewrite wrappers | `f_do_value`, `f_do_tail`, `f_all_domain`, `f_all_body`, rewrite motive/body callbacks: retain scopes; do not enter a later child |
| Declaration/module boundary | `f_def_body`, `f_tops`, private body completion, `f_complete_parsed`, `f_graph_finish`: retain prior-declaration priority and typed stopped state |

This is at least 27 named workers plus their compound-atom/rewrite callbacks,
not a measured patch size. Prior census has 70 FParsed destructures; inspect all
of them for propagation. A stopped cursor flag or a new internal result variant
can avoid subtree scans, but must be counted as representation cost. Keeping
marker and status must have a single invariant, not two competing error owners.
Budget a prototype at roughly 120–220 net lines with reused scope workers;
this is an uncertain estimate. Stop if it approaches the old 250–400-line replay
proposal without removing an owner. No net simplification or speed gain is known.

## Contextual alternative: minimum coherent semantic ownership

If the marker trial fails that boundary, attach immutable lexical state to the
existing grammar's input (cursor representation only if its cost gate passes).
Use the current loaded prior declarations/namespace/aliases from FParseScope,
one lexical stack, and an explicit fresh counter. Scope close restores the outer
stack while retaining consumed cursor and updated fresh count. Token coordinates
are not a fresh-name counter. Existing `ff_flat` has an explicit next result and
can share allocation order; do not separately estimate it with `fc_start` after
already performing the allocations.

The important name distinction is upstream's unbound ordinary Var with a global
Ref fallback. Preserve it explicitly, for example with one temporary `FName`
carrying the written spelling and canonical fallback. Bound names are Var;
unbound dotted names are Ref. Ordinary calls consume an unbound fallback before
parsing arguments, but `bound()` remains a Var when there are no arguments.
A new binder always opens a fresh identity, even if its spelling resolves to an
outer binder. Do not eagerly collapse a bare name to ADT/Ref and then try to infer
pattern eligibility from that lowered node.

Reuse `f_env`, alias/qualification name selection, `f_valid_patterns_mode`,
`f_pattern_env`, `f_adt`, literal constructors and `ff_flat`. Extract shallow
constructors from `f_scope_do_args`, lambda construction and call completion:
these currently recurse through raw children and are not shallow as written.
Do not call a whole `f_scope` walk on every completed successful prefix. Also,
do not use `f_scope_app_span`'s beta contraction to classify patterns: upstream
parse_patt sees an App even when later lowering could simplify it.

Move the checkpoints in the owner-order table into parser control flow, before
recursive continuation calls. Scope row bodies but retain them as Body until
their actual boundary; groups and lambda blocks flatten before returning to a
parent term. Distinguish this parse/scope representation from final core lowering.
The same parser grammar can have explicit raw and contextual entry modes; that
is not permission to retain two copies of its grammar or name-resolution rules.

Begin privately with declaration-body parsing supplied an authoritative prior
book and already opened telescope. Then migrate telescope/law/refinement/rewrite
and other expression entries before advertising a complete module parser. An
unimplemented private entry must be explicitly unsupported, never silently fall
back to raw parsing under a scoped result label. This slice has no defensible
net-LOC reduction estimate until compatibility owners can actually be removed.

## Public raw versus scoped boundary

`f_parse` and `f_parse_indexed` return raw FResult books. `FParsedSource` is a
trusted raw source input. Preserve those meanings and their raw structural
controls. This is more than preserving constructor field names.

There is an additional visible boundary: exported `f_complete_source` returns
`FCompletion{graph,parsed}`; `parsed` is the raw body result. The host stores it
as `record.parsed` and can reuse it as supplied parsed input. Returning a scoped
book there under loader ABI1 would silently change its stage and can double
scope/freshen it. This affects both proposed alternatives if stopped partial
results cross that boundary.

For the experiment use a private, explicitly staged completion/result entry.
Before installation choose a documented new loader capability and route it
explicitly, or keep a separate legacy raw compatibility entry. Do not parse a
normal successful body twice merely to populate the old raw field. Do not infer
raw/scoped state from term tags. Existing graph discovery, dependency order,
seed/source identity and trusted FParsedSource semantics remain separate owners.
The private experiment must preserve their supplied-source controls before any
public stage migration. Keeping legacy raw compatibility may retain much of the
old scoper; report that cost rather than counting it as deleted.

## Decisive controls before implementation expands

Freeze exact fixture text/reference observations before testing; the new variants
below are proposals, not measured expected strings. Both parse/check lanes matter.

1. Original monad plus a variant replacing RHS `p` with `)`: the original must
   select the invalid completed bind pattern; malformed RHS must win before it.
   Replace only the later `return` by another invalid token to prove it is never
   entered after an impossible pattern, rather than specially suppressing return.
2. The stopped assignment nested inside a group/call argument, lambda, earlier
   local and match row. Include missing closing `)` and malformed later argument.
   These discriminate real stop transport from the three-function shortcut.
3. Prior ungrouped row with an invalid global scrutinee, then the stopped monad;
   contrast its parenthesized version. Later pattern failure can precede deferred
   flattening, while a completed group's earlier error must win. Also retain
   `prior-row-pattern-before-body-syntax` and an earlier declaration failure.
4. Imported monad under an alias, in a nonroot module; outer parameter with a
   dotted spelling shadowing that alias; and the same spelling unbound. Reuse
   frozen `module-alias-frame`, `alias-shadow-frame`, `alias-bound` and
   `alias-unbound` fixtures as controls. No spelling replacement in diagnostics.
5. A valid typed do bind and pure typed do local with a continuation referencing
   the bound name, plus an expression after leaving its group. Check binder scope
   closes correctly and valid do syntax is not treated as an assignment pattern.
6. For contextual names, paired `name => bad_body` / `name() => bad_body`, bound
   and unbound dotted variants, and a computed application that beta-reduces to a
   name. Binder eligibility must occur before the body without conflating syntax
   classification with lowered value.

The cheap screen is approximately 12–18 fixture graphs plus saved 16 stage rows
and relevant alias/pattern cases. Then require the unchanged 196-row collection
with explicit retained differences, raw compatibility and complete lowered-book
equality on accepted controls, Base/full-source checks, and root integration
gates. The main two rows becoming exact would be a useful bounded result, not
closure of the broader 43 pattern differences or proof of full conformance.
