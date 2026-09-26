# S1 report: obsolete paths retired, smaller source release installed

Status: complete, 2026-09-26.
[Design](../../design/phase7/s1_retire_obsolete_paths.md) ·
[Independent review](s1-evidence/independent-review.md) ·
[Preserved evidence](s1-evidence/manifest.json).

The compiler now contains **15,961 physical lines**, down **548 (3.32%)** from
16,509. The phase meets its 16,000-line ceiling and removes inactive alternative
algorithms without adding a replacement mechanism. The freshly checked and
optimized selected compiler APIs are **byte-identical** to the previous release.
The validated attempt is installed as the ordinary compiler default.

## Source and conceptual reduction

| Measure | Before | After | Change |
| --- | ---: | ---: | ---: |
| Production modules | 59 | 59 | 0 |
| Physical lines | 16,509 | 15,961 | -548 |
| Nonblank lines | 13,803 | 13,343 | -460 |
| Source bytes | 509,937 | 494,957 | -14,980 |
| Definitions | 1,526 | 1,473 | -53 |
| Laws | 1,280 | 1,245 | -35 |
| Datatypes | 66 | 61 | -5 |

The [exact recount](s1-evidence/source-recount.json) records eight changed modules.
Every changed module exactly matches S0's hash-guarded declaration deletion; no
active function body was rewritten. The removed paths are the old recursive
freshener, recursive strong normalizer, non-graph strong-normalization worklist,
recursive comparison helpers, unused flat-layout packing subsystem and unused
native bang-reference traversal, plus their private/readback/frontend helpers.

Active lazy graph normalization, freshening work frames, `norm_rebind`, native
word/segment types, all supported loader/provenance APIs and all 54 selected
exports remain. Independent remaining-source and maintained tool/test/doc scans
find no references to the 58 retired function/type names. Undocumented private
helper exports in an all-definition library disappear deliberately.

The only auxiliary source repair adds one line to an existing test fixture: its
mock driver lacked the `createPersistentInspector` export now imported by the
adapter. The new stub throws if called, preserving the test's artifact-location
scope. Compiler, host, runtime and conformance-oracle logic are unchanged.

The review also caught ten lines (`f_dv`) allocated to both S1 and future S4 in
S0's summaries. They belong to S1 only. The [S0 erratum](s0-report.md) lowers the
future selector pool from 62 to 52 and its gross S4 pool from 224 to 214. This did
not change S1's actual source counts or deletion inventory.

## Validation

- The maintained workflow completes a genuine checked B1, verified equality
  derivation and all 21 focused paired controls. Their seven known exact
  diagnostic differences remain visible; those controls assert acceptance/phase,
  not full diagnostic equivalence. See [the selected report](s1-evidence/focused-validation.json).
- Both complete selected APIs equal their baseline bytes, and all 54 exports
  match. Runtime and host identities are unchanged. The
  [artifact comparison](s1-evidence/artifact-comparison.json) verifies the hashes.
- All compiler/runtime component groups pass: checking/annotation, diagnostics,
  source parity/provenance, native identity, indexing, reachability, prefix reuse,
  source/seed loading, deep freshening, main reporting, readback, normalization,
  specialization and JS primitive ABI. See [the component report](s1-evidence/component-report-02.json).
- After repairing the stale fixture, **51/51 harness tests pass, none skipped**;
  see [the command](s1-evidence/harness-04.command.json) and
  [complete output](s1-evidence/harness-04.stdout).
- Installation uses the existing release installer. Integrity/derivation replay
  passes, ordinary check succeeds, and interpreter and generated JS both print
  `42` for the existing scalar smoke program. See [the CLI observations](s1-evidence/release-smoke.json).

The raw component report remains `pass:false` because its final harness group
encountered the stale mock. It has not been rewritten to hide the failure. The
separate repaired harness run supplies that group's final passing evidence; all
preceding component checks were unchanged and already passed.

Two environment/setup outcomes are retained. First, the sandbox's synchronous
Node subprocess handling reports `EPERM` even with status zero and valid child
stdout. A minimal check succeeds outside the sandbox; the suite was rerun there.
Second, the first repaired harness run omitted `BEND_UPSTREAM`, so three gated
tests skipped. Repeating with the original pinned-upstream environment gives
51/51. Neither failed/incomplete attempt is called a successful complete gate.

## Context and release identity

The fixed review tasks use unchanged file-selection rules:

| Task | Physical lines before → after | Bytes before → after |
| --- | ---: | ---: |
| Parser first-error choice | 5,716 → 5,674 | 198,816 → 197,979 |
| Dependent application check | 3,156 → 2,992 | 106,647 → 100,873 |
| Constructor lowering across JS/native | 3,397 → 3,295 | 126,336 → 123,541 |

[Parser context](s1-evidence/parser-context.json) and
[checker/backend contexts](s1-evidence/contexts-root.json) retain each file hash.
These are conservative whole-file context proxies; their overlapping sizes are
not a language-concept count or a measurement of human effort.

The current [release manifest](../../selfhost/dist/release.json) binds the smaller
source to its fresh genuine checked parent and unchanged derivative:

- Source: `90675fb38a8ad68fc7b301417246d99f40c8af2678a8a2316923cebb2eb4a04f`.
- Checked API: `5969c53d34a088bc9630eb2c065c2eea7fd260294cf3fefb14dffb305b7e4667`.
- Optimized API: `e2b5463678a26558e8fea1d585782e0863f1046067949a374f0469080281b15a`.

No runtime speedup or new TS ratio is claimed: removed functions were already
outside the selected compiler closure. API/runtime/host byte identity preserves
its existing behavior evidence. The old full-source timings and B1→H→H proof
belong to their recorded source/workload; no new all-definition fixed point,
broad conformance sweep, native execution or GPU hardware run occurred here.
The phase's genuine checked-source and unchanged-selected-artifact gates are
distinct from those future integration gates.

## Preservation and next phase

The [evidence capsule](s1-evidence/raw.tar.gz) contains every S1 attempt, compiler
snapshot, generated API, command, raw failure, selected observation and release
smoke result. All archive members were independently read back and checked
against the [manifest](s1-evidence/manifest.json). Large local build paths alone
are not the preservation mechanism.

S1 is complete. Before S2 implementation, write a bounded design using the actual
15,961-line starting point and S0's counterevidence. Explicit terms/provenance
remain candidates, not a credited 2,500-line saving. Every subsequent completed
phase must still reduce both source size and conceptual complexity; the 50% and
75% milestones remain unachieved.
