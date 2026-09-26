# S3 report: one authoritative structured checker result

Status: complete, 2026-09-26. Validated release installed.
[Design](../../design/phase7/s3_authoritative_checker.md) ·
[Scope review](s3-evidence/scope-review.md) ·
[Independent review](s3-evidence/independent-review.md).

The candidate contains **15,687 Bend lines**, down **139** from S2 and **822
(4.98%)** from the 16,509-line baseline. Its host adds two lines, so the combined
production reduction is **137 lines**. One chronological checker preserves the
original failure and trace. Public String APIs project its error; diagnostics
consume the same result. The host checks a selected failing body once rather
than four times.

## Source and mechanism reduction

| Production measure | S2 | S3 | Change |
| --- | ---: | ---: | ---: |
| Physical Bend lines | 15,826 | 15,687 | -139 |
| Nonblank Bend lines | 13,209 | 13,093 | -116 |
| Bend bytes | 491,193 | 486,768 | -4,425 |
| Definitions | 1,460 | 1,450 | -10 |
| Laws | 1,232 | 1,222 | -10 |
| Datatypes | 61 | 61 | 0 |

Kernel, prefix and diagnostic producer change. Thirteen private helpers disappear
and three are added. The String-only event traversal, separate prefix traversal
and diagnostic definition/template replay are retired. Existing definition and
template workers retain `KChecked`; one event worker implements both full and
validated-prefix checks. The driver adds two lines and 303 bytes, yielding a net
4,122-byte reduction across production languages. No compiler reasoning moves
into the host. Type-fact retention/annotation deletion remains deferred.

The exact capability `compiler_check_result_abi() == 1` selects one-result host
consumption. Older artifacts retain their guarded legacy path. Public String and
`DResult` shapes, chronological event checks, unsafe/signature rules, quantities,
termination, TODO checks and exact-prefix fallback remain. ADT/foreign helpers
still express success with an empty error string; a comment explains why `good`
accepts that result independently of its placeholder payload tag.

## Correctness and compatibility

- Genuine checked B1, equality derivation and all 21 maintained focused cases
  pass. The selection retains its seven known exact diagnostic differences.
- All maintained components pass. The harness passes **52/52 tests, none skipped**,
  including a new check that absent, numeric 0/2 and string `"1"` capability
  values cannot replace the legacy verdict with a successful replay result.
- Existing diagnostic reuse passes **204 comparisons in 23 groups**, including
  complete result/book objects, real Base, source locations and prefix mutations.
- Four compound first-error controls pass **39 comparisons**: type error before
  body error, duplicate before malformed type/body, signature mismatch before
  body error, and an actual failure before final pending-TODO reporting.
- Observational instrumentation of the actual new host verifies **four → one**
  selected failure checks for early and late rejection. Accepted and rejected
  complete results match; an oversized prefix falls back to full checking.
- Fresh full-corpus vectors contain **2,756 observations each**. Every behavioral
  field and strict verdict matches: **919 positive check fixtures**, **459 negative
  check fixtures**, **zero differences**, and the same **318 strict check failures**.
  Host provenance is verified separately against each actual driver/adapter hash;
  diagnostic text is not normalized. The harness exits nonzero for known strict
  failures, correctly distinguished from completed preservation.

See [the full comparison](s3-evidence/frontend-comparison.json). This preserves
the current compiler's behavior; it does not turn existing nonconformance into
passing tests or constitute a new live TypeScript diagnostic comparison.

All 54 previous selected exports remain, with one added capability export.
The [generated-function comparison](s3-evidence/functions-optimized.json) finds
49 old roots with identical reachable function text. The changed roots are full
checking, prefix checking, the two detailed checker APIs and specialization,
which checks its generated definitions. Backend generation/interpretation code
is unchanged; specialization and accepted emission are tested separately.

## Performance and resource gate

The [serial ABBA pilot](s3-evidence/pilot.json) uses one frozen conditional host,
separately primed API-specific Base caches with equal decoded graphs, Node
24.18.0, CPU 0, 4 GiB heap and 4 MiB stack. Four fresh processes per workload run
without competing intentional compiler/archive/hash jobs. Exact accepted output
and rejected results match their preflights; all input identities remain valid.

| Workload | Request reduction, both orders | Process reduction, both orders |
| --- | --- | --- |
| Accepted library compilation | -0.18% / -0.67% | -0.19% / -0.69% |
| Early rejection | 2.22% / 2.17% | 1.64% / 1.64% |
| Late rejection | 33.46% / 33.49% | 30.68% / 30.63% |

Negative reduction denotes overhead. Accepted compilation stays within 0.7% and
passes the 5% guard. Late rejection improves materially; early rejection remains
mostly parsing/loading work. This does not establish faster successful full-source
compilation or a new ratio to TypeScript.

The [separate resource gate](s3-evidence/performance-guards.json) passes: maximum
paired worker peak-RSS growth is 2.91%, selected API bytes shrink from 1,036,548 to
1,030,277, and accepted generated bytes/hashes remain identical. Each fresh worker's
RSS high water is measured, not inferred from source size. The historical tool's
`complete` flag alone would not enforce these budgets; they were checked explicitly.

The frozen workload remains 60,909 bytes; it is not the current complete compiler
source. Its historical emitted-output hash is a preservation oracle for unchanged
input. The historical full-source 6.03× TypeScript result retains its old scope.

## Context, release and scope

The fixed nine-file dependent-application review context decreases from 2,992 to
2,976 lines and from 100,873 to 100,394 bytes. The producer/prefix/host review
required for this book-level change is additional context; the 139-line source
reduction is not a claim of 139 fewer lines in every review task.

Source: `58d57867be712b3b9c9df2c1d285fa6d856da850479cda02a3d86fc2b13c3a7d`.
Checked API: `ba121e4098044d9f106c4e7cb3e37b0e1ce1bc77f7e42f7e5418556b7f0f3e90`.
Optimized API: `7e913551460ac736f1af35e19049d712765291255a0e579482f2e7179dcadbc6`.

No new all-definition B1→H→H proof, native execution or GPU run is claimed here.
The original 10,500-line S3 forecast and the 50%/75% milestones remain unachieved.
The completed narrow reductions do not fund the still-large gap to 8,254 lines.

The installed release passes integrity/derivation verification, ordinary checking,
interpretation and generated JavaScript execution; both execution paths print
`42`. See [release smoke](s3-evidence/release-smoke.json). All raw full vectors,
worker histories, snapshots, controls, benchmark preflights/samples and command
logs are preserved in the [capsule](s3-evidence/raw.tar.gz), with independently
verified member hashes in the [manifest](s3-evidence/manifest.json). Historical
Phase 6 inputs were copied byte-for-byte into this evidence; unrelated research
files remain untouched and unpromoted. Test/evidence code is separately identified,
not counted as compiler work moved out of scope.

S3 is complete under its revised bounded design. Next is S4's frontend/book-state
and 50% milestone investigation. It must establish a credible replacement/removal
budget before a large rewrite; the remaining 7,433-line reduction cannot be claimed
from the small existing candidate inventory. S5 depends on actually satisfying
that milestone, not relabeling partial progress as 50%.
