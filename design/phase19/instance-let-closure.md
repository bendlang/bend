# Let closure: preserve the first failed child and source binder order

Prospective bounded follow-up to the live-instance source03 prototype. The first
22 chronology observations and eight memo-name controls pass exactly. Independent
review found inherited `check_let_done` behavior that conflicts with the new
sequential-checking invariant.

Pinned `term_check` Let checks the complete body before closing any binder, then
closes binders in their original j=0..n-1 order (bend.ts:3503–3522). Candidate
`check_let_done` checks each usage count before `good(r)` and receives a prepended
binding list. Thus an outer usage error can overwrite a failed body, and two
invalid parallel binders can report the later binder first.

Before changing compiler source, freeze and run four source03/pinned paired
witnesses: nested lambda failure versus duplicate outer let; both parallel
binders duplicated; only the later parallel binder duplicated; and a valid
parallel use. The first two are hypothesized strict differences; all acceptance
and phase contracts must agree. Syntax/setup failures remain evidence.

If the hypotheses hold, prepare a fresh source04 (source03 remains immutable):
check `good(r)` before examining usage and reverse the closure list into source
order. Keep the original reversed list for source value-cell substitution. No
new error formatter, ranking, semantic state or checker is needed. Rebuild
through the genuine checked workflow and require all four strict pairs plus the
original22 and memo8 to pass. Record the exact net source change.
