# Contextual constructor scope

Freeze before implementation. Parent wave9-source-01 contains the complete
contextual loader and accepted wave8 changes. Pinned TypeScript remains b2111cf.
The independent eight-case baseline is wave9-context-namespace-01/report.json:
four exact, two diagnostic-order differences and two false acceptances.

The parser has separate top-level and constructor namespaces. While resolving a
definition name, a constructor already declared in the current module makes that
module's qualified name the selected name. A prior far law with the same written
name therefore does not become fillable. TypeScript then refuses the new def at
its name because freshness sees the far top-level declaration. The context
lookup currently considers only constructors from completed prior modules.

Correct the missing local-constructor decision only after the prior lookup finds
a fillable law and only when an alias does not redirect the name. Reuse the
existing local constructor lookup, missing definition and freshness paths.
Ordinary missing-name declarations must not scan their local constructors.

Also apply the existing import-alias freshness rule to constructor headers before
field parsing. Constructors use their own duplicate table, but aliases are
forbidden in either fresh declaration namespace. Use raw import metadata; do
not infer dependency contents or interpret an error string.

Frozen controls cover the far-law/local-constructor case, malformed parameters,
far completed definitions, no far declaration, a far law without a local
constructor, an unrelated local constructor, and alias-prefixed constructors
with valid and malformed fields. Require all eight to match pinned TypeScript.
Then recheck the existing supplied-source39 and ordered-host43 controls plus the
36 maintained cases. Preserve the baseline failures and all earlier candidates.
