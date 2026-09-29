# Stage2: ordinary names in the existing grammar

Prospective addendum to the frozen names/state Stage1. Parent is
`selfhost/build/phase19/context-source-02/project`, genuinely checked as
context-build-02 (selected API `7c4d83bd`). The Stage1 underscore failure remains
retained. This is an isolated private parser experiment, not a loader change.

The decisive question is whether the actual grammar can resolve a name before
it parses the following call arguments, using the shared contextual cursor.
The pinned TypeScript `parse_term_base` calls `parse_var`/`parse_reso` before
`parse_term_ops` descends into arguments. Therefore an ambiguous alias in
`M.f(return)` must beat the invalid argument. A seeded local named `M.f`
suppresses that ambiguity and exposes the argument error instead. Preserve both
orders, nested arguments, earlier invalid siblings, and independent sibling
seeds. Freeze the TypeScript observations before constructing the candidate.

Export one private checked root `f_context_term_probe(input,seed)` alongside the
Stage1 root. It requires raw-context input, installs the same explicit scope,
newest-first parameters and fresh counter, then calls the existing `f_expr`.
Its result is a distinct `FNamesParsed{term,rest}`, `FNamesError{error,rest}` or
`FNamesUnsupported{feature,rest}`. A successful result is a names-stage term,
never Core and never a public raw FResult. No loader calls this root and no
fallback passes a partially contextual term to legacy `f_scope`/freshening.
The only host delta is the explicit private export root; its checked emitted
artifact is separately identified from any appended direct-test exports.

The supported semantic domain is ordinary names and ordinary calls, including
empty and nested calls. Bare datatype/family/constructor spellings retain their
Var syntax alternative, and call heads consume only the canonical Ref fallback,
as the pinned parser does. No eager ADT conversion, binder validation, template
fill, body flattening or value materialization is introduced. Ordinary bound
variables remain variables. Calls may remain explicit Call nodes in this staged
result; the direct oracle projection expands them to the TypeScript App spine
without performing resolution or any other semantics.

The shared grammar changes are bounded:

* `f_atom_name` delegates its existing final bare-name arm to a contextual helper;
  raw mode produces exactly its previous Ref/coordinate identity.
* `f_atom` and `f_grow` guard the private domain before entering any unimplemented
  owner. Existing raw workers remain authoritative. Groups, binders, do, rows,
  marked names, literals, constructors, family application, operators, indexing
  and offload return explicit Unsupported, including when nested in arguments.
  Ordinary invalid delimiters and `return` still use existing error producers.
* `f_grow_base` selects an FName's Ref fallback at call entry, before argument
  descent. `f_arg_next` and `f_grow_args` propagate the private stop tag alongside
  Error. The existing argument loop and call construction are reused. Its `~`
  branch is stopped before the template owner is entered.
* The two existing lexical error producers preserve the contextual error cursor;
  raw mode retains its empty-rest behavior. This makes the selected diagnostic,
  fresh counter, lexical stack and point cursor independently observable.

The private guard is a temporary supported-domain boundary, not a second parser
or a claim that unsupported syntax is invalid. Error and Unsupported stop before
later arguments. Unsupported rows count only as interface/demand controls, never
as conformance gains. Explicit beginning/EOF and whitespace cases test cursor
behavior; syntax errors before an ambiguous later argument must still win.

Freeze a small independent TypeScript `parse_tele` + `parse_term` oracle: ordinary
and dotted names, bound/unbound empty calls, near/far/alias choice, shadowing,
nested calls, both error orders, missing close and argument, newline boundaries,
and unsupported syntax at top level and inside a call. Record raw-parent
`f_expr` output on the ordering witnesses, so improved chronology is evidenced
against the actual former grammar rather than an inferred baseline.

Gates are genuine checked B1 and maintained36, the frozen Stage1 27 controls,
strict Stage2 term/state/diagnostic comparisons, explicit Unsupported controls,
and the 194 raw/public whole-book controls including Base and compiler source.
Preserve every failed attempt. No broad frontend, timing, promotion, monad fix,
or same-body instance fix is claimed by this subwave. Record exact line/byte,
definition and concept changes, then review the next real binder/body owner.
