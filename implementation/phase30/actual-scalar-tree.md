# Actual scalar-tree compiler integration

Checked attempt12 reproduces the private binary-tree mechanism from the
generated-output experiment. Against checked attempt11, the independent
mathematical oracle, ordered host behavior, depth admission and explicit-stack
checks pass. A separately frozen longer-warmup comparison measures a **13.5×**
gain on the original small Mandelbrot program over actual11, with stable measured
halves; actual12 is **5.86× slower than pinned TypeScript** at that point.

The prospective validation is
[actual-scalar-tree-validation.md](../../design/phase30/actual-scalar-tree-validation.md).
The compiler implementation recognizes the checked scalar binary-recursion
shape; the original-program names in diagnostic tooling are fixture selection,
not a compiler admission rule. Source admission/refusal tests are maintained
separately by the independent reviewer.

## Controls and provenance

`prototype-tree-compiler-adapt.py` verifies both actual emission receipts and
their attempt receipts before copying the modules. The baseline is
`ordinary-region-11/candidate.mjs`, with ordinary scalar-root regions already
enabled. The candidate is `tree-region-12/candidate.mjs`. This measures the
increment from actual11 to actual12; the earlier attempt10 generated prototype
is retained as separate evidence.

The adapter keeps the existing mathematical oracle and 130 host actions
unchanged. It changes variant labels and adapts only the diagnostic fast-body
and counter markers to actual output. Balanced block parsing creates a separate
sentinel module that retains exact entry permission, original slot reads, input
checks, the predecessor bound and closure guard. Neither sentinel nor
instrumented modules are used in performance measurements.

Acquisition-only results:

- **74 independent oracle points** across baseline and candidate, including
  both original whole-program outputs.
- **130 paired ordered host observations**, with complete traces retained.
- **4 candidate depth sentinels:** depths 1 and 32 enter the private path;
  depth 33 and a coercible raw predecessor select the original generic path.
- **20 paired stack/result checks:** exact leaf order including wrapped U32
  indices, node/leaf/combine/frame counts and stack high-water.
- **85 additional independent host controls** passed both the original
  prototype trio and actual11 versus actual12, covering persistent runtime
  marker hooks, descriptor metadata/bounds/call getters and earlier/later
  copied-vector length effects. See `review-tree-boundaries-12/report.json`.

Raw outputs are `tree-compiler-controls-12/derive.json`,
`tree-compiler-oracle-12/report.json` and
`tree-compiler-counts-12/report.json`, plus their separate outer process
receipts. The adapted source tools and original tool identities are retained.

## Mechanism in actual output

For original `bench(2,0)`, every result remains `887240761`:

| Operation | Actual11 | Actual12 |
| --- | ---: | ---: |
| Generic apply | 6,224 | 104 |
| Function descriptor | 5,438 | 84 |
| Partial application | 4,904 | 60 |
| Jump | 535 | 25 |
| Force | 5,689 | 79 |
| Projection | 270 | 16 |
| Closure guard evaluations | 260 | 5 |
| Build / constructor | 8 / 8 | 8 / 8 |

Actual12 visits 511 private tree nodes and 256 leaves, performs 255 combines,
and reaches a stack high-water of 8. The complete leaf index trace remains
0 through 255. Its five guards are four first-pass chunk entries and one
second-pass tree entry. The public constructor representation remains intact.

## Frozen performance comparisons

`tree-compiler-plan-12/{screen,confirm}.json` compares actual11, actual12 and
pinned TypeScript on the original small program; the paired depth-five
component uses the same host wrapper and oracle as the original experiment.
Every configuration records emission, controls, counters and wrapper hashes.

The earlier prototype's private whole-program samples changed substantially
between their measured halves despite three seconds of warmup. A separate
prospective [longer-warmup diagnostic](../../design/phase30/scalar-tree-long-warmup.md)
uses three samples, 15 seconds of warmup, a three-call floor and a one-second
measured target. The derived runner and launcher are retained alongside
`tree-compiler-plan-12/long-warmup.json`; ordinary protocols remain unchanged.
The maintained long confirmation completed in `tree-compiler-confirm-12`
(105.168 seconds, all outputs correct). The original-point medians were
3.626788 ms for actual11, 0.349187 ms for actual12 and 0.045497 ms for TypeScript.
Actual12's halves still changed sharply: four improved 31.6–35.0%, while one
worsened 50.4%. Keep that protocol result as measured; it does not establish
settled throughput. The separate depth-five component was stable: actual11
0.399035 ms versus actual12 0.024952 ms, a **15.99×** gain, with all candidate
half-window changes within 1.26%.

The prospectively frozen longer-warmup comparison then completed unchanged in
`tree-long-warmup-12`, taking 193.595 seconds end to end. Every output matched:

| Original `bench(2,0)` variant | Median ms | Three-process range ms | Half-window change |
| --- | ---: | ---: | --- |
| Actual11 | 3.614043 | 3.591245–3.651341 | −0.16% to +0.38% |
| Actual12 | 0.267604 | 0.265087–0.268783 | +0.32% to +1.59% |
| Pinned TypeScript | 0.045645 | 0.045614–0.045754 | +0.35% to +0.64% |

The observed **13.505×** incremental gain and **5.863×** remaining TypeScript
ratio have disjoint sample ranges and stable measured halves in this specified
window. This resolves the identified drift for this point under the longer
protocol; it is not a universal generated-program estimate. The three-second
and fifteen-second results remain distinct evidence, with all original process
outputs and outer launcher receipts retained. No instrumented output was timed.
