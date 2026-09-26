# S4 declaration audit: one typed definition where no forward law is needed

Baseline: S3 `8cc51c1`. This is static source analysis only: no compiler source,
assembler or host was changed, and no compiler, tests or builds were run.
[Counts and source identities](declarations-counts.json) retain the inventory,
conservative candidate names, module counts and the three largest graph cycles.

## Supported syntax and unchanged assembler

The pinned upstream `bend2/bend.ts` documents this distinction at lines 101–102
and implements it in `parse_def` at 2487–2535: without a prior law, a definition
must provide typed binders and `->`; after a law, it must provide bare names and
cannot repeat those annotations. Self-recursion does not require a separate law:
the definition's signature is entered before its body is checked. Chronological
visibility still matters (`book_valid`, lines 3759–3779): a forward reference
needs a declaration, and a law is visible but cannot unfold until its fill.

The maintained source already uses exactly this syntax. For example,
[native/text.bend](../../../selfhost/src/back/native/text.bend) contains:

```bend
@unsafe
def nt_choose(-A: Type, +b: Bool, yes: Unit -> A, no: Unit -> A) -> A:
  match b:
    case True{}: yes(Unit{})
    case False{}: no(Unit{})

@unsafe
def nt_count_go(-A: Data, xs: List<&2, A>, +n: U32) -> U32:
  match xs:
    case Nil{}: n
    case Con{h, t}: nt_count_go(A, t, U32.inc(n))
```

The same module retains laws for `nt_replace_go`/`nt_replace_step`, which call
each other. Thus this proposal extends an existing declaration convention.

[assemble.mjs](../../../selfhost/tools/assemble.mjs) already emits types, then
laws, then definitions, retaining manifest/file order within each category.
It does not need any new dependency resolver, signature inference, generated
declarations or semantic sorting. Keep its behavior unchanged. Public types move
to the definition header; public names, roots, modules, imports and quantities
remain explicit Bend source. A one-off audited edit may identify candidates, but
no such tool belongs on the compiler's runtime path.

## Fixed-order candidate budget

The 59-module manifest contains 1,450 definitions, 1,222 laws and 61 datatypes:
2,733 top-level declaration events, excluding imported Base and constructor
entries. All 1,222 laws have a matching fill; 228 definitions are already typed.
Every law has only ordinary `for` clauses, one return expression, and exactly
matching fill parameter names/order. There are no `exs`, `where`, or template
clauses in this pool. Signature/type expressions do not reference compiler value
definitions after excluding their bound names and field labels. All 1,450
definitions retain an explicit `@unsafe` marker.

The conservative body-reference graph has 6,276 edges after removing self-edges,
literal strings, comments and formal-parameter references. With the existing
definition order fixed, 797 names have an earlier caller and retain their laws.
The remaining **425 pairs** are eligible without reordering. The full candidate
name list is in the JSON. Local pattern/lambda shadows can cause the token scan
to retain unnecessary laws, so this is a conservative candidate set, not a proof
that all 797 remaining declarations are necessary.

Each typed replacement keeps **one parameter per line**. It preserves binder
names, types, order and quantities, moves the return expression to `) -> T:`,
and leaves the body and `@unsafe` unchanged. This removes one authoritative-name
and declaration/fill coordination site per candidate. It also removes one
chronological law event and its duplicate signature check; runtime gain is an
untested hypothesis.

| Policy | Removed law events | Laws left | Events left | Nonblank lines saved | Bytes saved, excluding blank separators |
| --- | ---: | ---: | ---: | ---: | ---: |
| Existing definition order | **425** | **797** | **2,308** | **427** | **11,812** |
| Reorder inside modules; retain all local cyclic members and later-module targets | 663 | 559 | 2,070 | 665 | 20,251 |
| Global ordering; retain all cyclic members | 699 | 523 | 2,034 | 701 | 20,526 |
| Convert every law, ignoring forward-reference constraints: unattainable ceiling | 1,222 | 0 | 1,511 | 1,224 | 45,049 |

For transparency, deleting the blank separator after each removed law would add
407/619/657/1,142 blank-line reductions respectively. The raw physical deltas
would then be 834/1,284/1,358/2,366 lines, and raw byte deltas
12,219/20,870/21,183/46,191. **Those blank lines earn no complexity credit.**
Packing multiple binders into a single line also earns no credit. The existing
order therefore funds a 427-line structural reduction, not a 50% reduction.
Even the unattainable no-law ceiling cannot establish that milestone without
counting signature packing or making unrelated architectural changes.

The graph has 100 multi-function SCCs containing 541 definitions; the largest
has 65 parser functions. Within individual modules there are 103 SCCs / 475
members, and 109 targets of calls into later modules. Retaining every cyclic
member is sufficient and deliberately conservative, not a minimum feedback-set
solution. In the actual resolved graph, every genuine multi-function SCC needs
at least one remaining forward declaration under any linear order; which names
form the minimum is unresolved. Merely counting SCCs cannot fund extra savings.
The extra ordering invariant is not worthwhile for the first bounded migration.

## Semantic obligations

Preserve the literal binder names and quantity markers, including dependent
references such as `A` in later domains/results. A name in scope is not a global
dependency. This audit checked that the fill names already match, so renaming or
substituting type expressions is unnecessary. Keep the law for every detected
reference from an earlier definition; self-reference is already supported by
the typed-definition path. Do not remove general law parsing or checking: user
programs and the retained compiler declarations still require it.

The event stream does change. [kernel.bend](../../../selfhost/src/check/kernel.bend)
`signature_mode`/`signature_fill_mode` currently propagate the later fill's
unsafe status to an earlier signature event. A typed definition already carries
that same `@unsafe` status when checking its signature. `event_error` currently
compares a fill against its law; there is no separate signature to compare after
conversion. These facts support equivalence for the identified compiler helpers,
but they do not prove it. Parsing two binder telescopes versus one can change
fresh IDs and source origins; exact internal parse-book identity is not a valid
unchanged-artifact assumption for this source migration. Check observable compiler
behavior and, where appropriate, compare binding structure modulo fresh IDs.

## Smallest useful pilot and falsifiers

Start with `src/core/term.bend`: 34 of its 43 laws are eligible in fixed order;
retain the nine names listed in the JSON. This includes erased/higher-order
`kc`, constructor helpers, direct recursion and dependent core operations.
Budget: **35 nonblank lines / 563 bytes**, excluding 34 separator newlines.
For an even smaller syntax probe, take only `kc`, `kt`, and `terms_at` first.

The smallest established compiler component containing this module is the four
core modules `term`, `index`, `normalize`, and `graph`, also used by the historical
core fixture. Use the unchanged assembler and `tools/stage0-library.mjs` to check
and export `wnf`, `strong`, `compare`, `lookup`, `book_cached`, `book_context`,
and `book_put`; run existing `tests/normalize.mjs` and `tests/index.mjs` with that
fresh API. These are proposed gates, not results from this audit. Also load/check
both source forms through the frozen S3 compiler to exercise its own typed-binder
parser, not only the pinned TypeScript parser. Reject a new forward-reference,
quantity, unsafe-mode, fresh-binding or generated-output discrepancy before
expanding to the remaining 391 candidates.

For the completed fixed-order migration, require a fresh checked whole-compiler
build and maintained component/selected controls, preserved full frontend
observations, normal interpreter/JS/native-generation scope, and a controlled
compile-cost check. Source declarations are input to both compilers: do not
reuse S3's generated-closure equality as proof for this different source form.
Charge any retained transformation/audit tooling separately from compiler savings.
