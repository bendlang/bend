# Independent do-boundary baseline

Twenty frozen parse/check observations completed on installed Phase21 API 44094e58 against pin b2111cf. Seventeen are exact. Three retained primitive differences reveal two additional existing defects:

- An actual imported `Box.Id` header parses on both sides, but the installed checker rejects an undefined `Box.Id.bind`; TypeScript accepts the program. This combines a typed `=` assignment followed by a typed `<-` bind through a real imported module.
- A typed-bind RHS containing `)` before a later return selects the pinned parser error at that `)`. Both installed lanes instead fail during loading with `Invalid compiler source range`. This is a failure-transport/source-range defect, not an acceptable parser rejection.

The other controls are exact: padded leading quantities and their refusal range, untyped discard binds, implicit Unit steps via newline/semicolon, RHS lookup before same-name binder opening, repeated nonbinding `_`, terminal value annotation, a later return syntax error, and parenthesized binders following astral comments. There are no new mistaken acceptance assumptions. The reused pinned negative fixture has an `observed` parse verdict; it is not counted as failed.

Inputs are frozen at `selfhost/build/phase22/context-controls-do-inputs-01`; complete raw outcomes are at `context-controls-do-baseline-01`. `context-controls-do-baseline.json` binds all fixtures, the imported module, plan, tools and complete observations. The original main `monad_do_destructure` remains in the earlier 60, unchanged; this cohort does not replace it. No previous fixture/oracle/report was modified.

All CPU2 jobs are closed. No compiler source, build, API, production file, archive or git state was changed. These public outcomes do not claim exact positive-term span equality; the implementation owner retains that independent structural gate. A future candidate must fix the actual header-resolution and failure contracts while retaining all 17 exact neighbors.
