# Bounded recovery v2

The consumed `context-recover.py` and its19 synthetic controls remain immutable.
No production capsule has used it. A fresh `context-recover-v2.py` addresses the
independent review before capture. Its27 controls run the actual executable on
small retained capsules; all reports, stdout and stderr are outside the capsules.

The complete reconstructed Git-plus-patch tree is checked with lstat before any
chmod: every source inventory member must be a regular file, all actual members
and ancestor directories must match the expected source membership, and symlinks,
broken links and special files are refused. A patch-created source symlink points
to an outside synthetic sentinel; refusal must preserve both its bytes and mode.
An extra broken symlink must also be refused even though is_file would miss it.

Exact nonnegative integer inventory sizes are required before any sum. Retained
cross-part targets plus checked/derived artifact lineage have a fixed8,000,000-byte
payload cap checked before scratch creation. The final build16 lineage currently
uses2,074,272 bytes; the eventual inventory must also fit all selected link targets.
Each part remains bounded by38,000,000 regular payload bytes and each compressed
archive by40,000,000 bytes, checked before extraction. These are payload bounds;
filesystem allocation and metadata overhead are separate. Source reconstruction
runs after part/retained scratch has been removed. Report destinations in or at
the capsule are rejected before opening a report.

The prior part-sum preflight, actual archive ownership and cumulative checks before
writes remain intact. Controls separately isolate exact-limit oversized members,
wrong-part members, negative/boolean inventory sizes, excess compressed bytes and
retained payload beyond8MB in an otherwise valid sub38MB part. All capsule inputs
must remain unchanged. Checked and derived API identities remain distinct; this
is storage recovery, not another compiler proof.

Real capture/recovery waits for the root release freeze and independent v2 review.
Every logical evidence member remains selected, including failed attempts and
all historical policy controls. No existing evidence tree is deleted.
