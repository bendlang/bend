# The Bend compiler written in Bend

The compiler port lives in [`selfhost/`](../selfhost/README.md) on the
`selfhost/bootstrap` branch. Its frontend, dependent checker with live instantiation,
normalizer, interpreter and JavaScript/native emitters are Bend modules.
JavaScript supplies filesystem/process orchestration, a primitive runtime, and
an adapter for the compiler's public data representation. Ordinary compilation
does not invoke the TypeScript compiler.

The active target is upstream
[`b2111cf43244e65f76ddc278ee695e669f720cbf`](https://github.com/bendlang/bend/tree/b2111cf43244e65f76ddc278ee695e669f720cbf)
(Bend 2.0.32 era). The [Phase22 report](../implementation/phase22/contextual-conformance.md)
records checked artifact identities, current conformance, measured cost and
remaining gaps. This experimental port does not establish independent proof
validity; `--verdict` is explicitly unsupported.

Phase19 checks and produces live template instances inside the ordinary checker,
removing the separate specialization traversal and fixing saved first-error
differences. It retains the exact-prefix correction for compact literal payloads
and lambda quantity presence, preventing reuse of an old prefix for a changed proof.
Phase20 corrects constructor admission and whitespace, decorator diagnostics,
and empty match heads/patterns through existing parser workers. Constructor names
are validated before alias/duplicate checks and the opening brace. Comments and
newlines can precede the brace; semicolons cannot replace it. Optional match
separators retain the pinned behavior. Phase21 gives grouped locals the first
binder's origin and constructs typed-local annotations from their original body
and returned RHS cursors. These changes reuse existing producers and workers.
Phase17’s direct lookup loop and Phase16’s compact literals, exact specialization
keys, source ranges and contextual module parsing remain.
The [development history](../implementation/phase16/full_conformance.md) retains
its separate prototypes and failures. Phase22 closes the remaining measured
frontend differences on the final main corpus and broader parser selection.

The [Phase22 contextual frontend](../implementation/phase22/contextual-conformance.md)
closes those measured gaps by carrying the actual lexical environment, module
aliases, namespace and fresh counter through parsing. It validates patterns and
completed groups before their continuations, and resolves simultaneous RHS
expressions before opening their binders. One higher/lower materializer preserves
the pin's eager-child and deferred-binder demand, including first-error order.
The installed release passes both the final conformance and cost gates.

Its load ABI2 carries completed terms through the trusted internal
`FCompletedSource` handoff. Text still enters as `FSource`; the old raw-parser and
`FParsedSource` replay APIs are retired rather than maintained as a second
frontend. Dependency ordering, canonical imported-law eligibility and checking
remain enforced at their existing boundaries. Supplied completed IR is not an
authentication mechanism. The compiler's `--checkup` command follows the pinned
textual import order, prepares Base once, checks each imported module independently
and continues after errors, including a missing-file read.

The current source retains S4's shared loader, provenance, structured checking
result and list operations. It adds upfront datatype/signature visibility while
keeping definition bodies chronological. The [architecture](../selfhost/docs/ARCHITECTURE.md)
explains these boundaries. Rejected generic binder and semantic-value experiments
remain research artifacts; neither is installed. Historical 50% and 75% source
reduction targets remain unachieved.

The [release manifest](../selfhost/dist/release.json) binds the installed compiler
to source, checked bootstrap, Base, runtime and host. The installed API is a
guarded native-equality/literal-choice derivative of a genuine checked B1. Its original checked
parent and exact transformation are preserved separately. This is not a new
self-hosting fixed point. [Conformance](../selfhost/CONFORMANCE.md) distinguishes acceptance,
proof trust, exact diagnostics, execution and unavailable platforms.

## Run the compiler

Use Node.js 24 or newer. From the repository root:

```sh
cd selfhost
npm run verify:release
node cli.mjs tests/conformance/typed-smoke/base-u32.bend --check-only
node cli.mjs tests/conformance/typed-smoke/base-u32.bend --run
node cli.mjs tests/conformance/typed-smoke/base-u32.bend -o program.mjs
node program.mjs
```

With Clang 14 or newer, `node cli.mjs FILE --cpu --run` compiles and executes
native CPU code. `CC` selects Clang. GPU execution requires its own SDK/hardware
and remains outside the measured coverage here. Without `--run`, the default
checks the program and interprets `main`.

`verify:release` checks installed bytes, current source/runtime/host identities,
and its genuine checked-bootstrap lineage, including exact versioned transformation
replay. It works after moving
the checkout; original bootstrap reports retain their historical paths and are
not relabeled as new proofs. This verifies integrity and lineage, not another
run of all conformance tests. Normal CLI execution does not rebuild source.

## Rebuild the default

The supplied artifact runs without TypeScript or a local upstream checkout.
Rebuilding explicitly uses the pinned upstream bootstrap tool. On a fresh
checkout, prepare it once from `selfhost/`:

```sh
mkdir -p .bootstrap
git clone https://github.com/bendlang/bend.git .bootstrap/upstream-phase8
git -C .bootstrap/upstream-phase8 checkout --detach b2111cf43244e65f76ddc278ee695e669f720cbf
```

Then build and verify from `selfhost/`:

```sh
npm run build
npm run verify:release
```

The build creates a fresh immutable attempt, checks all compiler source, applies
the guarded equality profile, runs the maintained focused paired selection, then
installs the result. A failed selected gate prevents installation. To choose a
different upstream location or selection, use a development JSON config:

```sh
npm run build -- /absolute/release-config.json /absolute/new-attempt
```

Config fields and selection semantics are documented in the
[maintained workflow guide](PHASE5_DEVELOPMENT.md). Broad conformance and checked
self-reproduction are release/integration gates, not every small edit's build.
The [Phase22 report](../implementation/phase22/contextual-conformance.md) records
the current artifact's evidence and remaining failures.

## Work on the current source

For new compiler edits, use the [Phase 5 development workflow](PHASE5_DEVELOPMENT.md).
It builds a genuinely checked compiler, freezes source/runtime/host identities,
prepares a validated Base cache and runs selected tests against pinned TypeScript.
The workflow's `validate` command reuses that frozen compiler for fixture-only
changes; run a new build when compiler source changes. The development workflow
defaults to `checked`; release builds default to `equality`. Set `"profile":
"checked"` explicitly to build an unchanged upstream-emitted API. The equality
profile recognizes the reviewed current and historical contracts and rejects
unknown runtime, dependency or public-ABI changes. Version5 includes native
literal choices and a restricted branch transformation: one-return branches with
call-free terminal arguments become scoped blocks, with generated tail calls
using the existing trampoline message. Other branches keep their closure
boundary. Runtime bytes and public forcing wrappers stay unchanged; private
unforced message identity is outside this contract. Historical versions1/2/3/4
retain exact byte replay. The normalizer seed change and broader branch
transformation failed stack controls and are excluded.

The [Phase22 report](../implementation/phase22/contextual-conformance.md) gives the
current source and artifact identities. Keep experiments isolated by selecting a
frozen attempt explicitly:

```sh
# From selfhost/, after creating build/dev/attempt-01 with the maintained workflow.
BEND_TYPED_API="$PWD/build/dev/attempt-01/api.mjs" \
BEND_TYPED_RUNTIME="$PWD/build/dev/attempt-01/snapshot/src/runtime.mjs" \
BEND_BASE="$PWD/.bootstrap/upstream-phase8/bend2/base.bend" \
  node build/dev/attempt-01/snapshot/tools/typed-driver.mjs \
  tests/conformance/typed-smoke/base-u32.bend --check-only
```

For an equality-profile attempt, its selected API is recorded in `attempt.json`;
the original `api.mjs` remains the checked parent. The maintained `validate`
command follows the selected artifact automatically. Full checked self-reproduction
is a separate integration gate, not a prerequisite for every small edit.

## Artifact history and advanced selection

`BEND_TYPED_API=/absolute/compiler.mjs` selects an experimental compiler API.
`BEND_BASE=/absolute/base.bend` selects Base; `BEND_TYPED_RUNTIME` supplies runtime
text for generated JavaScript and does not replace the runtime embedded in an
already generated compiler. Historical artifacts under `dist/phase1/` and
`dist/selfhost/` keep their original evidence. See the
[Phase 1 report](../implementation/phase1/report.md) for their historical limits.

The installed checked API and original bootstrap report are in
`dist/release-lineage/`. Previous defaults and their original lineage are under
`dist/release-history/`. Original reports retain historical paths; relocated
integrity checks do not manufacture new bootstrap evidence. The separately
self-emitted compiler retains its historical
[checked fixed-point proof](../implementation/phase5/final-selfhost.md).

## Full self-reproduction and component checks

`src/compiler.json` gives the ordered module list and upstream pin.
`tools/assemble.mjs` links those modules into one source file, ordering types,
laws and definitions. It does not parse user programs or implement compilation.

Compiler helpers can use typed `def` headers when their signatures need no
earlier forward declaration. Preserve parameter quantities and use the assembled
definition order when deciding whether a law is needed. Bootstrap capability
selection also currently depends on the literal laws for `j_layout_error`,
`annotate_selected` and `j_program_selected`; retain them. A declaration edit
must preserve the complete selected export set, even when focused checking tests
pass. The [S4 report](../implementation/phase7/s4-report.md) records the caught
capability loss and the corrected source-authoring trial.

The pinned upstream compiler is used explicitly as the initial bootstrap tool:

```sh
BEND_UPSTREAM=/absolute/pinned/upstream \
BEND_TYPED_API="$PWD/build/candidate-api.mjs" \
  node tools/typed-driver.mjs --bootstrap
```

This writes a checked API plus the assembled source and provenance in
`build/typed/`. Keep source, API, runtime and host snapshots immutable during
validation. Full self-reproduction has not been rerun for the current Phase22 release. The advanced
runner, separate from the checked release build, is:

```sh
BEND_TYPED_API="$PWD/build/candidate-api.mjs" \
BEND_SELFHOST_HEAP_MB=12288 BEND_SELFHOST_TIMEOUT=10800000 \
  node tools/conformance/selfhost.mjs \
  "$PWD/build/typed/compiler.bend" "$PWD/build/candidate-fixedpoint"
```

The runner performs two complete checked compilations. Stage 2 is emitted by the
bootstrap API; stage 3 is emitted by stage 2. Their bytes must match. The default
4 MiB JavaScript stack needs an OS stack limit of at least 8 MiB. The 12 GiB heap
ceiling is a resource limit, not a claim that every compilation needs that much
memory. Canonical paths affect foreign metadata and emitted bytes; regenerate a
local chain after relocating the checkout. A successful upstream bootstrap alone
is not evidence of self-hosting.

Run component checks with `BEND_UPSTREAM=... node tools/verify.mjs`.
`BEND_COMPONENT_REPORT=/absolute/report.json` preserves the historical report by
writing new results elsewhere. Backend and runtime tests are documented in
[`src/back/js/README.md`](../selfhost/src/back/js/README.md). Complete fixture
runs, frozen hosts, artifact identity and GPU gates are described in the
[conformance protocol](../selfhost/tools/conformance/README.md). For a self-emitted
API, pass `--stack-kb 4096 --heap-mb 4096` to the conformance runner so its isolated
workers receive the same large-book resource settings; parent Node flags alone
do not propagate to them.

Self-host reports now record canonical source and Base identities, the compiler,
runtime, driver and consumed host helpers, and verify them before and after each
stage. Use a fresh output directory for a new proof. Reports from the older
format cannot be resumed because they lack this provenance. Preserve the same
canonical Base path when comparing output bytes across native and JS hosts.

## Internal boundaries and performance

The [Phase22 controlled comparison](../implementation/phase22/constructor-index-cost.md)
checks the same frozen compiler source in **10.699 s**, versus **11.017 s** for
Phase21 and **3.383 s** for TypeScript: a **3.16×** remaining gap. Process cost
is2.88% lower and request cost3.22% lower in this two-sample screen; peak RSS rises
2.52%. This is a modest measured change, not a statistical or universal speedup.
Fresh processes run serially on CPU0 with the same Base/runtime and resource
limits. Exactly one of35 host members changes: the reviewed ABI2 driver. This
measures usable compiler bundles, not an isolated Bend-only change. Bend uses
validated Base caches; TypeScript checks Base. Emission and generated-program
performance are excluded.

The [Phase17 lookup worker](../implementation/phase17/find-worker.md) measured a
separate 6.55% reduction by eliminating per-miss dispatch allocations. The earlier
[Phase16 measurement](../implementation/phase16/consolidation.md) records its
separate 2.48× gain and 62.70% RSS reduction; ratios from different sources and
windows must not be multiplied into a current result.

Compact `KLiteral` nodes keep Nat, U32, F32 bits and string payloads intact until
a constructor view is needed. A separate, earlier-source census found **92.97%
fewer freshened terms**. Explicit lambda quantity presence and canonical JSON
specialization keys preserve distinctions that a compact representation must
not erase. The [architecture](../selfhost/docs/ARCHITECTURE.md) describes these
contracts, source ranges, capability negotiation and Base cache version6.

Installed Phase22 reaches **2,996/2,996 exact frontend observations**, preserving
all1,001 positive accepts,482 validation refusals and11 exact trust refusals.
The broader parser suite is196/196 exact, closing57 differences. Independent
public176, execution36 and integration198 selections also pass; their counts
overlap. Read [conformance](../selfhost/CONFORMANCE.md) for raw negative-fixture
verdicts, historical evidence and unsupported features.

The compiler contains **15,600 physical /13,305 nonblank lines** in60 Bend modules:
300 fewer physical lines than Phase21. One contextual frontend replaces the old
raw-parser/later-scope replay routes. Bytes rise3,305 and definitions rise31;
laws fall81. This is an architectural consolidation and modest line reduction,
not an across-the-board decrease or the historical50%/75% targets. The guarded
version5 profile and runtime are unchanged; the host now requires load ABI2.

Routine development uses checked B1 and 36 focused controls; reuse a frozen
attempt for fixture-only edits. The long string stays first. The selection adds
six exact upstream checks and four separate illegal-path witnesses with explicit
refusal-at-parse oracles; full diagnostics remain under the strict corpus gate.
Phase22 source11/12 checked builds plus these36 controls took roughly33–35
seconds in their observed runs; this is not a controlled loop-speed benchmark.
Keep full-source and broad frontend/backend gates for integration.

The [architecture](../selfhost/docs/ARCHITECTURE.md) describes the first-order
`KTerm`/`KDef` core and component responsibilities. These boundaries distinguish
the current contracts:

- Phase22 reuses `FCompletedSource` results within one invocation; their terms
  are already contextually completed. The host requires load ABI2 and its full entry-point
  set; it does not fall back to the old raw route. This remains a trusted internal
  handoff, separate from persistent Base-cache validation.
- After specialization, `book_context` prepares one immutable exact-name index
  and binder bound. Annotation, layout validation and emission reuse that full
  context while independently selecting live definitions. Native compilation
  retains its backend-specific flow.
- The emitter preserves audited native Base string operations using the same
  classification used for reachability. Names alone never grant Base provenance.
- Proven single-constructor field accessors use a direct worker while retaining
  the generic ABI and field-vector copy. Erased fields, computed arms and
  eta-short arms retain ordinary matcher behavior.
- Pure top-level matcher wrappers are cached; arm bodies and global references
  remain delayed until application. Computed matcher-producing initializers still
  run on every reference. This does not increase application-spine arity.
- Transparent Boolean-choice calls with literal lambda thunks become JavaScript
  conditionals. Structural validation, currying, evaluation order, erased slots
  and the tail-call trampoline remain part of the contract.

The [phase 1 plan](../design/phase1/faster_bootstrap.md) records the original
hypotheses. The [implementation report](../implementation/phase1/report.md)
records actual changes, measured improvements, remaining costs and validation.
Use the [explicit-artifact harness](../selfhost/tools/performance/README.md) for
new comparisons. Benchmark a rebuilt self-emitted compiler against a frozen
control with the same input, Base, cache policy, Node flags and CPU affinity.

The `selfhost-baseline-2026-09-21` tag and original archive reports preserve the
supplied implementation. Historical conformance or fixed-point evidence applies
to its recorded artifact hashes; it is never evidence for a later compiler merely
because the source files have the same names.

For historical raw/parsed-loader refactors through ABI1, the cross-version
boundary test compares complete ordered results, error precedence, cached parse
payloads, seed selection and input immutability. With matching genuinely checked
named-field APIs, its command remains, from `selfhost/`:

```sh
node --stack-size=4096 tests/frontend/shared-operations.mjs \
  /absolute/baseline/api.mjs /absolute/candidate/api.mjs /absolute/new-results
```

That test observes existing checked private bodies; it neither rewrites them nor
establishes self-reproduction. Its raw API assumptions do not validate ABI2.
Use the Phase22 report's completed-source, actual-host, request-history and
execution controls for that boundary; retained older reports keep their original
scope. S4's A02 declaration-source proof
is a genuine checked B1→H→H fixed point. Historical S4 B02 has its own
checked bootstrap and byte-identical B01 behavioral/performance evidence; A02's
full-source fixed point is not relabeled as B02's.
