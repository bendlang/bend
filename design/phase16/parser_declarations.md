# Declaration eligibility before parameter parsing

The pinned TypeScript compiler classifies a name before reading its parameter
list. An open, non-native law can be filled once. An existing definition,
foreign implementation or native claim is already closed and fails at the name.
The Bend parser currently waits until after the telescope, then emits a generic
unlocated refusal. An absent law for an untyped definition also loses the
already available post-telescope cursor.

Use one declaration-header worker that receives the existing lookup result.
It rejects locally closed names through the existing fpe_word builder before
reading parameters, and passes eligible declarations to the existing fill logic.
Remove the redundant old f_def wrapper rather than introducing a second lookup.
Retain the import owner's final nameTokens argument on f_def_prior. Use existing
fpe_error at the post-telescope cursor for a missing return arrow and the colon
required when filling a law. Do not add U32 or any Base name to the keyword list.

Scope: front/declarations.bend and front/validate.bend. No host, graph, cache or
KDef layout change. Imported-name conflicts still require a separate solution:
the parser starts with an empty local declaration book, and graph validation
currently finds those conflicts after parsing the entire module. This bounded
change must not claim to fix that ordering problem.

Freeze source from wave4-source-02, check with pinned upstream and the maintained
focused selection, then compare four fixtures in both parse/check lanes:
comptime/err_dup, parse/foreign_refill, parse/def_untyped_refused, and
parse/law_fill_arrow. Direct paired controls distinguish open-law fills,
completed-body repeats, completed-foreign repeats, malformed repeated headers,
unknown names, legal fresh U32 without Base, and real reserved keywords.
Keep all failures and exact raw vectors. Parent owns full-corpus, integration,
performance and promotion; this stage makes no independent speed claim.
