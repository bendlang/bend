# P16 parser names — stage 3 prospective supplement

Frozen before parser-source-04 preparation or execution. Source03 remains the
corrected stage2 candidate; source02 and its surrogate-construction failure are
retained.

Use one explicit name-error producer for keyword, malformed dotted lexeme and
missing-name diagnostics, based on actual lexer tokens. Apply it at declaration,
parameter, quantified binder and do-header boundaries. Law/type header validation
keeps the original name cursor before checking local freshness. Reuse stage1
source ranges for complete names. Preserve the first structured error through
binary/let/equation construction rather than hiding it in a successful outer
node and later producing EOF. Tighten the existing quantified binder's required
colon and arrow expectations to the pinned parse order.

Files may change front/{parser,declarations,validate,sugar}.bend; no checker, host,
metadata ABI or renderer edit. Input source/source order and local declaration
book determine diagnostics; never fixture identity or legacy-error parsing.
Imported/global duplicate origins remain deferred to the shared span path.

Before broadening: genuine checked B1,36 focused controls, inherited+range direct
controls, additional exact name/keyword/duplicate/precedence witnesses, and the
122-fixture paired parser census. Require all earlier exact controls to remain
exact and no corpus behavior-axis change. Any newly exposed parser acceptance
boundary must be explained against pinned TypeScript rather than hidden.
