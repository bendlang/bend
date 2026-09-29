# Canonical negated-equality references

The [prospective design](../../design/phase16/canonical-negation.md) survives its
bounded controls. Candidate `canonical-build-02` is a genuinely checked B1 with
the unchanged equality-v5 derivative; its maintained 36 cases pass with seven
inherited exact differences. It is isolated, not installed.

The two-file source delta adds **one physical line and no definitions or laws**.
The parser marks its generated Empty reference as FGlobal. Existing scope and
module qualification leave that surface tag alone; the existing freshening pass
turns it into an ordinary Ref and preserves its occurrence endpoints. No core or
backend case changes. A datatype shortcut would have broken valid global aliases.

All **11 direct controls** agree with the pinned TypeScript reference identity:
missing/global-ADT/global-alias Empty; lexical capture; module ADT/alias capture;
combined module/lexical capture; and four unchanged ordinary reference/equality
controls. Every freshened result is free of FGlobal. The controls inspect the
actual scoped/qualified/freshened terms rather than matching displayed names.

Six paired checks all agree on primitive outcomes: four new alias/missing-name
controls plus the original capture and reflexivity fixtures. Two are fully exact;
four retain missing excerpts or module display differences. Their strict runner
therefore exits nonzero, as required. The original capture now fails at `sneaky`,
matching the reference's expected/observed/context content; the older compiler
failed later at `exploit`.

The new imported-module witness exposes a behavior gap beyond the inherited
corpus: a module defines its own Empty alias, but no canonical global Empty exists.
The older compiler **accepts** the negated-equality definition by resolving the
generated name to that alias. The candidate and TypeScript both **reject** the
undefined canonical Empty. A root Empty alias and an ordinary explicit module
alias still work. The baseline comparison is the earlier metadata/common-rebuild
image, so unrelated diagnostic improvements in the combined candidate are not
attributed to this two-file change; the direct term controls isolate this cause.

Records under `selfhost/build/phase16/`:

- `canonical-source-02/manifest.json` and its two exact patches.
- `canonical-build-02/{attempt,report}.json`.
- `canonical-controls-01/report.json` (11/11).
- `canonical-fixtures-02/{manifest,selection}.json` and source files.
- `canonical-checks-02/selected/paired.json` and corresponding baseline in
  `canonical-checks-baseline-01`.

The first compiler candidate introduced an undeclared helper and failed checking;
source02 removes that helper entirely. The first fixture draft incorrectly used
U32 without Base and attempted to redeclare Base's Empty inside a module, which
the reference forbids during parsing. Those fixtures/results remain in
`canonical-fixtures-01` / `canonical-checks-01`; the corrected controls use their
own small datatype and reach the intended check. An initial ad-hoc upstream term
inspection tried to JSON-serialize circular span/book metadata; the corrected
inspection omitted span metadata. No failed experiment is a compiler pass.

The parser range owner will attach the `!=` operator range to the generated
FGlobal. Full corpus, complete module display and final performance remain
integration gates; this report makes no speed claim.
