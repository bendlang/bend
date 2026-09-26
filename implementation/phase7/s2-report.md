# S2 report: one provenance traversal

Status: complete, 2026-09-26.
[Frozen design](../../design/phase7/s2_provenance_consolidation.md) ·
[Independent review](s2-evidence/independent-review.md).

The installed compiler contains **15,826 physical lines**, down **135** in this
phase and **683 (4.14%)** from the original 16,509-line baseline. The public origin
APIs now share the loader's actual trace. The separate module-reparsing and
event-to-source alignment machinery has been deleted. The revised S2 reduction
gate passes; this is not completion of the original explicit-term migration or
the 50%/75% milestones.

## Reduction and contracts

| Production measure | S1 | S2 | Change |
| --- | ---: | ---: | ---: |
| Physical lines | 15,961 | 15,826 | -135 |
| Nonblank lines | 13,343 | 13,209 | -134 |
| Bytes | 494,957 | 491,193 | -3,764 |
| Definitions | 1,473 | 1,460 | -13 |
| Laws | 1,245 | 1,232 | -13 |
| Datatypes | 61 | 61 | 0 |

Only `src/diagnostic/frontend.bend` changes: 369 to 234 lines. Fourteen private
helpers disappear, including the duplicate reverse implementation; one shared
trace dispatcher is added. The trace already records module order and declaration
event counts, so provenance no longer reconstructs that alignment by parsing
source a second time. The explicit Boolean selects all definitions or an exact
name; `""` remains an exact empty-name filter. No new representation or metadata
field is introduced. Token spans, UTF-16 conversion, final-core routes and loader
error handling remain. All 13 retained origin/range/route/segmentation helpers
have unchanged bodies. Host, cache schema, runtime and manifest membership do not
change. See the [source recount](s2-evidence/source-recount.json).

The 13-helper, 139-line deletion pool overlaps S0's future provenance pool and is
credited here only. The full sum-type/numeric-span proposals remain deferred:
their reviewed implementations add more machinery than they remove. The revised
ceiling was 15,862 lines / 492,513 bytes; the candidate satisfies both.

## Validation and artifact scope

- Fresh genuine checked B1 and maintained equality derivative pass the existing
  21-case paired selection. Its seven known exact differences remain visible.
- Every maintained component group passes, including source provenance, dependent
  checking, graph normalization, deep freshening, specialization and runtime ABI.
  The harness contributes **51/51 passing tests, zero skipped**.
- The new [cross-version gate](s2-evidence/provenance-equivalence.json) passes
  **530 assertions across 20 raw/parsed-source rows**. It compares all three
  public origin APIs, complete ordered results, empty/unknown filters, alias and
  diamond imports, law/fill events, repeated terms, Unicode ranges, final paths,
  graph errors and seed invalidation. Targeted genuine checked APIs expose the
  unfiltered API omitted from the ordinary 54-root artifact.
- The existing [diagnostic reuse gate](s2-evidence/diagnostic-reuse.json) passes
  **204 assertions across 23 rows**, including real Base, exact located errors,
  prefix fallback, request-local tracing and actual host inspection.
- [Checked](s2-evidence/functions-checked.json) and
  [optimized](s2-evidence/functions-optimized.json) generated-function comparisons
  preserve all 54 selected exports and identical reachable code for **52 roots**.
  Only `f_load_origins_for` and `f_loaded_origins_for` change their closures.
  Accepted checking, interpretation, specialization and JS/native generation are
  within the unchanged set. Changed roots rely on behavioral controls above.
- Installed release verification, ordinary check, interpreter and generated JS
  pass; the latter two both print `42`. See [smoke results](s2-evidence/release-smoke.json).

The API hash changes, so the driver prepares a new compiler-bound Base cache.
This is expected integrity behavior; caches are not relabeled across APIs.
No native execution, broad frontend sweep, all-definition fixed point or GPU
hardware run is claimed. Clang is unavailable in this environment. Native
generation is unchanged at source and reachable generated-function levels; its
prior execution evidence retains that scope. Cross-version preservation is not
an independent upstream conformance oracle.

## Controlled affected-path timing

The [serial timing experiment](s2-evidence/provenance-timing.json) pins Node
24.18.0 to CPU 0, warms both checked APIs, alternates order over four pairs and
uses the same frozen 61-definition input. Exact output equality precedes timing.

| Public route | S1 median ms/call | S2 median ms/call | Change |
| --- | ---: | ---: | ---: |
| Load every origin | 245.69 | 183.33 | -25.4% |
| Load one definition's origins | 180.76 | 107.61 | -40.5% |
| Reuse an existing trace | 27.00 | 26.03 | -3.6% |

All pass the 5% regression guard on this workload. This measures provenance,
not whole compilation or a new TypeScript ratio. The process loads both APIs;
its recorded peak RSS is not a comparative memory measurement. Identical output
objects and unchanged term/cache layouts provide no evidence of retained metadata
growth; no numerical memory improvement is claimed. Generated selected API size
decreases. The historical full-source 6.03× TypeScript result is still historical.

## Review context, evidence and next phase

The affected module is 36.6% shorter and has one ownership source for module/event
alignment. The earlier fixed parser/checker/backend review-file sets are unchanged
in this phase; no reduction to those whole-file context measures is claimed.
The new cross-version test is separate validation code, not compiler functionality
moved outside the production count. Evidence programs are separately recorded.

The [raw capsule](s2-evidence/raw.tar.gz) preserves checked snapshots, both targeted
APIs, generated artifacts, commands, observations and logs. The
[manifest](s2-evidence/manifest.json) records every member hash and archive hash;
all members were read back and verified.

Installed source: `00b8c223ff070d40fefea7208eb2f7de6949ee63eea1944fdf3e04b3913db074`.
Checked API: `db97c8578746e5dfa2c3f2a8d3c0dbc2e58f5616cea14d5d177e41fb66f39604`.
Optimized API: `b3a75d62c7946301d987474fe097d5eb2e08cad2edcc6b3eae5371f5c5effbed`.

S2 is complete under its evidence-driven revised scope. S3 next designs one
authoritative structured checker result and deletion of diagnostic replay, using
the prior candidate as evidence rather than importing it without current gates.
Type-fact retention must earn its complete replacement cost independently.
