# The Bend compiler written in Bend

The compiler port lives in [`selfhost/`](../selfhost/README.md) on the
`selfhost/bootstrap` branch. Its frontend, dependent checker, specializer,
normalizer, interpreter and JavaScript/native emitters are Bend modules.
JavaScript supplies filesystem/process orchestration, a primitive runtime, and
an adapter for the compiler's public data representation. Ordinary compilation
does not invoke the TypeScript compiler.

The active target is upstream
[`b2111cf43244e65f76ddc278ee695e669f720cbf`](https://github.com/bendlang/bend/tree/b2111cf43244e65f76ddc278ee695e669f720cbf)
(Bend 2.0.32 era). The [migration report](../implementation/phase8/upstream_and_conformance.md)
records checked artifact identities, current conformance, measured cost and
remaining gaps. This experimental port does not establish independent proof
validity; `--verdict` is explicitly unsupported.

The current source retains S4's shared loader, provenance, structured checking
result and list operations. It adds upfront datatype/signature visibility while
keeping definition bodies chronological. The [architecture](../selfhost/docs/ARCHITECTURE.md)
explains these boundaries. Rejected generic binder and semantic-value experiments
remain research artifacts; neither is installed. Historical 50% and 75% source
reduction targets remain unachieved.

The [release manifest](../selfhost/dist/release.json) binds the installed compiler
to source, checked bootstrap, Base, runtime and host. A checked B1 release is
byte-identical to authentic upstream emission. It is not a new self-hosting fixed
point; older equality-derived and fixed-point evidence belongs to its recorded
artifacts. [Conformance](../selfhost/CONFORMANCE.md) distinguishes acceptance,
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
and its genuine checked-bootstrap lineage. Historical equality releases additionally
verify their exact transformation replay. It works after moving
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

The build creates a fresh immutable attempt, checks all compiler source,
runs the maintained focused paired selection, then
installs the result. A failed selected gate prevents installation. To choose a
different upstream location or selection, use a development JSON config:

```sh
npm run build -- /absolute/release-config.json /absolute/new-attempt
```

Config fields and selection semantics are documented in the
[maintained workflow guide](PHASE5_DEVELOPMENT.md). Broad conformance and checked
self-reproduction are release/integration gates, not every small edit's build.
The [Phase8 report](../implementation/phase8/upstream_and_conformance.md) records
the current artifact's evidence and remaining failures.

## Work on the current source

For new compiler edits, use the [Phase 5 development workflow](PHASE5_DEVELOPMENT.md).
It builds a genuinely checked compiler, freezes source/runtime/host identities,
prepares a validated Base cache and runs selected tests against pinned TypeScript.
The workflow's `validate` command reuses that frozen compiler for fixture-only
changes; run a new build when compiler source changes. The checked profile is the default. The historical equality
profile is source-sensitive and must not be applied to new upstream output
without validating its transformation contract.

The [current source report](../implementation/phase7/s1-report.md) and historical
[Phase 5 report](../implementation/phase5/report.md) and
[frontend comparison](../implementation/phase5/final-conformance.md) describe the
source reduction and unchanged API's broader evidence. The Phase 5 full fixed
point has not been rerun for the smaller all-definition source. For experimental source changes, keep
the release stable and select a newly built attempt explicitly:

```sh
# From selfhost/, after creating build/dev/attempt-01 with the maintained workflow.
BEND_TYPED_API="$PWD/build/dev/attempt-01/api.mjs" \
BEND_TYPED_RUNTIME="$PWD/build/dev/attempt-01/snapshot/src/runtime.mjs" \
BEND_BASE="$PWD/.bootstrap/upstream/bend2/base.bend" \
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

The default API's checked parent and exact transformation are under
`dist/release-lineage/`. The old default and its authentic bootstrap sidecars
are under `dist/release-history/`. The optimized API has no bootstrap sidecar:
it is a verified derivative of the checked parent, not a new upstream bootstrap.
The separately self-emitted compiler has its own [checked fixed-point proof](../implementation/phase5/final-selfhost.md).
Its performance must not be confused with the historical Phase 5 default's measured 6.03× ratio; S4 has no new full-source TypeScript measurement.

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
validation. Generate a local self-hosting chain with:

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

The [architecture](../selfhost/docs/ARCHITECTURE.md) describes the first-order
`KTerm`/`KDef` core and component responsibilities. The phase 1 changes retain
those boundaries:

- The host hands parsed source back to the Bend loader within one invocation.
  `FSource` remains supported; `FParsedSource` carries an already parsed result.
  This is an internal trusted handoff, not a persistent unchecked AST cache.
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

For a frontend loader/error refactor, the maintained cross-version boundary test
compares complete ordered results, error precedence, cached parse payloads, seed
selection and input immutability. Use genuinely checked named-field APIs and a
fresh evidence directory, for example from `selfhost/`:

```sh
node --stack-size=4096 tests/frontend/shared-operations.mjs \
  /absolute/baseline/api.mjs /absolute/candidate/api.mjs /absolute/new-results
```

This test exposes existing checked private bodies for observation; it neither
rewrites them nor establishes self-reproduction. S4's A02 declaration-source proof
is a genuine checked B1→H→H fixed point. The installed B02 source has its own
checked bootstrap and byte-identical B01 behavioral/performance evidence; A02's
full-source fixed point is not relabeled as B02's.
