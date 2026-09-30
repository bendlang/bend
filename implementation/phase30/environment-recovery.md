# Disk-full interruption and verified recovery

The host filesystem filled during actual13 validation. It reported zero
available bytes on a roughly 1.8 TB volume, with only 4% of inodes used. The
repository's build tree occupied about 23 GB and the active Phase30 tree about
852 MB. This was a capacity failure, not inode exhaustion or a compiler verdict.

All workers stopped. The partial `transfer-13` acquisition, its outer launcher,
the interrupted source-tree13 control and the independent bounds13 output are
retained. Some writes are empty or incomplete because of ENOSPC; they do not
count as successful gates. A later sandbox launch also failed before starting
the intended control process. Successful completed receipts remain separate.

Read-only diagnostics needed the approved unsandboxed route because sandbox
mount setup itself required unavailable disk space. Recovery considered only
two named old Bend temporary extraction directories:
`/tmp/phase23-independent-recovery-01` and
`/tmp/phase24-independent-recovery-01`.

Before removal, the cleanup verified that each preserved archive was tracked
by Git and matched its committed manifest's complete archive SHA256 and size.
Every removed temporary file then matched the corresponding manifest member's
path, size and SHA256. It removed 55,119 plus 20,503 duplicate files, totaling
774,304,305 logical bytes; directory/file allocation released about 900 MiB.
No unmatched files were found. This was a manifest-and-archive identity check,
not a new decompression experiment.

The original raw evidence, committed archives, current experiments, compiler
source, unrelated workspace changes and other projects' temporary files were
left intact. The complete removal receipt is
`selfhost/build/phase30/cleanup-recovery-temp-01.json`; recovery from the retained
archives remains possible. Available space returned to 918 MiB, and bounded
acquisitions resumed. Interrupted checks use fresh directories, including
`transfer-13b`, without rewriting earlier failure receipts.
