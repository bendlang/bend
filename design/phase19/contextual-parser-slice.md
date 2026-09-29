# Private contextual parser slice

Prospective design; no semantic compiler edits or new semantic probes yet.
Parent is the checked Phase18 `cursor-source-02/project`, built by
`cursor-build-01`, selected API `5d19edf5`. Installed Phase17 API `9b20de50` and
all public loader/parser contracts remain the compatibility baseline. Reference
is unchanged TypeScript `b2111cf`. Root must review this plan before source work.

The [cursor ablation](../../implementation/phase18/cursor-representation.md)
preserves 196 outcomes and 194 direct controls. Its separate cost screen is
+0.926% process / +1.062% request / +0.740% peak RSS. This clears only the inert
transport experiment. Populating lexical state, allocating fresh identities,
preserving name alternatives and moving checkpoints are unmeasured changes.

## Question and bounded decision

Can the existing grammar resolve names and open scopes at its real recursive
checkpoints, without a second failure interpreter or repeated `f_scope` of
completed prefixes? The minimum coherent private slice includes names/calls,
sequential and parallel locals, match rows, lambda, All/Exists, grouped bodies,
and do construction. It must fix the monad checkpoint for the right reason and
preserve both directions of the saved row/group error-order controls.

This is more work than inserting one FDo predicate. The independent
[scope review](../phase18/parser-semantic-slice-review.md) estimates that the
apparently narrow stopped-body alternative still needs 27+ callback audits,
partial scope/flatten machinery and roughly 120–220 lines. The earlier
five-operation failure program estimated 250–400 lines. Neither estimate is a
measured patch, and neither establishes a simpler long-term owner. This trial
instead tests whether the grammar itself can own the ordering once.

Do not change installed source, loader ABI, semantic checking, specialization,
or emitted user-program optimization in this experiment. In particular, it does
not address same-body instance chronology. Do not promote after only monad's two
main-inventory rows improve.

## Explicit private interface and artifact

Add one experimental bootstrap root, `f_context_body`, to the isolated candidate's
export list. This is the sole intended host-tool delta: no adapter behavior,
cache policy, ordinary entry selection or runtime patch. The checked bootstrap
must include the root; an unreachable unexported Bend definition is insufficient.
Record the complete bootstrap host delta and resulting artifact identity.

Proposed arity-two entry:

```text
f_context_body(input: FInput, seed: FContextSeed) -> FContextResult

FContextSeed {
  scope: FParseScope,             # authoritative prior declarations/index/ns/aliases
  parameters: List<KTerm>,        # opened declaration binders, in telescope order
  next: U32,                     # exact next parser identity after the header
  outer: U32                     # enclosing body indentation
}

FCursorContext                 # retain existing raw constructor unchanged
  | FCursorContext{serial:U32}
  | FContextual{scope:FParseScope, env:List<KTerm>, next:U32}

FContextResult
  | FContextCore{term:KTerm, rest:FInput, next:U32}
  | FContextError{error:KTerm, rest:FInput, next:U32}
  | FContextUnsupported{feature:String, begin:U32, end:U32, rest:FInput, next:U32}
```

`FContextCore` means a completed declaration body, flattened with the supplied
parameter binders and converted to ordinary core terms; it is neither a raw
FResult book nor a partially scoped body. `next` is the parser allocation counter,
not the later global core-renaming counter. The result cursor restores the entry
lexical stack while preserving all consumed tokens and the updated counter.
No internal contextual name/unsupported marker may escape a Core result.

The seed is an explicit test boundary. Its book must contain completed prior
declarations and any already established current declaration **header** required
by recursive references, never an unfinished body or later definition. Its
parameter IDs and next counter are supplied exactly, not inferred from source
coordinates. The first harness freezes each target's body cursor and seed in a
manifest. It obtains dependencies/prior declarations through the unchanged
loader, and verifies the matching pinned header allocation events independently.
It must not turn a failing prefix into an empty successful book.

The input contains tokens from the original indexed full source at that explicit
body boundary. Generic token slicing in a test harness is allowed; the compiler
must not detect fixture text, source paths or expected messages. Preserve the
original immutable source interval for error rendering. Tests record the returned
cursor, not just a final diagnostic.

Production `f_parse`, `f_parse_indexed`, `f_load_graph`, `f_complete_source` and
their callers continue to construct the raw context. Their output structures
**and stages** remain unchanged. Do not invoke the private route conditionally
from a production path to make it reachable. Probe suffixes may expose existing
checked functions, but cannot supply handwritten implementations of the parser.

## One grammar, explicit context, one failure result

Reuse `f_body`, `f_expr`, token movement and their existing callbacks. Add small
mode-sensitive semantic hooks at owner boundaries; do not clone the grammar.
Raw mode keeps the old output and old deferred scoper. Contextual mode performs
the named checkpoints below and never feeds its completed prefixes back through
the recursive scoper. The FCursorContext variant inside FInput determines mode; no term-tag
guessing, source-position heuristic or global mutable parser state selects it.

The context shares the immutable book/index/ns/aliases. Entering a binder saves
only the outer lexical list; leaving restores that list while retaining the
returned cursor and `next`. Fresh IDs increment for **every** upstream allocation:
unbound ordinary names, new binders including `_`, anonymous arrows and generated
flattening fields. Looking up an already bound name does not allocate an ID.
`_` consumes an ID but does not enter ordinary lookup. `ff_flat`'s explicit
returned next value is authoritative at a flattening boundary. Do not call
`fc_start` afterward to estimate allocations already performed.

Speculative typed-let parsing is a special cursor operation: pinned `parse_body`
rewinds `p.pos` when a parsed annotation is not followed by assignment, but does
not rewind `p.frs`. Add a shared private rewind helper that takes **tokens from
the saved input and context from the attempted parse**. Do not return the entire
old FInput and accidentally reuse fresh IDs. Test this independently.

`FParsed{term,rest}` remains the internal grammar result. Its Error term remains
the single selected failure, with the authoritative context in rest. A private
`FUnsupported` term may carry a feature/range until the entry converts it into
the distinct Unsupported result; it is not an upstream diagnostic or accepted
term. A shared stop predicate handles Error/Unsupported without scanning a tree.
Audit all FParsed callbacks for propagation: after either result, no later child,
argument, row, continuation or delimiter can replace it. Do not introduce a
second sticky status in the context that competes with this result.

Existing raw callbacks sometimes construct a parent around an Error or parse a
later child first. Contextual hooks must test the immediate result before the
next recursive call. This is a real part of the work, not “free” cursor plumbing.
If ensuring this requires a second body interpreter, stop and return the design
for review.

## Names retain syntax until their owner consumes it

Pinned `parse_var` distinguishes a bound Var, an unbound ordinary Var with a
canonical Ref fallback, and an unbound dotted Ref. Lambda/pattern eligibility
uses that syntactic distinction. New binders always receive a fresh identity,
even when the spelling resolves to an outer binder. A bare ordinary name must
not become an ADT/Ref before eligibility is decided.

Use one private raw tag `FName` with explicit children:

```text
FName(writtenName, children=[syntaxView, valueFallback], sourceRange)
```

The syntax view is the actual variable/reference alternative, including the
unbound ordinary variable's allocated ID. The fallback is exactly the canonical
Ref selected by name resolution, never an eagerly materialized ADT or a
value-only error. Bound names can remain ordinary Var terms. Marked syntax uses
the existing FUnboundVar sentinel instead of pretending U32 can store upstream's
negative identity. This avoids storing an unrelated stage bit in quantity,
removed or source-range fields. All FName shape access goes through small named helpers.

- Resolve lexical lookup before alias resolution or ambiguity errors. Reuse
  `f_env` and factor the existing canonical-name selector rather than redoing an
  alias walk with different precedence. Bound `M.f` must shadow an import alias.
- On an ordinary call, consume an unbound ordinary-name fallback **before**
  parsing arguments; use that Ref for offload eligibility and template slots.
  Bound `x()` remains Var when its argument list is empty. Unbound `x()` becomes
  Ref and cannot become a binder again. Repeated empty calls preserve that fact.
- Pattern and lambda owners read the syntax view. Qualified unbound Ref is not
  a binder; a qualified bound Var can introduce a new shadowing binder. Constructor
  membership uses canonical resolution while diagnostics retain written spelling.
- Marked names reuse the established `f_scope_marked` semantics at a shallow
  boundary: retain the distinction between datatype quantities and the unbound
  marked-variable sentinel. Do not set all Var quantities from the lexical stack.
- Do not beta-contract an App before pattern eligibility; upstream `parse_patt`
  sees the App even if later normalization would expose a name.

Constructor arguments can still be patterns, so do not recursively erase FName
while assembling Ctr children. Convert at an actual pattern or value boundary.
At successful declaration completion, consume remaining value fallbacks in the
existing core freshening traversal, through an explicit FName leaf case. That
case consumes already chosen fallback data; it does not resolve names again.
Raw production input never contains FName. On rejected computed patterns, use
the same materialization rule before printing, preserving enclosing binder IDs
and source ranges. If a separate general scope walk is needed merely to print
an already contextual term, stop: semantic ownership has not actually moved.

This precise representation is part of the first review gate. Tests must challenge
zero-arity datatype fallbacks, bare nonzero-arity families, constructor names,
unbound ordinary names, dotted aliases, offload heads and marked names before
the larger body migration depends on it.

## Exact checkpoint owners

| Area | Existing functions to change/factor | Contextual order |
| --- | --- | --- |
| Atom/name | `f_atom_base`, `f_atom_name`, constructor completion, `f_bang` | Perform lexical/name selection once; retain syntax view; offload eligibility before argument parse |
| Calls/families | `f_grow_base`, `f_grow_args`, `f_family_first*`, `f_args`, `f_arg_next` | Resolve callable/template slots first; process argument markers and arguments in source order; apply existing shallow family-fill logic |
| Lambda | `f_grow_base`, `f_rhs`, `f_binary`, `f_lambda_valid` | At `=>`, validate syntax view and allocate/open binder **before** calling body parser; flatten completed lambda block; restore outer env |
| Sequential local | `f_statement*`, `f_let_value`, `f_let_body`, `f_erased_local*` | Parse lhs/type/RHS before pattern conversion; validate/open patterns before continuation; restore outer env after body |
| Parallel/typed local | `f_parallel_values`, `f_parallel_value`, `f_parallel_body`, `f_typed_let_try` | All lhs/type/RHS terms see outer env; names-only eligibility precedes ordinary pattern conversion; only then open new binders and enter continuation |
| Match | `f_match_heads`, `f_case_pats`, `f_case_pat`, `f_case_body`, `f_match_cases` | Head expressions; row arity; patterns converted/opened left-to-right; row body; close row; next row. Keep ungrouped row body as Body; no eager row flatten |
| Group/tuple | `f_group`, `f_group_namespace`, `f_tuple`; new completion hook | Tuple comma rule first; otherwise flatten completed body **before** parsing annotation or demanding closing `)`; no FGroup marker needed in contextual mode |
| All/Exists | `f_all_domain`, `f_all_body`, anonymous-arrow branch | Complete domain before opening binder for codomain; close it afterward. Anonymous-arrow fresh allocation occurs at its pinned post-RHS point |
| Do | `f_do_types*`, `f_do_statement`, `f_do_annotated`, `f_do_value`, `f_do_tail`, `f_do_return` | Resolve/fill header; type/value before binder; bind before recursive tail; build already scoped Ann/pure/bind/Let using common shallow constructor |
| Declaration-body completion | new `f_context_body` only | Parse body under supplied opened telescope; `ff_flat` once at this body boundary; materialize/freshen to ordinary core; return explicit staged result |

The shared builder extracted from `f_scope_do_args` must take already completed
header arguments, type, value and continuation. Legacy scoping supplies those
children recursively; contextual parsing supplies them as they finish. Apply the
same factoring principle to lambda/call/pattern error construction. Keep one
implementation of quantity filling, constructor arity checks and diagnostic text.

`f_valid_pattern` currently calls `f_scope(p, Nil{}, book)` on its computed-error
branch. It cannot be reused unchanged on contextual terms. Factor its validation
and error construction so the legacy route supplies its legacy observation and
the contextual route supplies its already scoped observation. Do not copy the
recursive validation cases and let them diverge. Pattern conversion/opening must
be sequential: an earlier refusal prevents later fresh allocation or alias
resolution, just as pinned `qs.map(parse_patt)` throws at the first failure.

For monad's specific cause, the completed do expression becomes the lhs of the
enclosing assignment. Parse the RHS `p`, then reject that computed lhs before
entering the orphaned `return`. The observed term is the real bind application
constructed under its enclosing lexical/module context. A malformed RHS wins;
a prior grouped-body failure wins; a later ungrouped row's pattern failure can
precede flattening the earlier row. No FDo blacklist or return-message special
case is part of this route.

## Public/raw compatibility and intentionally unsupported work

Keep `FParsedSource` trusted raw input unchanged. In particular,
`f_complete_source` returns `FCompletion{graph,parsed}` and the host can reuse
`parsed` as supplied raw source. Do not replace it with the contextual result
under loader ABI1. No normal successful body is parsed twice to populate that
raw field. The private entry is used only by its explicitly bound test adapter.

Full telescope parsing, law/refinement declarations, module/alias discovery,
foreign declarations, full rewrite-motive parsing, and template-signature parsing
are outside the initial body entry. Preloaded prior books and explicitly opened
header parameters may contain these declarations; the trial does not claim to
parse them. Template calls used by the frozen body controls require their
existing marker/slot ordering and cannot silently fall back to raw scoping.

Unsupported body features must return FContextUnsupported at their own grammar
boundary before consuming later input; they cannot return an upstream Error or
successful raw subtree. A feature-coverage inventory precedes implementation and
binds every saved fixture to the entry it exercises. If a required monad, stage
or pattern control reaches an unsupported feature, expand the reviewed coherent
slice or explicitly report the gate incomplete. Unsupported is never counted
as an exact match or behavior-preservation pass.

Before any production migration, audit actual FCompletion/parsed-cache consumers,
choose an explicit loader capability/staged result contract, migrate all remaining
expression entries, and decide which legacy raw APIs stay supported. That future
decision is not hidden inside this experiment.

## Sequential implementation gates

1. **Freeze controls and seed provenance.** Retain the exact saved monad pair,
   16 stage observations, 114 pattern observations and all 196 compatibility
   outcomes. Add the independent fixture graphs below. Bind full source bytes,
   body cursor, prior/header book, parameters, parser next and source interval.
   Verify header fresh events against pinned TypeScript in a read-only oracle;
   no reference compiler is called by the candidate's implementation.
2. **Names and state prototype.** Add the checked private root/context and FName
shape, keeping unsupported owners explicit. Test bound/unbound/alias calls,
   new binder allocation, `_`, close/rewind, independent sibling contexts,
   zero-arity/family/marked names, and demand. Raw B1/36 plus the 194 cursor/whole
   book controls must remain exact. Review actual source/representation cost
   before migrating the remaining owners.
3. **Coherent body slice.** Move the owner table together in bounded subwaves:
   lambda/All/group, locals/parallel/rows, then do and completion. No claim of a
   working contextual parser until every required owner is implemented and the
   entire frozen frontier has run. Stop after a counterexample to repair the
   shared cause; keep every attempted source and raw result.
4. **Independent semantic gates.** Require the private monad parse/check pair
   exact; preserve existing exact saved16 and114 observations and explain every
   newly exact result. No new primitive disagreement or changed nonexact result
   is accepted. All required controls must be supported. Compare accepted body
   core under the same explicit alpha-renaming start, retaining full ranges,
   names, quantities and literal payloads. Also run unchanged public raw/base/
   full-source equality and all196 public compatibility outcomes.
5. **Cost/simplicity decision.** Genuine B1 and a frozen patch are necessary but
   insufficient. Root owns an exclusive same-source cost screen of populated
   context and a later full-module integration proposal. No broad sweep,
   loader migration or installation proceeds merely because two rows improve.

Independent controls include malformed RHS before computed-pattern failure;
different later syntax after that failure; nested call/group/lambda/row/local
frames; missing close delimiters and later arguments; grouped vs ungrouped prior
rows; earlier declaration failure; imported and aliased monads in a namespace;
dotted local shadowing versus an unbound alias; valid typed do binds and pure
do locals; scope closure after groups; `name` versus `name()` as lambda/pattern
heads; beta-reducible computed applications; marked and anonymous binders;
parallel RHS siblings; and speculative annotation rewind without fresh-counter
rewind. Freeze actual oracle results before asserting an expected diagnostic.

## Complexity accounting and stop rules

No net source reduction is promised in this private experiment. The legacy raw
route remains supported, so its scoper cannot be counted as deleted. The old
261-line opportunity census is **not** a 261-line saving here.

A fresh source census of the specific route candidates totals 27 existing
definition blocks, 119 physical lines / 9,199 bytes, excluding their decorators
and law signatures. It covers `f_elab_defs/def`, `f_scope/base/lower/terms/ref`,
`f_scope_reference`, `f_scope_body/base`, local/row workers and their validation
callbacks, the three parallel scope workers, two do scope workers, four lambda
scope workers, and call/head/args. This is a measured **bypass/factoring pool**:
some constructors remain shared, and all compatibility definitions remain in
source. It is not a deletion total. `ff_flat`, freshening, validation, family
quantity logic, literals and core semantics remain required.

Record per subwave added/removed physical and nonblank lines, definitions/laws/
types, raw tags, new semantic decisions and traversals. Count source plus required
host roots and test adapters separately. Compare the real patch with the stopped
body and error-program alternatives before expanding it. A successful explanation
requires one grammar/checkpoint authority on the contextual route, not only a
shorter rendered file.

Pause for review if the names/state prototype exceeds 150 added production lines,
requires a second full successful-body scope walk, guesses fresh IDs from source
positions, duplicates recursive pattern validation, or changes raw FCompletion
stage. The 150-line threshold is a review checkpoint, not permission to compress
logic into long lines or drop tests. Later subwaves need measured deltas and a
new review before large growth. Any normal-path cost over root's screening limit,
unexplained strict mismatch, or unsupported required control blocks promotion.
