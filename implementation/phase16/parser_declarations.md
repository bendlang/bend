# Local declaration eligibility and cursor preservation

The bounded candidate fixes four parser fixtures, eight paired observations:
`comptime/err_dup.bend`, `parse/foreign_refill.bend`,
`parse/def_untyped_refused.bend`, and `parse/law_fill_arrow.bend` now match pinned
TypeScript exactly. Primitive acceptance, phase and trust observations stay
unchanged for those fixtures. The checked bootstrap/B1 and36 maintained focused
probes pass; the focused set retains two unrelated exact differences.

A single declaration lookup now reaches the header eligibility worker before
parameter parsing. Closed body/foreign/native declarations fail at the actual
name. An open non-native law retains the existing fill path. Missing-arrow and
law-fill-colon errors reuse their existing post-telescope cursor. The old f_def
wrapper and law were removed. The change is two Bend files and one fewer physical
line overall; no host, cache, graph or declaration-layout change is involved.

The frozen46 direct observations cover legacy and indexed cursors at1/4097,
ordinary/open/unsafe law fills, repeated bodies and foreign implementations,
duplicate-before-malformed-header precedence, unknown untyped names, arrow
refusals, ordinary U32 names without Base, real keywords, and injected native
claims. All46 match TypeScript exactly; successful trees remain equal after
origin metadata is erased. Two indexed native-claim controls deliberately expose
a baseline acceptance bug: an open-looking native declaration could be filled by
the raw parser. The new eligibility check rejects it like TypeScript. That direct
semantic correction is separate from the eight corpus diagnostic improvements.

The exact frozen handoff is
`selfhost/build/phase16/parser-declaration-source-01-handoff/manifest.json` with
its two patches against `wave4-source-02`. Evidence includes
`parser-declaration-checked-01`, `parser-declaration-validation-01`,
`parser-declaration-audit-01.json`, and `parser-declaration-controls-01`.
The import owner separately retains the agreed final nameTokens argument on
f_def_prior; this header worker supersedes the import overlay's mechanical old
f_def threading. Root owns the integrated full-corpus and performance gates.

This does not resolve imported-name collision ordering. U32 is an ordinary Base
name, not a keyword. The empty local parse book cannot see imported declarations;
the graph's later string-valued freshness failure also loses the declaration
cursor. That remaining family needs a shared declaration-context solution, not
hard-coded Base names or diagnostic-string recognition.
