# Shared decorator diagnostic: source01 handoff

The isolated candidate closes the inherited decorator/import diagnostic gap by
using the existing structured parser error constructor at the two pending-unsafe
guards. No loader ordering, parser acceptance, source record or host/cache ABI
changes. It adds **zero lines, definitions, laws or types**, and 92 bytes in one
source file. It is not installed by this experiment.

`@unsafe` followed by `import` previously bypassed the shared renderer and emitted
`line 2:0: expected def after @unsafe; got import`. Pinned `parse_book` reports the
expectation `'def' (@unsafe marks the def below it)`, the current character and a
source snippet. `f_top` and the existing `f_import_leading` unsafe fallback now
construct that same structured failure with `fpe_error`. The normal public route
reaches `f_top`; both branches retain their original rejection checkpoint.

The genuine checked B1 and maintained36 pass. Strict maintained differences fall
from two to one: import-after-decorator becomes exact; import-after-type remains
unchanged. The frozen12 fixtures exercise both supplied sources and the ordered
filesystem host: all24 observations are exact, improving20 while retaining4.
They include EOF, law/type/repeated decorator, comments, valid definitions, missing
or invalid later imports, and an earlier invalid dependency whose failure wins.
Exact read lists prove that imports after the decorator are never opened.

The original supplied39 and ordered-host43 tools were executed unchanged. Both
pass with **empty strictDifferences**, independently checked despite their
historical allowance for the decorator gap. The latter preserves seed/lifecycle,
source-range, compatibility and ordering controls. The astral-comment fixture
tests an astral character before an ASCII error cursor; inherited fallback when
the offending cursor itself is astral/surrogate is unchanged.

The frozen Phase19 full frontend has2996 observations and none contains the
changed legacy message. The prospective broad-gate policy is no primitive or
unrelated diagnostic delta; root owns that integration gate. No timing was run,
so this error-only change makes no speed claim. Unknown decorators, whitespace
inside the decorator spelling and the datatype constructor checkpoint remain
outside source01. The separate datatype investigation must not be counted as a
source01 improvement.

Source: `selfhost/build/phase20/import-diagnostic-source-01/project`.
Patch and all214 project identities: its `declarations.patch` and `manifest.json`.
Checked attempt: `selfhost/build/phase20/import-diagnostic-build-01`.
Baseline/focused/supplied/host reports are the corresponding Phase20
`import-diagnostic-*-01/report.json` files. No failed Phase20 preparation, build or
control attempt occurred before this handoff. The machine report binds the exact
API, inputs and raw results; original reports and sources are frozen.
