# Generated JavaScript syntax comparison

Static syntax sites, not execution frequency, executed allocations, retained memory, or semantic correctness.

| Case / role | Module bytes | Post-runtime bytes (includes Base) | Post-runtime calls | Function-expression / arrow sites | Array / object literal sites | BigInt literal / conversion sites |
|---|---:|---:|---:|---:|---:|---:|
| local-pair / typescript | 12457 | 6025 | 39 | 0 | 0 / 11 | 0 / 0 |
| local-pair / baseline | 98344 | 44189 | 756 | 304 | 681 / 50 | 84 / 3 |
| local-fold / typescript | 5191 | 1033 | 5 | 0 | 0 / 3 | 0 / 0 |
| local-fold / baseline | 76128 | 22250 | 375 | 173 | 572 / 49 | 11 / 2 |
| scalar-region-0 / typescript | 6552 | 2088 | 15 | 0 | 0 / 0 | 0 / 0 |
| scalar-region-0 / baseline | 80789 | 27363 | 403 | 166 | 561 / 49 | 19 / 4 |
| scalar-region-8192 / typescript | 6552 | 2088 | 15 | 0 | 0 / 0 | 0 / 0 |
| scalar-region-8192 / baseline | 80789 | 27363 | 403 | 166 | 561 / 49 | 19 / 4 |
| complete-generic-row32 / typescript | 12616 | 8918 | 120 | 23 | 0 / 12 | 0 / 7 |
| complete-generic-row32 / baseline | 98497 | 44291 | 761 | 306 | 682 / 50 | 84 / 3 |
| mandelbrot / typescript | 15442 | 9422 | 78 | 0 | 0 / 3 | 0 / 0 |
| mandelbrot / baseline | 109212 | 55116 | 900 | 341 | 687 / 50 | 63 / 1 |
| editdist / typescript | 11907 | 5588 | 30 | 0 | 0 / 10 | 0 / 0 |
| editdist / baseline | 97519 | 43364 | 719 | 299 | 661 / 50 | 80 / 1 |
| tree-bitonic / typescript | 10593 | 5016 | 29 | 0 | 0 / 23 | 0 / 0 |
| tree-bitonic / baseline | 79946 | 25944 | 537 | 289 | 637 / 49 | 13 / 1 |
| lexer / typescript | 14110 | 7560 | 66 | 0 | 0 / 42 | 0 / 0 |
| lexer / baseline | 84649 | 29817 | 663 | 382 | 681 / 49 | 12 / 3 |
| symreg / typescript | 12815 | 6728 | 59 | 0 | 0 / 8 | 0 / 0 |
| symreg / baseline | 82590 | 28030 | 603 | 300 | 646 / 49 | 19 / 2 |
| test-morning-program / typescript | 48892 | 43891 | 242 | 2 | 5 / 374 | 0 / 1 |
| test-morning-program / baseline | 117258 | 62709 | 1854 | 921 | 1335 / 49 | 33 / 0 |
| test-evening-program / typescript | 62658 | 57725 | 361 | 2 | 13 / 422 | 0 / 3 |
| test-evening-program / baseline | 160856 | 105855 | 3578 | 2500 | 2718 / 54 | 39 / 1 |
| test-rle-roundtrip / typescript | 8728 | 3763 | 19 | 0 | 0 / 24 | 0 / 0 |
| test-rle-roundtrip / baseline | 74692 | 21266 | 405 | 201 | 594 / 52 | 4 / 1 |
| test-map-set-ops / typescript | 69178 | 62446 | 403 | 0 | 13 / 490 | 0 / 3 |
| test-map-set-ops / baseline | 137571 | 83022 | 2583 | 1184 | 1710 / 51 | 23 / 0 |
| raytrace / typescript | 28974 | 21214 | 451 | 0 | 5 / 11 | 0 / 0 |
| raytrace / baseline | 100044 | 46205 | 1293 | 492 | 838 / 49 | 23 / 3 |

Top-level statements mapped to declarations in the selected Bend source, excluding copied runtime, Base-only registrations and shared support declarations:

| Case / role | Source-owned bytes | Source-owned calls | Function-expression / arrow sites | Array / object literal sites | Trampoline helper sites | BigInt literal / conversion sites |
|---|---:|---:|---:|---:|---:|---:|
| local-pair / typescript | 5980 | 39 | 0 | 0 / 11 | 0 | 0 / 0 |
| local-pair / baseline | 24308 | 407 | 125 | 121 / 1 | 98 | 75 / 3 |
| local-fold / typescript | 1024 | 5 | 0 | 0 / 3 | 0 | 0 / 0 |
| local-fold / baseline | 3929 | 76 | 22 | 23 / 0 | 17 | 6 / 2 |
| scalar-region-0 / typescript | 2075 | 15 | 0 | 0 / 0 | 0 | 0 / 0 |
| scalar-region-0 / baseline | 10516 | 149 | 32 | 35 / 0 | 31 | 12 / 4 |
| scalar-region-8192 / typescript | 2075 | 15 | 0 | 0 / 0 | 0 | 0 / 0 |
| scalar-region-8192 / baseline | 10516 | 149 | 32 | 35 / 0 | 31 | 12 / 4 |
| complete-generic-row32 / typescript | 5980 | 39 | 0 | 0 / 11 | 0 | 0 / 0 |
| complete-generic-row32 / baseline | 24308 | 407 | 125 | 121 / 1 | 98 | 75 / 3 |
| mandelbrot / typescript | 9389 | 78 | 0 | 0 / 3 | 0 | 0 / 0 |
| mandelbrot / baseline | 35387 | 556 | 156 | 134 / 1 | 121 | 52 / 1 |
| editdist / typescript | 5545 | 30 | 0 | 0 / 10 | 0 | 0 / 0 |
| editdist / baseline | 23484 | 370 | 120 | 101 / 1 | 79 | 71 / 1 |
| tree-bitonic / typescript | 4981 | 29 | 0 | 0 / 23 | 0 | 0 / 0 |
| tree-bitonic / baseline | 6570 | 202 | 113 | 84 / 0 | 57 | 3 / 1 |
| lexer / typescript | 7403 | 66 | 0 | 0 / 42 | 0 | 0 / 0 |
| lexer / baseline | 10429 | 330 | 208 | 129 / 0 | 80 | 3 / 3 |
| symreg / typescript | 6685 | 59 | 0 | 0 / 8 | 0 | 0 / 0 |
| symreg / baseline | 8769 | 275 | 124 | 97 / 0 | 89 | 8 / 2 |
| test-morning-program / typescript | 3268 | 39 | 2 | 1 / 20 | 2 | 0 / 0 |
| test-morning-program / baseline | 4076 | 155 | 67 | 72 / 0 | 49 | 3 / 0 |
| test-evening-program / typescript | 2339 | 39 | 2 | 2 / 1 | 0 | 0 / 0 |
| test-evening-program / baseline | 3407 | 130 | 34 | 41 / 3 | 36 | 3 / 0 |
| test-rle-roundtrip / typescript | 3736 | 19 | 0 | 0 / 24 | 0 | 0 / 0 |
| test-rle-roundtrip / baseline | 3865 | 137 | 65 | 58 / 3 | 33 | 0 / 1 |
| test-map-set-ops / typescript | 6240 | 101 | 0 | 0 / 17 | 0 | 0 / 0 |
| test-map-set-ops / baseline | 8422 | 313 | 77 | 134 / 0 | 117 | 0 / 0 |
| raytrace / typescript | 19443 | 348 | 0 | 0 / 11 | 0 | 0 / 0 |
| raytrace / baseline | 27518 | 985 | 331 | 294 / 0 | 279 | 15 / 3 |

These source-owned statement ranges are disjoint. They include any private specializations nested inside an owned registration, but omit shared helper/table declarations that those functions can use. Missing mappings can make this inventory incomplete; the per-definition comparison keeps unmatched names visible.
`programInventory` retains the other support counts and trivia separately. `sharedArrayTables` records top-level array constants and their indexing sites.
Open [comparison.html](comparison.html) for aligned Bend-definition source and token comparisons.
Per-role normalized files retain token kind and value, removing formatting and comments. They are not a semantic normal form.
Function metrics exclude nested bodies. Definition metrics include nested units and must not be summed as disjoint execution or allocation counts.
