# Preserve invalid binder identity until diagnosis

The [design](../../design/phase16/unbound-binder-marker.md) keeps the parser's
existing `FUnboundVar` marker through freshening instead of inventing a valid
positive binder identity. The checker's existing unsupported-term fallback
recognizes this invalid-only marker and emits the ordinary unbound-variable
error. The diagnostic uses the existing scope query to display `^-1` only when
the spelling is already bound in that context. No new term variant, helper or
type is introduced, and no accepted checked term contains the marker.

The first candidate printed `^-1` unconditionally. Controls exposed plain-name
cases in inferred and open-template contexts, and one supposed positive fixture
was itself invalid. Both failures are preserved. Source02 corrects the scope
condition and uses the already established positive quantity-marked family
fixture; it does not change an upstream oracle.

`selfhost/build/phase16/unbound-marker-build-02` passes genuine checked bootstrap,
the unchanged equality derivative and the 36-case development gate.
`unbound-marker-checks-02` is **11/11 exact**, against seven differences on the
same controls in `unbound-marker-baseline-02`. Two observations belong to the
remaining upstream corpus; the other controls distinguish missing binders,
shadowing, template scope and valid marked syntax. Full integration is measured
separately. No timing or promotion claim follows from this bounded correction.
