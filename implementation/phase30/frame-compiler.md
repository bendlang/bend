# Actual13: reuse private tree frames

The compiler now retains one frame object and argument array per active tree
depth, resetting and reusing a popped frame on the next descent. The complete
tree still executes left child, right child and combination in the original
order. Storage is local to one invocation and bounded by the existing depth32
and arity32 limits. All scalar parent slots, phase and left-result state are
overwritten before reuse. No admission, runtime, numeric representation or IR
change accompanies this emitter change.

The [isolated experiment](scalar-tree-frame-reuse.md) confirms 8.06% less time
on the original small program under a separately frozen fifteen-second warmup:
0.266169 to 0.244705 ms, with disjoint ranges and stable timed halves. Those
numbers belong to the disposable actual12 derivative. Actual13 has its own
frozen measurement plan; its timings are not inferred from the prototype.

The checked actual13 build plus 36 strict focused observations completes in
38.042 seconds. This is an acquisition duration, not comparative throughput.
The exact artifact identities are:

| Artifact | SHA256 |
| --- | --- |
| Guarded derived API | `b6efd08b1f00907d44566405db53bc6caa4ea9cbc2e76432eaba7ca97a908ef9` |
| Genuine checked parent | `b9eed7a2ba772f86d57bee270316f27ea66348900605c0094d3c16466292e06d` |
| Runtime, unchanged | `a3547a8854b45c65fd804f106868dc28540118b611d85fe99ba0e3d199c66ef0` |
| Derivation report | `75596ee5969ac3a7fe11076ae90e91477d3acdc98978706cb49f02953a55980f` |

The actual Mandelbrot emission takes 5.226 seconds. A whole-module comparison
proves it differs from actual12 only in the intended private push/pop code.
Fresh gates pass 74 independent results, 130 ordered public observations,
eight depth sentinels, 85 supplemental boundaries, 24 traversal/count rows and
16 changing repeated calls. Independently, the 31-book/96-execution tree suite
and checked-source Bool/Nat result/refusal fixture pass. These overlapping
counts are separate scopes, not a unique conformance total.

For bench(2,0), traversal remains 511 nodes, 256 leaves and 255 combines. Fresh
frame/argument-array pairs fall from 255 to 8, with 247 reuses and depth8.
The original ten-library acquisition passes after the separately documented
[disk-full interruption](environment-recovery.md). Nine actual13 modules are
byte-identical to actual12; Mandelbrot contains the frame change. The comparison
is retained in `transfer-13b/unchanged-output-audit.json`.

Canonical compiler source now contains 16,828 physical /14,370 nonblank lines,
648,982 bytes, 1,851 definitions, 640 laws, 70 types and 66 modules. This specific
change adds 13 physical lines and two small emission helpers. Whole-phase growth
from Phase29 is 621 physical lines, about 3.83%; this is a speed improvement,
not a source-length reduction. The canonical module manifest excludes generated
bundles, unused source files and experimental tools from these counts.

The fresh actual-output confirmation now passes in
`frame-compiler-long-confirm-13`, taking 129.69 seconds end to end. Actual12 is
0.263759 ms [0.263549–0.264933], actual13 is 0.246737 ms
[0.246372–0.248607]: **1.0690× faster**, or **6.45% less time**. Actual12 half
changes range from −0.13% to +1.30%; actual13 from +0.39% to +1.08%. These
settled, disjoint three-process ranges confirm the maintained emitter under the
frozen fifteen-second warmup. Keep its measured gain separate from the earlier
prototype's 8.06% result.

Actual13 remains a candidate until final measurements, combined release gates
and installation. The installed release is still Phase29 at this checkpoint.
