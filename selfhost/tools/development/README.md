# Checked compiler development

From `selfhost/`, run Node 24:

```sh
node tools/development/workflow.mjs run CONFIG.json NEW_ATTEMPT
node tools/development/workflow.mjs validate ATTEMPT SELECTION.json NEW_VALIDATION
```

A minimal configuration is `{"upstream":".bootstrap/upstream-phase8"}`. Paths resolve
against the configuration file. The first command freezes source/runtime/tools,
runs the genuine checked bootstrap and checks the existing 21 frontend witnesses
against pinned TypeScript. The second reuses that verified compiler for another
selection. Compiler edits need a new attempt; fixture-only edits can reuse it.

`"profile":"equality"` explicitly derives a guarded optimized API from the
untouched checked build. It writes a separate `api.mjs.derivation.json`, never
a copied bootstrap sidecar. The default profile is `"checked"`. Unknown equality
bodies or provenance are refused.

The CLI reports `pass` and `exactDifferences` separately. Custom acceptance/phase
oracles can pass while exact diagnostics differ; `"strictExact":true` also
requires exact agreement. Failed commands, verdicts and replay histories remain
available. An incomplete build cannot be reused as checked. A verified completed
build with interrupted validation can use `validate` into a fresh destination.

See the [development guide](../../../docs/PHASE5_DEVELOPMENT.md) for selections,
optional full frontend coverage, resources, artifact kinds and scope. Historical
Phase 3/4 timing wrappers under `tools/performance/` remain evidence tools; use
this entry for ordinary development. This entry does not replace backend
execution tests or checked self-reproduction when a change requires those gates.
