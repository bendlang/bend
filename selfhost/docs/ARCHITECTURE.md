# Compiler architecture

The typed compiler uses a first-order representation shared by the frontend,
checker, normalizer and emitters. The original single-file compiler remains
available as a historical regression baseline.

## Components

| Component | Responsibility | Source |
|---|---|---|
| Core terms | Binder IDs, substitutions, definitions, data declarations | `src/core/term.bend` |
| Book indexing | Exact-name lookup, filtering and final-definition selection | `src/core/index.bend` |
| Normalizer | Weak evaluation, memoized strong normalization, definitional equality | `src/core/normalize.bend`, `src/core/graph.bend` |
| Quantities | Affine-use accounting, erased/reusable demand | `src/check/quantity.bend` |
| Kernel | Dependent bidirectional checking and termination | `src/check/kernel.bend` |
| Frontend | Lexing, syntax, desugaring, pattern compilation | `src/front/` |
| Loader | Canonical namespaces, import graph, foreign paths | `src/load/` |
| Diagnostics | Failed terms, expected/observed types, local context and available source spans | `src/diagnostic/` |
| JavaScript backend | Checked-term lowering, code emission, readback descriptors | `src/back/js/` |
| Native backend | Layouts, segments, closure/fork lowering, C emission | `src/back/native/` |
| Host JS runtime | Primitive representations and asynchronous effects | `src/runtime/js/` |
| Native runtime | Shared CPU/Metal/CUDA runtime and effect implementations | `src/runtime/native/` |
| Driver | End-to-end check/compile/run routing | `src/driver/` |

These components are implemented. Their measured compatibility is recorded
separately in the conformance report.

## Compilation flow

The loader parses the source graph, resolves imports and aliases, elaborates
surface syntax, and gives binders distinct IDs. The checker validates declaration
order, types, quantities and recursive calls before specialization creates live
template instances. The normalizer also supplies definitional equality and the
interpreter's result.

Strong normalization uses explicit work frames and a persistent heap of lazy
cells. Repeated uses of an argument share its evaluation; materialization returns
the ordinary core term format. Weak evaluation and conversion retain the kernel's
existing interface. Binder freshening also uses explicit frames so large generated
terms do not depend on the host JavaScript call-stack depth.

Emission selects reachable definitions while retaining the complete indexed book
as its type context. Annotation reconstructs the checked types needed for erasure,
runtime layouts, foreign marshalling and readback. Backend-specific intrinsic
stops must be shared by reachability, annotation and layout validation. Pruning
the type context itself would lose constructors and dependent type definitions.

The JavaScript backend emits functions and trampolined applications against the
JavaScript runtime. The native backend lowers to segments, closures and fork
continuations, then emits C against the pinned CPU/Metal/CUDA runtime. Its general
boxed representation differs from upstream's flat-layout optimizations; runtime
and performance equivalence are distinct validation questions.

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
normalization and graph modules. They do not require the checker or diagnostic
renderer. Shared book operations belong in core: `index_remove` supplies the
same order-preserving name filter to final-definition selection and checker
specialization. `tests/frontend/trace-component.mjs` assembles and checks this
smaller component, then compares the ordinary, traced and seeded loader APIs.

Raw declaration and import parsing uses private `FRawResult`, whose error field
retains the selected Error term. At `f_parse(source)`, the original source and
explicit expectation metadata can produce a diagnostic; the public
`FResult{book,error:String,imports}` and loader boundary remain unchanged. This
transport preserves the parser's existing first-error choice. Explicit syntax
expectations and adjacent constructor-freshness failures render once on rejection;
unknown or inconsistent positions and unsupported Unicode cursors retain their
legacy text. Successful parsing does not scan source text to render diagnostics.
This frontend formatter has no dependency on the checker diagnostic modules.
One confirmed location limitation remains: a physical newline inside a quoted
string can leave the lexer's next-token cursor on the wrong line, and a matching
character there can pass the formatter's guard. The [retained counterexample](../../implementation/phase5/static-counterexample.md)
records unchanged rejection behavior but an incorrect highlighted excerpt.

An embedded parser Error can survive inside a declaration until graph validation.
Only after that validation rejects, the loader can recover the same Error in the
same traversal order and use its declaration index plus Loaded event counts to
find the original source. It verifies the selected error identity and unique
canonical source before rendering. Accepted books are not scanned again, and
unknown provenance retains the existing diagnostic. Formatting an existing
parser error does not establish that its grammar or first-error choice agrees
with the reference compiler.

## Host representation boundary

Self-emitted libraries use positional constructor fields. The host accesses
these through lazy, read-only named views and unwraps a view when passing it
back to another compiler phase. This preserves graph sharing between phases
without copying entire compiler books. Newly supplied host values are encoded
iteratively. See [the ABI adapter and validation](COMPILER-ABI.md).

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

Source discovery can construct `FParsedSource` through the Bend
`f_source_parsed` factory. The graph loader, seed fallback and main-name query
consume that immutable `FResult` through `f_parse_source`; raw `FSource` callers
remain supported. This avoids reparsing the same physical text during one
request. It does not change the persistent Base-cache trust boundary or bypass
import resolution, binder freshening or checking.

The trace-aware loader returns `FLoadTrace` with actual module order and
per-module declaration-event counts. All public provenance routes use this same
alignment; they do not reparse source to reconstruct ownership. Rejection
reporting reuses the request's trace and lexes only the defining module.

One chronological event checker returns the verdict and original structured
failure together. `check_book` and `check_from_exact_prefix` remain String APIs
by projecting its error. The detailed APIs expose the same result without replay.
An exact validated-prefix comparison still precedes suffix checking, including
open laws; any mismatch falls back to the full checker. The host consumes one
result only when `compiler_check_result_abi()` returns numeric `1`. Historical
artifacts keep guarded replay, whose error must match the old authoritative
verdict. Source lookup and rendering cannot accept a rejected term. The trace
belongs to one request and is not a stored verdict or replacement for checking.

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
source position through private `FRawResult`/`KTermError` values. The public
frontend result shape stays unchanged. After an error is selected, the loader
can locate that same embedded error and its unique source owner to render a
location once. Existing graph-error priority and definition traversal order
remain authoritative. Accepted books do not incur this error-only traversal.
Faithful formatting does not repair a different parse decision; residual
diagnostic and phase differences remain explicit conformance failures.

A persistent inspector owns one trusted API and one immutable decoded Base
entry. Before reuse it binds the canonical API path and content digest, reads
and hashes the exact cache bytes, and verifies the expected compiler/Base/cache
identity tuple. Misses clear the prior entry; malformed or changed data follows
normal validation. The same buffer is hashed and decoded on a miss, and the
validated graph is frozen iteratively. Each request still builds its own source
graph. The public single-request inspector and execution lanes do not share this
private memo. See [the implementation and adversarial gates](../../implementation/phase5/persistent-base-decoding.md).
