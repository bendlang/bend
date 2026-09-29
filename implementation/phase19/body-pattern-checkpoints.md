# Ordinary locals validate patterns before their continuation

The isolated contextual body route now fixes a real parser ordering error:
`f(x) = y; return z` rejects the completed call as a pattern before parsing the
later return. In the reverse case, `f(x) = return z`, the RHS syntax error wins.
Valid local bindings, shadow restoration, successive locals, empty-call binder
eligibility and constructor-spelled binders agree with pinned TypeScript.

This is still a private Body-stage parser. Groups, rows, do and other unmigrated
owners return explicit Unsupported. The original saved16/group and monad2 are
the next approved target; they are not claimed fixed here. No loader migration,
Core result, speed measurement or installation is part of this experiment.

The final source is `selfhost/build/phase19/context-body-source-03/project`,
genuinely checked as `context-body-build-03`. Parent is frozen Stage2
`context-grammar-source-02/project`. The source manifest binds complete parent
and candidate memberships and all seven changed files. Its delta is104 physical
Bend lines /5,663 bytes and17 definitions, including three names for existing
worker bodies. The host export edit adds19 bytes and no lines. The private
expression and body entries share one FContextSyntax result union; no new
per-stage datatype or compatibility alias was added. No source deletion is
claimed while the raw compatibility route remains.

The existing body parser now performs RHS parsing, shared shallow pattern
validation and fresh binder opening before entering its existing continuation.
It restores the outer lexical environment on success and preserves the failure
environment on error. Contextual calls use the existing App constructor, so an
empty bound call remains a Var while an empty unbound call remains its canonical
Ref. The raw parser still produces exactly its previous Call representation.

One finding required a correction: pinned `term_higher(t,null)` converts an
outer/free parser Var to `Ref(writtenName)` when constructing a computed-pattern
observation. Ordinary alpha-renaming preserves that Var. The first body gate
therefore had two strict text mismatches (`x^1`/`x^2` versus `x`). The final
candidate seeds the existing freshener with explicit Ref maps for current outer
bindings. Its existing Var-map path is unchanged; inner Lam/All/Let maps shadow
the outer maps, and references retain occurrence spans. FName uses its distinct
canonical fallback. This is not a full implementation of term_higher: beta
reduction and Sub interpretation remain outside the admitted grammar domain.

All final producers closed normally on CPU3:

| Gate | Result and evidence |
| --- | --- |
| Genuine B1 / maintained36 | Pass; same two retained strict differences, `context-body-build-03/{build.json,validation-001/report.json}` |
| Actual local-body oracle | All40 pass:31 strict supported observations and9 explicit Unsupported controls, `context-body-probe-02/report.json` |
| Prior names/calls | All46 pass under the explicitly renamed private API, `context-body-grammar-02/report.json` |
| Prior names/state | All27 pass, `context-body-stage1-02/report.json` |
| Free-variable materialization | All13 pass, including inner shadowing, All domain/codomain, parallel Let, duplicate names/distinct IDs, old Var maps and absent/underscore Vars, `context-free-probe-02/report.json` |
| Public/raw compatibility | All194 pass, including full raw/lowered Base and compiler books, `context-body-raw-02/report.json` |
| Source/artifact/health audit | Pass, `context-body-audit-01/report.json` |

Evidence paths are under `selfhost/build/phase19/`. Oracles were frozen before
source. They execute the pinned TypeScript header/body parser and retain actual
predecessor raw-body results. Candidate implementation never calls TypeScript.
The direct API extensions preserve the production bytes as an unchanged prefix
and carry separate artifact hashes. Unsupported controls are not conformance
gains. Source ranges, exact fresh counters, stack state, failure cursors and
independent sibling contexts are checked along with the diagnostic/Body shape.

Retained failures are `context-body-build-01` (a constructor-valued local needed
an explicit FInput annotation), `context-body-probe-01` (the two free-Var
diagnostics), and `context-free-probe-01` (the direct tool compared a live
undefined property with a JSON oracle which omitted it). The corrected direct
tool canonicalizes its newly computed reference projection through JSON before
comparing it with the unchanged oracle; no expected semantic output changed.

The next [row/group proposal](../../design/phase19/saved-row-group-frontier.md)
is approved for a bounded experiment. Its manual source census binds65 files
and130 saved observations. It calls for real constructor-pattern/row checkpoints
and `ff_flat` at the group boundary before any later annotation or closing-token
demand, preserving deferred flattening of an ungrouped previous row.
