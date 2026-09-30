# P30-006 — Reuse constructor-arm prebinding for exact saturation

Owner:root. Independentreviewer:phase30_review. Started2026-09-30.
Correctness:not run; measurement:not run; decision:investigate.

[Prospective design](../../design/phase30/exact-constructor-arms.md) specifies
count==arity extension with unchanged runtime matcher1p, publicarity and body.
Separate from private worker calls and owned vectors. First ablate only the
5edit-distance cell arm prefixes, preserving all operations and callsites.
A semantic difference or clean regression rejects promotion; additional native
names or weaker identity/erasure guards are outside this experiment.
