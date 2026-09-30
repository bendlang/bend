# Actual scalar-tree compiler integration

Checked attempt12 reproduces the private binary-tree mechanism from the
generated-output experiment. Against checked attempt11, the independent
mathematical oracle, ordered host behavior, depth admission and explicit-stack
checks pass. Its clean performance comparison is prepared and has not yet run.

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
No precise settled throughput or speed ratio is claimed before these actual
compiler measurements complete.
