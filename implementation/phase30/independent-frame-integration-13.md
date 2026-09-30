# Independent checks of attempt13 frame reuse

The source diff in `back/js/tree.bend` matches the proposed two emission helpers:
reuse only inactive depth storage, overwrite every saved parent slot and reset
phase/left, and pop by decrementing logical top. Left argument evaluation stays
before the push; right arguments still read the active parent's immutable saved
state. Admission, budgets, helper analysis and runtime are unchanged.

The actual checked attempt13 API passes `review-tree-admission-13`: 31 synthetic
backend books and 96 executions, including noncommutative combination, different
child states, refused malformed/cyclic shapes, helper budgets and depth checks.
`review-tree-boundaries-13` adds 85 ordered prototype/metadata/copied-length
observations against actual12.

An attempted repeated terminal-budget acquisition ran out of filesystem space
while writing its evidence. `review-terminal-bounds-13` is retained as partial
ENOSPC evidence. After the parent's verified temporary-file recovery, a fresh
adapter regenerated and byte-compared the old synthetic books, then hard-linked
their immutable bytes instead of duplicating approximately 408 MB. It passed
seven unchanged budget cases in `review-terminal-bounds-13b`. That run had
already started when the parent correctly directed reuse of unchanged-budget
evidence; it completed before the termination attempt found no running process.
No further unchanged admission/budget suite is repeated for the new API label.

The prototype owner's separately executed actual13 inherited numeric, depth,
frame-count and ordered-boundary gates are recorded in the frame report. They
are distinct from these independent reviewer runs. The resource interruption
was a filesystem-capacity failure, not a compiler semantic failure.
