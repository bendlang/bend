# Live-instance checking: owned implementation and correctness report

This isolated candidate validates a template instance at the point where the
ordinary checker reaches its live reference. It fixes both saved Phase17
same-body diagnostic-order counterexamples, preserves the original instance-name
sets, and removes the old specialization term visitor. The final owned candidate
is `selfhost/build/phase19/instance-source-04/project`; its genuine checked build
is `instance-build-03`. Integration, execution, timing and promotion belong to
the separate root report. This report does not claim a speedup or installation.

## What changed

`KWorld` carries the source book, canonical memo, explicit Known/Deferred fresh
state and a separate checked-output list. `KChecking.term` carries checked syntax
on success and the existing structural diagnostic trace on failure. The same
checker now sequences children, stops at the first failure, carries returned
state into subsequent normalization/comparison, and rebuilds successful output
from checked children. Original source bodies remain the semantic authority.

A live template reference checks its closed arguments, computes the existing
canonical key, reserves an active memo entry, freshens and checks the instance
with that same checker, then publishes its original source body and completed
output separately. Nested effects survive the return. Pending applications use
the existing consumed count to skip already checked closed arguments. Active
cross-instance recursion, same-owner descent, the depth64 guard and the exact
32768 UTF16 key-size guard retain their pinned policies. Erased uses do not mint.

The old specialization visitor, its three traversal-state types, context walk,
erased re-inference and separate validation driver are deleted. `specialize_book`
uses the shared source-event checker and projects the stable public
`KSpecialized { book, error: KChecked4 }` result. Output assembly is a pure list
operation: completed nested instances precede their callers; final source events
remain chronological. Rechecking materialized output therefore needs no hidden
memo or former specializer skip.

Root's event/public boundary keeps a declaration visible before checking its
body, preserves final law-fill event order, and uses the actual failed world for
diagnostic normalization. A source-only prefix cache contains no memo, so it
replays checking. Program completion still applies open-law/TODO policy after
actual checking. No second checker, error ranking, host language fallback,
production probe exports or host/cache ABI change was introduced.

Deferred initialization does no book/body scan. At the first mint it includes the
saved complete owner body/type and current context/lhs/spine, then maintains a
strict fresh bound and updates the existing indexed-book bound without treating
the trie as language terms. Temporary match/rewrite identities are reserved
before checking dependent children. Generic success restores only the caller's
source-book view; returned memo/fresh/output survives. A failure retains its
private source view. Pure telescope substitution is repeated after freshening;
this report does not claim that all normalization work has been eliminated.

## Focused evidence on the final checked image

| Gate | Result | Evidence below `selfhost/build/phase19/` |
|---|---:|---|
| Genuine checked bootstrap + maintained default36 | pass; two inherited strict differences | `instance-build-03/` |
| Frozen original chronology observations | 22/22 strict exact | `instance-paired-02/report.json` |
| Original memo instance-name sets | 8/8 exact | `instance-memo-02/report.json` |
| Parallel-let and do-assignment boundaries | 6/6 strict exact | `instance-let-paired-03/report.json` |
| Frozen parsed canonical instance controls | 29/29 exact | `instance-parsed29-01/report.json` |
| Canonical JSON/Unicode/quantity-presence/size controls | 61/61 exact, including20 size boundaries | `instance-key61-01/report.json` |
| State transport, demand and actual freshness controls | 40/40 pass | `instance-direct-02/report.json` |
| Safe/unsafe self and cross-instance recursion | 4/4 strict exact | `instance-recursion-paired-01/report.json` |

The22 include both saved chronology gaps, nested local failures, same-key
structurally decreasing recursion, erased calls, active cross-instance recursion,
and the two saved grow/grow_double refusal diagnostics. The four supplementary
recursion controls preserve unsafe self-call type acceptance and its proof-trust
refusal; unsafe does not permit an active cross-instance cycle. No nonterminating
unsafe body is executed.

The direct40 exercise nonzero consumed counts and different worlds across
successful reconstruction and translated failure, seven poisoned later-child
boundaries, failed-let usage demand, generic restoration, memo-hit no-rescan,
Deferred/known bounds and overflow refusal. A real loaded nested-template book is
checked with an unpublished **nongeneric** owner: its first parallel-let RHS
mints while a later RHS contains a valid binder with ID900000 absent from the
current context/lhs/spine. Actual minted binder IDs exceed that later sibling,
source instance bodies retain the original template reference, checked output
contains the minted reference, and the indexed bound covers the returned fresh
state. This tests the saved-owner mechanism rather than only a synthetic bound
helper.

The direct61/direct40 tools append separately named instrumentation wrappers to
an exact byte prefix of the checked API. Both production and probe identities,
the precise suffix and target names are recorded. The probe module has a distinct
hash and is not represented as the production API. The raw convenience helper
`check_definition_result` is dead-stripped in this image; the direct owner probe
calls its exact existing two-call body,
`check_definition_world(kw_initial(book), owner, 0)`, over checked helpers.

Independent pinned public-boundary controls cover event visibility, law fills,
private failures, source/output separation, prefix replay and repeat raw
specialization. Their first104-control report is on source03/build02; source04
only changes let closure and is independently covered by the six paired let
controls. Consult the boundary owner's report for final-image repetitions and
projection scope. Root's final frontend2996 comparison is exact against the
installed prefix version; this does not increase the upstream corpus's pass count.
The meaningful conformance gains here are the saved custom counterexamples.

## Let closure follow-up

The first semantic prototype already passed all22 and memo8. Independent review
then identified an inherited closure-order concern. Four paired source03 controls
showed two strict differences: closing prepended parallel bindings reported `b`
before `a`, and a sole invalid later binder used its individual span instead of
the group's span. A nested-body-failure witness was already exact; it remains a
negative control, not a claimed fixed language failure.

A first range probe inspected raw parser surface terms and saw no core Let; it
could not support a core-origin conclusion. The fresh loaded-book probe found
ordinary Let origin0/0, while its first Bind's occurrence exactly matches pinned
`body_flatten`'s explicit `ws[0].s` choice. A typed pure assignment inside `do`
adds a distinct third difference: pinned closure highlights the full assignment,
whose nonzero enclosing Let origin is already present.

Source04 therefore closes bindings in source order, checks failure before reading
usage, and uses the existing nonzero Let site or the exact first-Bind lowering
origin when that site is absent. It adds one physical kernel line versus source03
and no helper/type. Six final strict pairs close all three observed differences,
including valid ordinary/do controls. This is not source-text searching or a
broad parser-origin change.

## Public compatibility: retained differences, not a waived pass

The frozen Phase18 public18 tool was run unchanged on world06/final03. It reports
**12 pass and six differences**, and is retained as `instance-public18-01`.
All nine historical four-field/projection-demand rows, advertised export
membership, and two empty-book rows pass unchanged.

The six raw first/repeated whole-result comparisons express the old boundary:
ordinary/instance output lists had the former order; `check_book` accepted a
bad instance until specialization; failure output represented the old specializer
world. The new shared checker intentionally changes those results. This report
does not relabel public18 as passing or claim raw whole-book byte equality.
The independently pinned public-boundary controls validate the new checking,
source visibility and repeat-materialization contracts. Historical immutable
payload demand and error-before-term ordering remain required and pass.

The raw unpublished-owner freshness control is explicitly nongeneric. Generic
checking assumes its owner declaration is already in the source book, as ensured
by the actual source-event entry and pinned checker. A raw unpublished generic
passed directly to the internal helper is outside that precondition; it is not
an advertised public API or covered by that nongeneric witness.

## Complexity census

Count only the59 modules in `src/compiler.json`, with the same physical/nonblank
line, byte and top-level declaration rules for both sides.

| Metric | Installed prefix version | Source04 | Delta |
|---|---:|---:|---:|
| Physical lines | 16,355 | 15,880 | -475 (-2.9%) |
| Nonblank lines | 13,956 | 13,527 | -429 |
| Bytes | 581,508 | 575,893 | -5,615 |
| Definitions | 1,657 | 1,659 | +2 |
| Laws | 775 | 719 | -56 |
| Types | 66 | 67 | +1 |
| Modules | 59 | 59 | 0 |

Versus the isolated Phase18 world06 parent, the delta is -580 physical lines,
-515 nonblank lines, -9,871 bytes, -14 definitions, -56 laws and -2 types. The
installed comparison includes the earlier world transport cost, so it is the
appropriate total-path comparison. The implementation does not achieve the
user's50%/75% whole-compiler reduction targets.

There is a concrete architectural simplification: one authority now checks
ordinary code and instances, and one source-event order controls visibility.
The checked-output accumulator is data, not a second semantic book. The cost is
explicit world/freshness transport and child continuations. Definition count alone
does not establish lower conceptual complexity, and no subjective concept total
is presented as a measured fact.

Exact changed production files versus the installed prefix version are
`src/check/{annotate,kernel,specialize}.bend`,
`src/diagnostic/{produce,trace}.bend`, and `src/driver/api.bend`.
`src/check/prefix.bend` already equals the separately installed prefix correction.
Source04 remains immutable; the cumulative handoff manifest binds every source
member, both comparison bases, changed-file patches and the checked API.

## Retained unsuccessful attempts

- Source01/build01 failed during genuine bootstrap: three rewritten helpers had
  lost explicit signatures. No API was produced.
- The source02 preparation failed its own incorrect callsite-count assertion
  before compiler edits. Its partial copied project remains, unbuilt.
- Source03/build02 restored those signatures and corrected safe minted runtime
  pending arity: original source self-references still name the template, so the
  ordinary `contains_self(mintedName)` shortcut was insufficient.
- The source03 let four/six-case observations retain their two/three strict
  differences; the initial raw-parser-only range probe is explicitly insufficient.
- Direct01 stopped before wrappers/tests because a convenience helper was
  dead-stripped. Direct02 uses the exact extant shared entry and passes40.
- The frozen public18 six transition differences remain failed rows. They are
  explained above and are not deleted, suppressed or converted into exactness.

No old phase evidence, pinned TypeScript, unrelated Phase6 payload or production
source was edited by this owner. Root owns final integration, sustained history,
backend execution, controlled whole-source timing, promotion and publication.
