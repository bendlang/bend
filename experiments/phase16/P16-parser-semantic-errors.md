# Positioned semantic parser errors

Prospective followup to the validated lexer/parser origin experiment. Preserve
existing first-error traversal. Error nodes keep their old fallback string and
carry the offending term's explicit origin. A message error has one ParseMessage
child; an expected/observed error has ParseExpected and ParseObserved children.
No renderer interprets the fallback string. One fpe_origin_render helper uses
source-interval ownership and unchanged dg_snippet. Indexed parse completion
uses it for early errors; the graph owner uses it for the already selected
lowering error. Legacy unlocated errors retain their fallback.

First freeze and test the transport independently of producer corrections.
Then apply shared producer families in separate immutable candidates: match
scrutinee categories/local binder prohibition; constructor pattern declaration
and arity/unsupported pattern; operator namespace and array count. Exact pinned
paired witnesses and controls must distinguish real offending terms, including
natural-number pattern desugaring and the backend257n boundary. After these
families converge, token errors (numeric syntax/overflow/escapes/imports) and
signature/refill ordering get their own bounded stages. No fixture-specific
messages, oracle edits, TypeScript fallback, or error-text matching is allowed.

The Empty semantic fence is owned by root. This parser work merely carries the
actual `!=` operator range to the generated canonical reference; root composes
its already independently checked FGlobal producer/freshener change.

The first producer candidate targets31fixtures/62paired observations in the
parser05 census:13scrutinee,5local-match,7pattern,4operator and2array-count.
Pattern validation will return Maybe<KTerm> instead of String, retaining the
actual first offending term and eliminating Error reconstruction from a string.
Success remains None; no second validation traversal is introduced. Unsupported
patterns retain their input tree until diagnostic printing; known constructor
patterns still recurse in the same order. Natural-pattern generated nodes inherit
the literal range, including the257n backend boundary.

Exact prospective IDs:

- `check/comp_splice_tuple_goal.bend`
- `check/computed_match_split.bend`
- `check/erased_local_match_000.bend`
- `check/motive_suffix_join.bend`
- `check/nat_literal_pattern_arity.bend`
- `check/nat_literal_pattern_empty.bend`
- `check/op_bare_refused.bend`
- `check/op_brace_refused.bend`
- `check/op_ns_call_arg.bend`
- `check/template_ns_late.bend`
- `flatten/consumed_column_error_001.bend`
- `flatten/dead_residue_elision_003.bend`
- `flatten/destructure_let_001.bend`
- `flatten/dup_guard_000.bend`
- `flatten/dup_guard_001.bend`
- `flatten/error_window_substituted_scrutinee.bend`
- `flatten/forward_reference.bend`
- `flatten/order_ban_000.bend`
- `flatten/order_ban_001.bend`
- `flatten/order_ban_002.bend`
- `flatten/order_ban_003.bend`
- `flatten/shared_param_computed_001.bend`
- `flatten/unsupported_pattern.bend`
- `halt/column_order_search.bend`
- `page/ctor_list_mismatch_001.bend`
- `parse/array_count_odd.bend`
- `parse/array_count_sum.bend`
- `parse/invalid_assign_target.bend`
- `parse/typed_let_pattern.bend`
- `reg/body_local_match.bend`
- `reg/erased_local_match.bend`

The first complete62-row probe left only the4operator fixtures (8observations):
message and range were exact, but the pinned compiler appends an explanatory
Note. Before the next probe, extend the structured Error payload with an optional
ParseNote after ParseMessage; render it after the snippet. This is a generic
explicit payload, not fallback-message parsing or a fixture condition.
