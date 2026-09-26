# S4 D: actual B02 context recount and validation supplements

This recount uses the actual `candidate-b02-project` source, not a prospective
edit. It reports source/context size only; compiler artifact validation is a
separate gate. The original S0 sets and denominators remain fixed. The previous
[B01 JSON](context-counts.json) and [B01 report](context-counts.md) are unchanged.
[Exact B02 counts and hashes](d-context-counts.json) retain all original entries.

B02 keeps **59 production modules / 14,667 physical lines / 12,505 nonblank
lines / 470,062 bytes**. Only `core/term.bend` and `core/normalize.bend` differ
from B01. Moving 24 physical / 21 nonblank lines / 396 bytes changes ownership,
with **zero production-size reduction**. See the
[independent block review](d-ownership-review.md).

## Original paths and replacement owners

| Original task | S0 physical / nonblank / bytes | B02 original paths | B02 including replacement owners |
| --- | ---: | ---: | ---: |
| Parser first-error choice | 5,716 / 4,851 / 198,816 | 5,258 / 4,554 / 191,321 | 5,418 / 4,693 / 196,578 |
| Dependent application check | 3,156 / 2,652 / 106,647 | 2,764 / 2,389 / 98,075 | 3,000 / 2,599 / 106,213 |
| Constructor lowering JS/native | 3,397 / 2,857 / 126,336 | 3,186 / 2,728 / 122,272 | 3,186 / 2,728 / 122,272 |

Parser keeps the complete seed-worker owner. Its structural joins now live in
the already-counted `core/term.bend`, so the remaining normalization module is
no longer charged solely for those replacements. Checker retains the previous
conservative `diagnostic/produce.bend` supplement and already counts both moved
source/destination files. Backend counts term only, so its total increases
**24 / 21 / 396** from B01. No original contract, test, fixture or historical
evidence entry is removed. Task sets overlap and must not be summed.

## Relevant maintained controls added after S0

The complete maintained test change list from S0 through S3 was inspected with:

```sh
git diff --name-status fc509f4cd5bf00b2cd600922b4e40c5d7b9a1e01 8cc51c1 -- selfhost/tests
```

It contains only the provenance and structured-checker additions and the ABI
test modification below. Relevance comes from their actual fixtures and calls,
not their filenames or mere existence.

| File | Physical / nonblank / bytes | Relation to the frozen parser task |
| --- | ---: | --- |
| `tests/frontend/shared-operations.mjs` | 142 / 141 / 12,567 | Direct S4 graph/trace/cached-result and embedded-error selection controls; include as visible B/D validation overhead. |
| `tests/provenance-consolidation.mjs` | 127 / 124 / 9,575 | Relevant S2 integration coverage for imported-source ownership, complete ordered results/traces, token ranges and final declaration routes. It includes parse rejection and import graphs, but is not itself a competing-parser-error oracle. |
| `tests/structured-checker.mjs` | 51 / 51 / 4,600 | Distinct S3 checking task: constructs `KDef` books directly and tests type/body/declaration/TODO error priority, rendered results and prefix checking. It does not parse malformed arrays, delimiters or match headers. |
| `tests/conformance/abi.test.mjs` | 66 / 66 / 4,472 | Distinct host/ABI task: S1 fixes a frozen-driver mock; S3 tests versioned structured-checker authority through `inspect`. Existing deep ABI sharing controls are also in this full file. |
| `tools/compiler-abi.mjs` | 92 / 89 / 4,264 | Unchanged adapter imported by the provenance harness; its positional-API wrapping path is optional when reviewing the named-field default API comparison. Count separately when reviewing that alternate path. |

All paths in this table are relative to `selfhost/`. The JSON records current
hashes and baseline presence/counts. The ABI test existed at S0: it is now
23 lines and 1,705 bytes larger; its complete 66-line file is charged when added
to a context that previously excluded it. The compiler ABI adapter is unchanged.
No historical execution archive or benchmark script is added merely because it
exists; these remain selected whole-file review sets, not executable capsules.

## Explicit parser supplements

Each row below cumulatively adds complete files to B02's replacement-owner set.
Every delta uses the **original S0 30-file set**, including its existing tests.

| Parser view | Files | Physical / nonblank / bytes | Delta from original S0 |
| --- | ---: | ---: | ---: |
| Original files plus replacement owners | 31 | 5,418 / 4,693 / 196,578 | -298 / -158 / -2,238 |
| Plus direct shared-operation control | 32 | 5,560 / 4,834 / 209,145 | -156 / -17 / +10,329 |
| Plus relevant imported-provenance control | 33 | 5,687 / 4,958 / 218,720 | -29 / +107 / +19,904 |
| Plus optional provenance ABI adapter | 34 | 5,779 / 5,047 / 222,984 | +63 / +196 / +24,168 |
| Plus broader checker and host-protocol test files | 36 | 5,896 / 5,164 / 232,056 | +180 / +313 / +33,240 |

For the original parser task with both direct shared-operation and relevant
imported-provenance controls included, physical context falls only **29 lines**,
while **nonblank context grows 107 lines and byte context grows 19,904 bytes**.
There is no uniform context-shrink claim. The optional last row expands the
task to include checker/host protocol tests; it is not a complete host-harness
context because it does not add `typed-driver.mjs` and every transitive import.

For the checker task, adding the two relevant checker/host test files to its
conservative source-owner set gives **12 files / 3,117 physical / 2,716 nonblank /
115,285 bytes**: **-39 / +64 / +8,638** against its original S0 context.
No claim that those tests are unnecessary for release validation is made by
excluding them from the narrower parser-only task.

## Method and limits

The unchanged S0 counting rules are used: UTF-8 `splitlines()` physical count,
nonempty `str.strip()` nonblank count, raw byte length and SHA-256. Original
baseline values and logical memberships come from the immutable B01 recount,
which verified S0 file hashes; all B02/current supplement files are read afresh.
Complete per-file source mappings, hashes and aggregate deltas are retained in
the JSON. All observed source/test files and both B01 context outputs were
rechecked unchanged before publication.

This audit executed no compiler, API or benchmark, and changed no production
source. Blank separators are not counted as concepts. Ownership, validation
scope and the original S0 denominator remain explicit; no 50% milestone,
performance or measured human-review-effort conclusion follows from these counts.
