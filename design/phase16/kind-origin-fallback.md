# Retain the original kind expression through diagnostic normalization

The remaining error_window_stuck_app_kind fixture reports the right expected
kind and observed F(Type), but has no snippet. check_adt_kind normalizes its
input before creating its diagnostic. The resulting App may have no source
origin even though the original expression has one.

Wrap the existing result with `dg_trace` at the original input term. A successful
result remains unchanged; an existing failure retains its innermost trace and
appends the original expression to the fallback trail. Existing direct origin
lookup then uses that occurrence only if no earlier trace term owns a range.
This uses the normal trace mechanism, with no structural/text search, helper,
state or extra successful checking pass. The declaration enters this worker
only after its kind-shape check fails.

Freeze the original case, a parameterized stuck application, a bound-type return,
an earlier ordinary declaration error and ordinary/quantified valid datatypes.
Compare pinned exact outputs and unchanged primitive results, then the genuine
checked/focused workflow. Full adjacent conformance remains required. Do not
rewrite the normalized observed expression or infer a range from matching text.
