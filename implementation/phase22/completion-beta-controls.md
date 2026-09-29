# Direct completion beta and demand review

The actual compiled `f_context_validate_operators` from context-build-05 matches the pin in 15 of 17 frozen direct controls. The suite remains failed; no source was changed and no compiler was built. A private append-only export preserves the entire checked API byte prefix and has a distinct retained artifact identity.

One semantic metadata mismatch is confirmed. The pin copies a variable occurrence's source span to an unlocated substituted argument, except negative variables. The candidate returns that unlocated Ref unchanged (0/0 instead of 20..21). Already-located arguments preserve their own 30..31 range correctly, and the negative-variable sentinel remains unlocated correctly. Whether ordinary parsed programs supply an unlocated argument at this point is not established by this direct test.

The second failure is extra direct demand: `f_context_material_next` reads the tag of a deliberately deferred lambda body to test `Error`, even when beta reduction discards the whole lambda argument. A poison getter observes that read; the pin does not read it. The natural counterpart with an implicit operator in the discarded body passes, so this is not reported as a demonstrated source-program regression.

Distinct-ID nested shadowing/outer references, absent and zero lambda quantities, ordinary discarded bodies, eager argument precedence, constructor sibling short-circuiting, All/Let eager versus deferred order, and Let occurrence ranges all pass. Successful output comparison preserves names, quantities and spans and uses only bound-ID alpha-equivalence with free IDs fixed. Candidate output is never evaluated through TypeScript to manufacture equality; the original candidate graphs are retained.

Evidence: `selfhost/build/phase22/completion-beta-controls-01/report.json`, private extension and consumed tool; fixtures/freeze in `completion-beta-inputs-01`. The process closed with exit 1 for the two reported failed controls, a completed 17-row report and no top-level harness error. No timing claim.
