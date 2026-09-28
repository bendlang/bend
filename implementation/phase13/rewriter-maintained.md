# Phase13 self-contained helper feasibility

The [prospective integration design](../../design/phase13/integration.md) requires
one maintained helper with Node builtin imports only. This bounded feasibility
work keeps all production files untouched. It removes the prototype's dependency
on a complete imported historical helper and shares one module/function view,
argument splitter, arrow/choice recognizer and source-range renderer across the
existing and proposed passes.

The original scalar dependency profiles, historical/runtime hashes, export ABI
checks, bootstrap provenance, snapshotting and derivation verification remain in
the file. Module recognition accepts the selected historical runtime profile.
Versions 1–5 retain their original paths; proposed profile 6 runs the constant-scope
selector pass for exactly the six accepted checking owners. Rejected worker
lifting is absent. A separate replay probe must reproduce every authentic old API
and exact serialized statistics, then reproduce the combined experimental image.

`selfhost/build/phase13/rewriter-maintained-01/preparation.json` binds the generator,
all source fragments and the prospective design. The prepared helper is
`project/tools/development/equality.mjs`, initially 535 physical lines / 519
nonblank lines / 34,355 bytes, including historical data. The released helper is
296 physical lines / 285 nonblank lines / 27,345 bytes; the prototype's full
imported dependency cost is separately recorded. Sharing recognizers removes
duplicate machinery but does not establish a physical-line reduction. The actual
increase is 239 physical lines and 7,010 bytes (25.6%). No minification or
formatting-only gain is claimed.

## Exact replay result

The prepared helper
`cdf6d41c68b79d77b120ab6e367c2805a94c512338c5672afee21144c49df6d4`
passes Node's syntax check. The isolated
[replay tool](../../selfhost/tools/performance/phase13/rewriter-maintained-replay.mjs)
records passing compatibility in
`selfhost/build/phase13/rewriter-maintained-replay-01/report.json`:

- Authentic versions 1–5 pass both old and new derivation/lineage verification.
  Every generated API byte and exact `JSON.stringify(stats)` result matches the
  original artifact and maintained historical transformation.
- Default and explicit version 6 produce identical source/statistics and reproduce
  `7eca544a1f2e3ab637064533117f290bd576c5774d111a619fdd12755817c81e`,
  the six-owner selector image. The selector report matches the experimental
  implementation's lower-pass report exactly.
- The complete helper imports only five Node builtin modules. All historical
  profile data and provenance logic are included; imported historical helpers
  and external parser dependencies total zero.

The helper uses one top-level module/function view for scalar equality, literal
choice lowering, leaf lowering and selector fusion. One argument splitter,
literal-arrow recognizer and source-range renderer serve the structural passes.
The old independently coded module/arrow/render implementations are removed from
this file; rejected branch-worker lifting is absent. This is a concrete sharing
result, not a claim that the entire maintained compiler became smaller.

## Decision and limits

Root defers production integration. The combined image's controlled 10.555%
process improvement does not meet the roughly 20% target, and the self-contained
helper still grows despite sharing recognizers. The current Phase12 release,
maintained helper/tests and Bend source remain unchanged.

This bounded replay is not a fresh checked build, complete frontend/backend gate,
run of all maintained mutation tests, installation or release verification.
Those conditional integration gates were deliberately not launched after the
performance/complexity decision. The valid experimental images, helper and exact
compatibility evidence remain available for future work.
