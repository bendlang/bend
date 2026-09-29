# Lexical binding before module alias resolution

The alias prepass changed `M.double` to `mod.double` before lexical scope could
recognize a parameter named `M.double`. The saved acceptance witness establishes
a semantic error: pinned TypeScript accepts `keep(M.double: Nat) -> Nat:
M.double`, while the previous Bend compiler rejects its body as `Nat -> Nat`.
This was present before the diagnostic module-name renderer.

The isolated candidate keeps a changed alias reference as one explicit
`FAliasRef` alternative. The existing scope lookup chooses the original lexical
binding first; only an unbound spelling selects its canonical reference or alias
ambiguity error. Canonical names are not looked up again in the lexical scope.
The same existing pattern traversal receives its existing environment, and raw
call-head handling recognizes the alternative while preserving template rules.
No additional scope traversal, host language fallback or source-name exception
was added. The imported ambiguity renderer remains unchanged.

Boundary testing caught another semantic gap: a fresh dotted lambda binder was
accepted after its body acquired the correct lexical binding. TypeScript permits
rebinding an existing dotted variable but rejects an unbound dotted reference.
Only qualified lambda syntax now retains an `FLambda` with its original reference
and explicit operator-end cursor. The authoritative scope pass decides its
eligibility; invalid binders reuse the structured point renderer. Ordinary valid
lambdas remain ordinary nodes. The same cursor closes the existing
`parse/reserved_lambda_binder.bend` diagnostic difference, including failure
precedence over an invalid body. Names and source cursors are never reconstructed
from diagnostic strings.

The final isolated snapshot is `alias-binding-source-04/project`, based on the
frozen `wave6-source-01/project`. Its six-file delta is **35 physical Bend lines
and 2,814 bytes**. Exact before/after source hashes and patches are in
`alias-binding-source-04-handoff/manifest.json`. No production source was edited.
The candidate has genuine checked bootstrap and derived B1 lineage in
`alias-binding-checked-04/attempt.json`.

Validation on CPU3, one process group at a time:

- Maintained36 focused controls pass, with their two existing exact diagnostic
  differences retained.
- `alias-binding-validation-04`: **46/46 paired observations exact**, covering23
  fixtures. The suite includes valid direct/applied/nested binding, nested
  rebinding, sibling aliases, constructor and binder patterns, family/template
  calls, dotted lambda spacing/comments/newlines/EOF, competing body failures,
  and the upstream reserved-lambda fixture. Reference and candidate workers each
  completed46 requests with zero failures or timeouts.
- `alias-binding-direct-04`: **16/16 direct controls pass** against pinned
  TypeScript name resolution at two disjoint positive source intervals. These
  protect lexical-versus-canonical collisions, nested scope, unbound ambiguity,
  and suppression of ambiguity by a real original-name binding.
- `alias-binding-demand-04`: **4/4 instrumentation controls pass**. Ordinary
  lambda and pattern controls make zero outer binding lookups; qualified
  controls exercise the lookup. The generated-code review prompted source04:
  eager Boolean guards in source03 had otherwise performed these lookups on
  ordinary terms. This is a removed-work assertion, not a timing result.

`alias-binding-audit-04.json` binds the final reports and artifact identities and
checks actual worker health. The paired harness intentionally reports
`selectedComplete: true` and full-suite `complete: false`; no full conformance or
performance claim follows from this local suite. Parent integration owns those
gates. A separately identified old boundary remains outside this handoff:
fresh qualified patterns without an alias still followed the existing plain-Ref
binder rule in source04. The separate [qualified-pattern follow-up](qualified_pattern_bindings.md)
subsequently corrects that boundary; source04 itself remains immutable.

All attempts remain. `alias-binding-source-01` is an uncompiled partial
preparation that stopped at an assertion after finding two template-head sites
rather than one. Source02 passed the checked build and20/22 paired observations,
but the two fresh-qualified-lambda observations exposed the acceptance gap;
it is unselected. Source03 corrected that gap and passed46/46 before source04
removed its unnecessary eager lookups. The unchanged baseline witness is in
`alias-binding-baseline-01`, and every consumed preparation/control tool is
copied into its evidence output.

Prospective plans:
[alias resolution](../../design/phase16/alias_lexical_bindings.md) and
[lambda cursor](../../design/phase16/alias_lambda_cursor.md).
