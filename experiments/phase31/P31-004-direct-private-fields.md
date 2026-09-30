# P31-004: direct reads of proved private fields

Retrospective index of the separately frozen [field-read design](../../design/phase31/direct-private-field-reads.md); the design and input receipts preceded implementation.

Checked07 retains the proved input type in its existing unpack plan. Canonical Sigma uses indexed reads; ordinary closed records use their field vector. All fields are snapshotted in order before the arm runs, with no public representation change.

Independent full-pair, alias, nested-record, empty-record, marker and exact-entry controls pass. In the [same-window ablation](../../implementation/phase31/local-data-ablation.md), this step removes 62.50% of checked06 full-pair time and 49.46% of fold time, with disjoint ranges. The complete pair loses 328,450 generic projections while preserving all 328,966 native operations and physical handles.

Decision: selected for final integration, subject to the disclosed fallback-regression investigation, original-program transfer and release gates. This does not remove producer tuple allocation, prove arbitrary public field equivalence, or establish universal backend conformance.
