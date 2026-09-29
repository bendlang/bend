# Phase16 source spans: retain occurrences, share rendering

Prospective bounded design, before candidate execution. Root approves an isolated
numeric metadata ablation; production sources and Phase6 experiments remain
unchanged. This refines the source-span work in [the phase design](full_conformance.md).

## Diagnosis and exact scope

Phase15's full vectors contain 153 snippet-only, seven caret and nine location/
span checker differences (169 distinct check observations). The shared UTF-16
renderer already agrees with pinned TypeScript on direct boundaries. The missing
invariant is occurrence provenance: `fp_origin` recognizes only Ref/ADT/Ctr nodes
whose semantic `id` happens to retain a packed lexer position. Resolving Ref to
Var replaces that position with the lexical binder ID; literal expansion drops
it; freshening replaces binder IDs; many App/Lam/Mat/Rfl nodes never receive it.
Structural matching cannot distinguish equal literals or repeated occurrences
of one variable. A fallback ancestor can identify the wrong source expression.

Five of the seven caret failures truncate constructor/datatype expressions to
their name token. A sixth needs the generated do-bind statement's actual range;
the seventh needs a lambda binder's range instead of its constructor ancestor.
The nine location rows all also lack an unrestricted-binder Note; three already
have correct spans. The checker owner handles this note, and the span owner the
remaining location portions. Two existing backend diagnostic differences on
custom Nat/Succ types supply additional literal/substitution boundary controls.

Pinned TypeScript attaches an optional Span to every term and deliberately
preserves or replaces it in lowering. Ranges follow AST construction, not generic
balanced text: an `ADT` range ends after its first angle argument in the current
pinned parser, whereas a constructor includes its closing brace. Binder lambdas
use binder ranges. Therefore neither token widening nor source-text searching
is an adequate general correction.

## Alternatives and selected contract

A lossless external sidecar would need parser accumulation, route remapping
through flattening/qualification/freshening/substitution, and occurrence keys
through checking. Keeping structural lookup would still be ambiguous. This is
more machinery than a direct occurrence range, and cannot safely be inferred
from the final core alone.

An optional range object mirrors TypeScript closely but allocates metadata
objects. Prior unpromoted Phase6 ABI1 experiments measured 5–11% accepted-work
overhead and 54.2% Base-cache growth. Its scalar ABI2 reduced retained size but
recorded only a start position, before caret conformance was required. These are
historical findings, not measurements of the current compiler. We do not adopt
their dirty sources or claim cache size alone establishes checking speed.

The isolated candidate adds `originBegin: U32` and `originEnd: U32` to KTerm.
Both are zero for an absent origin; otherwise the pair is an inclusive start/
exclusive end in UTF-16 units inside one immutable request-owned source interval.
Equal endpoints represent a real zero-width occurrence. Neither field affects
semantic equality, binding, quantities, child traversal, specialization keys or
fresh-ID bounds. `compiler_span_abi() == 3` identifies this eight-field layout.
There is no use of name/id/quantity/removed as hidden source metadata.

Later instrumentation reserves disjoint positive intervals for canonical module
source strings, including one EOF position. Source ownership includes exact bytes,
canonical path and interval. Base-cache intervals are compiler/Base/source-bound
and reserved before request modules; cached and cold graphs must agree. Check
integers, overflow, interval overlap, endpoints and actual module membership
before accepting external parsed graphs. A stale or cross-request interval must
be rejected, never guessed or silently remapped. Unicode offsets are UTF-16 from
tokenization onward; codepoint columns remain only for existing parser messages.

Common rebuilds preserve the original range. Alpha-renaming preserves occurrence
while changing binder IDs. Substitution uses the replacement's range; beta
reduction does not assign the application range to an argument-derived result.
Synthesized nodes remain zero/zero unless a lowering explicitly owns a pinned
source range. A node's span does not depend on the currently checked definition's
module, so substitutions across imports retain their source. Per-frame lookup
must resolve the deepest trace frame before looking at ancestors.

## First gate: metadata only

Start from the immutable Phase15 combined-02 snapshot. Add two zero fields and
their projections, preserving the fields at existing direct record rebuilds.
Do not instrument parsing or change rendered diagnostics yet. There are 40
direct constructor/pattern sites across 15 source modules, plus named-field ABI
conversion and three host-created KTerm shapes. JSON graph serialization already
preserves named fields; cached books remain compiler-hash-specific. No new cache
version/range table is needed while every origin remains zero.

The maintained checked-B1 v5 derivative does not guard KTerm's constructor body;
its runtime/string/choice/export guards remain unchanged. Older private H
projection/constant helpers do assume six fields but are not on this workflow.
Do not edit or weaken them. If the actual maintained derivative rejects a new
shape, retain the failure and review a separately versioned change before use.

Build a genuine checked B1 and run the maintained 36 cases. Require exact
baseline diagnostics/results, all metadata zero in loaded books, identical six
semantic fields, source projection/rebuild controls, unchanged helper bytes and
explicit source/host patches. Count lines, concepts, cache bytes and graph size.
After correctness, request an exclusive serial ABBA accepted-source pilot on the
same input, 4 MiB stack/4 GiB heap and validated per-image Base caches. A >3%
regression triggers investigation and confirmation under the root design; no
performance improvement is promised. Do not infer cost from overlapping builds.

## Instrumentation after the cost gate

Only after reviewing the ablation, add one source-range contract shared by parser
and checker. Capture ranges at parse construction and carry them through common
lowering/rebuild helpers; do not create a parallel parser or host-language
implementation. Reuse `dg_snippet` without changing its coordinate contract.
Test repeat equal literals/variables, binder/occurrence distinction, imports,
cached/cold Base, alias identity, beta substitution, erased/generated nodes,
tabs/CRLF/astral Unicode, EOF and multiline ranges, ADT first-argument ranges,
do-bind ranges and independent first-error order.

Direct immutable spans should replace the old token search and structural term
matching once the relevant coverage passes. Until that removal is justified,
keep any temporary fallback explicit and test deepest-frame precedence. Report
all remaining exact failures; 169 is an opportunity count, not a promised delta.
