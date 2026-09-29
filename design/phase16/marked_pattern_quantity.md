# Preserve marked-variable quantity at the pattern boundary

Read-only proposal after the ordinary empty-call experiment; no compiler edit
or probe is authorized by this file. The saved positive witness is
`empty-call-pattern-controls-02/fixtures/marked-bound.bend`:
`+x() = {0n : Nat}` under an existing parameter `x:Nat`.

The pinned TypeScript `+` expression rule first parses its operand. If that
operand is a variable and its resolved declaration is not a datatype, it returns
Var with identity -1. `parse_bind` then converts that sentinel into quantity Many
on a newly opened binder. In term position the sentinel remains an invalid
unbound variable; pattern position deliberately has different semantics.

Bend already distinguishes the term meaning in `f_scope_marked`: it returns
`FUnboundVar` for the variable case, an ADT for a valid quantified datatype, and
Error for invalid marked expressions. Its raw pattern traversal does not use
that distinction for marked empty Call nodes. Ordinary-call normalization must
not simply admit qt=2 because a global datatype can override a same-spelled
lexical variable in TypeScript's marked rule.

The smallest principled correction is to reuse the existing marked scope worker
at the pattern boundary, and translate only its `FUnboundVar` result into a fresh
pattern Var of quantity 2 (Many). Preserve original occurrence identity and the
whole marked expression's source range. Keep ADT/Error outcomes intact.

Proposed API changes: add the already available `book` to `f_patterns` and its
recursive/local/row/parallel calls. A single guarded helper
`f_pattern_marked(t, env, book)` runs only for qt=2 raw Ref/FAliasRef or empty Call
syntax, calls existing `f_scope(t, env, book)`, and maps the one sentinel. Ordinary
patterns still do not consult the book/environment. No change to `f_scope_marked`
or term semantics, and no host sentinel rewrite. Estimated scope: elaborate.bend
plus the one parallel.bend call site, roughly 10–20 new lines and argument edits.
This is a source-cost estimate, not a checked or measured implementation.

Before implementation, freeze paired controls covering bare +x versus +x(),
unbound and existing names, nested empty calls, alias and qualified bindings,
nonempty calls, marked datatype names shadowed by lexical binders, ordinary
marked datatype patterns, and terms using the same spellings outside patterns.
Use RHS annotations and a body that requires Many (two uses of the new binder),
plus an affine ordinary-binder control. Compare exact phase/message/range and
acceptance against the saved baseline and pinned TS. All current82 observations
remain selected. Validate genuine checked B1 and lazy normal-pattern demand;
root owns the broad gate and any decision to adopt the argument threading.
