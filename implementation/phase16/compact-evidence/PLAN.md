# Scoped compact-compiler evidence preservation

Prospective plan; no archive or hashing sweep has run. Capture requires root's
explicit producer freeze after final timing, promotion, CLI smoke and reports.
This extends the existing wave7 tar/inventory/patch method. It does not replace
the prior capsules or claim that every Phase16 experiment is preserved.

## Scope

Use separately sized topic capsules:

1. Final compact source/build, all compact-final gates, final timing, promotion,
   smoke, installed release identities, final documentation and current tools.
   Include the literal/context prototype and its controlled cost comparison.
2. Compact literal experiments and earlier memo-key counterexamples, including
   failed sources/builds, controls, original logs and consumed tools.
3. Explicit Lambda metadata and canonical JSON memo experiments, including the
   failed metadata witness and encoder predecessors.
4. Contextual loading and program completion, including wave8/wave9 predecessors
   used by final history/projection comparisons and all scoped failed attempts.
5. Ordinary/marked empty-call pattern experiments and their negative evidence.

Freeze prefix expansion into an exact top-level selection before capture. The
inventory records every selected regular file or symlink, size, mode and SHA256.
Record every excluded Phase16 top-level entry explicitly with a reason; older
range/allocation profiles, unrelated diagnostic experiments and active parser
checkpoint proposals remain outside this bounded capture. No original files
are deleted. Previously committed tools/reports remain available even where
their ignored historical payload is outside this scope.

All current Phase16 performance tools and current phase16 design/experiment/report
files are included to preserve exact consumed versions and interpretation. Copies
already stored inside failed attempts remain separate. Inclusion of an old report
does not imply inclusion of every path it mentions. The final capture report must
state its external prerequisites and unresolved preservation gaps precisely.
Selections and custom fixture families consumed by included final gates receive
an explicit dependency review before the root freeze.

## Capture and recovery

Use deterministic regular tar members compressed with gzip, following wave7.
Split topics into parts bounded by uncompressed payload before compression, and
refuse any output reaching 99,000,000 bytes. Preserve a failed capture instead of
silently dropping or rewriting input. Hash input bytes before and after capture.
Safe relative fixture links may be preserved only if their normalized targets
are selected regular files, remain inside the fresh recovery root and have no
symlink ancestor. Absolute/escaping/unselected links and hardlinks are refused.
Record the literal target and its hash; do not silently dereference fixture links.

An independent recovery program verifies each immutable archive hash, checks the
exact member set/types, extracts regular files into a fresh temporary directory,
creates reviewed links last, then verifies all bytes and modes. It never uses an
archive member name as an unrestricted write path. Recovery records are separate
from the frozen archive inputs.

Save the final project delta against fixed committed Phase15
`a383163b821e38510967849fdb791ff914031b62`, not a moving HEAD. Reconstruction
starts only from that commit's files for the final project's exact membership,
applies the saved patch in a fresh directory, and checks every source/tool/test
byte and mode against the final inventory. New files start absent. The source
membership manifest intentionally excludes unrelated historical tooling absent
from the checked project. This produces the complete checked project rather
than copying unrestricted working-tree directories.

The pin remains `b2111cf43244e65f76ddc278ee695e669f720cbf`. Historical Phase15 and
earlier capsules, pinned upstream, Node and Clang identities are explicit external
prerequisites where referenced; extraction does not manufacture bootstrap
provenance or rewrite the original absolute paths.

## Required root inputs

Provide a final closed-producer freeze binding the exact final source/attempt/API,
timing report, promotion report, smoke report, consolidation report and release
commit. Expected final paths are `compact-final-matrix-01`, `promotion-03` (with failures 01/02 retained),
`compact-final-smoke-01`, and `implementation/phase16/consolidation.md`. Confirm
any additional selected or excluded family before the exact inventory freezes.
Only then run selection inventory, review size/dependencies/exclusions, capture,
independent extraction and committed-source reconstruction. Root reviews and
commits the resulting evidence; this owner performs no git writes.
