# Observed let closure correction

Source03's frozen four-case experiment produced two strict differences, zero
primitive differences. The nested-body failure already matches the pin: retain
it as a control, and describe the pre-`good` usage read as a static sequencing
hazard rather than a demonstrated language failure. Parallel binders report the
last invalid binder instead of the first. A sole invalid later binder has the
right message but uses its own span instead of the group's span.

The first range probe only saw raw parser surface terms, so it did not observe
any Let and cannot justify a core-origin claim. The fresh second probe loads the
same files through public `f_load_graph`: ordinary Let has 0/0 origin, while the
first Bind range exactly equals pinned `body_flatten`'s explicit `ws[0].s` choice
(up to the documented one-based global offset). Both records remain immutable.

Source04 will pass a close-site through the existing let closure worker. Use the
enclosing Let when it carries a real origin; otherwise use the original first
Bind, the exact `body_flatten` correspondence. This preserves the independently
specified do-assignment span (`parse_term_do_stmt` uses the whole assignment),
which already travels on the Local/Let producer. Add invalid and valid typed
pure assignment inside `do IO<Unit>` as paired controls before compilation.
Reverse only the closure traversal list, retaining the reversed binding list for
source value-cell substitution. Test failure before reading usage. No source
search, location heuristic, parser edit or diagnostic ranking is introduced.
