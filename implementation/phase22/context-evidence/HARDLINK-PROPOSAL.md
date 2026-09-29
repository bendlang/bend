# Preserve logical evidence while sharing immutable bytes

Prospective disk recovery only. No hardlink mutation is authorized by this file,
and no inventory hashing runs during an exclusive compiler cost window.

After matrix03 closes, root may approve an exact list of closed Phase22 build
evidence roots. The read-only estimator walks only those roots, never live source,
tools, the Git directory, external anchors, active producers or symlink targets.
It groups regular files by size and mode, hashes only potentially duplicate
groups, and records exact file identities, inode/device/link count, allocated
blocks and candidate savings. A file changed during hashing is a refusal. Existing
multi-link files are excluded because their other owners are not established.

An independently reviewed later mutation could replace each duplicate regular
file atomically with a hardlink to an identical immutable donor on the same
filesystem. Every original path, byte, length and permission mode must remain.
The temporary hardlink must be created in the recipient's own directory and
atomically renamed over only that checked recipient. Do not unlink the recipient
first. Recheck both endpoints immediately before mutation and verify all approved
paths afterward. Preserve an operation journal and pre/post identities outside
the source roots. A failure stops further changes; existing bytes remain through
either the old recipient or the newly linked identical inode.

This changes inode/link-count/ctime and can unify unbound mtime values. Those are
not claimed invariant. Review must check that no selected frozen contract binds
these metadata fields or relies on separate mutable ownership. Files must never
be edited afterward: any future change requires a fresh numbered artifact. Roots
that may still receive cache writes or producer output must be excluded unless
root can establish exact closed immutable members independently.

The collector emits a fresh regular TarInfo and payload for each logical member;
it does not infer tar hardlinks from shared filesystem inodes. Thus every logical
file's full bytes remain in the final archive and ordinary recovery restores
separate regular files. This is physical storage sharing, not an evidence omission
or a change to capsule membership. No old or unrelated workspace tree is deleted.

First gate: review the read-only estimate, exact root authorization and proposed
groups with carets. Only a separate explicit root grant may authorize the exact
mutation list. Actual capture still waits for all producers and the final release
freeze; this proposal does not bypass either requirement.
