# Phase32 final measurements

Current status: all requested measurements completed.

| Original program | TypeScript ms | Checked07 ms | Candidate ms | Speedup | Candidate/TS | Identical07 bytes |
|---|---:|---:|---:|---:|---:|---|
| mandelbrot | 0.0458518 | 0.202877 | 0.204593 | 0.992× | 4.462× | True |
| editdist | 4.98795 | 72.2661 | 20.3976 | 3.543× | 4.089× | False |
| test-rle-roundtrip | 0.000598468 | 0.0447636 | 0.0456163 | 0.981× | 76.222× | True |

Compiler cost: complete. Canary confirmation: complete.

| Source / boundary | TypeScript | Checked07 | Candidate | Change vs07 | Ranges overlap |
|---|---:|---:|---:|---:|---|
| mandelbrot / requestMs | 352.49 | 1921.46 | 1958.21 | +1.91% | False |
| mandelbrot / importAndRequestMs | 620.06 | 1925.45 | 1962.24 | +1.91% | False |
| mandelbrot / processWallMs | 4960.47 | 6533.06 | 6570.03 | +0.57% | True |
| mandelbrot / maxRssKiB | 472460 | 522672 | 524704 | +0.39% | False |
| editdist / requestMs | 366.856 | 1804 | 1795.96 | -0.45% | True |
| editdist / importAndRequestMs | 655.262 | 1807.98 | 1799.97 | -0.44% | True |
| editdist / processWallMs | 5415.93 | 6420.26 | 6430.17 | +0.15% | True |
| editdist / maxRssKiB | 473452 | 522520 | 522600 | +0.02% | True |

All18 fresh library requests retain the normal validated Base pipeline. TypeScript explicitly imports compiler modules outside request time; the Bend API loads lazily within its request. Import-plus-request is reported separately. Supervised process wall includes preflight, persistence and postflight and is not ordinary CLI latency.

| Canary | Checked07 ms | Candidate ms | Change vs07 | Ranges overlap | Identical07 bytes |
|---|---:|---:|---:|---|---|
| scalar-region-0 | 0.00471083 | 0.00476023 | +1.05% | True | True |
| scalar-region-8192 | 0.138196 | 0.138412 | +0.16% | True | True |
| complete-generic-row32 | 0.443643 | 0.444208 | +0.13% | True | False |

The JSON retains every median, full range, sample, half drift, first-call/import cost, RSS, byte comparison and measurement boundary. Identical emitted bytes do not establish identical process timing; such differences cannot be assigned to a compiler source transformation.

This report does not replace the separate correctness closure or final admission decision.
