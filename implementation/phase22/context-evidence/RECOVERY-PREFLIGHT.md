# Pre-write recovery bounds

Independent review found that the first unexecuted bounded-recoverer draft only
checked a part's total size after extraction. Preserve that draft and its original
metadata under `bounded-recovery-preparation-02`; it was never used for a capsule.

The consumed correction checks each archive's declared regular payload before
creating extraction scratch, requires every actual member to belong to that
archive's declared set, and checks cumulative payload before opening each output
file. The original path, type, hash, mode, link and source reconstruction checks
remain. Current identities and the complete Phase16-relative diff are in
`bounded-recovery-adaptation-02.json` and `recovery-adaptation-02.patch`.

The actual corrected executable passed all 19 synthetic policy controls in
`bounded-recovery-policy-01`, including real cross-part link restoration, mode
checks, separate checked/derived API lineage and Git-plus-patch reconstruction.
The other 18 inputs were refused as expected. The over-budget part refuses during
preflight; the wrong-part member refuses before writing. The older file-ancestor
fixture happens to refuse earlier at its unselected link target, so this result
does not independently isolate that ancestor predicate. No production capsule
has been captured or recovered at this checkpoint.

The preceding amendment still governs scope and disk accounting. No failed input
or raw result is excluded. The recoverer is frozen after consumption; further
corrections require a new version and retained prior evidence.
