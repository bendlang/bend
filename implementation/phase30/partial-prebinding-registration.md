# Partial prebinding registration cost investigation

Status: prospective isolated variants and controls are prepared; no acquisition,
semantic execution or timing has run. The final14 original-program matrix raised
a release blocker because several generic programs regressed against Phase29.
This report does not assign the regression to a mechanism before measuring it.

The [design](../../design/phase30/partial-prebinding-registration-ablation.md)
separates two hypotheses. The generic-delayed variant removes matcher1p entry
registration and prebinding, returning the original literal-arm bounce. The fused
variant keeps registration and permission exactly, but exposes the unchanged
matcher body through a literal destructured-parameter IIFE inside the fresh public
arrow. It removes shared enterExact dispatch for this callback only. Neither
variant changes emitted definitions, ordinary apply, scalar workers or guards.
The analysis agent's separate ordinary invokeExact inlining experiment remains
independent; gains must not be multiplied or combined before isolated results.

Partial arity is insufficient to skip permission safely. The previously retained
`selfhost/build/phase30/review-prebind-entry-01/report.json` already uses two fields
and a three-argument arm. Eager field copying moves a foreign slice before outer
copied-length effects and changes raw callback bounce shape. The generic variant
therefore restores the complete original delayed application; it does not merely
return a prebound partial on every entry.

Prepared tools:

- `review-prebind-generic-derive.py` binds a checked actual14 emission receipt,
  its selected attempt/API/runtime/Base/driver/input and the prospective design;
  saves all three modules plus runtime cores; and verifies exact inverse edits
  and an unchanged generated suffix.
- `review-prebind-variants-controls.mjs` requires generic/literal-reference and
  fused/current14 semantic agreement, recording every generic/current14
  difference separately instead of treating14 as the correctness definition.
  Its 97 planned cases cover malformed vectors, copying and errors, raw and
  oversaturated scheduling, callable shape, saved partial hooks, and reentry.
- `review-prebind-prototype-diagnostic.mjs` preserves every one of 24 ambient
  prototype cases, including throwing hooks. It requires generic/original and
  fused/current agreement while separately recording all generic/current
  differences. It makes no full ambient-prototype equivalence claim.

The retained seven prebinding witnesses, independent public cell controls,
scalar ABI/entry suites and full four-array row oracle/alias/boundary harness are
also planned. The prototype owner will bind the latter to the same new checked14
row emission used by all regression variants. Phase29 participates in numeric
row comparison; its known older runtime scheduling defects remain separate.

Acquisition and timing await the lead's explicit release of the exclusive
original-program measurement window. Compiler/runtime source remains unchanged.
