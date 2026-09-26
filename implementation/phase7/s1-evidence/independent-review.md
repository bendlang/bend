# S1 independent source review

Date: 2026-09-26. Reviewer: representation/frontend auditor, independent of the
S1 retirement inventory and patch application. **Approved as a source-level
retirement, subject to the S1 checked-build, selected-artifact equality and
focused-control gates.** No active-code safety blocker found. This reviewer did
not run builds, compiler executions or benchmarks and does not certify pending
release results.

## Scope and verification

Reviewed the complete `git diff -- selfhost/src`, the S1 design, S0
`retirement.json`, active callers and maintained export selection. The reviewed
source diff SHA256 was:

`399775a74b9e129b116bf5a4747a171c85722a6f3508f43a14d2a5f440563165`

Independent read-only inline Python checks:

1. Retrieved each original module with `git show fc509f4:<path>`, verified its
   S0 SHA256, deleted exactly the inventory's inclusive ranges in memory and
   compared the result byte-for-byte with the working file. **All eight modules
   match exactly**; no replacement logic or unrelated edit is present.
2. Recounted the unchanged 59-module manifest: **15,961 physical lines, 13,343
   nonblank lines, 494,957 bytes**. The delta is exactly **−548 / −460 / −14,980**.
3. Collected all 58 retired symbol names (53 functions, five types) from the
   inventory. Exact-token scanning of all surviving manifest source, including
   strings/comments, finds **zero references**.
4. Independently scanned **989 tracked or nonignored files** selected by
   `git ls-files --cached --others --exclude-standard`, restricted to maintained
   `selfhost/tools`, `selfhost/tests`, `selfhost/docs`, `docs`, root/selfhost
   READMEs and conformance contract, with code/config/document suffixes. Historical
   performance tools are included. **Zero retired-symbol references** were found.
5. Inspected `typed-driver.mjs`'s initial root list and conditional `exports.push`
   branches. Their static union is **54 names**, all still defined. The source
   conditions selecting those roots, manifest and ABI adapter are unchanged.

The scan intentionally excludes generated images, ignored build/bootstrap trees,
and archived implementation/experiment evidence. Arbitrary all-definition exports
of private removed helpers change, as explicitly declared by S1. A textual scan
alone cannot prove every possible computed external name; review of the actual
maintained export/dispatch construction supplements it. No supported dynamic
entry was found that synthesizes a retired name.

## Active contracts checked

- **Freshening:** `f_fresh_term` still delegates to `f_fresh_stack`, and
  `f_fresh_defs` to `f_fresh_book_stack`. `fresh_work.bend` is byte-identical to
  baseline, retaining the explicit term and declaration continuations, binder
  allocation order, old/new let environments and bounded host-stack behavior.
  `FFresh`, `FFreshDefs`, `f_rename_var` and public result wrappers survive.
  Deleted recursive helpers and `FFreshTerms` form the unused alternative.
- **Evaluation and conversion:** `strong` still delegates to `graph_strong`;
  `graph.bend` is byte-identical. Weak-head evaluation remains unchanged.
  `norm_compare` still uses exact comparison plus `norm_cmp_loop`. Crucially,
  **`KNormFrame` and `norm_rebind` remain** because active graph normalization
  uses them. No graph heap, sharing, evaluation frame or comparison worklist
  is removed.
- **Native generation:** only unused layout-packing types/functions and private
  traversal/readback helpers disappear. `N_WordKind`, parameters, frames,
  segments, constructor/program records and `nl_c_type` remain. The native
  emitter still calls `nl_c_type`; active `nc_show_program` handles readback.
  Native emit/show/parallel modules are byte-identical. CPU/Metal/CUDA segment
  generation and fork/join conventions are not replaced or weakened.
- **Frontend:** `f_statement` uses retained `f_typed_let_try`; string decoding
  uses retained `f_string_decoded` and `f_escape_code`. Removed `ff_next`, `f_dv`
  and replacement helpers have no remaining callers. Parser/error-order code
  receives no behavior repair in this phase.
- **Public loading/diagnostics:** `f_load`, graph/seed loaders and origin APIs
  remain, including the legacy fallback used by the driver and `selfcheck.mjs`.
  No source-provenance or structured-checker experiment was silently integrated.

The net conceptual reduction is supported: a recursive freshening protocol,
obsolete normalization/comparison alternatives and unused flat-layout packing
machinery disappear without a new representation, compatibility path or validity
rule. Merely removing unused convenience selectors is a smaller cleanup and is
not counted as another language-level concept.

## Accounting finding: transfer `f_dv` from S4 to S1

The frozen S0 representation audit counted `f_dv` within its **62-line S4
selector pool**, while S0's retirement inventory also included its **10 lines**.
The retirement inventory's caveat calling those pools separate was incorrect.
The current S1 diff actually removes `f_dv`; the measured 548-line S1 delta is
correct. Future planning must therefore reduce the S4 selector pool to **52**
and its named gross pool from **224 to 214**, rather than crediting those ten
lines twice. Root was notified and accepted the ledger correction. Retain the
original S0 evidence with a visible erratum; do not silently rewrite history.

## Approval limits

Approve this exact deletion-only patch for completion of the planned validation.
Source inspection supports preservation of maintained algorithms/interfaces;
it does not replace a fresh checked build or establish selected API byte equality.
Any lost selected root, unexplained artifact drift or focused regression must be
resolved before promotion. No runtime speedup, new conformance pass or full-source
self-reproduction is claimed by this review.
