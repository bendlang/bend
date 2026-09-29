# Phase16 checker diagnostic investigation

Wave1 is ready for independent integration review. It changes diagnostic content
and transport only; all55 targeted and12 boundary primitive observations agree
with pinned TypeScript. The55 strict corpus observations improve fromzero exact
to13 exact,42still nonexact. Strict upstream mismatches remain failures.

## Mechanism and source

`check_ctor_domain` previously projected an existing KChecked into its error
String; the ADT entry point rebuilt it using bad(String). The same issue existed
for foreign declarations and template arguments. Wave1 preserves the typed
result through those existing paths and uses the actual constructor name as its
checker environment. Wrong template argument types retain their original
expected/observed/context; only an unbound Var present in the caller context
gets the upstream captured-variable explanation.

DTrace carries an optional sixth error-only child for the existing
DDiagnostic.note field. Outer traces preserve it. A shared kind-check wrapper
adds the Many-binder explanation only when the failure's expected kind and
innermost term match the immediate check. Nested missing-name/type failures do
not get an outer note. The duplicate typeless pretty-printer helper is removed;
the upstream datatype suggestion is a note, not part of observed text.

Only `src/check/kernel.bend` and `src/diagnostic/trace.bend` change. Net source
cost:+14physical lines,+2121bytes,+4definitions,zero laws/types/modules. No host,
runtime,generated-code or pinned-TypeScript changes. Positive-path performance
is not measured locally; root owns the controlled final comparison.

Final isolated files are in `selfhost/build/phase16/checker-source-02/project`.
Their patches and before/after hashes are in that attempt's `manifest.json`.
Kernel SHA256:`2a0094f63971b698bc83170e74a33a4240b63351cc31bebe96a314dd564a0be4`.
Trace SHA256:`b678ddc1b171abea5cfcc67b4bbf294ed79128493b2bbdc29a24667f07cc35dd`.
Checked `checker-build-02` selected API:
`4eaf0a926db5ef73da7a1c14237b01dd1431323a75810224152ba6e5ca858bb0`;
its genuine checked parent:
`4edf83c4d85ce29d91c51d7faf24c71db3f5b616073128c31c6192435eb62063`.

## Retained experiments and gates

- `checker-source-01`/`checker-build-01`:checked,36maintained cases pass.
  `checker-focused-01`:55healthy observations,10exact45nonexact. The note
  payload omitted the renderer's required literal `Note: ` prefix. Preserved.
- `checker-source-02`/`checker-build-02`:correct that prefix and use the same
  kind-check wrapper for let binders as pinned TypeScript.36maintained cases
  pass with11inherited strict differences in that maintained selection.
- `checker-focused-02`:55healthy paired observations,13exact42nonexact; all
  primitive status/phase/checked/typeAccepted/trust/output observations agree.
- `checker-boundaries-01`:12healthy paired observations,all12declared oracles
  pass;6exact6nonexact source spans/snippets. Three positives cover legal Many
  binders,ordinary function binders and closed templates. Negative controls
  preserve first constructor field error, second-field context, bound datatype
  parameters, closed wrong-type templates,captured caller variables,genuinely
  missing names, and two nested failures that must not acquire an outer note.
- `checker-audit-01/report.json`:scope gates pass,including8no-note controls and
  1required-note control. This does not rename42strict corpus mismatches passes.

Execution used the maintained checked B1 equality workflow, one correctness
worker on CPU1 after root's timing grant. The design anticipatedCPU2; actual
config was corrected before execution. No timings overlap baseline. Plans and
selectors are `design/phase16/checker-diagnostics.*`,
`experiments/phase16/P16-checker-diagnostics.md`,and
`selfhost/tools/performance/phase16/checker-selection.json`. Reproduction tools
are the numbered checker-prepare scripts and checker-audit-01.py. Curated project
copies contain no historical Phase6 tool tree.

## Remaining causes and next investigation

Constructor failures now retain correct content and constructor definition, but
need generic constructor origin lookup from the span owner. Other changed
errors still need spans for variables,lambdas,reflexivity and compound terms.
All169span-related observations remain that owner's work; nine share note
content with this patch. The parser owner handles244parse-phase observations,
including computed matches,and is checking bare-family/invalid-plus syntax
identity at the frontend boundary.

Seven template/TODO legacy cases reveal a larger ordering boundary: host
specialization occurs after complete source checking and TODO refusal,whereas
TypeScript checks a fresh instance at the actual live call. The specialization
state stores only String, and sp_validate projects check_definition. A second
prospective wave will first preserve KChecked through that path,with explicit
precedence controls for earlier/later invalid definitions,TODO/live-law use,
valid imported calls,recursive growth and cycles. No second-wave source or
host change is included in this result.

## Wave2: retain specialization results (closed)

The initial prose count was off by one: the 22 legacy checker observations are
15 ADT, one foreign and six other cases. Five of the six lose specialization
error structure; the remaining axiom capture is hidden by TODO precedence.
The frozen selectors and all observed totals were correct.

`checker-source-03` replaces the specialization state's String error with the
existing KChecked result. The existing specialized_error String projection is
preserved, and specialized_diagnostic returns the existing DResult. The host
uses one shared locate/render helper for checker and specialization errors.
Original instance checks use check_definition_result; growth and active-cycle
errors retain the real template reference and caller context. No new diagnostic
type or formatter is introduced. Successful kind checks now construct their
kind once. Successful ADT declarations use the old tele_tip/check_ctors route;
context reconstruction repeats normalization only for an invalid tip.

`checker-build-03` is genuinely checked; all 36 maintained cases pass with the
same 11 inherited strict gaps. `checker-focused-03` retains 13 exact / 42 strict
differences across 55 observations, with zero lost exact matches. Exactly five
diagnostics change, all predicted. Four now have matching error content,
context and definition and require source spans. The cycle has the correct
content/context but exposes inherited global instance numbering: bounce~1
versus upstream's per-template bounce~0.

The paired `checker-order-baseline-01` and `checker-order-candidate-01` runs each
complete 12 healthy observations: three exact, nine strict differences. All
primitive observations agree, and six custom controls are unchanged. They
retain the unresolved source-check/instantiation order difference for a later
invalid definition and TODO versus a live template law. Earlier invalid
source, captured caller variables, unused TODOs and valid imported calls stay
at their original first errors or acceptance. This transport ablation does not
claim to fix chronology.

`checker-boundaries-02` reproduces all 12 wave1 boundary rows byte for byte.
`checker-host-controls-01` passes ten bounded mocks covering absent historical
capability, mismatched verdict identity, shared original load trace, legacy
origin API, failed provenance, rendering exceptions and optional export
detection. `checker-audit-02/report.json` binds and verifies these reports.

Source03's frozen four-file manifest and patches are under
`selfhost/build/phase16/checker-source-03`. Relative to Phase15, its three Bend
files cost +37 physical lines and +3,621 bytes, including wave1; the host costs
+5 lines and +363 bytes. KSpecialized's internal error payload is now KChecked;
consumers retain specialized_error/book projections, and the new host's optional
structured path preserves historical API fallback. Final source-range migration
and controlled performance measurement belong to root's integration.

Root independently integrated wave1 with the parser candidate and completed
all 2,996 observations: 459 to 364 exact differences, 95 new exact, zero lost
and zero unexpected changes. The 13 checker gains are included in that result;
82 are parser gains. All 1,001 positive, 482 validation-refusal and 11 trust
refusal outcomes remain. This is the parent's reported integration result,
not an additional run performed by this owner.

## Wave3: local checking order and generic identities (closed)

`checker-source-04` changes only three kernel functions beyond source03. Rewrite
motive checking now precedes endpoint comparison, as in pinned TypeScript, and
the same checked motive is reused. Generic constants use `definition~binder`;
opening an already installed binder name is rejected before replacement. This
removes a global binder ID from diagnostics and fixes a real acceptance bug:
`def first(~A: Type, ~A: Type, x: Nat)` was accepted when the duplicate parameter
was unused. Both pinned TypeScript and source04 now reject it. Separate owners
may still use the same binder name.

The frozen incremental patch and manifest are under
`selfhost/build/phase16/checker-source-04`; kernel SHA256 is
`0218e3e11f57a931d213f1fd7b5a69c58330990686b3cbe1d1b71d09309de880`.
This wave adds one physical line and 291 bytes, with no new definitions or laws.
The genuine checked `checker-build-04` passes all 36 maintained cases, retaining
11 inherited strict gaps. Selected API SHA256 is
`7cec85cd9e176af132a58b4af7ed0132229397bb6e8038ecee36072f2044565b`;
checked parent is
`8cd3d1046b5f0ba7b953fc8a335719de45a24d6ada239d4735098a462e207814`.

`checker-all-04` closes 84 deduplicated paired observations: all 84 primitive
results agree, 25 are exact and 59 remain strict differences. The original 55
corpus observations retain 13 exact matches and 42 strict differences. Exactly
three corpus diagnostics change: `error_window_rewrite_proof`,
`template_dup_binder` and `comptime/err_generic`. Their corrected content still
needs the span owner's source ranges. The 12 original boundary rows and 12
ordering rows are unchanged. Ten local controls improve primitive agreement
from nine to ten through the duplicate-unused rejection; three positive
controls remain accepted. The equal-looking nested-type witness attaches only
the innermost `+inner` note, without adding `+outer` or `+again`. A later range
migration should additionally compare nonzero source intervals for this note
predicate; absence of metadata must retain the current conservative behavior.
`checker-audit-03/report.json` binds the inputs and verifies these assertions.

## Measured limit of definition-level interleaving

Three prospective same-body controls were actually run in `checker-all-04`.
The decisive witness first calls `app(~(n => Nat.add(n, n)), 1n)`, then returns
`True{}` where `Nat` is required. TypeScript immediately checks `app~0` and
reports repeated consumption of its affine `x`. Our compiler reports the later
`Bool`/`Nat` error in `main`, because source checking finishes before template
materialization. Both compilers refuse the program, but their first errors are
different. The other controls retain the ordinary type error when it occurs
before the instance or when the earlier instance is valid.

Moving specialization between definition events cannot fix this measured
within-body order. It is therefore not being implemented as the next candidate.
Calling the existing specialization visitor earlier also fails the general
contract: that visitor traverses an instance body before the authoritative
checker validates it. Shared instance effects must occur in the normal
checker's term order, with its memo and active-instance state carried to the
next subterm. The exact design and cost tradeoffs are recorded separately in
`design/phase16/checker-chronology.md`; no chronology implementation or speed
claim is included in source04.

## Wave4: per-template instance numbering (closed, one exposed boundary)

`checker-source-05` removes the global serial field from KSpecState and counts
existing memo entries for the called template only on a new-instance miss.
Active entries count; memo hits retain their existing name. The separate fresh
variable-ID bound is untouched. This replaces one accessor with one counter
helper: +1 physical line, -47 bytes, no net definitions/types/laws and one fewer
state field. The genuine checked build again passes 36 maintained cases with
11 inherited strict gaps. The previous 84 rows are healthy and unchanged except
that the cycle's definition is now correctly `bounce~0`; they retain 25 exact
and 59 strict differences, with all primitive observations agreeing.

Twelve frozen naming controls run against source04 and source05. All primitive
outcomes agree. The cycle and the custom prior-other-template case now have the
right instance name, while the custom repeated-reference case exposes another
inherited bug: `bad~2` rather than `bad~1`. The six direct materialized-name
controls improve from two exact sets to five. The remaining repeated `Zero{}`
argument creates three instances instead of two. Existing `term_key` includes
Ref/ADT/Ctr lexer positions and globally allocated binder IDs, so equal closed
arguments at different source locations miss the memo. This boundary is not
renamed a pass. `checker-name-direct-03` is complete with pass=false.

Two earlier direct attempts are retained. `checker-name-direct-01` used raw
`f_parse` without module scoping and failed before recording a witness; the
corrected loader attempt `checker-name-direct-02` stopped at the newly exposed
repeat-key mismatch. The nonaborting third attempt records all six controls.
The next source-independent key experiment is frozen separately in
`design/phase16/checker-memo-identity.md`; it must preserve binder spellings,
quantities and meaningful numeric payloads, rather than weakening norm_exact.

## Wave5: scoped memo keys rejected by boundary controls

`checker-source-06` rebases bound identifiers while serializing a key and omits
known source-position IDs. It adds 31 lines, 1,715 bytes and four helpers, reusing
the existing KPName binding map. No type, normalizer or source term is changed.
Its genuine checked build passes 36 maintained cases with 11 inherited gaps.
Sixteen initial direct controls all match pinned materialized instance sets,
versus 7/16 before naming and 10/16 with numbering alone. Across those controls,
the candidate creates 28 instances instead of 34, exactly the reference count.
Repeated lambdas, references, ADTs and constructors share; meaningful names,
quantities and Nat/U32 values remain distinct. The first parallel-let fixture
was invalid upstream because its constructor value lacked an inferable type;
that setup failure is retained and its explicitly typed replacement is bound
in controls02.

The candidate is **not eligible for integration**. The 22 paired controls and
prior 84 observations preserve primitive outcomes but reveal a new first-error
regression: `comptime/err_grow_double` moves from `grow~9` to `grow~10`. All other
84 diagnostics are unchanged relative to source05. The shorter custom key has
changed when the existing 32,768 guard fires. Strict mismatch counts alone
would conceal this regression because that row already lacked its source span.

Two genuine checked probe builds expose existing key/specializer workers through
experimental host exports only. `checker-key-length-02` reconstructs each closed
argument with the implementation's actual substitution operations and proves
that its keys equal every stored memo entry before recording the first refused
one. At proposed instance 10, the same lambda containing 1,024 applications and
1,024 `inc` references has these key sizes:

| Encoding | UTF16 units | First refused proposed instance |
| --- | ---: | ---: |
| Pinned TypeScript JSON | 43,080 | 10 (`grow~9` caller) |
| Source05 raw custom key | 37,934 | 10 (`grow~9` caller) |
| Source06 scoped custom key | 31,774 | 11 (`grow~10` caller) |

`checker-key-shape-02` reads both local key formats back into the four measured
term constructors and reproduces the pinned key bytes exactly at every level
0–10: 22 exact projections. Thus this growth example differs in serialization,
not hidden normalization order. That read-only comparator is explicitly limited
to Var/Ref/App/Lam with the observed explicit Lone lambda quantity; it is not a
general compiler serializer.

Additional prospective Nat/U32 literal-versus-explicit-constructor controls
expose a more fundamental limit. The pinned compiler distinguishes `1` from its
explicit `U32{WCon{...}}` tree. Our lowered core loses that literal identity;
source06 merges the two, so only 17/18 expanded direct sets match. Nat retains
its dedicated LitNat tag and still distinguishes the spellings. Preserving the
upstream key and logical UTF16 length for all terms requires explicit literal
identity before lowering, and care with optional syntax fields; origin offsets,
removed-constructor fields and arbitrary cutoff padding are not substitutes.
Source06 and all counterexamples are retained, unselected. Source05's independent
per-template numbering correction remains eligible.

`checker-audit-05/report.json` binds these gates and records promotionEligible=false.
Two additional probe setup failures remain: reading the uncompleted upstream
caller's body after validation replaced it with a declaration, corrected by
capturing original definitions before validation; and Python's default recursion
limit during read-only key decoding, corrected in a fresh bounded decoder run.
The key experiment makes no runtime speed claim. The instance-count improvement
is useful evidence for a later representation change, not permission to weaken
the pinned correctness boundary.
