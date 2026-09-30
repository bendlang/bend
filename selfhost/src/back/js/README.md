# JavaScript backend

`emit.bend`, `choice.bend`, `projection.bend`, `u32.bend`, `arm.bend`,
`primitive.bend`, `worker.bend`, `foreign.bend`, `literals.bend`, and
`validate.bend` are Bend2 source. Their input is the checked,
specialized, annotated `KTerm`/`KDef` core. They emit JavaScript; they do not
invoke another compiler.

- `j_compile_error(book)` validates the executable entry before reachability.
- `j_layout_error(context, annotatedDefinitions, roots, stops)` rejects live
  Array operations whose element representation remains open, while retaining
  valid generic identity functions and skipping erased or dead expressions.
- `j_roots(book, library)` and `j_stops(book)` drive shared reachability.
- `j_program_selected(context, definitions)` emits an executable from selected
  annotated definitions, retaining the full book for type normalization.
- `j_library_selected(context, definitions)` emits a library the same way.
- `j_program(book)` emits declarations and the executable entry point.
- `j_library(book)` emits declarations and an exported primitive ABI.
- `j_foreign_paths(selected)` requests live custom foreign sources;
  `j_foreign_error(selected)` rejects missing JavaScript implementations.
- `j_modules(selected, sources)` embeds custom foreign JavaScript modules once each.
  Each source is `KTerm("Source", exactPathName, ..., [KTerm("Text", contents)])`.
- `j_descriptor(book, type, fuel)` emits typed readback metadata. Recursive
  datatypes refer to finite named schemas.

Prepend `src/runtime.mjs` to the output. Erased arguments/fields are null ABI
slots and their expressions are not evaluated. Function and constructor
metadata comes from annotations and constructor telescopes. Applications in
tail position and returned constructor fields use the runtime trampoline.
Non-tail applications pass their fresh literal argument vectors to internal
`callOwned`, avoiding a redundant copy. Partial-prefix concatenation, public
`call`, matcher fields and tail-message vectors retain their existing copying.
Foreign JavaScript uses named
constructor fields and curried functions; runtime marshalling converts layouts
iteratively and preserves trusted inbound values, including opaque fields on
values passed directly between foreign functions.

The bootstrap-only integration tests use `build/js-backend.mjs`, built with
`tools/assemble.mjs` from `src/core/term.bend`, `src/core/index.bend`,
`src/core/normalize.bend`, `src/core/pretty.bend`, `src/back/js/foreign.bend`,
`src/back/js/literals.bend`, `src/back/js/validate.bend`,
`src/back/js/choice.bend`, `src/back/js/projection.bend`,
`src/back/js/u32.bend`, `src/back/js/arm.bend`, `src/back/js/primitive.bend`,
`src/back/js/worker.bend`, and `src/back/js/emit.bend`, then
`tools/stage0-library.mjs` exporting `j_program j_expr j_descriptor j_library
j_modules j_compile_error j_io_type book_cached j_layout_error`. Run `node src/back/js/test.mjs`,
`node src/back/js/test-foreign.mjs`, and `node src/back/js/test-validation.mjs`
from the project root. `survey.mjs` exercises actual upstream source files
through the checked compiler pipeline and records the compiler API hash.
`test-layout.mjs` checks the shared layout gate using the configured typed API;
`test-string-eq.mjs` compares the equality intrinsic with a pinned Base oracle.

The emitter uses lexical JavaScript variables for core binder IDs. Parallel
`Let` right-hand sides remain outside the arrow function that introduces the
new bindings. Consecutive leading lambdas share one closure; application
batching stops at the proven leading-lambda arity so intermediate computation
still precedes later argument evaluation. Computed globals remain reevaluated thunks; leading lambdas, top-level matcher wrappers and proven record projections share one closure.
`u32.bend` recognizes native U32-to-U32 ordered decision trees with closed literal
leaves before deep lifting. It emits one arity1 worker with unsigned bit tests,
with native ownership checks and an8192-node bound. Other result types, captures
and used structural fields keep generic lowering. It adds no runtime ABI. See
the [Phase26 report](../../../../implementation/phase26/direct-u32-decisions.md)
and `test-u32.mjs` for provenance, budget and valid-native-input boundaries.
`test.mjs` covers partial calls, erased arguments, effect/error evaluation order,
parallel shadowing, and closures that outlive their defining `Let`.

`primitive.bend` emits JavaScript arithmetic for 54 supported native U32/F32
operations at exact saturation. It checks native definition and datatype
identity, the complete scalar telescope, live arguments and arity. Operands
are evaluated once in source order; conditional division, modulo and shifts
bind both operands before testing them. Unsigned wrapping, zero divisors,
large Nat shift counts and F32 rounding follow the existing runtime. Partial
applications, foreign definitions and unsupported signatures use ordinary
application, retaining the native descriptors and their public ABI.

`worker.bend` recognizes a non-native definition with a native Nat
`Zero`/`Succ` matcher and explicit live scalar parameters. Its successor arm
must end in an exactly saturated self call on the captured predecessor, through
only annotations and `Let` bindings. The public matcher and initial partial
descriptor retain their argument demand. After full entry, a private loop
evaluates the next arguments into temporaries and selects the original Zero
body or the next successor iteration. Each iteration has fresh immutable
binder aliases, preserving closures; parallel RHSs precede their new bindings,
and erased RHSs remain unevaluated. Eligibility is limited to 2–32 slots,
8,192 core nodes, no deep closure factories, and native Nat/U32/F32/Bool scalar
parameters and results. All other definitions keep the existing emitter.
These rules add no runtime helpers, datatype representation or public arity.

For parser performance comparisons, build both outputs from the same checked
book with `benchmark-build-parser.mjs CANDIDATE_API.mjs`, then run
`benchmark-parser.mjs BASELINE.mjs CANDIDATE.mjs [SOURCE.bend]`. The benchmark
uses ABBA ordering and requires identical parsed output; `BEND_BENCHMARK_REPORT`
selects the report path. `BEND_TYPED_API` selects the baseline compiler API.

Definitions with more than 32 nested closures use flat closure factories with
explicit lexical captures, keeping emitted JavaScript within parser stack
limits. Below-threshold emission is unchanged; `BEND_JS_REFERENCE` optionally
checks byte-equivalence against a prior backend API in `test.mjs`. The deep
capture fixture and upstream `flatten/literal_rows_cubic.bend` cover the new
path. Benchmark and promotion evidence lives in `experiments/`.

`test-provenance.mjs` compiles a no-Base library that declares ten constructors
with primitive names and verifies that their fields survive construction and
matching. Generated metadata marks Base provenance; absent flags preserve the
legacy runtime ABI. Literal compression also checks the declared result type.

`test-global-initializers.mjs` checks that computed globals still initialize on
every reference. Set `BEND_EXPECT_CACHED_LAM=1` to require leading-lambda caching.
`src/runtime/js/test-apply.mjs` checks argument ownership, mutation isolation,
partial application, oversaturation, and constructor evaluation order. The
backend and runtime tests accept `BEND_JS_RUNTIME` for isolated runtime variants.

## Phase 1 execution improvements

`choice.bend` recognizes a transparent Boolean-choice definition by its core
body and Base Bool/Unit provenance. A fully applied call with two literal lambda
thunks emits a JavaScript conditional. The selected lambda receives Unit (or an
erased null slot), and its body retains the original tail-position flag. Partial
calls, computed thunk arguments, and different bodies use ordinary application.
`test-choice.mjs` compares both branches with pinned upstream and checks dynamic
argument evaluation, condition-before-branch ordering and 50,000 tail calls.

Base `String.contains`, `String.starts_with`, `String.reverse` and
`String.is_empty` preserve the existing native runtime implementation. The same
`j_intrinsic` classification drives stop sets and emission; user definitions
without Base provenance retain their Bend implementation.
`test-string-primitives.mjs` compares wrappers against pinned Base, including
empty, non-BMP and malformed host strings. Run both new tests with an explicit
`BEND_TYPED_API` and `BEND_UPSTREAM`.

Selected emission prepares one persistent `book_context` and reuses it through
annotation, layout validation and emission. Direct backend entry points prepare
an unindexed input themselves. A context is immutable and valid only for the
book from which it was built; specialization must finish before preparation.

To exercise a self-emitted API with the named-field backend fixtures, set both
`BEND_TYPED_API=/absolute/self-emitted.mjs` and
`BEND_JS_BACKEND=$PWD/tools/backend-test-api.mjs`. That adapter uses the same lazy
ABI boundary as ordinary compilation. Bootstrap APIs can still be selected
directly with `BEND_JS_BACKEND`.

`projection.bend` gives pure single-constructor field accessors a one-argument
worker. It proves that the arm consumes the complete live-field telescope and
returns one of those fields. Eta-short arms that apply a function-valued field,
erased-field arms and arbitrary computations retain the generic matcher.
The worker uses the same `project` helper and retains the field-vector copy,
including observable field-read order. `test-projection.mjs` checks those bounds,
function fields, oversaturation, effects, erasure and input ownership.

Top-level `Mat` values also have pure wrapper construction: `j_match` emits
`matcher`/`matcher1` factories whose arm expressions are delayed callbacks.
The wrapper is cached, while arms execute on each call. `Let`, `Rwt`, references
and other computed initializers retain their thunks, including computations
that return a matcher. Application-spine arity is unchanged, so applying a
matcher still completes before evaluating later curried arguments.
`test-global-initializers.mjs` and `test.mjs` cover deferred arms, live global
references, computed matcher effects and intermediate-error ordering.

`arm.bend` recognizes a single remaining constructor whose literal, unlifted
lambda arm has more leading slots than live fields. `matcher1p` prebinds those
fields into the original partial descriptor, avoiding one intermediate function
record, generic application and bounce. Outer arity, code body/name, captures,
null environment, field-copy schedule and later-argument demand are unchanged.
Unknown, erased, zero-field, lifted, eta-short and exact-saturation cases retain
`matcher1`. The runtime preserves generic mismatch and post-slice saturation
branches, including trusted foreign getters/custom slice results.

`test-arm.mjs` checks72 matching descriptor/effect/output observations against a
baseline through actual `j_library` emission. It uses synthetic KDefs; ordinary
checked corpus controls cover frontend admission separately. The
[Phase27 report](../../../../implementation/phase27/constructor-arm-prebinding.md)
retains the rejected inline variant, both warmup protocols and the shared helper's
modest measured benefit. Keep the helper and generic `apply` in sync; reduced
generic partial/copy counters do not mean the final descriptor/copy disappeared.
