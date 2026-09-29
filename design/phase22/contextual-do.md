# Contextual do expressions

This is a production grammar slice within the Phase22 frontend migration.
It replaces do's delayed lexical interpretation at its producer; it does not
special-case the maintained destructuring fixture.

Follow pinned `parse_term_do_stmt` in this order: return, term, optional typed
binder, implicit Unit step, typed assignment or bind arrow, RHS, one optional
semicolon, binder opening, continuation, binder closing, then generated call.
A terminal untyped expression returns its monadic annotation and leaves a
following `=` for the enclosing body grammar. That body's actual pattern
checkpoint must reject the resulting computed do expression before consuming
a later return. A do binder uses parse_bind, not constructor-pattern validation.

In contextual mode names are FName/Var syntax values, fresh binder IDs come
from FContextual, and monad/global names use the shared resolver. Resolve the monad name immediately after consuming `<`, before requesting any
type argument. Carry that result to the fill checkpoint rather than resolving
again after the arguments. The packed `<>` token still has the cursor just after
its first character for this decision. Type arguments are filled at the header
against the declaration visible there. Scope closes
before generated bind/pure resolution. Use the existing shallow syntax/value
projection and final freshener; never rescope a completed do subtree.

Emit App/Ann/Let directly in contextual mode. Keep the same statement grammar
for legacy raw callers until their production callers migrate; that route may
retain FDo as its existing representation. Preserve original statement start
and returned cursor explicitly for synthetic source ranges, including grouped
binders, comments and semicolons. A do error must remain shallow and prevent
later syntax from being requested.

Independent controls cover typed assignment/bind, untyped bind/Unit steps,
terminal annotation, parameter shadowing, repeated underscore, lexical capture,
header alias/quantity fill and earlier-RHS/later-body errors. Check the original
main do fixture, not a rewritten expectation. The slice is incomplete until
the production body checkpoint, checked build and exact controls agree.
