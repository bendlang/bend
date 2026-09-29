# Empty named calls in patterns

Frozen before implementation. Parent: `wave9-source-01/project`, pinned
TypeScript `b2111cf43244e65f76ddc278ee695e669f720cbf`.

TypeScript `parse_var` gives an existing lexical name a Var without a fallback.
`parse_term_ops` replaces only a Var carrying an unbound-reference fallback,
then constructs one App per supplied argument. With no arguments, a bound
name therefore remains a Var, while an unbound name becomes Ref; both retain
the original name span. `parse_patt` then accepts the Var as a new binder.
The Bend pattern traversal currently leaves both raw Call terms untouched.

Make one bounded correction in `front/elaborate.bend`: inspect ordinary empty
Call chains ending in an ordinary Ref or FAliasRef. Consult the existing
lexical environment once at the final head. A bound head becomes a pattern Var
with the original syntax occurrence identity and range, just as the existing
pattern-reference helper. An unbound head retains the original Call tree, so
normal scope, template and alias validation still runs, but its pattern refusal
range is the original head range. Calls with arguments, quantified/marked calls,
offload heads and other term heads retain their current path. Ordinary patterns
must not gain a lexical lookup. No new source pass, metadata type or host rule.

Keep the existing 50 checkpoint oracle observations visible, with their known
chronology failures. Add bound and unbound nested empty calls, constructor-field
and match-row patterns, lambda/local enclosing bindings, aliases with and without
lexical shadowing, and nonempty/marked/offload boundaries. First run the same
selection on frozen wave9. Preserve malformed fixture attempts separately.
Then build genuine checked B1, run the maintained 36 focused controls, and the
identical paired selection on the candidate. Compare exact outcomes and process
health. Any lost prior exact match or newly incorrect acceptance blocks handoff.
This is not a chronology fix or a performance claim.

The larger rejected-body frame transport stays read-only until an explicit API
and every lexical frame in `parser_failure_frames.md` have independent review.
