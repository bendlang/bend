# P31-005: registration explains generic fallback overhead

[Prospective diagnostic](../../design/phase31/generic-registration-diagnostic.md),
[results](../../implementation/phase31/generic-registration-diagnostic.md).

The final07 row canary fails the original no-regression performance condition.
Hypothesis: registering unrelated optimized roots enables the existing exact-call
registry lookup for all generic calls in that module. An exact22-byte addition
to17 registers one unused callback without changing its row body or guards.
Independent full-state, alias, boundary and negative controls pass.

Frozen long confirmation reproduces96.97% of same-window07 excess. Registered17
and07 ranges overlap; both are slower than ordinary17 with disjoint ranges.
Causal diagnostic PASS; original no-regression performance condition remains FAIL.
The root selects07 under the explicit admission amendment, with both row and
separate zero-entry costs disclosed. No unsafe dispatch change is implemented.
