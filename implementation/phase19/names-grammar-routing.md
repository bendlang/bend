# Ordinary names routed through the existing grammar

The isolated names-stage parser now demonstrates a real ordering improvement.
For `M.f(return)`, where alias `M` points at `mod` and both `M.f` and `mod.f`
exist, the former raw grammar reports the later invalid `return`. The private
contextual route reports the earlier alias ambiguity, exactly as pinned
TypeScript does. Seeding a local named `M.f` suppresses that ambiguity and exposes
the return error instead. Nested calls and an earlier invalid argument before a
later ambiguous name preserve the reference order too.

This is an experimental names/calls stage. It produces explicit Parsed, Error
or Unsupported results, never Core. The ordinary loader still uses raw parsing.
Neither the two main monad observations nor the independent same-body instance
gap is claimed fixed. There is no timing or installation decision for this wave.

Parent is the frozen Stage1 `context-source-02/project`, selected API
`7c4d83bd`. Candidate source is
`selfhost/build/phase19/context-grammar-source-02/project`; its complete parent
and candidate memberships and three patches are beside it. Genuine checked B1
is `d0f6933090633ebc5a51334d95d9f2ac7312d250d640f29f96bebc753a7b985c`;
the existing guarded derivative selected for validation is
`780ed907d85441ccb2e1a7ad04fe076a0446c01972641cea9d78a5512c5a9a52`.

The [prospective design](../../design/phase19/names-grammar-routing.md) and
46-case control file were frozen before the TypeScript oracle and source.
The reference directly executes the pinned parser with header seeds obtained
from its actual `parse_tele` events. Compiler code never calls TypeScript.
The baseline oracle also invokes the parent's actual raw expression grammar on
the ordering witnesses and retains both diagnostics.

The patch adds 79 physical Bend lines / 3,936 bytes, 13 definitions and one
result datatype. Three definitions name the preexisting raw worker bodies;
their grammar is not duplicated. The private stop tag distinguishes unsupported
owners from upstream errors. One host line / 40 bytes explicitly roots the
private checked export. No existing semantic owner is deleted, and this is not
a source-reduction claim. Relative to the pre-Stage1 cursor parent, the two
semantic experiments together add 199 Bend lines, plus their manifest/host roots.

`f_atom_name` uses the shared contextual lookup only in contextual mode. The
call owner consumes an ordinary unbound name's canonical Ref alternative before
arguments; bound variables remain variables. Existing argument recursion and
raw Call construction are reused. The direct oracle projection expands that
staged Call into an App spine; it does no name lookup or semantic evaluation.
Unsupported owners stop at their real entry, including inside arguments.
Error/Unsupported are checked before contextual growth, before subsequent
arguments and before wrapping a call. This ordering matters because private
errors preserve their cursor instead of using the raw parser's empty rest.

All final producers closed normally on CPU3:

| Gate | Result and exact evidence |
| --- | --- |
| Checked B1 and maintained36 | Pass; same two known strict differences, `context-grammar-build-02/{build.json,validation-001/report.json}` |
| Existing-grammar oracle | 32 supported term/state/diagnostic observations exact; 14 explicit Unsupported interface controls pass, `context-grammar-probe-01/{report.json,controls/report.json}` |
| Stage1 names/state | All27 pass, `context-grammar-stage1-01/report.json` |
| Public/raw compatibility | All194 pass, including complete raw and lowered Base/compiler books, `context-grammar-raw-01/report.json` |
| Source/artifact/health audit | Pass, `context-grammar-audit-01/report.json` |

All evidence paths above are under `selfhost/build/phase19/`. Direct-test APIs
retain the production API bytes as an unchanged prefix and record distinct
extension hashes. No hand-written JavaScript supplies compiler semantics.
Fresh counters, lexical stacks, source ranges, consumed cursors, sibling
independence and refusal of already-contextual entry inputs are checked.
The 14 Unsupported cases are not counted as conformance gains.

Failures remain visible. `context-grammar-source-01` and `build-01` failed
bootstrap because three renamed raw workers no longer inherited their old named
law signatures. Source02 gives them explicit signatures; no test or expected
diagnostic changed. The first audit script had a Python syntax error (`pass` as
a keyword argument) before it could create output; that tool is retained and
the corrected `context-grammar-audit-v2.py` produced the audit above.

The next useful move is a real pattern checkpoint in the existing body grammar:
parse left expression and RHS first, validate/open the pattern next, then enter
the continuation. That should first prove computed-pattern versus later syntax
ordering and lexical scope restoration. Groups, rows and do require their own
reviewed owner migration before this can claim the saved monad/group frontier.
