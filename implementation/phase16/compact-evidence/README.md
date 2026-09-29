# Phase16 compact compiler evidence

Local preservation and independent recovery passed for release
`0b51d965e2638048b5526b351047daae0c61ed7c`, installed API `35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315`.
See [consolidation](../consolidation.md) for compiler behavior, performance and
remaining conformance gaps. This directory records preservation, not remote publication.

The frozen [inventory](capsule-01/inventory.json) contains **20,344 members**
(20,339 regular files and five fixture links), **778,699,976 uncompressed bytes**.
The [capture manifest](capsule-01/manifest.json) binds 16 archive parts totaling
**100,549,967 compressed bytes**; the largest is 8,460,810 bytes. Every part is
below the 99,000,000-byte guard.

| Topic | Members | Parts | Compressed bytes |
| --- | ---: | ---: | ---: |
| final | 5,377 | 4 | 27,178,533 |
| literal | 3,950 | 3 | 18,726,549 |
| lambda-memo | 3,324 | 2 | 13,823,596 |
| context | 5,826 | 5 | 29,854,120 |
| patterns | 1,867 | 2 | 10,967,169 |

The final topic includes the complete source/build, all named final gates, the
prototype and final timing windows, all three promotion attempts, installed CLI
smoke, installed `dist`, current documentation and Phase16 tools. The other topics
retain the selected literal, Lambda, memo, contextual loading, program completion
and pattern attempts, including consumed failed sources/tools and original logs.
The nine synthetic recovery controls intentionally include invalid archive paths,
links and types as negative test data; those tiny fixture archives are not unpacked
while recovering the outer evidence capsule.

## Scope and exclusions

[Root freeze](root-freeze.json) binds the closed producers and release commit.
[Selection review](selection-review.json) records 17 explicitly referenced fixture
sibling trees. Root approved the exact 220-file `unbound-marker-source-02` tree
because its consumed fixture lives beside that project snapshot. Its exact member
rows are authoritative despite the generic prefix-exclusion label.

This is **not a complete archive of Phase16**. The inventory enumerates 405 roots
outside the topic-prefix selection; 14 have explicit fixture descendants included.
Earlier profiles, source-range and diagnostic experiments and parser checkpoint
investigations are outside this bounded preservation. Their committed reports and
tools may be included without every historical payload they mention. Omitted
ignored payloads may remain only in the working environment. No original files
were deleted and no unrelated Phase6 tools were captured.

External prerequisites are explicit in the inventory: fixed committed Phase15
source, [Phase15 and its eleven prior capsules](../../phase15/evidence/RECOVERY.md),
the [wave7 checkpoint](../wave7-evidence/README.md), pinned upstream
`b2111cf43244e65f76ddc278ee695e669f720cbf`, and the recorded Node/Clang toolchain.
The archives preserve original absolute references; recovery does not manufacture
bootstrap lineage or make every historical reference self-contained.

## Independent verification

[Recovery](recovery-01.json) verified every member's bytes/type/mode, all five
selected relative links and complete archive membership. It then rebuilt all
**214 final source/tool/test files** from committed Phase15
`a383163b821e38510967849fdb791ff914031b62` plus
[the saved patch](capsule-01/phase15-to-final.patch), verifying exact membership,
bytes and modes without reading working-tree source.

Run from the repository root with Python 3 and Git; use a new report path:

```sh
python3 selfhost/tools/performance/phase16/compact-recover.py \
  implementation/phase16/compact-evidence/capsule-01 \
  /tmp/phase16-compact-recovery-report.json
```

The verifier uses fresh temporary directories and removes them after verification.
All 16 parts, manifest, inventory and source patch must be present. The fixed
Phase15 commit must exist locally. It rejects unsafe paths, hardlinks, symlink
ancestors, unselected link targets, duplicate or missing members and changed
hashes/modes before accepting recovery.

[Readiness](readiness.json) binds the independent tool review and **9/9 policy
controls**: one valid parent-relative link accepted and eight malformed cases
rejected. The original Python syntax-check failure is retained separately. The
capture manifest's `recoveryPending:true` describes capture time and remains
immutable; the separate successful recovery record completes it. Outcome metadata
in this directory is outside the frozen archive input set, avoiding self-reference.
