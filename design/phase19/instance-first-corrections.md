# First prototype corrections before correctness gates

Source01's genuine bootstrap stopped at parsing: the rewritten tele_check_head
lost its former explicit parameter/return signature and has no law declaration.
A static census finds the same omission in tele_check_static and check_mat_filled.
Source02 restores all three explicit signatures. No API was produced by build01.

Root's independent review also found a semantic counterexample in the draft.
Minted source bodies retain the original template reference, so self_pending's
search for the synthesized owner name can return zero. Pinned def_check always
starts with the instance's runtime arity. For a safe depth>0 instance, use that
runtime pending count; keep the ordinary source contains_self optimization and
unsafe behavior. Save decreasing same-key recursion and nondecreasing controls.

Closed arguments are checked once. The shifted instance type still performs
tele_fill after source binder freshening; this is repeated pure substitution and
normalization, not a repeated type check. It is retained to avoid capture and
must not be described as zero repeated work.

Source01/build01 remain immutable. Source02 is copied from their frozen source
with only the changes above before a fresh checked build and focused gates.
