# Diagnose the checked-14 generic-runtime regression with an exact row

The complete original-program matrix must finish unchanged before this new
experiment runs. Its initial rows expose roughly 20–25% more time on several
programs outside the scalar region grammar. Correctness repairs and runtime
entry machinery changed together during Phase30, so those measurements alone
cannot identify a cause. Checked14 remains a candidate, with release on hold.

Use the already canonical `prototype-owned-source-01/row.bend`, whose scalar
`row.probe` allocates four fresh arrays and runs one edit-distance row. Emit this
same source with checked14 and Phase29, retaining full checked emission receipts.
Do not relabel an older output as checked14, even when bytes happen to agree.
Retain the pinned TypeScript emission from this exact source. The identical
adapter serializes all four 128-slot arrays; the independent retained oracle
computes every field for 28 combinations of length and seed. The timed point is
length 32, seed 17, as in the existing owned-row experiments.

First measure the unmodified Phase29 and checked14 modules. Add only separately
designed runtime-dispatch derivatives over the checked14 bytes, after their own
boundary controls pass. This experiment does not adopt the private row/cell or
native-array ladder: source, emitted public definitions and storage operations
stay fixed so runtime entry costs can be isolated. Each variant needs an exact
derivation showing all unchanged bytes outside its stated runtime edits.

Run the full 28-state oracle before timing and bind the independent ABI/effect
reports for each runtime transformation. Existing public raw/new/partial/overfull
application, live descriptor mutation, getter order and deferred forcing controls
must continue to pass. A fast row cannot justify weakening those semantics.

Freeze a new screen configuration only after all modules and gate reports exist.
The ordinary short screen determines whether the row reproduces the original
regression and whether a proposed mechanism is promising. A root-authorized
confirmation can use the retained row protocol; any evident warmup drift is
reported rather than silently changing the protocol. Confirmed microcase gains
still require checked compiler integration and selected original-program transfer
before release.

The alias/effect gate reuses `prototype-owned-controls.mjs` with exactly four
current-runtime modules: unchanged checked14, inline-exact dispatch, generic
constructor prebinding and their separately checked combination (if supplied).
The adaptation changes only the variant list and removes the original private
owned-region admission sentinel block, which tests a different optimization.
All 28 full-state points, handle/alias assertions and 257 paired boundary
observations remain intact. Phase29 is included in the independent state oracle
but is not the boundary reference because Phase30 deliberately repaired several
earlier scheduling defects. Ambient prototype differences must remain recorded
failures, not be normalized out of the observations.
