# Render global names in the diagnostic source module

The pinned TypeScript `err_show` chooses `err.spn.file`, then `name_show` removes
that file's own namespace first, or substitutes the first matching import alias.
The current compiler preserves canonical names but prints them without this
context. This accounts for the remaining `import/goal_alias` and `goal_own`
differences. Source text rewriting and renaming the AST before pretty-printing
would be wrong: a module's own constructor named `Nil` must not become builtin
list sugar, and diagnostic prose must not be rewritten.

Retain each module's already resolved alias list beside its namespace in the
existing `Loaded` trace record. Select that record through the first valid
numeric source interval in the diagnostic trail, exactly as source-location
resolution does. No term matching, source search, name-prefix ownership guess
or parsing of a synthetic definition name is permitted. An unavailable source
context retains the existing canonical display.

Extend the existing pretty-printer environment with a separate file-context
constructor. Local binder queries skip it and it does not contribute a binder
depth. Pass it through existing recursive pretty calls. Apply global-name display
only at Ref, ADT, removed-constructor, Ctr and Mat output sites, after canonical
sugar decisions. The Ref shadow marker compares the displayed name with local
binders, matching TypeScript. Type checking and normalization see unchanged terms.

Keep existing diagnostic rendering as the context-free API. Add an optional
loaded-trace rendering API used only after the ordinary source-origin validation
succeeds. Legacy images retain the existing path. The source interval, parsed
book, cache ownership and compiler capability checks remain intact.

Freeze a source snapshot and build a genuine checked B1 before paired controls.
Test both corpus gaps, alias declaration order, own-namespace precedence,
qualified data/constructors, global/local shadowing, a module constructor named
Nil, and ordinary builtin sugar. Compare complete books to prove rendering does
not change semantics. Run an adjacent full frontend gate before integration;
standalone loader and ordinary/relocated CLI checks remain release requirements.
Record source growth and any host delta. No success-path speedup is predicted.
