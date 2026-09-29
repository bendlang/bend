# Preserve the grouped-body checkpoint explicitly

Read-only follow-up to `rejected_parser_transport.md`. No marker or parser
callback change is implemented or authorized by this document. The independent
stage experiment disproved the earlier unchanged-success-AST constraint: a
failure-only resolver cannot recover a parser boundary that was already erased.

## Observed distinction

In pinned TS, an ordinary completed row body remains a raw Body until the entire
enclosing body finishes. Its pattern checks have happened, but its enclosing
match has not flattened. A parenthesized body calls body_flatten inside
parse_term_tup before the closing parenthesis. Therefore:

| Earlier row body | Later failure | Pinned first error |
| --- | --- | --- |
| Unparenthesized match on a global name | Later row syntax `)` | Later syntax |
| Same match, parenthesized | Later row syntax `)` | Earlier global-match error |
| Unparenthesized match on a global name | Later row pattern `Type` | Later pattern |
| Same match, parenthesized | Later row pattern `Type` | Earlier global-match error |

The frozen 16-observation suite has 8 exact matches and 8 differences in the
current compiler. All reference acceptance/phase oracles are valid. The direct
six-control probe confirms f_scope_body retains the raw Match while f_scope
crosses its flattening boundary. It also confirms that the current successful
raw grouped and ungrouped use bodies have identical tags/names/quantities/child
structure after removing only numeric fresh ids and source coordinates. Those
coordinates must not become a substitute for an explicit stage marker.

## Smaller representation candidate

Introduce raw `FGroup{body}` only when a parenthesized body is a raw Local,
Match or Parallel. A plain grouped name, call, type, literal or tuple needs no
extra node. This is syntax-stage metadata, not a semantic core term or a cached
host hint. A shared scope consumer flattens its child at the term boundary and
removes the wrapper. It must never reach checker, normalizer or backends.

Initial implementation sites are one producer (`f_group` and a small helper in
parser.bend) and one shared consumer (`f_scope` in elaborate.bend). Existing
f_scope_body falls through to that consumer for a grouped term. Initial source
estimate: one small helper plus one dispatch branch, about 10–25 lines across
two files; this is an estimate before implementation and semantic audit.

Do not claim those two sites alone establish all grouping semantics. Explicitly
audit f_group_namespace, f_binary/f_lambda_valid, f_mark, f_args_min, f_bang and
f_valid_pattern: each can inspect a raw term's shape before ordinary scope.
If a grouped body can flatten to an eligible variable/reference, a raw marker
must not create a false rejection or be blindly stripped before its checkpoint.
Tuple/group disambiguation also matters: pinned parse_term_tup does not make a
raw Local/Match the first tuple component simply because a comma follows it.
These seven decision sites are a bounded review list, not proposed workarounds.
Do not change their semantics speculatively to force the marker experiment to pass.

Nested grouping needs one distinct boundary per actually grouped body, with no
wrapper for already marked/scalar terms. Preserve existing term/source ranges;
neither closing delimiters nor generated ids may be used as stage tags. Keep
successful lowered books exactly equal after the raw wrapper is consumed.

## Allocation census and cost limits

Instrumented final compact API `35044ae6…5315` counted f_group input tags without
changing outcomes:

| Input | UTF16 units | f_group calls | Raw Local/Match/Parallel inputs |
| --- | ---: | ---: | ---: |
| Pinned Base | 72,371 | 302 | 0 |
| Final assembled compiler source | 668,185 | 84 | 0 |

A body-only unary wrapper would add zero wrapper/list nodes on those two exact
inputs. On a program with N eligible groups, a direct implementation adds N KTerm
wrappers and N singleton list nodes before any later traversal copies. This is a
count of prospective raw nodes, not a heap-byte or speed estimate. The added
scope dispatch branch can still cost time even where N=0. A frozen same-source
cost gate is required before promotion. Fixtures with nested groups must measure
marker counts and verify complete consumption separately.

## Compare the architectural alternatives

| Option | Scope / complexity | Benefit and unresolved work |
| --- | --- | --- |
| Explicit raw FGroup + rejection-only frames | 2 initial marker sites, 7 shape-decision audit sites; frame callbacks still span the complete lexical inventory | Restores the demonstrated lost bit of parser stage; reuses f_scope_body for prior-row checkpoints and f_scope only for completed term boundaries. Does not by itself retain rows discarded by later errors. |
| One contextual term/body parser | Prior census gives 104 transitively affected functions and 64 FParsed destructures as an inspection upper bound | Performs scope-sensitive validation at the actual upstream checkpoint; may remove delayed reconciliation, but is a much larger signature/control-flow migration that affects successful parsing. |
| Reconstruct grouping from spans/source or flatten all prior bodies | Rejected | The first guesses erased syntax; the second chooses the wrong error for the independent ungrouped-row controls. |

The next approved decision should be a small marker ablation, with no full frame
wiring until its shape audit, successful-book equality and cost gate pass. A
marker would make the rejected-path design possible; it does not prove that the
complete frame implementation is simpler than a contextual parser migration.
