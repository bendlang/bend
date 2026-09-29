# Resolve lexical bindings before import aliases

Pinned TypeScript parse_var checks the lexical stack for the original spelling
before parse_reso expands an import alias. The current Bend alias prepass rewrites
all Ref nodes first. A valid parameter named M.double is therefore replaced by
the imported mod.double function, even in an otherwise simple identity function.
The old and module-name-rendering compilers share this semantic bug.

First preserve a baseline paired acceptance witness. Then, from the frozen
wave6 source union, make alias expansion an explicit transient alternative for
changed Ref spellings: retain the original name/id/quantity/origin plus the
precomputed canonical Ref or ambiguity Error. The existing authoritative f_scope
lookup selects the lexical variable first; only an unbound original spelling
uses the canonical alternative. That alternative must not be rebound against a
local variable whose spelling happens to equal its canonical module name.

Keep f_alias_named and its already validated point diagnostics unchanged. Its
result is merely deferred. Other canonical tags/family metadata retain their
existing prepass. Raw call-head checks must recognize the alternative without
turning a local function into a template head. Pattern processing uses its
existing traversal and incoming scope, never a parallel lexical walk: a dotted
name already bound can introduce a new pattern binder, while an unbound qualified
reference remains an unsupported pattern like TypeScript.

Controls include direct/applied/nested lexical uses, unshadowed sibling uses,
constructor patterns and a qualified binder pattern, alias-family/template calls,
canonical-name collision, and a fresh qualified lambda refusal. That lambda is
an older parser gap; if the alias repair exposes new acceptance, retain the
failure and escalate a separate minimal cursor-preserving fix rather than hide
it with an oracle. No unused metadata-field encoding, AST rename-back, fixture
message or TypeScript fallback. The candidate is not selected until checked
bootstrap, focused36, exact paired controls and parent integration gates pass.
