# Inert parser cursor representation

The isolated cursor candidate preserves all 196 saved outcomes and passes 194
direct controls. It is a representation prerequisite, with no new conformance
result and no installation decision. This owner did not time it. The significant
cost question is generated allocation work: parsing the unchanged compiler source
executes 2,236,971 cursor constructor expressions, or 11.62 per lexed token.
These counters do not measure physical V8 heap allocations; JIT escape analysis
may eliminate some objects.

The [prospective design](../../design/phase18/cursor-representation.md) follows
the [architecture comparison](../../design/phase18/parser_state_options.md).
Parent is the installed Phase17 find-worker source, checked attempt
`selfhost/build/phase17/find-worker-build-01`, selected API `9b20de50`.
Candidate source is `selfhost/build/phase18/cursor-source-02/project`, genuinely
checked as `cursor-build-01`: checked API `700c61df`, guarded derivative
`5d19edf5`. Both use pinned upstream `b2111cf`, the unchanged emitter/runtime,
and the existing v5 derivation. Full SHA256 identities and exact consumed files
are in the attempt and audit records.

## What changed

`FInput{tokens, context}` carries the same token list and one inert
`FCursorContext{serial}`. Production initializes serial zero. Readers unwrap the
cursor; advance, empty and prepend preserve its context. Skip/space traverse the
raw list and produce one final wrapper. The lexer still returns exactly the old
FToken list, with unchanged token fields and endpoints. Four lexer-to-parser
boundaries create the cursor. Five synthetic-token functions and five empty-rest
exits use the shared helpers. `FParsed` still has two fields; its internal rest
field now has type FInput. Public parse/load result shapes remain unchanged.

The nine-file delta is entirely in front/declarations, lexer, literals_arrays,
parallel, parser, sugar, validate and load/imports, modules. No name resolution,
grammar, scope, lowerer, checker, host or runtime semantics changed. This trial
does not include the separate Phase17 FGroup experiment. It does not fix the
remaining monad chronology or same-body instance gap.

| Active compiler manifest | Parent | Cursor | Change |
| --- | ---: | ---: | ---: |
| Modules | 59 | 59 | 0 |
| Physical lines | 16,353 | 16,430 | +77 |
| Nonblank lines | 13,954 | 14,017 | +63 |
| Bytes | 581,322 | 582,613 | +1,291 |
| Definitions | 1,657 | 1,670 | +13 |
| Laws | 775 | 775 | 0 |
| Types | 66 | 68 | +2 |

The audit also records a recursive census of all 61 `.bend` files under src,
including the two non-manifest files: 17,892→17,969 lines. Its difference is the
same +77 lines; it must not be confused with the active 59-module compiler count.
The added concepts are the cursor wrapper and its explicitly inert context.
Thirteen adapters centralize entry, reads and movement. No later pass is removed;
any simplification from contextual parsing remains a separate hypothesis.

## Correctness evidence

All jobs used CPU3, one process group at a time, Node v24.18.0, stack 4 MiB and
heap 4 GiB. Supervision records include exit, signal, timeout, log overflow and
child errors. Baseline/candidate selected runs each use one persistent worker,
recycling every 64 requests. No controlled timing claim is drawn from their
durations or memory statistics.

- Genuine checked B1 and maintained 36 pass, retaining the same two strict
  diagnostic differences allowed by that focused gate.
- The frozen Phase17 selection has 196 observations. Fresh parent and candidate
  each have 128 exact and 68 known strict differences, with every complete
  normalized candidate and reference outcome unchanged. Stage witnesses remain
  8/16 exact, patterns 71/114, and grouping shapes 49/66. Both raw selected suites
  retain `pass:false`; the separate no-regression audit passes.
- All 194 direct controls pass: raw lexer equality; seven cursor readers;
  movement, skip/space, prepend and EOF; serials 0, 7 and 4,294,967,295;
  indexed and legacy inputs, astral text, unterminated strings; synthetic
  `++`, `>>`, `<-`, `->` boundaries; diagnostic endpoints and all five
  empty-rest exits, including typed-let restoration of the original context.
- Complete raw and lowered Base and unchanged assembled parent compiler books
  are equal, including IDs, ranges, imports and diagnostics. No term
  normalization or origin erasure is used for equality.
- Direct probe modules append only exports of existing generated functions.
  Each has a recorded, byte-identical production API prefix and its own hash;
  neither is used as a production or timed compiler.

`cursor-audit-01/report.json` verifies complete parent/candidate project
membership, the exact nine-file delta, source snapshots, checked lineage,
consumed design/tool hashes, process health and all complete outcomes. The
paired reports, detailed direct controls and allocation records remain separate.

## Allocation finding

The Bend source returns `input` for empty advance and no-op skip/space. The
pinned emitter reconstructs that destructured record in those branches. Thus
each call to input, empty, prepend, advance, skip or space executes one FInput
constructor expression, even when the token list does not move. Context remains shared.
The source-level preservation of input values is correct; object reuse is not
implied.

| Raw indexed parse | Tokens, including terminal | FInput constructions | Constructions/token | Context constructions |
| --- | ---: | ---: | ---: | ---: |
| Base, 72,371 UTF16 units | 26,685 | 283,964 | 10.64 | 1 |
| Parent compiler, 668,372 UTF16 units | 192,461 | 2,236,971 | 11.62 | 1 |

The compiler parse makes 1,651,564 wrapped advance calls, 501,729 skip calls,
83,670 space calls, seven prepends and one entry. The raw helpers make another
79,374 tail calls without cursor allocation. Their sum matches the parent's
1,730,938 tail calls. This is repeated parser lookahead as well as movement;
one wrapper per token would have substantially understated it.

The untimed `cursor-allocation-01` probe inserts entry counters in exact named
functions in **separate instrumented artifacts**. It verifies the nine static
FInput constructor sites and records their function-body hashes. The production
APIs are unchanged. Its complete raw outputs hash identically to the independent
uninstrumented direct controls. The raw report field `wrapperAllocations` denotes
executed generated constructor expressions, not measured physical heap objects,
bytes retained or GC cost. V8 can optimize some constructions away. Timing uses the original candidate
API and identical source, with root's exclusive matrix protocol.

## Retained failure and decision

`cursor-source-01` is preserved unbuilt and unselected. Static review found that
its broad rename also changed FToken's public `f_line`, `f_col`, `f_kind` field
labels. `cursor-source-02` narrows renaming to function/call syntax. Its read-only
review record, first preparer and complete first snapshot remain available. No
checked build or behavioral failure was hidden or rewritten.

All owner compiler/probe jobs are closed. Root subsequently completed the separate
representation matrix: process +0.926%, request +1.062%, peak RSS +0.740%, within
the 5% screening threshold. This shows no measured speed gain. Exact samples and
interpretation belong to root's [cursor cost report](cursor-cost.md), not the
instrumented controls. The candidate is ready for independent semantic-stage
design review. No broad frontend
sweep, semantic parser migration, speed claim or promotion is authorized by these
results alone. The separate semantic-slice review should determine whether one
authoritative contextual parser can eventually remove enough deferred work to
justify this representation and its allocation cost.

Primary evidence is under `selfhost/build/phase18/`: `cursor-controls-01`,
`cursor-source-01`, `cursor-source-02`, `cursor-build-01`, `cursor-baseline-01`,
`cursor-validation-01`, `cursor-direct-01`, `cursor-allocation-01`, and
`cursor-audit-01`. Tools are the corresponding frozen `cursor-*` files in
`selfhost/tools/performance/phase18`. The owner receipt binds their final bytes.
Ignored local artifacts still need root's durable evidence capture; this report
does not itself claim an archived or recovered capsule.
