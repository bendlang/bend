# Conditional maintained return-statement lowering

This proposal is conditional on `general-tail-let-promotion.md`. It is not a
production edit. The current disposable rewrite proves a representation is
worth testing, not that a particular compiler routing has the same coverage.

Decision after `general-tail-let-long-confirm-01`: **defer**. The generic owned
row improves only 2.31%, and the whole-program gain is not isolated beyond the
already accepted private-helper-only attempt14 change. No source acquisition
or maintained generic emitter change is authorized by this proposal's
existence. The source fixture and control tool below remain prepared,
unexecuted future work.

Generalize the existing `j_region_return` to `j_return(book, env, term, type,
tail)`, preserving one implementation. Ann recurses with its annotation; Let
uses the existing two nested blocks, `j_nat_loop_values`, `j_nat_loop_names`,
`j_context` and `j_body`; the terminal case returns `j_expr` with the supplied
tail flag. Private helper emission passes False exactly as attempt14 does now.
The non-Lam terminal branch of `j_lambda_code` calls `j_return(..., True{})`
instead of constructing `return j_expr(..., True{});` itself. Lambda parameter
slot reads, erasure, callback shape and matcher construction are unchanged.

Do not broaden other expression boundaries initially. RHS expressions,
deferred constructor fields, curried descriptor construction and lifted factory
expressions continue to use `j_expr`. Existing specialized loop/tree transfer
statement emitters remain responsible for their own final transfers. Cold
guard fallbacks can remain expression returns. Because this is a subset of
the disposable AST rewrite, remeasure actual checked output rather than
transferring the prototype's ratio.

Reuse `j_nat_loop_values` but spell its initializer as `(0,(EXPR))`. The erased
branch still emits null and never evaluates its RHS. This small spelling
change prevents named evaluation for anonymous functions/classes without
needing a permanent proof that every current and future `j_expr` branch is
incapable of returning a bare anonymous definition. It introduces no value
conversion, effect or forcing. It affects existing private/loop statement
spelling too, so complete checked-output semantic and timing gates are needed.
The current expression emitter mostly produces fn/matcher descriptors or
calls rather than bare JavaScript functions, but relying on that incidental
property would be a less stable invariant than the comma initializer.

The helper's `$v<number>` temporaries are safe in this scope: generated Bend
locals use `x<number>`, all values execute in the old environment before the
inner alias block, and each nested Let creates a fresh outer block. All aliases
are immutable. Nested/escaped closures retain the same per-invocation values.
`j_nat_loop_values` and `j_let_values` use the same qt==0 erased-RHS rule and
the same original environment and absent expected type for live RHSs.

Expected maintained cost is roughly 3–8 net lines: rename/generalize one
existing helper, supply the flag at its existing private caller and new generic
caller, and wrap one initializer spelling. There is no new IR, runtime state,
region admission, AST postprocessor or second Let lowerer. If moving the helper
from region.bend to emit.bend improves ownership, perform that as a move with
unchanged behavior, not a duplicate implementation.

Before promoting a genuine candidate, acquire the proposed
`controls-return-lets.bend` with both checked predecessor and candidate. It
exercises parallel and nested bindings, old-scope RHS capture, returned
closures used after later compiler calls, separate factory invocations,
record-held deferred closures and a public higher-order callback that mutates
live bindings between two RHS evaluations. Validate independent numeric
oracles and exact ordered host traces, including a throwing second callback.
Also retain the 25 independent JavaScript witnesses for anonymous names and
lexical this/arguments/new.target that Bend source cannot directly express.

Inspect actual emitted modules to prove intended tail Let boundaries changed,
runtime bytes and public callback name/length/kind stayed fixed, deferred field
thunks remain deferred, and unsupported expression-position Lets remain valid.
Run the original ten output gates, actual owned-row full-state/alias controls,
scalar/ordinary/tree ABI and entry controls. Benchmark the checked maintained
candidate against its predecessor in the same declared row/whole windows.
