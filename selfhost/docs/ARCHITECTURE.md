# Compiler architecture

The typed compiler uses a first-order representation shared by the frontend,
checker, normalizer and emitters. The original single-file compiler remains
available as a historical regression baseline.

The current Phase23 compiler targets upstream
`018751270e800bc222a93dad7f257083ee53a5f7`, after Bend2 2.0.34. It retains the
Phase22 contextual frontend and load ABI2, reuses the existing graph evaluator
for shared-term conversion, and adds array atomics over the uniform runtime
representation. The [Phase23 report](../../implementation/phase23/upstream-graph-conversion.md)
records checked and derived identities, validation, controlled cost and promotion
status. The [Phase22 report](../../implementation/phase22/contextual-conformance.md)
retains the prior installed baseline. Kernel/device capability claims remain
separate from the architecture and tested frontend agreement. The final candidate03
image has3026/3026 exact main and196/196 exact broader frontend observations,
with independently validated compiler, fixture, host and reference identities;
see [frontend validation](../../implementation/phase23/frontend-validation.md).
Raw fixture verdicts and backend/kernel capability claims remain separate.

## Components

| Component | Responsibility | Source |
|---|---|---|
| Core terms | Binder IDs, substitutions, definitions, data declarations | `src/core/term.bend` |
| Book indexing | Exact-name lookup, filtering and final-definition selection | `src/core/index.bend` |
| Normalizer | Weak evaluation, memoized strong normalization, definitional equality | `src/core/normalize.bend`, `src/core/graph.bend` |
| Quantities | Affine-use accounting, erased/reusable demand | `src/check/quantity.bend` |
| Kernel | Dependent bidirectional checking and termination | `src/check/kernel.bend` |
| Frontend | Contextual parsing, lexical binding, desugaring, pattern compilation | `src/front/` |
| Loader | Canonical namespaces, import graph, foreign paths | `src/load/` |
| Diagnostics | Failed terms, expected/observed types, local context and available source spans | `src/diagnostic/` |
| JavaScript backend | Checked-term lowering, code emission, readback descriptors | `src/back/js/` |
| Native backend | Layouts, segments, closure/fork lowering, C emission | `src/back/native/` |
| Host JS runtime | Primitive representations and asynchronous effects | `src/runtime/js/` |
| Native runtime | Shared CPU/Metal/CUDA runtime and effect implementations | `src/runtime/native/` |
| Driver | End-to-end check/compile/run routing | `src/driver/` |

These components are implemented. Their measured compatibility is recorded
separately in the conformance report.

## Core representation

`KTerm` is a first-order datatype with three variants. Ordinary `KTerm` nodes
carry a tag, name, binder ID, quantity, children, removed-constructor names and
an optional source interval. `KLiteral` carries an explicit kind (`Nat`, `U32`,
`F32` or `String`), an unsigned numeric payload, decoded text and its interval.
Numeric kinds use empty text; String uses numeric zero and scalar text. F32 stores
its 32-bit representation, including the sign of zero. Character syntax uses a
`Chr` constructor around a compact U32 value. Literal values are never encoded
in a binder ID or quantity field.

`KLambda` carries the ordinary Lambda fields plus `quantityPresent`, replacing
the redundant tag field. This distinguishes an omitted quantity from an explicit
one. Structural rebuilding, freshening and substitution preserve it; strong
normalization and annotation's rebuilt Lambda output deliberately clear it.
Checking uses the flag when deciding whether a written reusable binder requests
promotion. Legacy ordinary `KTerm`/`Lam` values count as explicit quantities.
Semantic equality ignores this syntax fact, but template memo identity retains it. Exact cached-prefix comparison also retains quantity presence and all compact
literal payload fields. It compares syntax, so compact and equivalent expanded
constructor terms remain different prefixes. Source intervals retain their
separate host provenance contract. The [Phase19 correction](../../implementation/phase19/prefix-identity.md)
closes a demonstrated changed-proof acceptance through the public prefix API.

Template keys use the pinned lowered-term JSON shape, including binder names,
lexical indices, literal syntax identity and optional Lambda quantity. Source
ranges and incidental reference token IDs are excluded. The same JSON string
supplies memo identity and the 32768 UTF16-unit growth guard, with newline-separated
arguments; the independent instantiation-depth limit remains 64. This is not an
extra normalizer or checker. See the [canonical-key report](../../implementation/phase16/checker-canonical-memo-json.md).

## Local and annotation source locations

A raw `Local` owns its first binder's range. A typed local's generated `Ann`
owns the interval from the original body cursor to the returned, spaced RHS
cursor. These differ from the child term ranges when a binder or RHS is grouped,
or comments follow the RHS. Three existing parser workers forward the body
start to the sole annotation producer. Unindexed input keeps0/0.

`f_locate` preserves an already located term without recursively filling its
children. Generated children must therefore receive their own origin at their
producer. The [Phase21 report](../../implementation/phase21/group-range-release.md)
records the caught intermediate annotation-range loss and exact cursor controls.
Source ranges do not encode whether a group has completed. The contextual parser
carries that distinction explicitly: a completed body cannot re-enter the tuple
or continuation grammar merely because its outer syntax was parenthesized.

## Compilation flow

The ordinary host discovers canonical files while Bend owns import syntax,
namespace resolution and contextual parsing. Load ABI2 separates each module's
leading import header from its body. The host completes dependencies in source
order, then passes their declarations, the canonical namespace and the file's
aliases to the Bend body parser. A dependency failure stops traversal before a
later sibling is opened or the importing body is completed. Completed results
and the graph are reused within that request.

One contextual frontend owns lexical binding and semantic completion. Its cursor
carries the real environment and declaration-local fresh counter alongside the
module scope. Header parameters open in telescope order; a nested scope restores
the outer environment while retaining allocated IDs. Simultaneous local RHS
expressions resolve before their binders open. Where grammar needs both meanings,
a name retains its written variable shape and resolved value. Pattern validity
and group completion are decided before parsing the continuation that follows
them. There is no later scope pass with an empty environment to reconstruct those
choices.

The parser scope holds a constructor-only index using the existing book index
structure. Building it preserves the original first depth-first winner: earlier
definitions and constructor heads take precedence over later entries and children.
Ordinary same-name definitions never occupy constructor entries. Empty/partial
headers reuse the prior index; qualified complete datatypes publish their children
at the existing declaration boundary. Named misses retain the original payload.
Raw/local constructor-book consumers retain the recursive lookup.

Completion follows the pinned higher/lower demand stages. Higher visits eager
children and performs beta reduction, while lambda bodies, dependent codomains
and let tails remain deferred. Lower forces those deferred parts at the required
completion boundary. Headers and complete bodies have different forcing points;
an error in an earlier completed body must precede later declaration syntax.
Do blocks, rewrite motives, arrays and namespace operators use this same lexical
state and error order. Substitution preserves a located argument's origin; an
unlocated argument inherits the variable occurrence's origin except for the
negative-ID unbound-variable representation.

The host's `--checkup` command has a separate, pinned textual import scan. It
prepares Base once, visits matching import lines in textual order and checks each
module independently, continuing after errors. Each import is read before module
inspection so a missing file keeps the pinned IO diagnostic. This command's
continue-on-error behavior does not change ordinary dependency traversal.

The checker validates declaration types, quantities and recursive calls with all
signatures and ADTs visible; bodies become available at their final source event.
`KWorld` carries the authoritative source book, instance memo, fresh-ID state and
checked output. A live template use checks closed arguments, reserves its memo
entry, then checks the instance immediately through the same ordinary checker.
Subsequent children receive the returned world, and successful terms are rebuilt
from checked children. Original source bodies remain available for conversion.

The old recursive specialization visitor is removed. Completed instances publish
before their callers in the checked-output list; output assembly reverses this
accumulator without checking terms again. Generic success restores the private
source-book view while retaining memo, freshness and completed output; failure
keeps the actual failing world. The stable public `KChecked` payload retains four
fields, while internal `KChecking` carries the world and consumed-argument count.

Program completion reports TODO/open-law incompleteness after actual checking.
The result already contains materialized output. Prefix APIs replay source events
because the existing source-only cache cannot restore the memo and checked output;
that Phase19 checker change did not alter the host/cache ABI. The Phase22 loader
ABI change is separate. Deferred fresh-ID initialization includes the
entire saved owner body at its first mint, including later siblings not yet
visited. The [live-checker report](../../implementation/phase19/instance-live-checking.md)
records the order, recursion, scope and demand controls. The normalizer supplies
definitional equality and the interpreter's result.

Strong normalization uses explicit work frames and a persistent heap of lazy
cells. Repeated uses of an argument share its evaluation; materialization returns
the ordinary core term format. Binder freshening also uses explicit frames so
large generated terms do not depend on the host JavaScript call-stack depth.

Phase23 conversion carries the same `GHeap`, `GState` and `g_wnf` evaluator
through its existing comparison worklist. A `KNormShare` continuation copies
the forced left cell value into the right cell only after all equality
obligations succeed. Repeated edges then reach the same child cells instead of
expanding a logical tree. Directional `LE` comparisons never establish symmetric
sharing; failed alternatives discard unfinished sharing continuations. Completed
proofs and normalization results remain valid within that pass.

Conversion first compares with an empty definition book, keeping definitions
rigid, then retries with the actual book only on failure. Each pass owns a
separate heap. Exact comparison still precedes the fresh-identifier scan.
Telescope domains share through heap cells; deferred codomains remain outside
those cells until their binder is opened and substituted. This adds no global
cache, alternate checker or new term representation. Ordinary weak-head queries
retain their prior evaluator and public interface. The
[graph-conversion report](../../implementation/phase23/graph-conversion.md)
records depth64 equality/inequality, capture, failed-alternative and LE/EQ controls;
finite controls are not a general complexity or soundness proof.

Weak evaluation retains its original initial `Absent` fallback allocation.
Reusing the input term in that otherwise unreachable slot passed finite semantic
controls but regressed the 4MiB long-string check under a matched request history.
The Phase12 experiment restores the allocation rather than raising the limit.
Delayed-spine reconstruction also remains unpromoted: its small diagnostic gain
did not justify another internal protocol.

Phase14 expresses the six `norm_eval_node` tag choices as Boolean-parameter
workers. Each worker executes its original selected body or tests the next tag;
`App`, `Ann`, `Let`, `Ref`, `Min`, `Rwt` and the final fallback keep their order.
The pinned bootstrap compiler emits direct conditionals/calls for these workers,
avoiding intermediate choice closures and trampoline messages. Unlike the index
workers, this chain is not emitted as one mutually recursive loop. Its finite
call-depth cost is covered by fresh and saved-history controls; it is not a
general stack-safety guarantee. The nested rewrite-proof choice and initial
normalizer fallback stay unchanged. No new JavaScript transformation is needed.

Emission selects reachable definitions while retaining the complete indexed book
as its type context. Annotation reconstructs the checked types needed for erasure,
runtime layouts, foreign marshalling and readback. Backend-specific intrinsic
stops must be shared by reachability, annotation and layout validation. Pruning
the type context itself would lose constructors and dependent type definitions.

The JavaScript backend emits functions and trampolined applications against the
JavaScript runtime. The native backend lowers to segments, closures and fork
continuations, then emits C against the retained compatible CPU/Metal/CUDA runtime.
Foreign CID/FID scanning is shared in Bend. Reachable effects determine the
foreign-source namespace; the full book resolves identifiers. The host provides
file bytes and backend-compatible Base effects. Internal closure dispatch uses
a separate C identifier namespace so user `Clo.apply` cannot collide. Its general
boxed representation differs from upstream's flat-layout optimizations; runtime
and performance equivalence are distinct validation questions.

## Uniform arrays and shared ownership

Native arrays retain one64-bit slot per element. `Array.fork` and `Array.join`
use checked Base bodies and the existing reference-counted redirect handles.
Consumers follow a handle with `term_peek`; its redirect count is read through
the existing atomic-half `rfc_view`. A shared block is released through
`term_drop`, while an unshared block whose children moved is freed shallowly.
This is the existing ownership representation, not a packed-array migration.

Matching a shared leaf retains its element before dropping the handle. Shared
node construction and splitting retain each copied element before releasing the
source handle; unshared paths move the elements. A clone returns the original
array first and a separate copy second, preserving alias behavior when another
forked handle still exists. Candidate02's reversed clone pair was exposed by an
execution counterexample and corrected in candidate03; the failed result remains
recorded in the [ownership review](../../implementation/phase23/native-ownership-review.json).

The nine Base atomic operations update the low32-bit payload through a native
CAS loop, wrap indices with the ordinary array indexing rule, and return the
previous value. `fadd` rounds through F32. JavaScript performs one synchronous
read/modify/write operation under its existing sequential execution model.
Intrinsic recognition retains the existing Base-provenance checks. These rules
do not establish safety for concurrent ordinary structural reads against atomic
writes, nor ThreadSanitizer or GPU/device validation. The Phase23 backend gates
record actual executions and their platform limits separately.

## Checker bounds and literals

Imported law fills are resolved after dependencies load. For an omitted return
type under a declared import alias, the parser temporarily stores `ImportLaw`
with the original parameter telescope. The existing graph alias traversal looks
up the latest canonical declaration and requires an unfilled, non-native law,
plain binder names and a compatible template count. The fill retains that law's
type, name and unsafe flag. A temporary `ImportFill` definition kind protects its
canonical signature while module completion qualifies declaration names;
the pass eliminates the marker before returning the checker input. This remains
a dependency-aware graph operation after contextual body parsing. ABI2 does not
move law-fill authorization into the host or let a supplied completed result
establish that authorization by itself.

An import alias is not a namespace for fresh annotated definitions. Such a
declaration is a parse error. Loaded declaration events also supply proof-report
order; final-definition lookup supplies dependency bodies. The host passes this
event book to the Bend reporter instead of the specialized unique book. Checking
and materialization still use their existing books. Template trust is assessed
from source declarations, matching the pinned upstream controls; specialization
must not accidentally make an unsafe source declaration appear trusted.

Parser-owned source intervals follow term and binder occurrences through
elaboration, freshening and specialization. Coordinates are UTF16 code units in
disjoint request-local module intervals; zero/zero means absent. Each interval
reserves its EOF position, Base starts at one, and canonical physical aliases
share an interval. Source ownership comes from these ranges and immutable module
snapshots rather than searching for matching term text or synthesized names.

Checker and parser diagnostics share caret rendering. Tabs retain their alignment,
and a multiline span is clipped to its first displayed line. Empty spans receive
one caret. Checker snippets blank leading import lines for upstream's module
view while keeping raw coordinates; parser/import errors retain raw source text.
Rendered names use the owning file's namespace and aliases without renaming the
semantic book or replacing text inside literal strings. Rejection rendering uses
the selected error and recorded source ownership; it does not rerun a separate
raw parser to recover scope. Unknown provenance retains fallback text. Exact
formatting and first-error agreement are separate conformance obligations.

Checking keeps two independent persistent books: one supplies all declared
signatures and chronological bodies, while the other records only prior events
for duplicate and law-fill checks. Both start from an immutable empty index with
the maximum binder ID of the complete input. This shares a bound, not declaration
visibility. Each subsequent index update remains independent. Constructor-name
search skips internal BookCache metadata. Prefix checking replays full source
events; `exact_prefix` remains a separate syntax-identity helper.

Conversion tries exact equality before finding fresh binder IDs. Lambda checking
rechecks a domain's kind only for the quantity promotion that requires it; public
book checking validates signatures first. Termination descent remembers its first
failed field comparison and skips that already-tested child during subterm search.

Compact literals remain leaves through parsing, scoping, freshening and normal
checking. Matching, conversion and descent expose constructor structure only when
needed: one Zero/Succ layer for Nat, one SNil/SCon layer for String, or a bounded
32-bit Word for U32/F32. Literal patterns expand where constructor-pattern
compilation requires them. The compact checking/annotation fast path requires the
matching, unremoved native Base datatype; custom definitions retain ordinary
constructor checking. Both emitters, pretty-printing and readback understand the
compact form. Invalid scalar string encodings retain the constructor fallback.

The source numeric payload is U32; this does not restrict wider runtime Nat
values. Overflowing Nat construction retains its dynamic path. The previous
`LitNat` quantity-field encoding and eager ordinary String trees are superseded
by `KLiteral`. The [compact-literal report](../../implementation/phase16/checker-compact-literals.md)
records the demand boundaries, retained failed experiments and scoped correctness
evidence; it does not establish support for arbitrarily large inputs.

## Avoiding repeated work

Loader alias ambiguity uses explicit conditional evaluation before searching
declarations. A successful membership search returns immediately; no symbol table
or alias-resolution rule is changed. Boolean conjunction/disjunction alone does
not defer these searches in the current pipeline.

Source offload resolution likewise uses explicit branches: it searches the book
only for an offload-marked reference whose local binding has not already selected
the refusal. Ordinary references retain their later resolution path. This
preserves results and error order on finite well-formed compiler data; irrelevant
lookups on malformed raw host objects are outside that equivalence boundary.

Match checking fills a constructor telescope once and shares it between the
arm's context and goal. The missing-constructor refusal precedes that work, and
arm/default checking and usage merging retain their order. This shares one local
immutable value rather than introducing a cache or changing declaration visibility.

The persistent definition index uses Boolean-parameter branch workers for lookup.
Pinned upstream lowers their mutual tail recursion to a loop, avoiding branch
closure allocation. The trie, hashes, collision buckets and source event order
remain the same. This is a property of the checked release's upstream emission,
not a claim that every self-emitted compiler has the same machine-level behavior.

Backend layout validation can use a checked constructor's normalized ADT to find
its telescope locally. Unknown shapes retain the general search. Native Nat
Zero/Succ layers traverse their fields directly instead of repeatedly recognizing
an entire literal suffix. Dynamic-tail dependencies and open-Array refusals remain
part of that traversal. See the [Phase10 report](../../implementation/phase10/repeated_work.md)
for the checked-book invariants, controls and remaining emitted-code size limits.

The JS constructor emitter also uses that existing typed local lookup at its
three nonliteral field-traversal sites. Checked books give constructors unique
owners; unknown types or missing local constructors retain the general search.
It shares the literal text already computed at constructor entry instead of
recognizing the same tree again. The first recognition and nonliteral-branch
demand stay in their original positions. No new cache or term representation is
introduced. Repeated normalization of a nonliteral constructor's type remains;
reflective host objects and deliberately ambiguous unchecked constructor books
are outside this checked-source equivalence contract. The
[Phase12 investigation](../../implementation/phase12/known_structure.md) records
the ablations, exact emission controls and operation counts.

After typed erasure, native lowering combines an open run of unary `Succ` nodes
into private `NNatAdd`/`NNatSum` terms. User-owned constructors have already been
renamed; closed literals keep their existing path. One continuation evaluates
the dynamic tail once, then computes a checked first increment followed by the
remaining offset. Preserving that first check retains U64 wrapping/error behavior
even for malformed foreign values. A passing first check establishes the 48-bit
Nat cap, and a U32 run-count bound makes the remaining addition safe in U64.
Zero count preserves the tail, and reaching the count cap compacts the rest
separately. Reference discovery still traverses that tail. These mechanisms and
their retained failures are recorded in the
[Phase11 report](../../implementation/phase11/known_work.md).

The [Phase13 structured-rewriter experiment](../../implementation/phase13/structured_rewriter.md)
finds that replacing branch closures with named workers alone adds capture-array
work without removing trampoline dispatches. Selector fusion instead removes
intermediate tag-selection closures and dispatches while retaining selected body
arrows and their execution order. The six-owner prototype passes bounded
semantic and saved-history controls and reduces full-source checking time by
10.6%; it remains uninstalled because its maintained helper would grow by 7 KB.
Constants stay in their original scopes. Neither these finite controls nor
retaining body arrows establishes general stack safety.

## Compiler source assembly

The compiler implementation modules use one shared internal namespace, with
component-specific prefixes. `tools/assemble.mjs` gathers their type declarations,
forward law signatures, and definitions into a deterministic bootstrap input.
It performs no user-program parsing or compilation. This ordering permits the
mutually recursive compiler routines to refer to declared signatures, while
preserving Bend's sequential declaration rules. The generated file has a source
map back to individual modules. It is not the primary editable source.

The old `src/compiler.bend` is not linked into this typed implementation: its
surface AST lacks quantities and dependent types. It remains a bootstrap aid
and regression baseline, clearly separate from the typed compiler.

The frontend and loader form a standalone component with the core term, index,
normalization, graph and pretty-printing modules plus diagnostic model/rendering.
They share source snippets with checker diagnostics, but require no checker,
trace, producer or diagnostic-frontend module. Shared book operations belong in
core: `index_remove` supplies the same order-preserving name filter to final
definition selection and checker specialization. The unchanged
`tests/frontend/trace-component.mjs` rebuilds26 modules on Phase22 and validates
the retained ordinary, traced and seeded text-source routes. Its independently
checked component API is distinct from the release API. Completed-source and
actual-host controls are linked from the Phase22 report.

Private `FRawResult` retains the selected Error term while declarations and
imports are parsed. Completion renders explicit expectation metadata against the
original source into `FResult{book,error:String,imports}`. Under ABI2 its successful
book contains contextually completed terms; it is not the old raw parser stage
despite retaining the result's field names. Standalone raw `f_parse` entry points
and the old raw-loader replay route are retired. Syntax expectations and
constructor-freshness failures render once on rejection; unknown positions keep
fallback text. Successful parsing does not scan source to render diagnostics.
The frontend shares the diagnostic model and renderer while remaining independent
of the checker and diagnostic trace/producer modules.
The older [Phase5 newline-in-string counterexample](../../implementation/phase5/static-counterexample.md)
is retained as historical evidence of why token cursors and source intervals
must agree. Current source cursors and actual ranges are validated separately;
legacy fallback text is not evidence of exact diagnostic agreement.

An embedded parser Error can survive inside a declaration until graph validation.
Only after that validation rejects, the loader can recover the same Error in the
same traversal order and use its declaration index plus Loaded event counts to
find the original source. It verifies the selected error identity and unique
canonical source before rendering. Accepted books are not scanned again, and
unknown provenance retains the existing diagnostic. Formatting an existing
parser error does not establish that its grammar or first-error choice agrees
with the reference compiler.

Phase15 import nodes retain the original path token's line and code-point
column. Bend validates plain local path segments before IO resolution and renders
missing-import and cycle messages with the shared UTF-16 snippet formatter. The
ordinary host walks canonical filesystem paths, distinguishes active from completed
visits, and stops active reentry at the closing import edge. Completed physical
aliases remain reusable. Earlier dependency failures precede a later module-body
error; existing compiler phases and unrelated IO failures keep their categories.
The supplied-source Bend graph loader retains its own graph and cycle validation.
Hub/package fetching remains outside the ordinary host's supported scope.

Phase15 ordinary-list `lookup` uses two Boolean-parameter workers for cache-marker
and name decisions. The cache marker wins before ordinary name lookup, and lists
remain first-match-wins. Pinned upstream emits a three-state mutual-tail loop for
each generated entry; no new lookup representation or JavaScript rewrite is added.
The indexed lookup implementation and malformed-data demand guards are unchanged.

## Host representation boundary

Self-emitted libraries use positional constructor fields. The host accesses
these through lazy, read-only named views and unwraps a view when passing it
back to another compiler phase. This preserves graph sharing between phases
without copying entire compiler books. Newly supplied host values are encoded
iteratively. See [the ABI adapter and validation](COMPILER-ABI.md).

The Phase22 compiler advertises `compiler_term_abi() == 1` for the three core
variants, `compiler_span_abi() == 3` for source intervals,
`compiler_load_abi() == 2` for completed-source loading, and
`compiler_check_result_abi() == 2` for program completion. Historical Phase21
uses load ABI1. Term ABI1 requires span ABI3. The host validates literal payloads,
scalar String text, Lambda presence booleans and ownership/range bounds on
source-aware discovery results and caches. The host requires load ABI2
and its complete entry-point set; it has no fallback to the retired raw route.
Unknown capabilities or missing required entry points are errors. Historical
artifacts retain their matching frozen hosts. Direct low-level AST entry points
and completed-source handoffs retain their trusted-input contract.

The current checked Base cache is version6 with `termAbi:1` and `spanAbi:3`. Its
identity binds compiler and Base content hashes, the canonical Base path, exact
source interval, serialized-book hash and `validatedBy:check_book`. Persistent
reuse also binds the API path and exact cache bytes. The development workflow
checks cache identities and understands versions2,4 and6; the ordinary host also
selects and validates the expected layout from the compiler capabilities. Older
span-only version4 and ordinary version2 routes support matching historical
artifacts. Prototype literal-only version5 caches are not the installed contract.

## Trust boundary

A successful parse is not a successful type check. The driver must reject a
checker failure before emitting executable code. Proof/type negative tests
cannot pass merely because a parser does not implement their syntax. Bootstrap
upstream APIs are used only to build/test the port; normal operation must not
fall back to the TypeScript compiler.

Copied upstream C/Metal/CUDA runtime code is a runtime dependency, not a
substitute for porting code-generation logic. Target hardware limitations must
be reported as untested capabilities, not passing GPU tests.

## Invocation work reuse

Source discovery constructs `FCompletedSource` through `f_source_completed` after
contextual completion. Its historically named `parsed` field holds that completed
`FResult`; `FCompletion.parsed` has the same stage contract. The graph loader and
seed paths consume it without repeating body parsing or reconstructing lexical
scope. `FSource` still supplies text to this contextual route. It does not select
a second raw parser, and `FParsedSource`/`f_source_parsed` are retired.

This is an immutable, trusted handoff inside one request, not a persistent
unchecked AST cache or authentication of arbitrary host-supplied IR. Dependency
resolution, canonical imported-law eligibility, module qualification and ordinary
checking retain their owners. The persistent Base-cache trust boundary remains
separate.

The trace-aware loader returns `FLoadTrace` with actual module order and
per-module declaration-event counts. All public provenance routes use this same
alignment; they do not reparse source to reconstruct ownership. Rejection
reporting reuses that trace and resolves stored occurrence ranges against the
request's immutable source intervals. Historical unlocated-input replay controls
remain evidence for their frozen APIs, not a reason to reintroduce raw parsing
into ABI2.

One chronological event checker returns the verdict and original structured
failure together. `check_book` and `check_from_exact_prefix` remain String APIs
by projecting its error; their detailed compatibility APIs retain the same
open-law completion contract. Current prefix entry points replay the full source
events through that checker because source alone cannot restore its live memo,
freshness and checked output. `exact_prefix` remains a separately callable syntax
identity helper; it does not authorize suffix-only checking in the current API.
The host's validated Base cache is a separate boundary.

For checker-result ABI2, `check_program_diagnostic` uses the live checker and
final source TODO count, returning the already-materialized book in `DResult`.
The host consumes one verdict and does not run a second specialization traversal.
Historical checker-result ABI1 supplied a structured ordinary-check result;
older artifacts used guarded replay whose error had to match the original
verdict. Those contracts are separate from the new loader ABI. Source lookup and
rendering cannot accept a rejected term. The trace belongs to one request and is not a stored verdict or
replacement for checking.

Final-definition selection for TODO reporting, interpretation and specialization
retains the last declaration of each name in reverse event order. Short lists
use the original filter. Lists of at least 256 events use the existing immutable
exact-name trie as a local seen-name set, avoiding repeated filtering of all
earlier definitions. Initial accumulator entries whose names were not replaced
keep their original order and duplicates. Private marker values distinguish an
empty name from an unsuccessful lookup; exact buckets handle hash collisions.
A nonthrowing name scan sends malformed raw JavaScript UTF-16 input back through
the original filter, preserving its comparison demand and error order.

After specialization, the JS host prepares one Bend `book_context`, carrying
an exact-name index and the book's fresh-binder bound. Annotation, runtime-layout
validation and emission retain that full context while selecting live output
definitions separately. An already prepared head `BookCache` is reused instead
of nested. Changed books require newly prepared contexts.

For a reference- or variable-headed application spine, annotation infers the
head type once and threads the dependent result type through the arguments.
The original `Ann` structure is preserved, and other application heads retain
the general path. Native erasure similarly reuses an unchanged normalized
telescope within each step. Its annotation-context merge builds one exact-name
index for ordinary lists; lists containing any `BookCache` marker retain legacy
lookup so cache boundaries and duplicate shadowing keep their meaning.

Constructor checking and annotation also recognize telescope tails that are
structurally unchanged by substitution. `core_subst_stable` excludes variables
and beta-reducible applications, recursively checks children, and admits only
canonical neutral applications. A successful fact is reused through the literal
`All` suffix; reaching another head returns to ordinary normalization. A failed
fact uses the original traversal without repeatedly scanning dependent suffixes.
The first argument is checked before the fact scan, preserving diagnostic demand
order. This is a local fact about immutable typed terms, never a cache shared
between books or requests. See the [telescope report](../../implementation/phase4/analysis-telescopes.md)
for the invariant, malformed-input boundary and exact controls.

The JS backend's structurally proven choice calls and record-projection workers
are described in [the backend guide](../src/back/js/README.md). They change
execution of generated Bend code, not checker rules or source-language meaning.
The [phase 1 report](../../implementation/phase1/report.md) identifies the
artifacts and measurements that validate those changes.

## Native compiler host

The [experimental graph host](../tools/performance/rapid/native-graph.md) passes
raw module text and explicit foreign assets through a bounded transport to a
Bend entry point. The Bend loader resolves imports and performs parsing,
checking, specialization, reachability, annotation and emission. The host only
handles filesystem identity, process execution and guarded output publication;
it does not parse imports or fall back to TypeScript compiler routines.

This entry currently emits JavaScript. Running the compiler as a native
executable is separate from validating the compiler's native backend or proving
a native self-hosting fixed point. Explicit manifests also differ from the
ordinary JS host's automatic file discovery. The phase 2 report preserves those
scope differences and checks output bytes against the same-source JS entry.

Long self-emission proofs freeze the source, compiler, Base, runtime and consumed
host helpers. Their identities are checked before and after every stage.
Targeted differential attempts retain their own harness and input identities,
and cannot turn a selected pass into a whole-suite conformance claim.

## Validation processes

The development `equality` profile is a compatibility name for an explicit
checked-B1 derivative. Version6 binds the new Base equality dependency chain,
including guarded `String.order` and `Pair.snd` bodies. Runtime identity and the
`String.eq` body jointly distinguish old and new profiles; unknown bodies are
refused. It retains version5 native string equality and literal-choice lowering,
includes the native choice helper, and replaces eligible returned literal
branch closures with scoped blocks. Each branch must be one return without nested
call work; a terminal generated call may have only call-free arguments. Other
branches keep their original closure boundary. This restriction retains boundaries
around non-tail recursion that the wider rejected trial moved into larger frames.
Eligible terminal generated calls become ordinary messages
for the unchanged trampoline. The original runtime and public forcing exports
remain exact; Unit bindings, argument order and bounded tail stack are preserved.
Unknown branch bodies retain the prior path, while unsupported lexical features
and protected-name rebinding are refused. The transform is always behind the
reviewed runtime/profile/export guards, not a standalone arbitrary-JS optimizer.
Historical versions1/2/3/4/5 retain exact replay; the
[profile review](../../implementation/phase23/profile-review.md) records the
new dependency guards and unchanged transformation policy. Private unforced message shape,
reflection and mutated host prototypes are outside the contract. This host-image
derivative does not change emitted user-JS behavior or establish a new self-emitted
fixed point. See the [workflow](../../docs/PHASE5_DEVELOPMENT.md).

The [private compiler image](../tools/private-compiler/README.md) specializes a
completed checked self-emitted compiler for a dedicated process. Static saturated
calls use positional workers; reviewed scalar operations and immutable record
projections avoid generic runtime work. Dynamic, partial and overapplied calls
retain their original paths. A runtime fingerprint and generated-body checks
guard these assumptions. Ordinary emitted libraries keep the public runtime ABI.

Its interface accepts only file paths and parse/check/compile/library modes.
Functions, graphs and callbacks cannot cross that interface, and compilation
does not execute foreign source. Finite batches reuse a verified image but create
fresh source graphs, enforce per-request external deadlines, and defer output
publication until their worker's input and artifact identities are revalidated.
An incomplete self-host proof can only produce an explicitly experimental image.

The conformance runner supports isolated requests and explicitly declared
persistent parse/check sessions. A persistent session retains the compiler
module and validated Base data but creates a fresh source graph and context for
each request. Bounded transport, request deadlines, process-group termination,
worker recycling and recorded session prefixes preserve failure isolation and
replay. Program execution lanes continue to use isolated processes.

Native build caching is separate from compiler checking: it reuses a binary
only for matching checked C, preprocessed headers, compiler identity and build
settings. It assumes a stable host linker and libraries. See the
[phase 3 workflow](../../docs/PHASE3_DEVELOPMENT.md) for commands and the
[phase 3 report](../../implementation/phase3/report.md) for measured benefits,
rejected experiments and remaining validation limits.

## Parser diagnostics and session-local Base decoding

Parser rejection sites can carry structured expected-token information and a
source position through private `FRawResult` values containing an `Error`-tagged
core term. The public
frontend result retains its fields, with the completed-stage meaning declared by
load ABI2. After an error is selected, the loader
can locate that same embedded error and its unique source owner to render a
location once. Existing graph-error priority and definition traversal order
remain authoritative. Accepted books do not incur this error-only traversal.
Faithful formatting does not repair a different parse decision. The release's
zero differences on the frozen frontend corpus and selected adversarial controls
are finite evidence; new diagnostic or phase differences remain failures.

A persistent inspector owns one trusted API and one immutable decoded Base
entry. Before reuse it binds the canonical API path and content digest, reads
and hashes the exact cache bytes, and verifies the expected compiler/Base/cache
identity tuple. Misses clear the prior entry; malformed or changed data follows
normal validation. The same buffer is hashed and decoded on a miss, and the
validated graph is frozen iteratively. Each request still builds its own source
graph. The public single-request inspector and execution lanes do not share this
private memo. See [the implementation and adversarial gates](../../implementation/phase5/persistent-base-decoding.md).


Phase17's frontend `f_find` retains its separate named-`Missing` and first-match
contract. A single Boolean-parameter worker expresses misses as mutual tail
calls; the original emitter lowers these to a direct loop. This removes per-miss
trampoline allocations without changing name equality, tail demand, book
representation or the maintained generated-code transformation. See the
[lookup report](../../implementation/phase17/find-worker.md).

## Declaration grammar checkpoints (Phase20)

`front/declarations.bend` uses the existing structured error owner for a pending
`@unsafe` that is not followed by `def`. The datatype constructor loop admits
name heads until the pinned `def`/`type`/`law` boundary; it no longer relies on
indentation or immediate opening-brace lookahead. One header worker preserves
name→alias→duplicate→brace validation order, then reuses the existing telescope.
`f_space` skips whitespace/comments at datatype boundaries, preserving semicolons
for the correct error; the loop exits through `f_top` on its already-spaced cursor.
The general `f_skip`/`f_tops` behavior remains separate.

The two existing match workers require a first term before consuming a colon or
comma. `List.is_empty` examines the accumulator tag in constant time. Later
optional separators retain their prior/pinned semantics. No contextual cursor,
new result type, semantic state or host work is introduced. The independent
[review](../../implementation/phase20/declaration-checkpoints-review.md) retains
the rejected intermediate semicolon behavior; the
[release report](../../implementation/phase20/declaration-checkpoints-release.md)
binds the installed one-file correction and its execution/CLI/cost gates.


## Phase24 lookup and emission invariants

The parser's existing contextual index can prove a local declaration absent.
`f_decl_local` maps the queried name through exactly the current alias/namespace
mapping used to publish local headers. A miss returns the original named Missing
sentinel; a hit runs the original first-event local scan. The index's prior-event
winner is not substituted for that scan, because duplicate prior headers can
select a different full definition. Temporary self/type headers only add possible
hits. No extra index, cache or scope field is introduced.

`has_name` passes each head comparison to a Boolean worker. The bootstrap's
existing tail-cycle lowering compiles this pair to a loop, preserving first-hit
short circuit while removing per-miss branch closures. It uses the same String.eq
contract and does not inspect a matched tail.

The shared emission ownership check rejects foreign definitions whose exact name
also names a constructor, after the existing reserved-name check and before
reachability. Constructor lookup is demanded only for foreign definitions. Native
function IDs reuse the existing Unicode-scalar encoding used for constructor
identity; MAIN_FID goes through that same function. This prevents punctuation and
case normalization from merging distinct functions. Runtime-reserved IDs retain
their existing names. See the [Phase24 report](../../implementation/phase24/profile-and-coverage.md)
for finite validation scope and unchanged representation counts.
