# Phase19 output assembly order

Independent read-only review found that repeated public specialization requires
the output book to be a valid source-event stream for the shared checker. The
old materializer's reverse-publication order was tolerated by its sp_needed skip;
the new shared checker must not rely on that hidden precondition.

`kw_put_checked` prepends each completed unique final definition. The pure
`sp_assembled(world) -> List<KDef>` reverses that accumulator: nested instances
precede their enclosing instance/caller, and final source events retain their
chronological order. Original generic definitions are preserved. The assembler
does not walk terms or recreate memo state.

This intentionally changes raw output-list order relative to Phase18. Keep the
old whole-value public18 oracle and any resulting report unchanged; use a new
Phase19 gate that explicitly checks this declared order, repeated specialization,
unchanged historical KSpecialized/KChecked4 shapes and demanded-field behavior.
Do not call the new result byte-identical to the old reverse-ordered book.

Root's common entry is `dg_check_world(book)->DChecking`, with
`dg_checking_result(result)->KChecking`. It performs source guard/check events
without final TODO policy. specialize_book projects that result once. Mint
failures keep their unqualified language message and deepest DTrace owner;
the event boundary qualifies the public message once from structural ownership.
