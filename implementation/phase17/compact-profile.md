# Profile the installed compact compiler

The fresh profile points to declaration scans and their dispatch overhead as a
small next experiment. It does not demonstrate another speedup. The installed
Phase16 performance comparison remains **12.36 s versus TypeScript 3.61 s**.

`selfhost/build/phase17/compact-profile-02` samples the unchanged selected API
`35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315` on its exact
final source. The immutable Phase16 sampler uses Node 24.18.0, CPU0, a 1,000 µs
sampling interval and stack 4 MiB/heap 4 GiB. This diagnostic run may overlap other
work on separate CPUs. It includes startup and hashing, so its elapsed time is
excluded from all uninstrumented speed ratios.

The source accepts types and produces the expected proof-trust refusal. Inputs
and checked-attempt identities pass before/after verification. V8 records 136,043
nodes and 10,179 samples, with 12,948,713 µs total signed sample weight. The streamed
summary reports these exclusive weighted shares:

| Physical frame | Sample share | Interpretation |
|---|---:|---|
| `run_loop` | 13.26% | Dispatch shared by many generated functions |
| Garbage collector | 8.53% | Allocation remains material; owner not established |
| Node hash update | 5.80% | Includes evidence/input hashing outside compiler work |
| `index_remove` anonymous list reconstruction | 5.61% | Generated line 2793; caller attribution still needed |
| `f_find` | 4.00% | Linear frontend declaration lookup |
| `f_eq` | 3.13% | Shared string comparison wrapper |
| `dn` | 2.86% | Shared definition-name projection |
| Host `validateSpanBook` | 2.64% | Validates the compact representation's source bounds |

The `f_eq`, `dn` and dispatch shares also serve unrelated callers; adding them to
`f_find` would overstate the opportunity. Sample shares are neither call counts
nor recoverable-gain estimates. The earlier expanded-literal census/profile does
not describe the remaining compact workload.

Inspection of the actual generated helper shows one `$JMP` object plus argument
array for each missed declaration in `f_find`. The existing ordinary `lookup`
already uses a Boolean-parameter worker that the original emitter lowers to a
mutual tail loop. The [bounded worker design](../../design/phase17/frontend_find_worker.md)
tests the same pattern with eight additional source lines, preserving linear
lookup, first-definition precedence and lazy tail demand. A controlled comparison
must decide whether that small change earns its maintenance cost.

`compact-profile-01` failed at output-directory creation because its new parent
did not exist. It ran no compiler request and yielded no profile. The failure
record is retained;02 creates a fresh output after preparing the parent and uses
the unchanged sampler. Neither attempt edits the installed compiler. The raw
profile, complete ordinary result, request, consumed worker, stdout/stderr and
summary remain separate from subsequent source experiments.
