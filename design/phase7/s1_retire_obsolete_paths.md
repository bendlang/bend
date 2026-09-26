# S1: retire obsolete implementation paths

Status: ready for sequential implementation after [S0](../../implementation/phase7/s0-report.md).
Baseline source is unchanged from `fc509f4`: 16,509 / 13,803 lines/nonblank and
509,937 bytes. This phase changes no active algorithm or supported interface.

## Exact change

Apply only the complete declarations in the reviewed
[retirement inventory](../../implementation/phase7/s0-evidence/retirement.json):
53 unused functions, 35 laws and five exclusive types in eight modules. Verify
whole-module and block hashes before deleting inclusive ranges in descending order.
The expected result is **15,961 physical lines, 13,343 nonblank lines and 494,957
bytes**, removing **548 / 460 / 14,980** respectively. No replacement code is needed.

The retired mechanisms are recursive freshening superseded by the explicit work
stack; recursive/non-graph strong normalization and old comparison helpers;
unused flat-layout packing and its exclusive types; unused native traversal and
readback helpers; and unreferenced frontend convenience functions.

Retain `KNormFrame`, `norm_rebind`, the graph evaluator, comparison worklist,
`nl_c_type`, native word/segment types, public loader/origin APIs and all 54
maintained selected roots. The audit's external-root scope includes historical
tools and documentation. Undocumented all-definition library exports of deleted
private helpers will disappear; their removal is explicit, not public API drift.

## Execution and gates

1. Recheck S0's deletion inventory and residual references. Apply only those
   declarations, recount source and have an independent reviewer inspect the diff.
2. Build a fresh genuine checked B1 and its existing equality derivative with the
   maintained development workflow. Preserve logs, source snapshots and failures
   in a fresh `selfhost/build/phase7/s1/` attempt; do not overwrite the default.
3. Compare all selected roots and complete selected checked/derived API bytes with
   the baseline. Exact equality is expected for unreachable code removal. If it
   fails, identify why before any promotion; do not infer equivalence from counts.
4. Run the existing maintained focused controls and component checks, particularly
   graph normalization, deep freshening, declaration freshening, diagnostics,
   template checking and native identity. No new tests mirroring the deletions
   are needed. Actual selected API byte equality plus unchanged runtime/host gives
   stronger unchanged-runtime evidence than rerunning unrelated full workloads.
5. Once gates pass, install the validated attempt using the existing release
   installer, verify its source/lineage binding and run ordinary CLI smoke checks.
   Generated behavior, conformance observations and timing evidence may be reused
   only where exact consumed API/runtime/host identities are unchanged. The old
   full-source/fixed-point proof does not validate the new all-definition source.

No runtime speedup is expected: these declarations were already outside the
selected compiler closure. No new full-source timing is justified to claim one.
Source-wide self-reproduction is reserved for the representation integration and
final milestone, as specified by the overall design. If selected bytes change,
broaden the gates proportionately before deciding whether the candidate is safe.

## Deliverables and completion

Write `implementation/phase7/s1-report.md` with exact deltas, retired mechanisms,
review-context recount, roots/API comparison, checked and component results,
release identity and limitations. Retain small durable evidence and enough source
identities/commands to reproduce larger artifacts. Update the compiler guide,
README, experiment ledger and steering for the smaller usable source release.
Commit and push the completed phase before beginning S2.

The source line ceiling is 16,000. All source-size measures must decrease and the
review must confirm that only obsolete paths disappeared. Any live reference,
supported export loss, checking failure, unexplained output drift or component
regression rejects its deletion unit. Do not add other Phase 6 candidates to this
phase merely because they have earlier successful observations.
