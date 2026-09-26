# S3 independent implementation review

Reviewed against S2 `7474b0b1f9dcbde2989b9a3ca4e1a7d6a079dd1b` and the
committed [S3 design](../../../design/phase7/s3_authoritative_checker.md).
No blocking source issue found. This is approval of the bounded implementation
and the completed controls inspected below, conditional on the remaining full
frontend, cost and release gates. The candidate frontend vector was still running
at review time; this review does not claim that vector or S3 is complete.

This reviewer read the final production diff and existing test/evidence files,
performed read-only counts/reference scans, and wrote only this report in this
review turn. No compiler build, benchmark or test was executed by the reviewer.
The reviewer authored the two new focused test additions earlier; that test
review is therefore not an independent authorship review. Their reported runs
were executed by the root agent.

## Verdict, ordering and metadata

The chronological worker is now `dg_suffix_events`, reached by both detailed
book APIs. `check_book`, `check_events` and `check_from_exact_prefix` project its
error; `check_definition` projects `ce(check_definition_result(...))`. The old
String event loop, duplicate String prefix loop and diagnostic definition/template
replay are removed. No new term/result variant, stored typed-fact table, unchecked
acceptance predicate or host implementation of compiler semantics was added.

The following source relationships are preserved:

- `event_error` precedes `signature_mode` and definition checking. Duplicate
  declarations/constructors and prior-law signature mismatch still win before
  malformed declaration types or bodies. `signature_mode`/`signature_fill_mode`
  are unchanged, including the later unsafe fill's effect on an earlier law.
- Declaration type checking still precedes ADT, absent-body, foreign and template
  paths in the same order. A failed type check returns its original `KChecked`.
  Template opening keeps the same generated names, substitution, book extension,
  pending-self count, quantities and unsafe flag.
- Successful events enter `done` through `book_put(done, d)`. Failed guards retain
  `done`; failed definition checks retain `book_put(done, declared(d))`. Successful
  detailed results return the original input book; final unresolved-law failures
  return the accumulated book. These match the previous detailed result shapes.
- Final `check_open(done)` occurs only after all events. A later actual error
  still precedes an earlier unresolved law's final TODO report. Hole/quantity/
  termination checking inside `check` is unchanged.
- The exact-prefix comparator is unchanged. Both String and detailed prefix
  entry points reach its existing full-check fallback on mismatch, including an
  oversized prefix. The retained prefix seeding worker reconstructs the same
  `done`; this still assumes a compiler/source-bound, previously validated prefix.

The subtle ADT/foreign packing is valid under the existing result contract.
`bad(msg)` constructs a `KChecked` with placeholder `Error` terms and error
`msg`; `good(r)` is exactly `String.eq(ce(r), "")`. Thus `bad("")` is successful.
`dg_suffix_check` tests `good`, discards successful payloads and advances the book.
It does not interpret the placeholder term as a rejection or consume it as a
successful inferred type. Nonempty legacy ADT/foreign errors retain the former
message-only failure presentation. The new source comment states this contract.
The existing successful Bool/dependent-grade ADT and native-IO foreign controls,
plus foreign rejection controls, passed in the current component report.

## Host capability and focused tests

The bootstrap export list includes `compiler_check_result_abi`. The host takes
the authoritative path only for `api.compiler_check_result_abi?.() === 1`;
absence and other values retain the old guarded String/replay path. A rejected
version-1 result is reused for source lookup/rendering. Optional lookup/render
failure leaves the original error string intact. The old path still refuses a
replay result whose error differs from the String verdict. Base preparation and
compiler/source cache identity checks were not weakened.

The new `abi.test.mjs` control injects only a host-protocol fixture. It verifies
that numeric `1` avoids the String checker, while absent/`0`/`2`/string `"1"`
preserve a String rejection even when presentation replay says success. It checks
status, phase, checked flag, exit code, diagnostic and call counts. This is useful
compatibility coverage, not evidence of compiler soundness or arbitrary malformed
version-1 API support. Checked generated artifacts supply that API contract.

The new `structured-checker.mjs` covers four compound errors with explicit
first-error oracles: type versus body, duplicate versus type/body, law-signature
mismatch versus body, and actual error versus pending final TODO. For each it
compares the full ordered `DResult`, String verdict, rendered error and valid
exact-prefix result between the frozen artifacts. The valid ADT prefix is checked
independently. Four extra presence/absence assertions distinguish selected terms
where the legacy error string alone would be ambiguous. The report preserves
input hashes and incomplete failures; it makes no performance or general
soundness claim. These are named-field B1-compatible APIs; this script does not
validate a separate positional H ABI.

Current evidence inspected under `selfhost/build/phase7/s3/`:

| Evidence | Observed result | Limit |
| --- | --- | --- |
| `components-01/report.json` | All 19 groups passed; harness 52 passed, zero failures/skips | Finite component and host coverage |
| `diagnostic-reuse-01/report.json` | Complete, 204 comparisons, 23 rows, no failures | Includes actual Base/prefix and source-location behavior; not a full conformance vector |
| `first-error-controls.json` | Complete/pass, 39 counted comparisons, four rows | Includes three artifact identity checks; four additional term assertions are not in the count |
| `host-counts-01/report.json` | Complete; early/late selected missing-body checks 4 → 1; same observations; oversized-prefix fallback true | Instrumented no-Base fixtures; counters are not timings or a cached-prefix host call-count proof |

The counter report consumed the actual frozen new host: candidate cases call
`check_book_diagnostic` once and do not call the public String checker. Control
cases retain their legacy path. Accepted cases retain the same internal checks.
The current diagnostic-reuse controls separately cover real Base behavior. The
new first-error report records S2 API hash
`db97c8578746e5dfa2c3f2a8d3c0dbc2e58f5616cea14d5d177e41fb66f39604`
and S3 API hash
`ba121e4098044d9f106c4e7cb3e37b0e1ce1bc77f7e42f7e5418556b7f0f3e90`.

## Exact cost and concept delta

Independent UTF-8 `splitlines()`/nonempty-line/byte counts against `git show
7474b0b:PATH` agree with [source-recount.json](source-recount.json):

| File | Physical delta | Nonblank delta | Byte delta | Def/law delta |
| --- | ---: | ---: | ---: | ---: |
| `src/check/kernel.bend` | -16 | -14 | -479 | -1 / -1 |
| `src/check/prefix.bend` | -29 | -25 | -699 | -2 / -2 |
| `src/diagnostic/produce.bend` | -94 | -77 | -3,247 | -7 / -7 |
| **Production Bend** | **-139** | **-116** | **-4,425** | **-10 / -10** |
| `tools/typed-driver.mjs` | +2 | +2 | +303 | — |
| **Bend plus changed host** | **-137** | **-114** | **-4,122** | — |

The unchanged manifest contains 59 production modules. Their independently
recounted total is **15,687 physical / 13,093 nonblank / 486,768 bytes**, with
1,450 definitions, 1,222 laws and 61 types. The design's bounded 130-line gate is
met. The explicit compatibility capability is charged above. Two new focused
tests add 73 physical/nonblank lines and 6,187 bytes separately: 22 lines/1,587
bytes in `abi.test.mjs` and 51 lines/4,600 bytes in `structured-checker.mjs`.
Documentation and historical evidence are separate from these compiler costs.

Thirteen definitions/laws were removed and three added (`check_definition_result`,
`dg_result_error`, `compiler_check_result_abi`). The substantive concept reduction
is one verdict-and-diagnostic event traversal, one prefix seeding route, and one
definition/template checker retaining its original failure. The host adds an
explicit capability branch and retains compatibility. This is a modest reduction
in concepts and source size; declaration counts are not a semantic-complexity
metric and do not establish the overall 50%/75% targets. Typed-fact reuse and
annotation removal remain deferred.

An identifier-boundary scan of 1,123 text/code files under `selfhost/src`,
`selfhost/tools` (including performance tools), `selfhost/tests`, `selfhost/docs`,
and the existing selfhost README/CONFORMANCE files found zero references to the
13 removed helpers. Build outputs, archived experiment/report trees and the
upstream checkout were excluded. Removed identifiers were `check_event_guard`,
`check_event_done`, `check_prefix_seed`, `check_prefix_step`, `dg_book_checked`,
`dg_events`, `dg_event_guard`, `dg_event_check`, `dg_definition`,
`dg_definition_type`, `dg_template`, `dg_template_binder`, `dg_template_open`.

Reviewed source SHA-256 identities:

| File | SHA-256 |
| --- | --- |
| `src/check/kernel.bend` | `0d920c6026e66ca0ff11f7d210789d398ca162d6cc3858d3a91081c6c763619f` |
| `src/check/prefix.bend` | `b95dcd2bcd8bd22d23b1bdce90e44f4e2554a127ef78d3f26a20190cf8c21322` |
| `src/diagnostic/produce.bend` | `5e036e63cd32af0f64642bc4cea581ea191e4281c6cbb5ba840fd87b979213b5` |
| `tools/typed-driver.mjs` | `96dd1d6637fa25e28fe3fd83a963189d12da2a939468e651ff5318dee383224c` |
| `tests/conformance/abi.test.mjs` | `f409d3d2f4107ce727c90d9855c6024848093968f6179ef591e3fcc00539fe69` |
| `tests/structured-checker.mjs` | `e7d9b08d70f70e70bb947a4078300bc79a441ec93bdc0721ff21025379995a40` |

## Remaining promotion obligations

The root agent must finish and compare both complete 2,756-row frontend vectors,
retaining existing upstream differences and rejecting missing/changed rows. The
root also owns the controlled accepted/early/late cost pilot, RSS/generated-size
checks, installation and release smoke. A String-only rejection now constructs
an internal detailed result, so a zero cost assumption would be unsupported.
No current TypeScript ratio, performance pass, native execution or source-wide
B1→H→H fixed point is established by this review.
