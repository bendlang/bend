# Accepted wave7 checkpoint

`checkpoint.tar.gz` preserves 917 files (67,062,038 uncompressed bytes), including
the isolated source, checked compiler and v5 derivative, bootstrap records,
maintained focus, full frontend results, combined controls, direct alias checks,
comparison vectors and custom Bend fixtures. The manifest records every size
and SHA256. Independent extraction and hashing passed for every member.

The accepted result is **18 exact frontend differences**, down from24 on wave6,
with no lost match or changed primitive outcome in2,996 observations. The159
combined controls retain only two imported-law wording differences;16 direct
alias controls pass. Production remains Phase15. Timing, history, backend and
release gates for this changed image are still required.

`phase15-to-wave7.patch` captures the complete source/tool delta. The independent
recovery tool reconstructs the source from committed Phase15 files and this
patch, then compares every file with the saved inventory. Its result is in
`patch-recovery.json`. Both preservation tools are under
`selfhost/tools/performance/phase16/`.

Extract the archive into a new temporary directory to inspect it. Entries use
repository-relative paths. Original provenance/report paths are intentionally
unchanged: extraction does not create a new checked bootstrap or rewrite the
recorded identities. For a fresh compiler build, use the extracted
`selfhost/build/phase16/wave7-source-01/project` as the project in a new
[development-workflow configuration](../../../docs/PHASE5_DEVELOPMENT.md), with
the unchanged pinned upstream checkout and a fresh attempt directory.

This capsule covers the accepted wave7 checkpoint, not all Phase16 experiments.
Earlier failed attempts, large profiles and later active candidates require
separate preservation; no broader archival-completeness claim is made.
