# Reuse private continuation storage by depth

The isolated actual12 frame-reuse output passes its semantic and allocation
controls. A separate longer-warmup comparison confirms an 8.06% reduction in
execution time on original Mandelbrot `bench(2,0)`. This report first evaluates
the disposable output; the parent separately owns any compiler integration.

The checked original Mandelbrot output allocates an argument array and frame
record for each internal tree node, then truncates its private backing array
on pop. The proposed variant keeps this pool for one invocation and overwrites
every saved argument, phase and left result before reusing a frame at the same
depth. Pop changes only the logical stack top. The root design is
`design/phase30/scalar-tree-frame-reuse.md`.

Only the one rcol push and one pop statement differ; guards, original fallback,
private helper code, primitive arithmetic and traversal order are unchanged.
The saved fields are scalar parent aliases and cannot escape through an output
or deferred closure. Each public invocation still owns a fresh pool. Standard
Array intrinsics remain the explicit scope; numeric prototype accessors are
outside the existing private-storage contract.

`review-tree-frame-01` preserves the checked receipt and attempt identity:

| Complete module | Bytes | SHA-256 |
| --- | ---: | --- |
| Actual12 unchanged | 110,405 | dbd065e8888b757edbfe49cb707682f4d7c0924ab37a6d4f1e94022e84ea3b3e |
| Frame pool reuse | 110,805 | 85992ea4f74c5509347ba92c31fa6f222c609f3825acffa144c74ca9f0c38495 |

Passing receipts under `selfhost/build/phase30/`:

- `review-tree-frame-controls-01`: inherited 74 independent scalar/original
  program points, 130 ordered descriptor/entry/coercion observations, and eight
  post-guard depth sentinels across the two variants.
- `review-tree-frame-boundaries-01`: 85 independently authored ordered
  prototype-marker, metadata and copied-length observations.
- `review-tree-frame-counts-01`: 24 instrumented traversal rows and 16 repeated
  calls with changing depth, index, limit and every palette entry.

The original `bench(2,0)` keeps the same full result, 511 tree visits, 256 leaves,
255 combines and complete leaf index trace. Fresh frame/argument-array pairs
fall from 255 to eight, with 247 reuses and logical high-water eight. These are
specific allocation-site counts, not total heap-allocation estimates. Counter
records are snapshotted immediately and the diagnostic programs are never timed.

An initial Python quoting typo failed before producing any module. Its exact
source and error are retained in `review-tree-frame-derive-failure-01`; the
corrected derivation and all semantic controls passed. There was no compiler
failure or code change associated with that tooling error.

The gated `review-tree-frame-plan-01/{screen,confirm}.json` configurations compare
only original actual12 and frame reuse on original `bench(2,0)` and the identical
depth-five adapter. Under the parent's exclusive CPU3 grant, the retained
`tree-frame-screen-01` completed in 8.13 seconds with all outputs passing:

| Screen point | Actual12 median ms | Reuse median ms |
| --- | ---: | ---: |
| Original bench(2,0) | 0.376582 | 0.361615 |
| Depth-five adapter | 0.031103 | 0.027217 |

The original-program screen had baseline half changes from −3.69% to −1.76%
and reuse changes from +4.41% to +6.36%; the depth-five point also drifted.
These small-screen ratios were insufficient to settle the warmed gain.

Before further measurement, `design/phase30/tree-frame-long-warmup.md` and
`tree-frame-long-plan-01/long-warmup.json` froze a separate original-program
confirmation. It uses the unchanged, previously derived actual-tree runner:
15-second warmup, three independent samples, three-call floor and one-second
measured target. All original control/derivation/module identities are bound.
The old screen and maintained protocols remain unchanged; the original
three-second frame confirmation was not needed or executed.

`tree-frame-long-confirm-01` completed cleanly in 129.44 seconds:

| Original bench(2,0) | Median ms | Sample range ms | Half changes |
| --- | ---: | ---: | --- |
| Actual12 | 0.266169 | 0.265532–0.267865 | −0.20%, −0.51%, +0.02% |
| Private frame reuse | 0.244705 | 0.244142–0.245161 | −0.73%, +0.37%, +0.42% |

The ranges are disjoint and within-process drift is small. Frame reuse gives
**1.088× throughput**, or **8.06% less time**, on this original program and input.
This measurement isolates frame storage lifetime with the same semantics and
traversal. It does not establish a universal generated-program speedup. Fresh
actual-compiler gates remain required before installing a compiler change.

## Actual checked compiler integration

The parent integrated the same storage rule in checked attempt13. Fresh checked
original Mandelbrot output is retained at `tree-region-13/candidate.mjs`.
`frame-compiler-controls-13/derive.json` binds actual12 and actual13 emission and
attempt identities and proves that their complete module bytes differ only in
the intended private frame push/pop sequences. The emitted private name
`$saved` replaces the prototype's `$reuseFrame30`; only diagnostic
instrumentation is adapted to that spelling.

Fresh actual-output gates all pass:

- `frame-compiler-oracle-13`: 74 independent values, 130 ordered host
  observations and eight post-guard depth sentinels.
- `frame-compiler-boundaries-13`: 85 independently authored supplemental
  observations, using the maintained control tool unchanged.
- `frame-compiler-counts-13`: 24 traversal rows and 16 repeated calls with
  changing inputs. Original bench(2,0) retains 511 visits, 256 leaves and 255
  combines; fresh frame/argument-array pairs fall from 255 to eight, with 247
  reuses and logical high-water eight.

The first oracle launch was prevented before process creation by a sandbox
ENOSPC error. `frame-compiler-oracle-13-launch-failure.json` retains that event
explicitly. After parent-authorized verified temporary-file recovery, the
previously uncreated output names were acquired successfully; no failed
compiler/control execution was hidden or overwritten.

Actual-output timing configurations are frozen separately in
`frame-compiler-plan-13/{screen,confirm,long-warmup}.json`. They have not yet run.
The longer-warmup case uses the unchanged earlier derived runner. Installation
and broad compiler conformance remain parent-owned work.
