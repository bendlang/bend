# S3 scope and measurement review

Read-only source/metadata review against S2 `7474b0b`; no compiler, tests or
benchmarks were run by this reviewer. This report records methodology and source
facts, not completion of the running S3 validation. Only this report was written.

## The fixed workload remains useful

`selfhost/build/phase4/private/component/core.bend` is still 60,909 bytes / 2,186
physical lines, imports only Base, and has SHA-256
`7ea730ae3e2ee190ff55a0def12f8410203fee9fa2c0573df52265b583523ccf`.
Its bytes match the identity in the historical
[experiment capsule](../../phase6/structured-checker-evidence/manifest.json).
The expected emitted JavaScript SHA-256 remains
`016a5cedeb7e285adeabdad19388d99d3d9070668c15776ccc10fab8ea7b7186`.
It is deliberately a frozen source program: removing compiler implementation
lines in S1/S2 does not remove declarations from this benchmark input.

The [S1 report](../s1-report.md) records byte-identical selected compiler APIs;
the [S2 report](../s2-report.md) records unchanged generated closures for 52 of
54 exports, with only the two origin roots changing. Those facts support using
the unchanged output oracle, but do not prove S3 will preserve it. Fresh S2 and
S3 preflights must independently produce the oracle and identical observations.
S2 provenance is common to the two new compiler versions. The early/late failures
still exercise one authoritative result versus chronological diagnostic replay;
their unchanged frontend load cost remains part of the measured request.

This is a compiler-core library workload and two single-error placements, not
the current complete compiler source, the full validation loop, a B1→H→H fixed
point, or a new TypeScript speed ratio. Its library mode bypasses some program
entry validation, and its two failures do not represent every diagnostic kind.

## Controls and explicit gates

The historical [comparison tool](../../../selfhost/tools/performance/phase6/structured-checker-compare.mjs)
requires verified checked-parent/equality-derived attempts, a shared Base/runtime,
one frozen candidate host supporting both compiler versions, separately primed
API-specific Base caches, equal decoded Base graphs, exact preflight results,
and reverified input hashes. It runs accepted/early/late workloads serially in
four fresh processes each, in ABBA order, CPU 0, with 4 GiB heap / 4 MiB stack.
Each worker has a 90-second maximum and the shared absolute deadline. Instrumented
check-call counts are a separate mechanism control and must not become timings.

The [fresh-process worker](../../../selfhost/tools/performance/phase5/equality-worker.mjs)
measures requests after import and before output writes; process duration and
peak RSS include those costs. Both views matter. The current S2/S3 attempt
metadata identifies equality-derived B1 artifacts with matching Base SHA-256
`b8c2734d45ec6b4ce70fee70ff06ef35e08fce885af8852d8eb77dbff020e946`
and runtime SHA-256
`26f5eee2f54b194b64f768df6ff505c67bf7a5df2159aa06caf53ecba54e910b`.
Those are metadata observations; the tool's fresh identity checks remain required.
The S3 historical-input manifest freezes the exact consumed patch/counter/timing
tool/worker bytes. No S3 timing configuration or completed timing result existed
when this review began; use fresh S2/S3 attempt identities, Node 24.18.0 and a new
deadline, not the historical configuration.

Two review obligations are not enforced by a successful process exit:

- The comparison tool sets `complete: true` even if
  `acceptedWithinFivePercent` is false. Require that field to be true for both
  request and process pairs. Record the early/late material-gain fields separately.
- Peak RSS is recorded, but its 10% growth budget is not asserted. The generated
  compiler API's size is distinct from the unchanged emitted workload's size;
  calculate both API sizes and the RSS ratios explicitly and resolve growth
  beyond the design threshold. Do not infer a pass from the fixed output hash.

Four processes per workload are a bounded regression pilot, not a confidence
interval. Run it without competing intentional compiler/archive/hash work.

## Concept delta and deferred facts

The source removes 13 helpers and adds three, a net ten definitions/laws. More
substantively, one event loop replaces separate String-verdict and diagnostic
replay loops; one prefix seeding route replaces two; definition/template checking
keeps the original `KChecked` instead of reconstructing it on rejection.
[Kernel](../../../selfhost/src/check/kernel.bend) `check_definition_result` and
[producer](../../../selfhost/src/diagnostic/produce.bend) `dg_suffix_check` show
that handoff. The host adds one explicit version-1 capability and retains the
legacy compatibility branch. Existing result layouts and String public APIs
remain; compiler source falls by 139 lines, or 137 after host support is charged.

Source inspection establishes these call paths and unchanged expressions. It
does not establish exact verdicts, first-error order, prefix fallbacks, diagnostic
metadata, call counts or acceptable cost. Those require the new full frontend
vectors, diagnostic/prefix/host controls and controlled timing results. In
particular, String-only rejection now constructs an internal diagnostic result;
the audit cannot declare its cost zero. `good` tests the error string, so the
legacy ADT/foreign `bad("")` wrapper means success despite its placeholder payload.

Typed-fact migration remains unfunded. The unchanged 400-line / 10,850-byte
[annotation module](../../../selfhost/src/check/annotate.bend) reconstructs types
from the validated, specialized book and lexical context (`ka_type`, `ka_type_app`,
`ka_app_spine`), with dependent substitution and backend-selected roots/stops.
[Specialization](../../../selfhost/src/check/specialize.bend) changes the book,
creates template instances and shifts binder IDs (`KSpecState`, `specialize_book`,
`sp_shift`). The host annotates after this transformation. S3 preserves failures
within their original check; carrying successful types across specialization
would require a separate transformation/invalidation contract. Historical
[attribution](../../phase6/typed-facts.md) found 1,205 `ka_type` calls and 2,817
application-spine calls with zero repeated exact argument identities. This is
counterevidence to that exact-input cache on that workload, not proof that all
future type reuse is impossible or a current-run measurement. No annotation
deletion or positive-path speed gain is credited to S3.

## Fixed dependent-application review context

Reuse exactly the nine files under `dependent_application_check` in
[the prior context inventory](../s1-evidence/contexts-root.json), with whole-file
counts from `git show 7474b0b:PATH` versus the current worktree:

| File | Physical lines S2 → S3 | Bytes S2 → S3 |
| --- | ---: | ---: |
| `selfhost/src/core/term.bend` | 463 → 463 | 8,527 → 8,527 |
| `selfhost/src/core/normalize.bend` | 560 → 560 | 17,027 → 17,027 |
| `selfhost/src/check/kernel.bend` | 1,261 → 1,245 | 35,691 → 35,212 |
| `selfhost/src/check/quantity.bend` | 175 → 175 | 3,514 → 3,514 |
| `selfhost/src/diagnostic/trace.bend` | 131 → 131 | 4,866 → 4,866 |
| `selfhost/docs/ARCHITECTURE.md` | 245 → 245 | 15,301 → 15,301 |
| `selfhost/tests/kernel.mjs` | 88 → 88 | 9,256 → 9,256 |
| `selfhost/tests/kernel-upstream.mjs` | 33 → 33 | 2,643 → 2,643 |
| `selfhost/tests/specialize.mjs` | 36 → 36 | 4,048 → 4,048 |
| **Total** | **2,992 → 2,976** | **100,873 → 100,394** |

Nonblank lines are 2,510 → 2,496. The reduction is 16 physical / 14 nonblank /
479 bytes; all eight files other than kernel are byte-identical. This fixed task
context measures a modest reduction, not the full 139-line compiler saving or a
50% context reduction. It is not the complete review package for S3's book-level
change: producer, prefix, host compatibility and diagnostic controls were also
read for the scope findings above. Keeping the fixed task file list prevents
claiming a reduction by changing the measurement boundary.
