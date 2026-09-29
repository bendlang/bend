# Preserve the lambda eligibility cursor while deferring dotted names

The first alias-binding candidate resolves all ten valid/refusal fixture pairs
except the deliberately frozen fresh dotted lambda. TypeScript checks the
original lexical stack first; a fresh dotted name is a Ref and cannot introduce
a lambda, while an already bound dotted name is a Var and may be rebound. Its
failure cursor is immediately after the consumed `=>`, before parsing the body.

Use the existing operator-end cursor, not reconstructed source arithmetic.
Ordinary valid lambda binders stay ordinary Lam nodes. Only a syntactically
qualified binder gets a transient FLambda with its body, original reference and
an explicit LambdaCursor child. The alias pass already traverses children, so
the original reference receives the same deferred alias/ambiguity alternative
as an ordinary use. The authoritative scope pass first checks the original
spelling in its existing environment. A bound name uses the ordinary lambda
lowering. An unbound name preserves an earlier alias ambiguity if present, or
returns the existing structured point failure at LambdaCursor. No new scope walk.

An immediately invalid binder such as `Type => Type` can use that same point
failure directly in the parser; it needs no deferred node. Preserve the body
error for ordinary valid lambdas, but allow the exceptional invalid/qualified
binder to select its earlier error before a parsed malformed body. This extra
eligibility correction is recorded separately from the alias capture correction.

Freeze source03 as a delta from source02. Verify genuine bootstrap and36 focus,
the original22 paired observations, the reserved_lambda_binder corpus fixture,
and direct cursor boundaries: spaces, comments, newline, EOF and competing body
errors. Include bound dotted rebinding and canonical dotted names without alias.
Exact failures remain retained. Root owns whole-corpus and performance gates.
