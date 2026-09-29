# Preserve local law-fill parameter error order

The remaining `comptime/err_law` and `err_fill_short` fixtures share a local
declaration context that the header worker already knows. Pinned `parse_def`
rejects an initial `~` before parsing a known law's telescope; after ordinary
telescope parsing it requires bare names, then at least one name per compile-time
law clause. The current combined predicate loses these distinct cursors and
messages.

Reuse the known fillable declaration and existing token cursors. Reject the
initial marker in the header worker. Preserve a telescope parser failure before
checking the resulting parameter list. Split the bare-name and minimum-count
conditions at the existing post-telescope cursor, then retain the colon/body
path. No source scan, new term/type, dependency guess or alternate parser is
needed. Imported declaration visibility stays a separate architecture task.

Validate both corpus cases and typed, marked, short, malformed, correct, trailing
comma and earlier-error local fills against pinned TypeScript. Keep valid ordinary
template declarations exact and protect the preceding declaration/native/foreign
controls. Count complete source changes rather than claiming compact formatting
as simplification. Integrate only after a checked build and adjacent full gate.
