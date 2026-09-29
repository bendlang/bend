# Shared decorator/import diagnostic checkpoint

This bounded candidate starts from the immutable Phase19 instance-source04
compiler, installed at fd9e8b2. It changes no import traversal, namespace policy,
parser acceptance, public record or host/cache ABI.

The remaining strict difference in supplied-source39 and ordered-host43 is
`@unsafe` followed by `import`. The import-header scan correctly stops at the
decorator. The ordinary body parser then reaches `f_top`'s pending-unsafe guard,
which still calls plain `f_err("expected def after @unsafe")`. That error has no
ParseExpected/ParseToken payload, so the existing shared renderer returns a
legacy one-line error. Pinned `parse_book` (bend.ts2499–2500) reports expectation
`'def' (@unsafe marks the def below it)` and observes the current character.

After freezing and running a pinned/current baseline, replace that existing
failure expression with `fpe_error(ts, "expected def after @unsafe",
"'def' (@unsafe marks the def below it)")`. Make the same correction in the
existing `f_import_leading` unsafe fallback for internal consistency. The normal
public route hits `f_top` first. Both use the existing renderer and fallback;
there is no new formatter, helper, state, law or type. Expected net lines: zero.

Freeze twelve controls before source mutation: valid/missing/malformed import
after the decorator; law and datatype after it; EOF with/without final newline;
repeated decorator; comments/blank lines with an astral comment; valid unsafe def;
prior valid import before the decorator; and prior invalid dependency whose
failure must still win. Files after the decorator must not be opened, including
when missing or invalid. Both supplied-source and ordered-host routes are
compared with the pinned loader. The expected complete diagnostic strings come
from the frozen baseline oracle, not the candidate. No unrecognized-decorator or
decorator-whitespace grammar changes are in scope.

Prepare a fresh isolated source and preserve every failed preparation/build.
Require genuine checked B1/default36, all12 focused strict pairs on both routes,
and the unchanged original supplied39/ordered-host43 controls with their previous
single strict difference now absent. Preserve lifecycle counts, seed/raw source
compatibility and precedence assertions. Report any unexpected diagnostic delta;
no historical mismatch may be silently relabelled as exact. The old controls'
legacy special case remains in their original bytes; candidate promotion requires
an independently checked empty strictDifferences list.

Record source/file/hash membership, zero-line/concept delta and the explicit
absence of timing evidence. This tiny error-only candidate makes no speed claim.
Root owns integration, promotion, docs and preservation. CPU1 correctness only;
no live source changes or independent timing window.
