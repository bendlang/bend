# Checked-source scalar tree results

The additional checked-source gate passes on attempt12: three admitted trees,
eight deliberately generic neighbors,270 independent scalar points across
pinned TypeScript/attempt11/attempt12, and six paired live-owner/saved-partial
observations. This extends coverage through the actual source parser/checker
and backend, complementing the independently authored synthetic KDef tests.
No production compiler or runtime source changed and no timing was performed.

The [prospective design](../../design/phase30/source-scalar-tree-controls.md),
source `inspect-source-trees.bend`, oracle `inspect-source-tree-controls.mjs`
and acquisition tool `inspect-source-trees.py` are retained with consumed copies
and exact emission receipts under `inspection-source-trees-04` in the Phase30
build directory. All three compilers accept and emit the identical source;
the candidate controls report is `inspection-source-trees-04/controls/report.json`.

| Checked source shape | Candidate12 admission | Independent expected behavior |
| --- | --- | --- |
| Bool-result tree with ordinary Boolean helpers | Private tree | Different left/right U32 states; ordered `left && !right` combine |
| Nat-result tree | Private tree | Native BigInt result with wrapped U32 subtraction of distinct children |
| Nat carried state and Nat result | Private tree | Both results consumed through a scalar choice; full48-bit maximum preserved |
| Combine captures parent state | Generic | Parent value participates in each combination |
| One child | Generic | One recursive child doubled after return |
| Three parallel children | Generic | All three independently evaluated and combined |
| Changed right predecessor | Generic | Right child explicitly starts at zero |
| F32 state/result | Generic | Every add/multiply/subtract rounded separately |
| Record result | Generic | Complete source projection compared across differing JS record representations |
| Two sequential one-binding lets | Generic | Same mathematical tree, outside the initial strict parallel-let shape |
| Native Base Boolean helper closure | Generic | Bool.and/Bool.not remain outside ordinary-source private capture |

The oracle uses separately written recursive arithmetic, not extracted generated
expressions. Five small depths include zero and5; U32 states include the maximum,
F32 includes signed zero and a large rounded value, and Nat state includes
`281474976710655n`.270 points each run on all three modules. `Object.is` compares
complete primitive results, including signed zero. No exponential depth-boundary
computation is launched. The six host observations mutate each positive owner's
public code before ordinary or saved-partial invocation and compare full value
and callback event order on actual11 and12.

The failed preparation attempts remain visible:

| Evidence | Result and correction |
| --- | --- |
| `inspection-source-trees-launch-01` | Python launcher parse failure before any child; retained source uses reserved `pass` as a keyword argument. Fixed with dictionary update. |
| `inspection-source-trees-01` | All three compilers reject linear predecessor duplication. Corrected the fixture to use unrestricted `+n`, as the original rcol does. |
| `inspection-source-trees-02` | All compilers check/emit; the positive-admission assertion fails because separate source lets form nested one-binding terms. Positive fixtures now use explicit parallel syntax; sequential form remains an executable negative neighbor. |
| `inspection-source-trees-03` | Both Nat trees admit; Bool assertion fails because Base Bool.and/Bool.not are native definitions. Their `native:true` flags were verified in the attempt12 checked Base cache. Equivalent ordinary source helpers form the positive witness, while the Base-helper version remains a negative neighbor. |
| `inspection-source-trees-04` | All11 admission assertions,270 oracle points and6 ordered observations pass. |

These failures exposed fixture assumptions and conservative admission boundaries,
not wrong generated results. The gate establishes ordinary checked-source and
tested backend behavior. It does not enlarge the historical frontend percentage,
certify unsafe recursive definitions in an independent proof kernel, or imply
that every semantically pure tree is currently optimized.

## Renewal on attempt13

`inspection-source-trees-final-13b/` renews these same controls against the
checked attempt13 image (API
`b6efd08b1f00907d44566405db53bc6caa4ea9cbc2e76432eaba7ca97a908ef9`).
Its eleven admission decisions,270 independent scalar points across all three
modules and six paired live-owner/partial observations pass. The pinned
TypeScript and pre-tree attempt11 modules are retained byte-identical from
`inspection-source-trees-04/`; their checked receipts and exact frozen source
identities are verified. Only attempt13 is newly checked and emitted. The
control derivation changes its descriptive image label; assertions and oracles
are unchanged. This checks the maintained frame-reuse implementation without
relabeling the original attempt12 evidence.

The preceding `inspection-source-trees-final-13/` remains incomplete: its
candidate emission passed, then the controls child exited unsuccessfully while
the workspace exhausted disk capacity. That child's stdout and stderr are empty,
so it provides no semantic failure diagnosis. Concurrent sandbox launches
reported `ENOSPC`. After the lead recovered space by verifying and removing only
duplicate temporary archive extractions, the fresh13b run passed. The interrupted
receipt and partial files were preserved unchanged.

`inspection-source-trees-final-14/` repeats the same retained-reference renewal
for the private-Let compiler image. All11 admission decisions,270 scalar points
and6 paired host observations pass. Candidate14 alone is freshly checked and
emitted; the original TypeScript/attempt11 modules and source bytes are reused
with their existing provenance. This result is distinct from the13b renewal.
