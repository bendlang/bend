# Phase13: structured rewriter investigation

The bounded experiment is complete. A selector-fusion prototype checks the
complete compiler source with **10.6% less process time**, but it does not replace the installed
Phase12 compiler. The agreed investment criterion was roughly 20% less checking
time, or a compelling smaller gain with simpler maintained machinery. The
self-contained implementation adds 7,010 bytes and 239 physical helper lines.
It shares recognition code, but does not establish that combined tradeoff.

The useful result is a validated experimental image and a clearer optimization
target: eliminate intermediate dispatch work. Merely replacing branch closures
with named workers and explicit captures was slightly slower. This is a bounded
decision about these implementations, not proof that larger rewrites cannot help.

## Designs, stages and decisions

The [master design](../../design/phase13/structured_rewriter.md) was frozen before
profiling. Each hypothesis has its own prospective record:

| Stage | Outcome | Evidence/report |
| --- | --- | --- |
| Fresh released-image profile | Completed; dispatch and GC remain substantial | [P13-001](../../experiments/phase13/P13-001-profile.md) |
| Shared structural view and branch lifting | Exact historical replay; lifting rejected on cost | [Rewriter](rewriter.md), [P13-002](../../experiments/phase13/P13-002-structured-branches.md) |
| Independent semantic controls | Unsafe lifting cases found, repaired and preserved | [Controls](controls.md), [P13-003](../../experiments/phase13/P13-003-controls.md) |
| Matched histories and controlled measurement | All surviving images pass bounded gates | [Measurement](measurement.md), [P13-004](../../experiments/phase13/P13-004-measurement.md) |
| One-family selector fusion | 6.63% less process time; earned bounded expansion | [Selector report](selector-fusion.md), [P13-005](../../experiments/phase13/P13-005-selector-fusion.md) |
| Constant-scope selectors in six checking owners | 10.56% less process time; integration deferred | [Combined report](constant-scope-selectors.md), [P13-006](../../experiments/phase13/P13-006-constant-scope-selectors.md) |
| Self-contained helper feasibility | Versions 1–5 replay exactly; v6 reproduces prototype; larger helper | [Maintained-helper report](rewriter-maintained.md), [conditional design](../../design/phase13/integration.md) |

No production Bend source, maintained helper, host, runtime, pin or installed
artifact changes in this phase. All 75 pre-existing unrelated Phase6 files are
checked against their starting hashes and kept unstaged.

## Complete-source performance

Each row is a separate exclusive, fresh-process ABBA comparison on the exact
same complete compiler source and unchanged host/runtime. The mean uses two
samples per image; these are screening measurements, not confidence intervals.
The initial profile and diagnostic operation counts are excluded from timings.

| Pilot | Baseline process | Candidate process | Reduction | Baseline request | Candidate request |
| --- | ---: | ---: | ---: | ---: | ---: |
| Named workers, one owner | 27.4538 s | 27.7322 s | −1.01% | 26.3075 s | 26.5837 s |
| Original-body selector fusion, one owner | 27.3299 s | 25.5166 s | 6.63% | 26.1801 s | 24.3722 s |
| Constant-scope selector fusion, six owners | 27.3622 s | 24.4740 s | 10.56% | 26.2075 s | 23.3271 s |

The combined request reduction is 10.99%; process speedup is 1.118×. Its maximum
observed RSS is 1,334,972 KiB versus 1,341,740 KiB for its paired baseline. Two
observations do not establish a general memory improvement. Raw reports are
`selfhost/build/phase13/measure-{norm-eval,selector,const}-pilot-01/report.json`.

All runs use Node 24.18.0, CPU0, a 4MiB stack and 4GiB heap. Other intentional
compiler/archive jobs pause during timing. Each API has its own validated disk
Base cache; preparation and rewriting happen outside timed workers. OS caches
are not flushed. The unchanged Phase8 worker checks complete ordinary results,
including the expected compiler-source proof-trust failure/unsafe-definition
report. Launch errors, signals, timeouts and overflow invalidate a sample even
if a wrapper reports exit zero. Complete results and consumed identities agree.

There is **no new TypeScript ratio**. The installed release's last paired result
remains 26.8969 s versus 2.8550 s for pinned TypeScript, a 9.42× process gap. Do not
divide these new prototype timings by an old TypeScript sample. No emitted
user-program runtime or JS/C compilation-workflow gain is measured here.

## What the counters established

The probes use two valid modules with 4, 16 or 64 definitions per module. Their
loaded books and checker results are exact across images. At 64 definitions:

| Checking operation | Phase12 | Named workers | One-owner selectors | Six-owner selectors |
| --- | ---: | ---: | ---: | ---: |
| Trampoline dispatches | 60,344 | 60,344 | 56,799 | 54,413 |
| Consumed argument-array elements | 70,287 | 91,557 | 66,742 | 64,356 |

Plain lifting replaces 4,254 selected closures with worker entries but adds
21,270 capture-array elements. Its reduced `run_tail` call count reflects
explicit packet construction, not fewer messages.

One-owner fusion removes 3,545 intermediate steps; six-owner fusion removes
5,931 during checking and another 1,052 during loading. Each omitted step removes
a closure, Unit, message, singleton array and dispatch. These are instrumented
operation counts, not allocated-byte measurements. The runtime, selected terminal
body frames and public wrappers remain unchanged. The selector conditions move
to an earlier frame, so operation counts and source reasoning alone cannot prove
the fixed-stack resource contract.

## Correctness and replay boundaries

The shared view reproduces authentic version 1–5 API bytes and exact serialized
statistics, including skipped-site offsets and report ordering. The final
self-contained feasibility helper does the same, and its default/explicit v6
reproduces the six-owner prototype exactly. It imports only Node builtins.
Evidence: `rewriter-stage1-01/report.json` and
`rewriter-maintained-replay-01/report.json` under `selfhost/build/phase13`.

Independent controls include 23 packet-convention comparisons, five confirmed
unsafe-capture witnesses, 30 structural-refactor comparisons plus four range
checks, and 17 corrected actual-lifter controls. The first lifting implementation
loses a shadowed `undefined` binding and mishandles three compound shifts; those
failures remain preserved. Its exact normalizer candidate does not contain the
bad shapes, and the repaired recognizer emits the identical candidate bytes.

The one-owner selector passes 30 paired semantic observations and 23 refusals.
The combined constant-scope rule passes 72 paired observations and 45 refusals.
All ten actual constant declarations retain their bytes and nearest-arrow scopes;
52 surviving arrows are exact, two enclosing arrows contain declared nested
rewrites, and 28 unused-Unit arrows disappear. Every unselected top-level function
is exact. The first selector preparation guard failure and a body-comparison
harness's raw-parent/v5-baseline mix-up are retained as setup failures.

Baseline calibration passes a fresh 6,000-character string and both exact 53/60
request histories. Every surviving candidate then passes paired fresh checks and
both histories: each paired gate records 226 complete historical observations,
113 per image, matching the released vectors and paired baseline. All predecessors, request order, worker state and original
results are retained. The old 53rd request's rejected-seed failure is historical
evidence, not the current success oracle. There is no worker recycle, input drift
or launch error in the accepted gates. These bounded histories do not establish
universal stack safety.

## Complexity and promotion

| Maintained-helper surface | Physical lines | Nonblank lines | Bytes |
| --- | ---: | ---: | ---: |
| Installed v5 helper | 296 | 285 | 27,345 |
| Self-contained v6 feasibility helper | 535 | 519 | 34,355 |

The prototype's imported support plus historical helper totals 640 lines; the
self-contained layout removes that dependency duplication. It also replaces
separate module/function and branch recognizers with one source-range view.
Nevertheless, total helper context grows 25.6%, physical lines grow 80.7%, and
constant-scope/selector obligations are added. Adding only the existing 207-line
maintained tests gives 742 lines and 52,034 bytes. That is an arithmetic total,
not a runnable replacement test bundle: the existing tests still import the
installed helper. Production would need the imports ported and maintained
coverage for the new selector rule. Independent experimental controls
are retained separately and are not hidden as a completed production test suite.

Bend source remains 15,130 physical / 12,916 nonblank lines in 59 modules. This
phase achieves no Bend source reduction or conformance increase. Because the
speed/complexity gate does not justify promotion, it does not run a new checked
release build, full 2,996-observation frontend sweep, 37-pair backend sweep,
native/JS emission matrices or relocated release suite on the prototype. Those
remain prerequisites for a future production integration, not claimed passes.
The previously validated Phase12 release stays usable and its lineage is checked
again at phase closure. `selfhost/build/phase13/final-gates-01.json` records a
passing release replay, unchanged production paths and pin, and all 75 unrelated
file hashes/statuses preserved. No new self-reproduction, Lean or GPU claim is made.

## Identities, recovery and next decision

- Installed baseline API: `0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697`.
- Genuine checked parent: `a8453133f37a0965b7291795af2e06c7c65e3ee7c97a8ff4b14b98cfba2e5568`.
- Named-worker API: `d74ecdbd243bb1bafe4ed726b1b697ccb3b942ca39a0b7a8dfe27e5ff5581554`.
- One-owner selector API: `5a1a9449ec9a190e1bee0b695d211fd83e5672a6e1fc87623c3e3826268d4441`.
- Six-owner selector API: `7eca544a1f2e3ab637064533117f290bd576c5774d111a619fdd12755817c81e`.
- Pinned upstream: `b2111cf43244e65f76ddc278ee695e669f720cbf`.

The fresh release profile retains 56,402,488 raw bytes, SHA-256
`0b78df312769c3c98b1f5b57707128a38ee884de9dc605620bdc3cd99cf7b6e7`.
Its 2,698 samples assign 14.55% exclusively to `run_loop`, 13.47% to GC, 4.72%
to `norm_eval_node`, 4.54% to `lookup`, 3.83% to `index_find`, 2.92% to
`check_node`, and 2.78% to `check_ctr_found`. These are lexical-owner samples,
not logical caller attribution or recoverable-gain estimates. The instrumented
28.884-second process is excluded from performance ratios.

[Evidence preservation](evidence/README.md) records complete raw attempts, tools,
failed controls, profiles, exact histories and measurements, with verified byte
and mode recovery and explicit prerequisites. The installed compiler guide
remains linked from the repository README.

A future decision should start from these measured limits, not multiply the
pilot gains or relaunch broad inlining. Selector fusion is a valid, bounded
optimization candidate; a larger rewriter still needs either more substantial
whole-workload savings or a cheaper maintained representation. The current
phase stops here rather than broadening the grammar to chase a target number.
