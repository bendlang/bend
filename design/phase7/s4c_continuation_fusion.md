# S4 C: remove private continuation boundaries

Status: **rejected before implementation** after independent pinned-language
review. The proposed local-then-match replacement is not supported by the current
Bend body grammar. The original proposal is retained below as an experiment,
not an instruction to make those source edits. This remains inside S4; its 50% milestone
and subsequent S5–S7 gates do not change. A single final stable S4 candidate can
receive the broad frontend/performance/release gates after its focused units.
No intermediate candidate is promoted on the strength of a proposed test.

## Bounded candidate

Use these seventeen private helpers from the original read-only census, recosted
against B01. Each has one textual production call, at an entire function result
or the result of an existing match arm, and is outside recursive SCCs:

| Helper removed | Caller retaining its body | Computed argument bindings |
| --- | --- | ---: |
| `f_ascii_space_code` | `f_ascii_space` | 1 |
| `f_all_body` | `f_all_domain` | 1 |
| `f_equation_type` | `f_equation` | 1 |
| `f_matcher_tail` | `f_matcher_arm` | 1 |
| `f_let_body` | `f_let_value` | 1 |
| `ff_miss_done` | `ff_hit_done` | 1 |
| `f_do_tail` | `f_do_value` | 1 |
| `f_rewrite_body` | `f_rewrite_motive` | 2 |
| `f_char_decoded` | `f_char_literal` | 1 |
| `f_float_read` | `f_float` | 1 |
| `f_array_size` | `f_array_type` | 2 |
| `f_fresh_result_end` | `f_fresh_result` | 1 |
| `f_adt_fill` | `f_adt` | 2 |
| `f_graph_finish_alias` | `f_graph_finish` | 1 |
| `f_main_result_names` | `f_main_names` | 1 |
| `f_qual_result` | `f_parse_at` | 1 |
| `f_loaded_result` | `f_load` | 1 |

Retain every helper body in its caller. Remove only the now-private law/function
boundary and its one call. Bind computed arguments once, in original left-to-right
order. Already evaluated variable arguments may use their existing bindings;
map differently named formals explicitly without copying their values. Use fresh
local names to avoid capture, preserving quantity markers and body evaluation
inside the same function or chosen match arm. No work moves out of a lazy branch.

For example, the existing `f_ascii_space` calls a helper solely to share
`Char.to_u32(c)` between two comparisons. The proposed body is:

```bend
@unsafe
def f_ascii_space(c):
  +code = Char.to_u32(c)
  U32.is_eq(code, 32) || U32.is_le(U32.sub(code, 9), 4)
```

For a parsed result, bind it before the helper's existing match. Preserve captured
values such as `name`, `id`, `q`, `exi` and `a` in `f_all_domain`; only the
computed `f_expr(ts, 0)` needs a fresh shared local. The retained body must still
use the *new* parsed token remainder after its inner match. Similar care applies
to freshened books and the aliased book used twice by `f_graph_finish_alias`.

The preliminary nonblank boundary budget is 139 lines before twenty computed
argument bindings, or **119 net nonblank lines**, before new forward declarations
and comments. This is not deletion credit yet. Require at least 100 net nonblank
lines and 1,800 bytes after all replacements, fewer physical lines, seventeen
fewer helper interfaces, and no new representation or generic combinator. Recount
the actual candidate; do not count the bodies that remain or reuse A/B savings.
Reject any subset whose replacement cost defeats its simplification benefit.

## Cheapest falsifiers and integration

1. Read every selected helper and its complete caller. Verify unique nonrecursive
   use and external-root absence on B's actual source. Record source identities.
2. Start with whitespace, character and float helpers. Check quantity/local-binding
   syntax through pinned TypeScript and the existing Bend frontend/checker, and
   compare actual outputs on ASCII boundary characters, Unicode, malformed literal
   cases and representative floats. Do not broaden a failed pilot.
3. Expand only after the pilot passes. Review capture, sharing, argument order,
   error order, direct tail calls and new forward dependencies. Required laws
   stay in source and count against the budget. Keep the legacy loader algorithm.
4. Run a fresh checked attempt, all 21 focused controls and the strengthened
   whole-result loader/error tests. Exercise all changed parser families and
   deep stack/freshening cases through maintained components. If any public
   observation changes, reject/fix before performance measurement.
5. On the stable combined candidate, run the full frontend preservation vector,
   accepted/rejected host costs, unseeded raw/parsed graph costs, supported runtime
   smoke, release integrity and relocation. Retain the 5% runtime and 10% RSS/size
   guards; no source saving can override a failure. Identify A's self-reproduction
   source exactly; never relabel it as a later candidate's fixed point.

Record actual counts, source/tool overhead, failed attempts and the accepted or
rejected outcome in the evolving S4 report. This small reduction does not fund
the remaining gap to 8,254 lines. Typed tag dispatch, recursive/nested helper
fusion and checker-owned specialized terms remain separate unbudgeted research.

## Decision after independent review

Fourteen selected helpers inspect a computed result with a match. The pinned
frontend rejects both matching a local binder and matching a computed expression.
Constructor destructuring of a computed right-hand side lowers through the same
restriction; it is not a valid workaround. Thus the proposed `+parsed = ...`
followed by `match parsed` is invalid, even though ordinary shared scalar locals
are valid. Constructor field quantities already make the relevant `FParsed`
fields unrestricted; that was not the blocking issue.

Only `f_ascii_space_code`, `f_adt_fill` and `f_graph_finish_alias` remain directly
viable without matching a computed value. Their estimated combined saving is
23 nonblank lines, below the committed 100-line acceptance gate. Do not expand
the language, add a new eliminator framework or count the original 119-line
estimate as a saving. Keep all seventeen helpers in this S4 release. The
[independent review](../../implementation/phase7/s4-evidence/c-review.md) records
exact source locations and the bounded syntax falsifier. B remains the final
S4 integration candidate; C contributes a rejected hypothesis, not code.
