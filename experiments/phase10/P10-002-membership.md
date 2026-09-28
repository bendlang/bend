# P10-002 — Avoid unnecessary loader declaration-membership scans

Registered before probes, 2026-09-28. Owner: membership subagent; reviewer: root.
Bounded initial investigation: about 15 minutes. Correctness untested; measurement
not run; decision investigate. Report: [membership](../../implementation/phase10/membership.md).

## Prospective hypothesis

`f_alias_named` checks whether an import alias changed a name, then whether both
spellings are declared. Source Boolean conjunction is eager in the current JS
emitter: both declaration scans happen even when the first predicate is false.
`f_declared` similarly scans the entire recursive declaration tree even after a
hit. Hypothesis: lazy control flow at these two sites eliminates unnecessary
quadratic work without a new data structure. Try the alias guard first; count
membership calls and visited cells on public, valid module graphs with 4/8/16/32
ordinary definitions, then actual alias, ambiguity, constructors and missing-name
controls. Preserve each counter-modified image as observational, not deployable.

The original scanner is the exact membership oracle. Names, declaration order,
constructor nesting, qualification, error text, graph output, source origins and
public ABI must remain unchanged. The changed operation is an internal pure
membership query; unchanged alias names cannot be ambiguous by this predicate.
Untrusted malformed JavaScript object demand is a separate boundary to inspect;
never silently claim equivalence for arbitrary host objects or resource failures.

Stop if counts are small, a valid graph changes, a checked candidate does not
pass the default focused gate, or implementation exceeds this bounded task.
Reuse existing exact-name trie only if the lazy test is insufficient; do not
introduce symbol IDs or index source events speculatively. Historical
local `experiments/phase6/P6-016-membership-attribution.md` counts backend `has_name`
scans and is not evidence that loader `f_declared` has already been optimized.

## Controls and provenance

Baseline: frozen genuine Phase9 `integrated-03`, selected equality derivative
`d27968f11fa322bf3685ff0d276d9577a3b589b9cbae80784f5e4d404f7c3529`.
Node24.18.0, CPU1, 4MiB stack, 4GiB heap. Record actual source/API/runtime/Base,
harness and consumed fixture hashes before/after each run. No full-source timing
or broad suite. Counter runs are not timing samples; independent tasks may run
elsewhere. Any candidate is prepared in an isolated copied project, receives a
genuine checked B1 plus guarded equality derivation, and uses the standard
21-case focused differential gate. Root owns production integration and timing.

Fixtures include ordinary declarations, imported references, unchanged aliases,
actual alias replacement, ambiguity refusal, nested constructors, duplicate and
Unicode names. Compare complete public results exactly against frozen Phase9;
retain expected rejections and any known reference diagnostic differences.
Record all failed attempts and superseded candidates; never mutate the baseline.
