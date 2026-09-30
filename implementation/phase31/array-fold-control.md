# Independent local-array source

The second source uses one 128-slot Array, a U32 accumulator carried in a Tuple,
and a single Nat loop. Its Tuple places delayed Array.set in the first field;
the edit-distance Dp placed it fourth. There is no Dp record, PRNG, minimum,
four-array cell chain or nested DP. The scalar root prevents container escape.
The source and [prospective design](../../design/phase31/array-fold-control.md)
are independent of the full-pair timing fixtures.

Fresh checked17 emission `local-data-fold-source-02` passes in 4.925 seconds;
pinned TypeScript emission passes in 0.602 seconds internally. These descriptive
acquisitions are not a speed comparison. `local-data-fold-controls-03` passes
40 points on both modules against a BigInt/U32 oracle: ten sizes through 257,
four seeds including U32 max, and modulo-indexed revisits to the 128-slot array.
Two selected points distinguish a fault that postpones writes until the end:

| Point | Correct result | Incorrect delayed-write result |
| --- | ---: | ---: |
| n130, seed17 | 2228 | 2210 |
| n257, seed1 | 1153 | 257 |

Three unsuccessful preparations remain preserved. Source01 introduced a mutual
forward call rejected as an unfilled law; source02 uses a single recursive loop
carrying its Tuple. Controls01 passed all 36 ordinary points but incorrectly
expected n129 to distinguish the delayed-write fault; the first overwritten
slot retains its original value. Controls02 passed 40 ordinary points and two
negative witnesses but expected the max-U32 seed to distinguish the same fault;
it happens to hide it. Controls03 retains that third point as an explicit
neutral observation instead of calling it a fault-detecting witness. No generated
module disagreement occurred in those harness corrections.

The maintained source is `selfhost/tools/performance/phase31/local-data-fold.bend`.
The maintained oracle accepts additional actual compiler modules without changing
its expected results. Actual candidate promotion and timing remain separate.
