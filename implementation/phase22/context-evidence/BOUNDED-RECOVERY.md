# Bounded extraction amendment

Root approved this amendment after the preliminary disk estimate. It supersedes
the unchanged-recoverer and simultaneous full-extraction paragraphs in PLAN.md;
the initial proposal remains retained. All Phase22 payload bytes remain selected.
There are no payload omissions and no deletion of existing workspace trees.

`context-recover.py` derives from the frozen Phase16 recoverer, with its exact
diff and identities recorded in recovery-adaptation.patch and
bounded-recovery-adaptation.json. Archive format and collector safety are
unchanged. Recovery remains an independent process and never trusts working-tree
source as a reconstruction input.

The recovery process:

1. Verify manifest/inventory identities, archive coverage and archive hashes;
   reject unsafe paths, links, link/file ancestors and unsupported member types.
2. Create an invocation-owned temporary directory. For each bounded archive,
   create a fresh part subdirectory, extract every regular member through an
   exclusive create, restore its recorded mode, and verify its length/hash/mode.
   Verify symlink tar metadata without following or extracting the link yet.
3. Retain exact regular targets needed by cross-part fixture links, plus final
   attempt/build/validation metadata and the checked and derived APIs. Verify
   those retained copies. Delete only this invocation's completed part scratch.
4. After all parts, independently recompute coverage and extracted byte/member
   counts; create every recorded link against its verified retained target and
   verify its literal target, mode and resolved containment. Record the largest
   extracted part and retained payload, exposing the scratch-space bound.
5. Bind final API lineage from the extracted attempt record. The upstream-checked
   bootstrap API and equality-v5-derived API are separate artifacts. The final
   installed candidate API is the derived API, not a claim that its bytes equal
   the checked bootstrap or establish a new fixed point.
6. In another fresh temporary directory, reconstruct every final project member
   from fixed commit a784e0e1a0de1ee085cc188ca0f1f19038679bdb plus the captured patch.
   Verify complete membership, each byte/hash/mode, and no unexpected files.
7. Recheck all archive and metadata identities and write the outcome receipt
   outside the immutable capsule. Source reconstruction and extraction counts
   are regenerated from actual operations; no compiler or old reports are rerun.

Expected scratch payload is at most one 38 MB uncompressed part plus a few MB of
link targets/API lineage, then the roughly 1.3 MB final project. Directory and
filesystem block overhead is additional; reserve at least 150 MB free for the
recovery window and verify space after capture. The full capsule itself remains
on disk throughout. Do not overlap recovery with large extractions or timing.

Synthetic tests must exercise valid cross-part links and modes plus malformed
paths, absolute/escaping/unselected links, symlink/file ancestors, hardlinks,
changed archives, wrong modes/content, duplicate/missing members, part bounds,
API lineage and source patch identities. Preserve every attempt and raw failure.
An independent owner reviews and runs final recovery after the final selection,
release freeze and capsule closure; preparation is not capture authorization.
