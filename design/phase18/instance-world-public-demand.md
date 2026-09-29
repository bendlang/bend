# Phase18 stable payload: preserve diagnostic field demand order

The frozen source04 raw-public gate completed 18 controls: 17 pass. Its nested
KChecked pattern reads `term` before `error`, while the historical public
specialized_diagnostic reads `error` first. A payload whose two required fields
throw different sentinels makes this difference observable. Normal diagnostics
and all unused-field controls pass; retain the exact failed demand control.

Source05 adds a stable `sp_payload_error(KChecked) -> String` projection, used by
specialized_error and by specialized_diagnostic. The latter first matches the
outer result, binds its error string through this projection, and only then
matches the term field for the shared renderer. This preserves book/payload/error/
term demand order without reading the outer payload twice, duplicating a renderer
or manufacturing a world. No record layout changes and no semantic checking
changes are included. Repeat the same immutable 18-control public tool, then the
42 transport/demand,22 outcome and8 memo gates on the final candidate.
