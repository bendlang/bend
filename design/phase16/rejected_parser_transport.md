# Rejected-path lexical checkpoint transport

Prospective API/prototype proposal, not an implemented compiler change. Parent
for the investigation is wave9, which already completes earlier declarations
before selecting a later parser failure. The remaining maintained discrepancy
is `check/monad_do_destructure.bend`; the independent checkpoint suite has 30
chronology observations across 15 fixtures. Fixing only that declaration body
would not cover the actual language boundary.

## Representation and selection contract

Keep FParsed and the successful raw AST unchanged. On a parser callback's
existing Error branch only, attach an explicit `ParseDeferred` payload to the
Error. It carries the original structured leaf error and an outer-to-inner
program of lexical/checkpoint frames. This is compiler metadata in Error
children, never data hidden in ids, quantities, origins or diagnostic text.
The outer tag stays Error so existing failure propagation continues to work.
The renderer must receive a fully selected leaf; it must never render or walk
unconsumed frames. Legacy context-free parse entry points keep their current
fallback leaf if authoritative module context is unavailable.

Concrete helper interface (all arguments are immutable):

```
f_reject_wrap(error: KTerm, frame: KTerm) -> KTerm
f_reject_pending(error: KTerm) -> Bool
f_reject_resolve(error: KTerm, env: List<KTerm>, book: List<KDef>) -> KTerm
f_reject_before(prefix: List<KTerm>, error: KTerm, env, book) -> KTerm
f_reject_patterns(patterns: List<KTerm>, values: List<KTerm>,
                  namesOnly: Bool, continuation: KTerm, env, book) -> KTerm
```

`f_reject_wrap` preserves the original Error payload and stores the new frame
outside its existing frame program. It is called only when its child already
failed. The resolver interprets explicit frame constructors; it does not recurse
through arbitrary incomplete ASTs. Completed expression prefixes delegate to
existing f_scope/fpe_term. Pattern conversion/eligibility delegates to
f_patterns/f_valid_patterns_mode, and scope extension delegates to f_pattern_env
or the existing binder constructors. Extract a tiny shared binder-construction
helper if necessary, rather than implement a second lexical lookup or parser.

For unsupported computed patterns, observed syntax must be scoped in the actual
lexical environment before rendering. The existing validator currently renders
its fallback with `f_scope(p, Nil{}, book)`; the prototype must either pass env
through that existing fallback worker or give it the already scoped rejected
term. It may not replace alias names with text substitutions. Every existing
ordinary-pattern check remains authoritative.

The basic chronological rule is: complete earlier expression prefixes; validate
the current pattern; open its new bindings; then select the continuation failure.
An earlier Error discovered in a left/RHS expression wins. A case body's syntax
failure wins over flattening of the enclosing unfinished match. These are
separate parser stages, not source-position sorting.

## Complete enclosing-frame inventory

| Frame | Capture point(s) | Resolver operation / existing owner |
| --- | --- | --- |
| Definition body and result type | f_def_body, f_def_type, f_def | Open the actual prior telescope parameters with f_vars; resolve a body/type failure without adding the unfinished definition to the lookup book. |
| Lambda | f_binary before it returns a failed RHS | Validate the actual left binder, including FLambda alias eligibility and operator cursor; open the shared lambda variable; then resolve the body. A malformed binder precedes body parsing. |
| All / Exists | f_all_domain, f_all_body | Complete domain outside the new binding; open the written binder only for the body. Preserve Exists lowering metadata for observed computed terms. |
| Sequential/erased local | f_let_value, f_let_body, erased-local wrapper | Left expression, RHS, pattern eligibility, then continuation under f_pattern_env; retain actual terms, not just their names. |
| Parallel / typed local | f_parallel_values/body, f_typed_let_try | Retain all earlier left/RHS/type expressions in parse order, run existing names-only eligibility, then open all binders. Do not infer mode from a later error message. |
| Match row | f_match_head, f_case_pat, f_case_body | Complete prior head/pattern expression prefixes and validate row patterns; open fields for the row body. Prior completed rows retain their parse checkpoints. Do not call enclosing match flatten while a row body is incomplete. |
| Do bind / do local / return | f_do_annotated, f_do_value, f_do_tail, f_do_return | Preserve monad, type, value and binder metadata; resolve type/value before opening a binder. Return has no new binder. Completed sugar uses existing f_scope_do when needed as a pattern's observed term. |
| Rewrite motive/body | f_rewrite_proof/motive/body | The motive alone sees `_` and optional proof-name binders. Close both before entering the body; preserve earlier proof/motive parse checkpoints. |
| Telescope cell | f_tele_type and enclosing def/type/constructor callers | Open accumulated earlier cells in source order for the failing current cell's type. Never open the current cell before its type completes. |
| Law clause / refinement | f_law_type/end, f_law_where | Open prior clauses; where adds its temporary binder only around the predicate. Later clauses see the normal declaration binder. |
| Transparent prefix | group, annotation, call arguments, constructor/array/list elements and delimiter continuations | Carry a failure unchanged if no earlier complete prefix exists; otherwise preserve that prefix's expression checks. A completed parenthesized body may flatten before a later closing-delimiter error. |
| Module | f_complete_source, private raw body worker | Resolve under successfully completed prior declarations, current namespace and resolved aliases, after earlier declarations have had their existing frontend checks. |

These are semantic frame families, not necessarily twelve new IR constructors.
Use Bind, Before, Pattern and Row checkpoint forms with explicit children where
one operation actually suffices. Do not force two different stage orders into a
flag merely to reduce the count. The saved transitive caller census is 104
functions / 64 FParsed destructures in the principal parser files; that is an
inspection upper bound, not a claim that all need editing.

## Module handoff without rendered-string inference

Keep public f_source_body returning FResult and trusted FParsedSource behavior
unchanged. Add a private raw body worker for ordinary FSource that returns
FRawResult until failure selection. The context owner independently confirmed:
completed-prefix frontend errors must win, and the unfinished current definition
must not enter the prior book.

The completion boundary needs an explicit structured outcome identifying whether
the completed prefix selected an error. Do not compare returned error strings to
the fallback string. Factor the existing f_graph_finish final selection into a
small result such as:

```
FCompletedPrefix { graph: FGraph, localBook: List<KDef>, rejected: Bool }
```

Its existing public wrapper preserves today's fallback and freshness behavior.
Only a raw parse failure with deferred frames asks the private worker for this
outcome. If `rejected`, preserve its selected error. Otherwise apply existing
module alias/freshening preparation to the frame program, resolve it against the
successful prefix and render the selected leaf with the owned source interval.
Do not rerun graph discovery, parse a body twice, flatten an unfinished match or
alter the existing skip-freshness rule for an incomplete declaration stream.
The exact factoring of graph finish is part of the reviewed prototype: if this
needs a second graph walk or duplicated module resolution, stop and revise it.

## Prototype scope and gates

First demonstrate the frame resolver with synthetic structured programs for
every row above and compare chosen errors, lexical spelling, binder identity and
range. Then wire rejection-only parser callbacks for all frame families into an
isolated source, preserving the existing success path. This is a bounded
architecture experiment, not a promised small patch: the cost is primarily the
complete callback inventory and precedence controls.

Freeze both order directions for every boundary: malformed earlier RHS versus
bad pattern, bad pattern versus later continuation, bad row body versus global
match head, nested completed match versus delimiter, invalid lambda binder
versus body, dependent binder domain versus body, shadowed alias versus global
alias, each telescope/refinement/rewrite scope opening and closing, and do types,
values and continuation. Retain all current82 ordinary-call observations plus
the marked-quantity controls. Reject a def-only solution even if the maintained
monad fixture turns exact.

Require genuine checked B1, focused36, exact oracle controls with no lost match,
root full-corpus and backend gates, then identical-source cost measurement.
Successful parse books must be structurally identical to the parent, and direct
counters must show no deferred-frame allocations or replay on successful input.
If frame semantics begin to reimplement parse_body or require broad changes to
successful nodes, compare the single contextual-parser alternative before
continuing. No chronology implementation has begun under this proposal.
