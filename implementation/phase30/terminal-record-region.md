# A larger closed region around Mandelbrot's histogram chunk

Status: generated-JavaScript controls and clean long-warm confirmation pass. The
complete chunk improves **8.16×** and the original small program **1.64×** against
unchanged attempt07. The original program remains **133× slower than the pinned
TypeScript output**. No compiler or maintained runtime source was changed by this experiment.
The prospective design is [terminal-record-nested-region.md](../../design/phase30/terminal-record-nested-region.md).

## Frozen implementation and controls

The input is the checked attempt07 original Mandelbrot library from
`selfhost/build/phase30/transfer-07/mandelbrot/candidate.mjs`, SHA-256
`6c5ebcc9f07c0294e876754a6dce168fa0fee489fd2038bc56efe914d24abd3e`.
It includes the corrected exact-callback entry and selected-arm scheduling.
`inspect-terminal-region.py` derives four modules under
`selfhost/build/phase30/inspection-terminal-region-01/`:

| Variant | Change inside `hchunk` |
|---|---|
| baseline | Original emitted bytes |
| outer | Private countdown, original public helpers |
| acyclic | Private countdown and scalar helpers; public `mit` |
| nested | Private countdown, helpers and nested `mit` |

All three variants read the original eleven successor slots once, then require
exact-entry permission, valid primitive scalar inputs and snapshots of all eight
reachable public descriptors. The external Zero arm is unchanged. The private
`mit` accepts its original Nat count, handles zero before decrementing, and reuses
the original BigInt loop and primitive expression text. The terminal result uses
the original `build("Hl", fieldThunks)` with immutable final aliases. `rcol` and
the second pixel pass remain generic.

Independent review found no blocker under the stated standard-intrinsics scope.
The control tool compares all four variants against an independently written
scalar histogram oracle, including all eight counters. The retained
`inspection-terminal-controls-01/report.json` passes 200 oracle states and 123
boundary controls. The expanded `inspection-terminal-controls-02/report.json`
passes the same 200 states and 129 boundaries, adding four throwing copied-length
cases and successor-code reflection/constructibility checks. Other controls cover
the eight descriptors' replacement, Proxy/accessor metadata, saved partials,
raw/forged callback entry, slot getters/reentrancy, boxed/coercing/throwing values,
the original small benchmark, and deferred/throwing Zero-arm constructor fields.
Raw errors and observation order are compared without normalizing error wording.

Separate instrumentation also checks the fast path's internal returned build
before forcing it. Its eight fields remain thunks, a later worker call cannot
overwrite their captures, and forcing produces the expected complete `Hl`.
This internal `apply` export is diagnostic only; the public API is unchanged.

## Mechanism counts, separated from timings

The corrected counts are in
`selfhost/build/phase30/inspection-terminal-counts-02/report.json`. Every row resets
the counters after import and snapshots them immediately after the computation.
These count named runtime operations, not total allocations or CPU costs.

For one complete 64-pixel chunk with the original seven inner iterations:

| Variant | `apply` | Function descriptors | Partial descriptors | Tail messages | Region guards |
|---|---:|---:|---:|---:|---|
| baseline | 2,242 | 1,281 | 1,024 | 449 | 64 inner |
| outer | 1,475 | 578 | 385 | 322 | 1 outer + 64 inner |
| acyclic | 515 | 450 | 385 | 130 | 1 outer + 64 inner |
| nested | 3 | 2 | 1 | 2 | 1 outer |

All four variants produce exactly one build and one final constructor. The final
variant removes administrative transfers rather than changing the histogram or
Mandelbrot work. The guard checks eight descriptors once instead of five
descriptors for each pixel.

For the original small `bench(2,0)` program, `apply` falls from 21,068 to 12,112,
function descriptors from 12,858 to 7,742, and tail messages from 3,603 to 1,815.
The baseline enters 512 inner guards. The nested variant enters four chunk guards
and 256 inner guards in the unchanged recoloring pass. Output remains 887240761.
For `bench(0,0)`, guard entries are the prospectively predicted 128 versus 65.

The first counter receipt, `inspection-terminal-counts-01`, is retained but its
chunk rows must not be used: they retained a live counter object that later
internal build controls mutated. The original whole-program rows were isolated
by subsequent resets. The second version immediately clones each count snapshot;
all twelve computation rows and four internal build controls pass. No generated
program changed during this correction.

## Clean measurement

The frozen configurations are
`selfhost/build/phase30/inspection-terminal-plan-02/{screen,confirm}.json`.
They compare the untouched original small workload across the four variants and
the pinned TypeScript output, then a complete 64-pixel chunk across the four
self-hosted variants. The chunk wrapper fixes the original seven inner iterations
and consumes all eight histogram fields in a checksum. All nine timing inputs
passed exact-result checks before measurement. The maintained harness supplies
rotating fresh processes, prescribed warmup, first-call timing and independent
long-warm confirmation. Instrumented modules are excluded.

The coordinator ran the exclusive CPU3 screen and confirmation. Raw receipts are
`selfhost/build/phase30/terminal-screen-02/report.json` and
`terminal-confirm-02/report.json`, with launcher receipts adjacent. Confirmation
uses five samples per variant, at least three seconds warmup per process and a
300 ms sample target; the complete confirmation launcher took 190.22 seconds.

| Variant | Original `bench(2,0)` median | Complete chunk64 median |
|---|---:|---:|
| baseline | 9.91506 ms | 1.11516 ms |
| outer | 8.77632 ms | 0.83828 ms |
| acyclic | 7.91644 ms | 0.64831 ms |
| nested | **6.04837 ms** | **0.13665 ms** |
| pinned TypeScript | 0.04541 ms | Not measured |

The full chunk gains 8.161× and the complete original program gains 1.639×. The
whole-program baseline sample range is 9.81393–10.03243 ms, versus
5.98123–6.11741 ms for nested. The chunk ranges are 1.10404–1.14269 ms versus
0.13461–0.14196 ms. The ranges are clearly separated. Nested's original-program
second halves remain 2.98–4.08% slower than first halves; its chunk halves differ
by at most 3.37%. Other original-program halves differ by at most 2.21%, and the
outer chunk has residual drift up to 5.79%. These limits remain part of the result.

The short screen showed larger drift: baseline and nested original runs were
still warming, and acyclic chunk second halves were 29–35% slower. Its headline
chunk gain was 9.08×. Use the long-warm 8.16× result; retain the screen rather than
treating it as confirmation.

First-call medians also improved: original 48.35→29.47 ms, chunk 10.53→3.50 ms.
TypeScript's original first call was 5.83 ms. These are separate from warmed
throughput and do not include import time; the raw receipts retain import and
peak-RSS samples.

The original program still spends substantial work in its unchanged second pixel
pass and generic branching/helpers. Closing one pure histogram chunk eliminates
almost all of that chunk's administrative calls, but it does not close the
whole renderer. This explains why the local gain is much larger than the total
program gain; it is not evidence for an 8× gain across arbitrary programs.

`inspection-terminal-plan-01` is retained and unused because its provenance cited
the superseded counter receipt. The active second plan cites the corrected counts.
The speed conclusion comes from the separate clean measurements, not from the
static or dynamic operation counts.

## Reproduction

Run the derivation and controls in fresh output directories; existing evidence is
never overwritten. The tools are in `selfhost/tools/performance/phase30/`:

- `inspect-terminal-region.py --out <new-directory>` freezes all four modules.
- `inspect-terminal-region-controls.mjs <modules> <new-directory>` runs the oracle
  and public boundary controls.
- `inspect-terminal-region-counts.mjs <modules> <new-directory>` creates separate
  diagnostic copies and records named operations and build checks.
- `inspect-terminal-region-plan.py <modules> <new-directory>` freezes clean timing
  inputs after the recorded controls; its evidence paths are explicit.

The measured win justifies a small compiler implementation following
[terminal-region-compiler-extension.md](../../design/phase30/terminal-region-compiler-extension.md),
followed by actual-emission controls and confirmation. It does not establish
safety for record inputs, mutable arrays, foreign callbacks, arbitrary recursive
SCCs or a new general backend.
