# Declaration and namespace checkpoints

This extends the Phase22 plan after the first production candidate exposed
shared chronology errors. Original candidate vectors remain immutable. No
candidate is promoted on smaller-suite gains while broad regressions remain.

An implicit operator is a Ref whose last dot is at offset zero, exactly as in
the pinned compiler. A relative canonical name is not an operator. Share this
predicate between namespace application and final unresolved-operator refusal.
Namespacing visits the tail of Let and the arguments of an operator, Bool.and,
Bool.or or String.append. Arbitrary function-call arguments are not implicitly
namespaced by annotating the outer call.

Namespace resolution errors use the actual checkpoint cursor, while successful
operators retain the original operator range. Array and index namespace steps
run after the closing bracket; their cursor is the previous token end. Group
namespace steps run before consuming the closing parenthesis; their cursor is
the current skipped input. Invalid namespace *types* are structured errors at
the type's source span, distinct from resolver ambiguity errors. Do not infer
any of these from descendant spans or from the next token's start.

After body flattening, a group may accept a namespace annotation and then its
closing parenthesis. It must not re-enter tuple grammar: a body such as a local
binding is not made into a valid tuple by flattening it first. Completed nested
groups still participate in surrounding expression grammar.

Unresolved operators must fail at declaration completion, after any enclosing
namespace annotation can act and before requesting later declarations. The
reference eagerly forces completed bodies, but some signature children are
higher-order closures. Independent competing-error cases must establish the
signature demand order before applying an eager whole-tree signature check.
Reuse existing error and completion traversals where their demand contracts
match; do not maintain a second resolver or infer lexical state from positions.

The first checked migration may retain a small explicit completion validator.
The ABI2 cleanup should fuse or remove duplicated traversals once their ordering
is demonstrated. Removing raw-loader consumers is the prerequisite for deleting
old scoping/flattening/counter replay without sacrificing the user-facing CLI.
