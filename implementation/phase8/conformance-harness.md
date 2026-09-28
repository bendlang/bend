# Conformance harness migration to b2111cf

Date: 2026-09-28. This report covers the reference adapter, fixture inventory,
selected comparison infrastructure and strict judge. Compiler semantics and
release promotion belong to the [migration report](upstream_and_conformance.md).

## Oracle boundary

The upstream fixture gate uses `--checkup`, which validates each book and then
runs a filled `main`, or prints its declaration verdict when there is no main.
It is not interchangeable with `--check-only`: an unsafe executable can validate
and run even though the latter refuses to certify its proof trust.

The harness preserves its distinct parse, check and execution lanes. Check
success records `typeAccepted: true`. Declaration-only unsafe/foreign books have
`status: error`, `phase: verdict`, `checked: true`, `typeAccepted: true`,
`proofTrust: failed`, and exit 1. Matching these exact expectations earns
`proof-trust-rejection`, never `checker-rejection`. Their complete ordered list
of unsafe/foreign-dependent definitions is retained. Safe declaration verdicts
are `ALL PROOFS CHECK` followed by the upstream mathematical-validity hint.
All results state `kernelChecked: false`; the adapter does not run Lean.

Loading, parsing, checking and unresolved-TODO errors gain upstream's exact
`SOME PROOFS FAIL` heading. Compile/runtime diagnostics remain unframed. The
judge compares exact expected text and nonzero exit status; it does not remove
headings or treat any arbitrary failure as proof of a language rule. Explicit
acceptance-only fixtures may accept a separately demonstrated type acceptance
before a trust refusal, but cannot call that refusal a type rejection.

Reference calls use current unmodified upstream APIs. Removed `C.book_owned`
and `Book.open` are no longer read; complete validation calls `book_valid`, and
unresolved holes use `book.hols`. Trust propagation follows `main.ts` across all
non-Base definitions, including imports, types and constructor fields.

## Fixture discovery and provenance

The frozen new target has **1,509 Bend source files** beneath `tests`. The
upstream gate enumerates **1,498 direct namespace fixtures**, comprising:

| Expected outcome | Fixtures |
|---|---:|
| Positive | 1,001 |
| Validation failure | 482 |
| Unsafe/foreign proof-trust refusal | 11 |
| Plain `Error:` expectation | 4 |

Eleven nested files are imported support modules without `#|` expectations.
They remain inventoried and hashed, but are not assigned invented empty positive
oracles. An initially failing pure test exposed this distinction; its raw output
is retained. A second initial failure was in a test fixture that spread an
object containing deliberate throwing getters, before the adapter ran.

The active pin comes only from `src/compiler.json`. The inventory records
`safe.ts` and `bendtt.lean` in place of the removed `bend.lean`. Selected-run
snapshots copy and hash their own compiler manifest; they do not silently read
a different live pin. Both adapters and the runner include the manifest in
artifact provenance. A relocated snapshot with spaces in its path, a distinct
valid pin, an invalid pin and a missing manifest are covered by tests.

Progress rows preserve fixture `failureKind`. Semantic summaries keep trust
refusals apart from validation negatives and explicitly report type acceptance.
Paired comparisons retain `typeAccepted`, `proofTrust`, `kernelChecked` and
unsafe-definition metadata alongside existing exact output/phase/status fields.
These fields prevent an unsafe acceptance from disappearing into a generic
negative-test count. `compare-artifacts.mjs --strict-paths` compares completed
raw reports without rerunning either compiler. It preserves exact paths, binds
fixture paths/oracles and target manifests, rejects duplicate rows, and compares
all acceptance/trust/kernel metadata. Its default retains historical upstream
path-prefix normalization for old workflows. Runner manifest provenance has its
own `harness/compilerManifest` key, so it cannot overwrite the typed host's
separate manifest identity.

## Completed focused validation

- **42 pure harness controls pass**, including 23 new Phase8 controls and the
  19 existing judge/selection controls. The removed upstream API properties are
  throwing getters in the adapter tests, so accidental reuse is observable.
- **17 live-reference observations pass** exact fixture text and exit behavior:
  all 11 trust refusals, a safe declaration, unsafe-main checking and execution,
  an actual checker rejection, a TODO rejection and foreign-main JS refusal.
  The report separately records 11 trust refusals and two checker rejections.
- **Three actual IO.args lanes pass**: interpreter, JavaScript and native Clang16
  compilation/execution all print `True 0`. Generated program names derive from
  the fixture basename, preserving upstream's new argv[0] contract. This is an
  actual native execution gate, not source-size or emitted-text evidence.
- The ordinary CLI version command prints `Bend2 port targeting 2.0.32`, read
  from the active manifest. This checks target labeling, not release promotion.

The focused reports have `selectedComplete: true` and `complete: false`, with
no changed inputs or artifacts. No full-language conformance is inferred.
Raw files are retained at `selfhost/build/phase8/harness-controls-01`, including
both initial failed-test logs, later passing logs, selections, reports, runtime
outputs, native build information and the reference adapter before the argv
filename adjustment.

## Full reference frontend baseline

The fresh frozen reference run completed all **2,996/2,996 observations** under
`selfhost/build/phase8/reference-frontend-01`. The launcher copied the exact
harness, adapter, native/resource helpers and compiler manifest and recorded
their identities. CPU2 ran one persistent worker at a time, recycling after 64
requests, with 4 GiB heap, 4 MiB stack, 30-second request caps and a 30-minute
outer cap. This is correctness evidence, not a performance comparison.

| Lane/outcome | Observations |
|---|---:|
| Positive parse passes | 1,001 |
| Negative parse observations | 497 |
| Strict check passes | 1,494 |
| Strict check failures | 4 |
| Actual checker rejections | 288 |
| Frontend rejections | 194 |
| Proof-trust refusals after type acceptance | 11 |

All 1,001 positive fixtures were type accepted. The 11 proof-trust refusals and
four deferred-error fixtures were also type accepted: **1,016 demonstrated type
acceptances** in total. There were no timeouts, crashes, worker errors, changed
inputs or changed artifacts. Full-suite `complete` remains false because this
run covers frontend lanes; `selectedComplete` also remains false because the
four strict check-lane oracle failures are retained.

Those four cases are `io/cid_unknown.bend`, `io/effect_ctr_name.bend`,
`io/main_foreign.bend` and `reg/array_open_element.bend`. The first three have
failed proof trust from their foreign definitions; the Array example has passed
proof trust. Their fixture expectations concern later errors. Successful type
checking alone therefore cannot pass their exact check-lane output oracle, and
is not evidence of checker unsoundness. Their actual later-lane observations
are retained in a separate bounded gate.

Execution with main now records `proofTrust: not-assessed`, matching the CLI's
actual demand; check-with-main retains its full trust assessment. The
interpreter's IO-main eligibility gate is classified as compile, after type
acceptance, so a foreign-main refusal cannot be mistaken for type rejection.
These execution-only refinements leave the frozen full frontend observations
unchanged. The earlier focused reports remain separate artifact-specific evidence.

The final execution-policy gate at
`selfhost/build/phase8/harness-controls-02/reference.json` passes **14/14** rows.
All four deferred fixtures reject exactly at compile in every eligible exercised
lane: unknown CID and effect-name collision each have interpreter/JS checks;
foreign main and open Array element each have interpreter/JS/native checks.
The Array fixture's old source comment predicting JS/interpreter success is
stale: the actual new-target observations reject in all three lanes. One unsafe
main and all three IO.args lanes also pass with unassessed execution trust.
No input or artifact changed during this gate. Earlier execution observations
with eagerly computed trust metadata remain retained, not rewritten.

## Durable evidence

The [evidence directory](conformance-harness-evidence/README.md) retains the full
reference vectors and focused harness/native observations in a content-addressed
archive: 335 path identities, 227 objects, 2,258,668 compressed bytes, SHA-256
`b011854d9869ee6db4262668c0523a36ab84d253c13b901b57a39bc53ba42422`.
Every object was verified after archiving and every original input was checked
for changes. The separate [candidate execution report](selected-js-execution.md)
records actual candidate03 gaps and its preserved permission failure.

A subsequent broader maintained harness suite passed 112 of 114 tests; its two
failures were old inventory constants. The targeted correction binds the new
pin and 1,498/1,497 total/excluded counts, 1,001 positive/497 negative fixtures,
11 support sources and the new 68-file effects inventory. Only those two tests
were rerun, and both pass; their follow-up logs are retained beside the archive.
The earlier failed suite and the original archive are unchanged.

## First complete candidate03 frontend comparison

The frozen reference and candidate03 vectors each contain all **2,996 parse and
check observations**. `compare-artifacts.mjs --strict-paths` pairs every row with
zero missing rows and rejects changed fixture or target-manifest identities.
Neither run changed inputs or artifacts. The comparison is retained at
`selfhost/build/phase8/candidate-frontend-03/reference-comparison.json`.

There are **743 exact observation differences: 543 check and 200 parse**. This
unit includes diagnostic text, paths, phase and trust metadata, so it is not a
count of unsafe type acceptances. Candidate03's strict check rows comprise
**995 pass, 501 fail and 2 timeout**. It establishes type acceptance for
**991/1,001 positive fixtures**, and positive parse succeeds on **999/1,001**.
Only **3/11 proof-trust fixtures** match the complete strict oracle.

Seven negative fixtures are additionally type accepted beyond the reference's
four known deferred compile failures: `check/do_header_quantity_span`,
`check/do_header_typed`, `comptime/later_def`, `import/alias_shadow`,
`import/alias_twice`, `import/shadow_base` and `parse/type_arg_parens` (all `.bend`).
These are semantic gaps requiring fixes; they are not waived as formatting
differences. The two request timeouts are `check/string_literal_descends.bend`
and `halt/literal_descent_linear.bend`. A positive acceptance can also be
followed by an erroneous later refusal: `check/name_owned_def.bend` type-checks
but candidate03 rejects its reserved compiler name during compilation.

This vector predates the subsequent fixes. It remains an immutable migration
baseline and makes no claim about final release conformance.
