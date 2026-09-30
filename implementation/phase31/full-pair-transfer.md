# Transfer to the complete edit-distance pair

The transfer uses the actual canonical `pair(p)` computation: generate two
256-symbol inputs, initialize two 512-slot rows, execute 256 x 256 cells,
read the distance and produce the original checksum. All variants consume
exactly the same checked Bend source, including its unused diagnostic row probe.
The [prospective design](../../design/phase31/full-pair-transfer.md) separates
whole-call-graph entry, private setup and the Dp shell optimization.

`local-data-pair-02` derives five modules from current17: generic, full private
graph with generic setup, full graph plus private setup, plus the earlier Dp
shell step, and pinned TypeScript. All public helpers stay byte-identical.
Only the scalar pair entry can pass the complete definition-time snapshot and
runtime guards. Private dp steps force complete rows before transfer; the zero
dp returns identity, while zero row swaps handles. The prologue reads a[i],
forces the cur[0] write, then runs cells. Dist observes the final forced row.

`local-data-pair-controls-02` passes six independent scalar oracle points across
all five modules, complete four-array equality and identical hashes of all
328,966 native events for p0 across four runtime modules, plus 17 public mutation
and entry cases. The schedule consists of 4 allocations, 262,401 reads and
66,561 writes. Its SHA256 is
`f4687aaa2fc12e4f9665b8a3bb20ce6b3557959f7bb97dab31d0c1c24c8af04d`.
The four documented pairs sum to the known checksum 2065873279. These scoped
controls are not performance evidence or a general compiler correctness proof.

Two preparation failures are retained. Derivation01 expected a matcher-shaped
dist.fin, but the real emitted code already uses a projection-only callback;
derivation02 accepts that exact shape. Controls01 incorrectly expected a scalar
from JavaScript `new pair.code`. All four modules instead return their fresh
empty constructor instance because JavaScript ignores a constructor's primitive
return. Controls02 checks empty own keys and `instanceof code` consistently.
No candidate-code semantic mismatch was observed in either correction.

Actual checked Phase31 candidate02 is emitted against the identical source in
`local-data-actual02-source-01` (5.276 seconds descriptive acquisition). Its
wrapper joins all original modules in `local-data-pair-actual02-01`; a fresh
six-way semantic renewal precedes any timing. The previous candidate17 ladder
and all earlier receipts remain unchanged. Performance plans are not yet frozen.

The actual02 renewal detects a real integration failure before timing:
`ReferenceError: localGuard is not defined`. The new generated root references
a runtime helper absent from the emitted runtime. This is retained in
`local-data-pair-actual02-controls-01`, alongside its exact bytes and acquisition.
The prototype controls still pass; they do not excuse the actual compiler error.
The coordinator is repairing the emitted runtime boundary before another attempt.

## Actual checked compiler integration

Checked04 repairs the missing bundled runtime helper. Fresh exact-source row
acquisition passes in 5.226 seconds; the distinct fold source passes in 4.925
seconds. Six-way `local-data-pair-actual04-controls-01` passes all six p points,
five complete-state/native-schedule comparisons and all 17 public boundary cases.
The independent `review-actual-pair-01` additionally checks complete physical
arrays and the entire event stream at p17, plus p0 and U32-max checksums. The
separate fold oracle passes all 40 points on checked17, TypeScript and checked04.
All these are correctness acquisitions, not speed measurements.

Separate diagnostic modules in `local-data-pair-actual04-counts-01` quantify one
complete pair:

| Named operation | Generic17 | Prototype full graph | Plus setup | Plus Dp shell | Actual04 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Apply | 2,295,886 | 6,930 | 1,281 | 1,281 | 1 |
| Fn / partial | 1,243,712 / 199,432 | 4,620 / 2,311 | 1,024 / 256 | 1,024 / 256 | 0 / 0 |
| Jump | 1,110,326 | 2,563 | 256 | 256 | 0 |
| Force entry | 1,185,560 | 332,823 | 330,765 | 527,373 | 65,797 |
| Project | 517,940 | 329,219 | 328,450 | 263,170 | 328,450 |
| Ctor | 66,049 | 66,049 | 66,049 | 769 | 66,049 |
| Build | 65,792 | 65,792 | 65,792 | 256 | 65,792 |

All variants retain exactly 4 allocations, 262,401 reads and 66,561 writes.
Actual04 enters one guard and removes generic descriptor dispatch throughout
the closed computation. Record construction/projection and delayed field work
remain measurable mechanisms. Counts are not CPU shares or elapsed-time gains.

The six-way frozen performance plan is
`local-data-pair-plan-actual04-01/transfer.json`. It uses the unchanged maintained
original-program protocol (five fresh samples, at least three warm calls and
one second, 300 ms timed target, rotating serial CPU3). This avoids 100 warm
calls per half-second generic pair. No timed result is claimed yet.
