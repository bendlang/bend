# Preserve a bare family reference until checking

Prospective bounded frontend correction. The existing checker already rejects
a Ref to a parameterized datatype with the pinned structured family-instance
message. Delayed scope currently converts that Ref into an empty ADT application,
so the checker instead reports a parameter-count error. It may also implicitly
fill quantities for an invalid bare quantity-only family.

Keep an ordinary bare family as Ref when its declared arity is nonzero. Continue
converting zero-arity datatype names into ADT as required by the current core.
Explicit angle applications and the separate marked +D path retain their existing
elaboration. This needs one predicate and no new term or checker behavior.

Before promotion, compare bare ordinary and quantity-only families, explicit
applications, +D quantity inference, lexical shadowing and zero-arity datatype
controls against pinned TypeScript. Include the original family_head_bare test,
the maintained 36-case gate and final full-corpus regression gate. Preserve
failed control assumptions. Root owns only the f_scope_reference predicate in
front/families.bend; source-range owners may separately preserve its locations.
Expected code size: no added physical lines or definitions; one arity test.
