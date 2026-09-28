# Phase14 imported-law semantics

The isolated final candidate fixes all four imported-law fixtures: they now parse,
accept their types and reach the exact pinned TypeScript proof-trust refusal.
It also preserves all eleven existing trust-refusal fixtures. Root owns production
integration and the broader release gates. The prospective
[plan](../../experiments/phase14/P14-001-imported-laws.md) remains unchanged.

Final checked attempt: `selfhost/build/phase14/laws-candidate-04/attempt`.
Derived API: `8115da6414e3e7cc312860796cf3263847bf59c325405e2f6998264d2f86727a`.
The [patch and identities](../../selfhost/build/phase14/laws-candidate-04/patch-manifest.json)
and [scoped final audit](../../selfhost/build/phase14/laws-final-audit-01/report.json)
identify the exact candidate. Ignored build paths are preserved by the root phase
capsule; a local path alone is not a durable publication claim.

## First divergence

The released Phase12 compiler parses each module before traversing its imports.
An omitted return type searches only declarations already parsed in that module.
Thus `def Laws.false_law?(): ...` fails before the imported law and canonical
alias identity are available. Pinned TypeScript instead resolves the declaration
name against its loaded global book, recognizes an unfilled law, and retains
that law's type and template count while reading the fill body.

The fresh paired reproduction in
`selfhost/build/phase14/laws-reproduction-01/run` preserves all eight parse/check
observations. TypeScript parses all four fixtures, checks their types and refuses
proof trust. Phase12 rejects all four during parsing, before assessing trust.
The source graphs, commands, checked baseline API `0975a4a8…` and upstream pin
`b2111cf…` remain identified by the maintained harness. No TypeScript source was
edited, and failed proof trust never counts as an independently proved theorem.

## Correction and scope

Only an omitted-type definition whose name starts with a declared import alias
may carry an `ImportLaw` raw term with its parameter telescope. Existing local
law parsing remains in place. Dependency loading resolves the marker against the
latest canonical imported declaration and requires an unfilled non-native `Def`,
plain parameters, enough template binders, and no foreign template body. The
resolved fill inherits the original type, template count and unsafe flag. Its
body uses the existing parameter lowering and fresh-counter policy.

A temporary `ImportFill` definition kind prevents qualification from rewriting
an already canonical imported law name or type. Ordinary module body elaboration
still runs; `f_module_def` removes this kind before the checked loaded book is
returned. Canonical imported-fill names do not become local names during module
qualification. Existing freshness checks still reject duplicate canonical fills.
Alias conversion uses its existing traversal: only pending fills reverse and
search the prior declaration scope. Ordinary no-fill modules do not acquire an
extra whole-book fill pass. They do incur the new tag guards and helper call;
this report does not claim zero overhead.

An imported alias prefix is not a fresh declaration namespace in TypeScript.
Explicit return annotations on these definitions now refuse during parsing,
whether they attempt a law fill or a new alias-prefixed declaration. This follows
pinned `parse_def`/`parse_fresh` and bounds the new admission path. It also moves
`import/alias_decl.bend` from a late checker error to the intended parse refusal.
Its exact diagnostic still differs.

The old name-based `f_load` API has no canonical dependency-fill context. It now
explicitly refuses unresolved markers, retaining its prior inability to accept
these inputs. Canonical graph APIs and the normal CLI support imported fills.
Raw `f_parse` may return the deferred marker; successful loaded and specialized
books must not contain it. The legacy failure is a documented boundary, not a
claim that all loader entry points gained the feature.

## Claim order and the host boundary

The first checked prototype reached the correct trust refusal for all four
cases. Three agreed exactly. `unsafe_law_derived` had the same three unsafe claims
in a different order: materialization's unique book reflects law-fill replacement
order, while TypeScript reports first source declaration order.

The correction preserves checker and materializer order. Two host call sites
pass the loaded event book to the existing Bend `driver_report` and
`driver_bad_names` APIs. The Bend reporter selects names in source event order
but resolves dependencies using `book_final_fast`, so an initial bodiless law
cannot hide the later unsafe fill. Reporting remains implemented in Bend.
This is an explicit `typed-driver.mjs` change and must be accounted for in root's
final controlled workflow comparison.

Independent review correctly identified a broader risk: an original template body
can have different references from its specialization. The finite annotated
`Bool.pick` witnesses call `choose(~0n)` and `choose(~1n)` with a marked-unsafe
constant helper. Both compilers report exactly `bad`, `choose`, `main`, with the
same output, trust, status, checked/type-accepted fields and exit code. No generated
instance name becomes a claim. These are bounded tests, not a universal trust
analysis equivalence proof. The full frontend integration gate must still inspect
all changed trust observations.

## Gates and exact limits

The unchanged maintained workflow builds genuine checked B1 and its guarded
version-5 equality derivative. Its 22 focused cases pass, retaining their twelve
known exact diagnostic differences. There is no new JavaScript rewrite rule.

The final targeted selections contain **50 paired observations** with **zero
semantic differences** and **18 exact diagnostic differences**:

- All four target fixtures agree exactly in both parse and check lanes: eight
  observations. Each check is type-accepted, checked, trust-failed, exit 1, with
  the exact original ordered unsafe-definition list and diagnostic.
- All eleven upstream trust-refusal cases agree exactly. They include the four
  targets; these are not fifteen independent cases.
- Both template trust witnesses agree exactly in both lanes, including the unsafe
  names and complete stdout. A custom acceptance oracle alone was not sufficient.
- Safe fills preserve renamed dependent binders and a law's unrestricted quantity
  while fills use plain names. Missing laws, duplicate names/aliases, already
  filled and foreign definitions, return annotations, typed/template parameters,
  too few template parameters, late imports and alias ambiguity reject at the
  intended phase. The native eligibility guard has a separate metadata-level API witness below.
- A consumer before a safe fill rejects during checking; importing the fill before
  the consumer accepts. An invalid fill body also rejects during checking. Exact
  diagnostic names and caret layout remain different for the negative cases.
- A foreign law returning base `IO(U32)` accepts types and refuses trust exactly.

The main paired harness deliberately remains **strictly failed** on three existing
alias diagnostic fixtures (`alias_decl`, `alias_shadow`, `alias_twice`). Their
semantic phases match. The four supplementary chronology/foreign/body cases pass
their declared acceptance/phase oracles. The final audit records these separate
axes and does not rewrite a failed strict result into a pass.

`laws-api-controls-01` checks six result families: the four upstream targets and
the two safe custom fills. For each, raw `FSource` versus parser-handoff
`FParsedSource`, with and without validated Base seeding, yields the exact same
serialized loaded result: **24 observations**. Every successful loaded book is
marker-free. Each distinct result is checked and specialized once, with the
other modes reusing exact-result equality; all specialized books are marker-free.
The old `f_load` refuses the marker with its explicit boundary error.

`laws-native-controls-01` additionally exercises the native-law guard through the
public graph API. Identical synthetic source graphs differ only in the library
source metadata that marks its declarations native. The ordinary bodiless law
loads, fills and checks; the native bodiless law refuses before checking. Exact
input/output files and clean supervision are retained. This is a metadata-level
guard witness, not a TypeScript source-conformance comparison or permission to
label user modules as Base.

All final launches complete without launch errors, signals, deadlines, output
limits or input drift. These are scoped correctness gates, not timing samples,
full conformance, self-reproduction or kernel validation.

## Preserved failed and superseded attempts

- `laws-candidate-01`: checked B1 and 22 focused cases pass; seven of eight target
  observations are exact. The derived trust order differs. Its extra full-book
  fill pass is superseded.
- `laws-candidate-02`: preparation failed on an assertion against an obsolete
  `f_error_term` body shape. No build ran. Partial inputs and the tool remain.
- `laws-candidate-03`: fused traversal and source-order trust reporting; all four
  targets and eleven trust cases are exact. The alias-annotation phase boundary
  was not yet corrected.
- `laws-controls-01`: two intended positive witnesses were invalid under pinned
  TypeScript: a duplicated value whose type had only kind `Type`, and invalid
  `&T` syntax. These are fixture setup failures, not compiler regressions.
- `laws-controls-02`: the corrected kind was valid, but a marked untyped fill
  binder was still invalid. A self-recursive unsafe helper caused pinned checking
  to stall in the first template witness. The run was explicitly cancelled with
  the exact target PID/arguments and partial history retained in `cancel.json`.
  The cancellation is not a timeout pass or a compiler correctness result.
- `laws-controls-03`: a finite unsafe helper removed that divergence, but the
  unannotated matcher could not be inferred by pinned TypeScript. Its observations
  remain failed; controls04 uses a valid annotated expression and plain fill names.
- `laws-extra-controls-01`: both compilers reject a foreign law returning bare U32
  during checking; a foreign definition must return base IO directly. This failed
  intended trust witness remains preserved. Extra-controls02 uses `IO(U32)`.

No consumed source or tool was overwritten. New attempts use new paths. The final
50-observation audit is based on controls04 and extra-controls02, not a selection
of successful rows from the earlier invalid runs.

## Complexity and integration

The proposed patch changes five Bend modules and two arguments in one host tool:
**+13 physical / +11 nonblank Bend lines, +1,997 Bend bytes; +14 host bytes and no
new host lines**. It adds two private Bend helpers and two temporary internal
representation markers. Existing declarations are extended; no runtime, public
export, checker or materializer protocol changes. These line counts reflect the
repository's existing compact expression style and do not substitute for concept
accounting. Experimental preparation, fixture and audit tools are additional
validation machinery, preserved under `selfhost/tools/performance/phase14/laws-*`.

Root should apply only `laws-candidate-04/candidate.patch` against the manifest's
before hashes, combine it with independently surviving Phase14 work, and build a
fresh checked attempt. Re-run the 22 focused cases, target/trust/template witnesses
and one full frontend comparison, explaining every changed observation. Include
the two host argument changes in final performance identity accounting. Applicable
backend and release gates remain root-owned. This subtask does not install,
commit, push, or claim a production speed change.

All workstream producers are closed. The consumed project is
`selfhost/build/phase14/laws-candidate-04/project`; the patch SHA-256 is
`11e5b8dbf6262526d5b9776b766b08df79aa8ea1576031f4afa357357dd25dbf`.
No production file was edited by this workstream.
