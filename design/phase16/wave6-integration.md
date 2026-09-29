# Integrate declaration, import and module-display corrections

Start from the accepted 48-difference wave5 (`kind-origin-build-01`), carrying
its invalid-binder and kind-origin corrections. Combine only the frozen local
declaration handoff, import handoff04 and module-name renderer02. Alias-binding
semantics and Base-prefix reuse remain separate experiments.

Declaration ownership is explicit: the new parser header worker and fillable
predicate replace the old `f_def` wrapper. Keep its duplicate/native/foreign and
colon checks. Add the import owner's fresh-alias diagnostic branch and named
law/type guard, preserving the final `nameTokens` parameter. Graph changes are
disjoint: one adds the structured ambiguity error, one retains resolved aliases
in the existing Loaded record. Preserve both. Hash every complete owner delta,
base input and output; save the complete integrated diff.

Build checked B1 with unchanged v5 and the maintained focus. Revalidate both
owner target selections against the integrated image. Then run the complete
adjacent frontend gate against wave5, protecting every earlier exact match and
all 2,996 primitive outcomes. Report counts only after this gate closes.

The import handoff has two explicit annotated-law wording differences and safe
fallback for two invalid astral-code-unit point controls. The module renderer's
shadowing control exposes a preexisting alias-binding semantic bug, tracked
separately; do not omit that control or call the candidate fully conformant.
Standalone, backend, history, performance and release gates remain outstanding.
