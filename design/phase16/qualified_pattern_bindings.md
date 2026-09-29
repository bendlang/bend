# Apply qualified-pattern eligibility to references without aliases

The alias-binding handoff correctly checks an original dotted spelling against
its existing environment before making a pattern binder. The old plain-Ref
branch still creates a binder unconditionally, so a fresh `Foo.bar` pattern
without an import alias can be accepted even though TypeScript treats that
spelling as a reference and rejects it. This is a separate semantic correction.

First freeze paired controls against alias-binding-checked-04. Then factor the
two reference forms through one `f_pattern_reference` worker in the existing
pattern traversal: an unqualified Ref becomes a binder, a qualified original
name becomes a binder only if already bound, and an unbound qualified name keeps
its canonical/ordinary reference or its prior ambiguity error. Do not perform
scope lookup for ordinary undotted patterns. Keep constructor/literal handling
and traversal unchanged. No keyword exception, host fallback or new scope walk.

Controls cover fresh/bound dotted patterns, canonical module references without
aliases, nested constructor patterns, ordinary fresh names, and existing alias
controls. Test both parse and check lanes, exact diagnostic vectors and health.
Save all failures and preserve the accepted source04 handoff. CPU3 correctness
only; parent owns integration, full-corpus and cost gates.
