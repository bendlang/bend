# Move the actual body pattern checkpoint next

Proposal for root review; no Stage3 source is implemented or authorized by this
file alone. Parent is the frozen `context-grammar-source-02/project`, checked as
`context-grammar-build-02`, selected API `780ed907`. Its actual names/calls route
passes32 strict supported observations,14 Unsupported controls, Stage1's27 and
the public/raw194. This proposal advances into the existing body grammar rather
than adding another primitive-state protocol.

## Smallest decisive implementation

The next subwave should implement ordinary sequential locals under the shared
context. Its first witness is an actual body such as `f(x) = y; return z`.
Pinned `parse_body` parses the left term and RHS, rejects the computed pattern,
and never parses the later return. The current deferred raw route selects the
return instead. Reverse it with `f(x) = return z`: the RHS syntax failure must
win. Add a valid `x = y; f(x)` sibling, shadowing, empty bound/unbound calls,
constructor-spelled binders, and two successive locals. These are actual body
grammar observations, not calls to a stand-alone pattern simulation.

Use a private checked root `f_context_body_stage(input,seed)` with a distinct
Body-stage result: completed scoped Body, selected Error, or Unsupported. It
calls existing `f_body_context` with an explicit indentation argument; it never
calls legacy `f_scope`. It does not advertise Core or enter the loader. Raw
entry inputs and seeded contextual rest follow Stage1/2. On successful local
completion, restore the enclosing environment while retaining fresh IDs and
cursor; on failure, retain the exact failure environment just as the pinned
parser does when its exception skips `parse_close`.

Exact existing owners for the first patch:

| Owner | Bounded change |
| --- | --- |
| `f_grow_args` | In contextual mode build the App spine using existing `f_app_span`; empty calls return their already selected head. Raw mode keeps Call. This makes bound empty calls retain Var eligibility and unbound empty calls retain Ref in the actual term, not a probe projection. |
| `f_context_grow`, `f_context_term_done` | Permit assignment to terminate an expression for its body owner. Keep the earlier names-only entry's unsupported-body contract in its result boundary. Do not add an implicit second scope mode. |
| `f_body_at`, `f_statement` | Check stop results first. Contextual mode uses the same expression/assignment grammar; reject as Unsupported before the currently unmigrated match, erased, typed and parallel owners. |
| `f_let_value` | After a successful RHS, run the contextual pattern checkpoint and open fresh binders before calling the existing `f_body` continuation. A bad RHS wins before pattern validation. |
| `f_let_body` plus a contextual completion callback | Preserve Error/Unsupported, construct the same Local shell with the opened pattern, restore the saved outer env on success. No abandoned Local shell, replay or diagnostic-text coupling. |
| `f_valid_pattern` | Factor the shallow Var eligibility/constructor diagnostic into a shared helper taking the written node and canonical constructor identity. Factor the computed-pattern diagnostic's already-materialized observation. Keep existing raw behavior and messages. |
| `ffw_walk` | One explicit FName leaf consumes its already chosen Ref fallback. No name resolution or ADT guessing. This is the existing freshening traversal, not a new contextual tree walk. |

The contextual pattern checkpoint takes the actual completed term and contextual
input and returns FParsed with the opened pattern and updated input. FName exposes
its Var syntax child; ordinary bound Var remains Var. Before opening a variable,
use the same canonical name selection that `parse_patt` itself performs, then
the shared constructor-name check. This is a **new pattern-stage** resolution:
even a name which skipped alias resolution because it was bound during
`parse_var` can encounter the pinned `parse_patt` canonical check here. Do not
reuse only the earlier value fallback and silently change that ordering.

For a nonpattern App/Ref, use the shared computed-pattern error constructor.
Its observation is produced by the existing freshener with the new FName leaf,
then the existing printer. It does not run `f_scope` on an already contextual
prefix. This corresponds to pinned `term_lower(term_higher(t),0)` for the narrow
supported term domain. Prove bound/free identities and ranges directly; if this
needs another generic semantic lowering traversal, stop for review.

The first subwave supports variable patterns and rejects computed patterns;
constructor/literal syntax remains explicitly unsupported until the shared
recursive pattern extension below. No lambda/do/row success may slip through
as an unscoped subtree. Estimated first patch:90–140 physical Bend lines across
contextual/parser/declarations/validate/fresh_work, roughly8–12 small workers
including the new private entry, plus one host export line. This is an estimate,
not a cap to meet by compressed formatting. Review actual delta above150 lines.
There is no deletion claim while raw APIs remain supported.

Freeze the predecessor's raw body result and pinned `parse_body` result on each
witness before source. Verify the complete Body shape, bindings, fresh counter,
lexical stack, cursor and selected diagnostic. For accepted bodies the reference
Body projection is a stage comparison; any Core comparison is a separate later
`body_flatten` observation. Preserve Stage2's46, Stage1's27, maintained36 and
raw194. Unsupported results on required controls fail the subwave.

## Then reach the saved group and monad frontier

Do not stop after the ordinary-local proof. The following extensions belong to
the same authoritative parser route, with a review after each measured patch.
Their intended endpoint is the original saved16 stage controls and monad2,
without changing the production loader while the body contract is incomplete.

1. **Constructor patterns and row checkpoints.** Extend the same contextual
   pattern owner left-to-right through Ctr children and literal stepping. Factor
   the existing constructor-head existence/arity check out of
   `f_valid_ctor_pattern`; both legacy validation and the contextual owner call
   that one rule. There is no second copy of constructor diagnostics or arity
   logic. The contextual recursion combines validation and binder opening, so
   an earlier refusal prevents later fresh IDs or canonical lookups. At
   `f_case_pats`, check arity, then open patterns, then enter `f_body_context`;
   `f_case_body` closes the row before its sibling. Row bodies remain Body until
   their actual enclosing flatten boundary. Do not call `ff_flat` on each row.
2. **Actual group/block boundary.** In `f_group`, preserve the tuple exception:
   a comma forms a tuple only when the completed body is neither Local nor Match.
   Otherwise run existing `ff_flat(body,Nil{},next)` before any annotation or
   closing-delimiter demand, and propagate its returned next through the cursor.
   A malformed later `)` must not suppress an earlier completed group's flatten
   error. An ungrouped previous row must still defer that same flatten error.
   Contextual grouping needs no FGroup raw marker: it still owns this cursor.
   Lambda must open its binder before entering the existing body grammar and
   flatten its completed block once. Keep domain-before-binder order for All.
3. **Do and the monad witness.** Allow the existing do grammar only after its
   header/name/family quantity construction and statement callbacks have the
   same contextual stop/open/close contract. Factor `f_scope_do_args` into a
   shared shallow builder receiving already completed children; the raw scoper
   supplies recursively scoped children, the contextual parser supplies its
   already scoped children. Reuse quantity fill, call application and `f_do_bind_types`.
   In `f_do_value`, type and value complete before binder opening and recursive
   tail parsing. `f_do_return`/`f_do_tail` must propagate stops before wrapping.
   Support tuple/constructor/literal and `&` type syntax needed by the actual
   monad fixture; do not substitute simpler fixture text and claim monad fixed.

For the saved monad, the do grammar legitimately ends at `(a,b)`. Its completed
term is the real Result.bind application with a lambda body annotated as Result.
The **enclosing ordinary local** then parses RHS `p`, invokes the same general
pattern checkpoint, rejects that application, and never reaches the orphaned
return. This is neither a do-pattern blacklist nor a special diagnostic case.
The saved grouped/ungrouped controls are decided by the row and group boundaries
above, not by origins or source scanning. Same-body instance specialization stays
a separate checker task and is not affected by these parser checkpoints.

Before extension1, freeze a feature census for all saved16 and114 observations
against the new private body entry. Before extension3, bind the exact monad body
slice, full original source interval, prior Base/header book and actual pinned
header allocation events. Required fixtures may not be counted as passing when
the entry returns Unsupported. Include RHS-first failures, later syntax/close
failures, aliases/namespaces, enclosing lambda/row scopes, typed and parallel
siblings and raw compatibility. Parallel/typed locals reuse the same checkpoint
owner in names-only mode after all RHS terms; successful annotation rewind must
preserve the attempted fresh counter.

The remaining row/group/do work cannot honestly be priced as one tiny hook.
Current read-only estimate is another170–280 lines, subject to actual control
coverage and shared-helper extraction. The accumulated private route also still
contains Stage1's fixed test protocol and Stage2's temporary feature guards.
Record those separately from retained semantic state/owners; do not claim their
eventual removal as a current reduction. Root should reassess after the first
actual local checkpoint if the shared traversal cannot stay smaller and clearer
than the rejected failure-program alternative. No second body interpreter,
repeated successful-prefix scope walk, inferred fresh IDs or raw-loader ABI
change is an acceptable shortcut.
