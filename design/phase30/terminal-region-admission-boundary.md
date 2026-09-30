# Initial terminal-record admission boundary

Implementation amendment to
[the terminal region plan](terminal-region-compiler-extension.md), frozen before
compiler changes. Independent review recommends narrowing record fields to
immutable scalar variables and scalar literals. Adopt that restriction initially.
The measured `Hl` result uses only variables, so computed field expressions have
no demonstrated benefit for this experiment.

The constructor remains an ordinary delayed `build` with the original field
thunks. Its type must be a parameterless, unrefined, nonnative single-constructor
Data, and its complete local constructor telescope must contain at most 32 live,
nondependent scalar fields and return the same owner. A terminal constructor's
field count must match. A field may be a scalar variable, a native U32/Nat literal
or a native Boolean constructor with no arguments; no application, Let,
projection, record, or other computation occurs in a deferred field.

Keep record values out of parameters, intermediate bindings, private helper
results and carried state. Check scalar RHS and argument types explicitly before
using the broader terminal expression recognizer. Existing scalar type validation
and annotations still apply to every allowed field.

Nested private loops retain scalar results and the existing single-predecessor
self-tail proof. Their analysis shares the caller's active names, completed
helper cache, depth and fuel. No fresh analysis state may be started inside a
nested helper. Both arms must succeed before the helper is cached.

The first candidate combines this admission with the separately validated lexical
helper spelling. Keep attempt08 as the spelling-only control, then build a fresh
checked attempt for this extension. Compare actual emissions and controls at both
boundaries. Reject rather than widen any unanticipated checked shape; record
failed acquisition and refusal evidence before changing the plan.
