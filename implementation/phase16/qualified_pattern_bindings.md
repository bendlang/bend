# Qualified patterns without matching import aliases

The alias repair exposed a nearby old rule: plain Ref patterns became binders
unconditionally. TypeScript treats an unbound dotted spelling as a reference,
even when no alias matches it, and rejects it as a pattern. A dotted name that
already has a lexical binding may be rebound as a pattern.

The frozen baseline `alias-pattern-baseline-02` establishes three erroneous
acceptances: fresh `Foo.bar`, canonical `mod.double` when the module is imported
as `M`, and nested `Mk{Foo.bar}`. Each differs from TypeScript in both parse and
check lanes, for six primitive and exact differences. Four positive fixtures
already agree in both lanes. Both workers finish14 requests with no errors,
failures or timeouts.

`alias-pattern-source-02` factors Ref and FAliasRef handling through one
`f_pattern_reference` worker in the existing traversal. Undotted names remain
binders without an environment lookup. A dotted name becomes a binder only if
its original spelling is already bound; otherwise its ordinary or canonical
reference, including a prior ambiguity error, survives for the existing pattern
validator. Literal and constructor construction are unchanged. The delta is
one file, seven physical lines and219 bytes, against alias-binding-source-04.
`alias-pattern-source-02/manifest.json` and `elaborate.patch` bind its full delta.

The genuine checked bootstrap and derived B1 attempt are
`alias-pattern-checked-02`; its maintained36 focused controls pass with their
two existing exact differences. `alias-pattern-validation-02` compares the new
fourteen observations plus the prior46 alias/lambda observations: **60/60 agree
exactly**, with no lost prior matches. Both workers finish60 requests without
errors, failures or timeouts. Thus the six incorrect acceptance observations
now agree with the reference, while all positive controls remain accepted.
This is a selected-scope result; root owns full-corpus and performance gates.

The first controls attempt used an invalid import without its required `as`
clause, so those rows did not exercise canonical-name patterns. That entire
attempt is retained; controls02 correct the fixture syntax before candidate
comparison. An initial preparation also stopped at a stale insertion anchor
before writing its source delta; the partial source01 copy and consumed tool
are retained. Neither failure was selected or used as a conformance gain.

Design: [qualified pattern eligibility](../../design/phase16/qualified_pattern_bindings.md).

The unchanged alias resolution direct runner also passes16/16 controls on this
artifact (`alias-pattern-direct-02`), and its demand instrumentation passes4/4
(`alias-pattern-demand-02`): ordinary lambda and pattern cases still perform
zero outer binding lookups. `alias-pattern-audit-02.json` checks these counts,
exact paired vectors, worker health and immutable evidence identities. All
owned compiler/control processes are closed. No timing claim is made.
