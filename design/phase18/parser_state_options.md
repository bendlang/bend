# Parser state versus rejected-path checkpoint replay

Read-only investigation. No compiler source, ABI or frozen Phase17 file changed.
The census below uses the immutable Phase17 group-source-02/project/src, API
0b9f57d26cb0660531e0f7335fb292e13c9fefe86f491e48554a11e5f8312a3e.
It includes the measured eight-line FGroup ablation; the installed frontend has
the same cursor architecture without that experimental marker. The reference is
pinned b2111cf, inspected locally in bend2/bend.ts. Proposed gains are not measured.

## Recommendation

Test an explicit parser cursor/context before implementing the250–400-line
rejected-path program from Phase17. The old104-function transitive-call count
substantially overstates the number of semantic rewrites needed to carry context:
most callbacks already return the remaining cursor through FParsed.

This alternative has a better eventual concept structure: perform lexical
resolution and pattern checkpoints at the point where parsing reaches them,
then perform context-free lowering and pattern-matrix compilation at the actual
term/body boundary. It could remove the need to replay an alternate checkpoint
program after failure. It is not automatically faster or shorter. A naive
cursor wrapper creates allocations on the successful path, and compatibility
with raw parser APIs can prevent deletion of the old scope walk. Both questions
need explicit gates before a semantic migration.

## Actual mechanical census

The counted unit is a distinct function/law signature containing an explicit
List<&2,FToken> type, with whitespace normalized. Inferred def signatures paired
with a typed law do not count twice. Lexer construction and cursor access are
separated. The source has143 textual token-list type expressions overall;
that number includes return types, type arguments in bodies and raw lexing.

| Area | Function signatures whose cursor type changes |
| --- | ---: |
| front/declarations.bend | 30 |
| front/parser.bend | 26 |
| front/sugar.bend | 9 |
| front/validate.bend | 5 |
| front/parallel.bend | 4 |
| front/literals_arrays.bend | 1 |
| load/imports.bend | 3 |
| Cursor helpers in front/lexer.bend | 10 |
| Total | 88 |

FParsed.rest is one additional field-type change, not a new result field. Its70
case destructures retain their two-field shape. The many inferred callbacks
that receive FParsed therefore need no new context argument. Most successful
FParsed constructors simply pass ts/rest through; their source need not change.
This does not mean88 semantic changes: most are type spelling replacements.

Exactly eight functions directly pattern-match the token list: f_tx, f_tl,
f_line, f_col, f_kind, f_begin, f_end and f_previous_end, all in lexer.bend.
f_skip and f_space are the other two cursor helpers. Eight raw lexer routines
keep List<FToken>; notably f_symbol_text/f_lex_symbol currently call f_tx/f_col
on their reverse accumulator. Give those two consumers explicit raw-list peek
helpers rather than allocating parser cursors in the lexer.

Only five non-lexer functions synthesize FToken values: f_atom_base (splits ++),
f_args (splits >>), fpe_word (diagnostic endpoint), f_validate_param (the >
endpoint of ->), and f_type_base (splits <-). They create six token records in
source. Replace their raw list splicing with one context-preserving prepend or
endpoint helper. Do not rebuild the token tail. The five literal Nil rest exits
are in f_err, f_atom_nat_start, fpe_legacy, fpe_span and f_typed_let_try; each has
an input cursor available and can return an empty cursor preserving its context.

There are154 static f_tl call sites (152 outside lexer.bend). These are source
sites, not dynamic counts, and do not establish an allocation-per-token ratio.
For reproduction, count declarations under src with a top-level law/def scanner,
inspect only each signature for the type count, and count `case FParsed{` and
`f_tl(` in function bodies. Exclude src/compiler.bend's separate Token grammar
from the FToken cursor census. The complete source membership is already frozen
by group-source-02/manifest.json; this investigation created no compiler artifact.

## Representation options and allocation accounting

The simplest first experiment is:

```
ParserInput { tokens: List<FToken>, context: FParserContext }
FParserContext { module: FParseScope, bound: List<KTerm>, visible: List<KDef> }
FParsed { term: KTerm, rest: ParserInput }
```

The context fields are a proposed responsibility split, not an approved final
layout. module reuses the existing imported declaration index, namespace and
resolved aliases. visible must be the chronological declaration/family/template
view, not a copy of the whole module rebuilt for every token. bound is a
persistent lexical stack. A later implementation should remove a redundant book
view if FParseScope can own it cleanly; it must not accumulate several competing
symbol tables merely because they already exist in different passes.

Read helpers unwrap the cursor without allocating. A nonempty f_tl returns a
new two-reference ParserInput sharing the old context and token tail. Scope
opening creates a new context sharing the module view; closing restores the
saved outer context while retaining the returned token position. f_skip/f_space
can skip using raw tails internally and wrap only their final cursor. A parser
error must preserve context explicitly rather than substituting a bare Nil.
The lexer and its token-list ABI remain unchanged.

| Option | Added work/allocation | Assessment |
| --- | --- | --- |
| Cursor wrapper, shared immutable context | One wrapper per dynamic nonempty f_tl, plus scope changes and entry cursors; readers add no objects. Raw-list skip helpers avoid one wrapper per skipped newline. | Smallest representation ablation. Must measure its successful-path cost. |
| Add explicit context parameter to every parser function | No cursor wrapper needed for a plain advance; persistent environments still allocate at binders. Many call expressions and callback signatures change. | Lower allocation risk, larger mechanical patch. Keep as fallback if wrapper cost is material. |
| Put context into every token/list tail | Changing scope would leave the already-built tail with stale context or require copying/relabeling the remaining stream. | Reject this design; it can introduce suffix copying per binder. |
| Mutable host object carrying parser state | Could resemble the TS object directly, but adds host mutation or runtime machinery to a Bend compiler. | Outside this proposal and the simplicity goal. |

Let A be the measured dynamic nonempty f_tl count, S scope transitions and R
entry/reset operations. A naive immutable wrapper adds approximately A+S+R
cursor records, not necessarily one record per lexical token. Repeated lookahead
can make A substantially larger than tokens. Existing token and list records
are still present, including the lexer's reversed accumulator/list construction.
No bytes/object, speed ratio or memory reduction is assumed. Count allocations
and token visits in a probe artifact, then time an uninstrumented checked build.

## One authoritative parse stage needs explicit name meaning

Pinned parse_var is more informative than “resolve the name now.” A bound name
returns Var; an unbound dotted name returns Ref; an unbound ordinary name returns
a Var with a Ref fallback. parse_patt/parse_bind may turn that last form into a
new binder, while term lowering uses its global fallback. This explains why
ordinary empty calls, qualified binders and import-alias shadowing are sensitive
to exactly when a name is resolved.

Our current core Var/Ref representation does not encode that fallback. Simply
canonicalizing every atom to Ref would lose the written unqualified name and
binder eligibility, especially inside a module. A contextual parser needs one
explicit temporary name/fallback representation, or an equally explicit typed
parser term. An initial FName node can carry the written name and its resolved
reference in children; it must not hide this information in id, quantity or a
source coordinate. Bound names stay ordinary Var; unbound dotted names stay Ref.
A bare FName can become a binder, whereas an ordinary empty call consumes its
global fallback. That same decision makes bound zero-argument calls retain Var.

This is an architectural replacement candidate for FAliasRef and FLambda,
not a promise to add another marker permanently. FGroup can also disappear once
f_group performs the actual body_flatten boundary before closing/annotating the
group. A context-free final lowering may still be required to consume FName and
other raw sugar. That pass is analogous to pinned term_lower; it must not redo
lexical lookup, pattern eligibility or first-error chronology. One authoritative
syntax/scope pass does not mean eliminating pattern compilation, freshening or
all later tree traversals.

The semantic migration points are narrower than the cursor plumbing:

- Resolve names/aliases with the current environment in f_atom_name and the
  call/marked-name completion path, reusing existing quantity/family/template
  rules as shallow constructors rather than rescanning complete child trees.
- In f_let_value and parallel value completion, finish all earlier left/RHS
  terms, validate patterns, open the resulting binders, then call f_body.
- In f_case_pats, validate/open patterns before parsing that row's body; close
  them before the next row. Keep a Match body raw until its enclosing term/body
  boundary, exactly as pinned parse_body does.
- In f_group, flatten the completed body before testing the closing delimiter
  or namespace annotation. No failure replay is needed to recover this point.
- In f_binary's lambda path, validate/open the binder before invoking the body
  parser; in f_all_domain, open only after its domain finishes. Restore the
  outer environment after each nested parse.
- Apply the same explicit open/close discipline to f_tele_type, declaration
  bodies, law/where, do binds and rewrite motives. Rewrites close the temporary
  `_`/proof-name scope before parsing their body.

The existing f_rhs eagerly calls f_body before f_binary sees the result, so
lambda ordering is a real control-flow change. Likewise f_let_value currently
calls f_body before pattern validation. Merely changing a cursor type or
calling f_scope on a completed whole expression would not establish a single
pass; that would retain the duplicate work and fail to test this architecture.

## What could actually be removed

The following is a measured pool of current declaration blocks, not a deletion
promise. Physical block counts include their @unsafe line and internal lines,
but exclude separating blanks and surrounding comments. They count both laws
and definitions. Some semantic operations must move into parser owners and
therefore do not become net savings.

| Current pool | Defs / laws | Physical block lines | Bytes |
| --- | ---: | ---: | ---: |
| Structural scope/elaboration walk and local/row/parallel/lambda adapters | 21 / 16 | 195 | 7,919 |
| Alias preparation walk (f_alias_term/deferred/named/terms/defs) | 5 / 1 | 30 | 1,958 |
| Raw pattern conversion/reference/empty-call/marked adapters | 4 / 0 | 30 | 2,050 |
| Experimental f_group_finish helper | 1 / 0 | 6 | 303 |
| Pool total | 31 / 17 | 261 | 12,230 |

This pool is229 nonblank, noncomment code lines. The195-line scope pool is:
f_elab_defs/f_elab_def, f_scope/base/ref/terms/body_base/body/local/rows/row/lower,
f_scope_local_valid/f_scope_row_valid, f_scope_parallel/pats/valid, and
f_scope_lambda_eligible/refused/lambda/var. Pattern validation, quantity rules,
constructor checks, do desugaring and pattern-matrix compilation are retained
semantics; moving them is not a deletion. A final term-lowering walk may replace
part of the structural pool. Thus261 lines is an upper candidate pool, not a
forecast net reduction. A representation-only ablation likely adds60–120 lines
plus mechanical type substitutions. The complete migration has no defensible
net-LOC estimate until the name representation and compatibility decision are
proved; even a successful rewrite is unlikely to halve this compiler's source.

## Public boundary and compatibility decision

FParsed's constructor arity stays two, but its rest field changes type. Direct
internal callers/tests constructing FParsed from a list need a cursor adapter.
FParsed is not in typed-driver's marshalled public constructor table. f_lex can
continue returning the same tokens; f_parse/f_parse_indexed can keep their
FResult shape, and FSource/FHeader/FCompletion/FGraph need no representation
change for the metadata-only experiment.

The semantic migration is different. f_parse with no dependency context and
trusted FParsedSource currently supply raw books to later scoping. An already
scoped book must not silently be passed through f_module_defs as if it were raw.
For an experiment, expose a private contextual completion entry with an explicit
stage/result distinction and keep old entry behavior intact. Before promotion,
choose one of these compatibility contracts:

1. Keep raw-parser/trusted-raw-source compatibility. Retain an explicit legacy
   scoping adapter for those inputs; report that much of the261-line pool remains.
2. Version the loader/parser-stage contract, expose an explicit raw compatibility
   entry only where actually required, and make ordinary module completion use
   the single authoritative parser. Audit all consumers and preserved tests;
   never infer stage from tree shape or silently reinterpret FParsedSource.

Neither choice is authorized here. The host's current loader ABI is1, and no
metadata-only cursor change requires bumping it. A new raw-versus-scoped public
contract would require a deliberate ABI decision and routing/refusal controls.
Successful parse-book equality is the representation gate; after a declared
semantic-stage migration, full lowered-book equality is the relevant gate.
Earlier module/declaration errors still have priority, so completed declaration
prefixes must finish at their actual source order rather than be replayed after
an arbitrary later body failure.

## Decisive experiments, in order

1. Cursor-only ablation on an isolated frozen parent: change cursor transport and
   centralized helpers, initialize an inert context, and leave grammar/scoping
   behavior unchanged. Check genuine B1, maintained36, raw and lowered Base/full
   source equality, all196 Phase17 observations, synthetic token splitting, EOF,
   error-rest preservation and context push/pop restoration. Count dynamic cursor
   allocations per token and use a root-controlled identical-source timing/RSS
   gate. This isolates the principal new hot-path risk before any semantic rewrite.
2. One contextual parsing slice through the existing grammar, not a second parser:
   name/fallback resolution, local/parallel pattern checkpoints, match-row scope,
   lambda/All scope, grouped-body flattening and the do construction needed by
   monad. Reuse semantic constructors on already parsed children; forbid a whole
   f_scope replay on each prefix. The decisive outputs are exact monad2 and
   saved16 stage rows, plus the saved114 pattern witnesses (bound/unbound empty
   calls, quantities, qualified names and alias shadowing). Add independent
   module-qualified bare-name and scope-restoration controls first. Keep this
   private slice unselected until the remaining frame families are migrated.
3. Only after both proofs, choose the public stage contract, move the remaining
   telescope/law/rewrite/array/template paths, and delete superseded adapters.
   Audit actual removed concepts/lines; run root full conformance, backend,
   histories and final controlled speed checks. If compatibility forces both
   complete semantic traversals to remain indefinitely, reconsider whether this
   migration still earns its complexity advantage.

The rejected-path DSL preserves successful-path allocation behavior more easily
but adds six frame tags, a replay selector, canonical Error transport and a
special completed-prefix handoff across45 callback audit sites. It offers little
natural code deletion. The cursor route adds allocation risk and requires a
name/stage-contract decision, but moves chronology to the parser's existing
control flow and has a concrete adapter-removal pool. Given the user's priority
on simplicity, the cursor-only cost proof is the smaller next decision. Neither
option has an established speed gain, and neither fixes the separate checker
same-body specialization chronology by itself.
