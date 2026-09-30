# Bend2 compiler port in Bend2

Use the [compiler guide](../docs/BEND-IN-BEND.md) and
[Phase31 report](../implementation/phase31/closed-local-regions.md). The installed
checked07 compiler extends bounded private regions to closed local records and
arrays. It completes private returns at proved demand points and reads known
fields directly. Public representations and unsupported fallback remain intact.
Release verification and all42 ordinary/relocated CLI checks pass; the [release record](../implementation/phase31/release-07.md)
tracks ordinary/relocated CLI closure and exact artifact identities.

The original four-pair edit-distance program improves 26.83× over Phase30, with
a 14.28× TypeScript gap. A distinct array fold improves 17.67×. These are emitted
JavaScript execution results, not a universal speed ratio. The
[comparison report](../implementation/phase31/final-measurements.md) separately
records 6.90% slower edit-distance compilation and small entry/generic-row costs.
The [performance guide](../docs/BEND-IN-BEND-PERFORMANCE.md) explains the fast loop:
saved-JavaScript experiments, checked compiler builds (about 38 seconds with 36
focused observations), then broad integration. Acquisition durations are not
controlled compiler-throughput claims.

Fresh frontend execution agrees exactly with pinned TypeScript on **3,026 main
and 196 broader observations**. Selected upstream JS, 23 libraries/127 points,
worker/primitive controls, 22 compiler components and the HVM application pass.
The backend pilot preserves **69 passes, 8 not-applicable cases and 4 shared
failures** across 81 observations; its failed restricted Clang run and successful
context retry are both retained. Counts overlap. [Conformance](CONFORMANCE.md)
keeps raw fixture verdicts, agreement, backend coverage and self-emission separate.

The target remains upstream
[`018751270e800bc222a93dad7f257083ee53a5f7`](https://github.com/bendlang/bend/tree/018751270e800bc222a93dad7f257083ee53a5f7),
after Bend2.0.34.

```sh
# From selfhost/, with Node.js 24 or newer:
npm run verify:release
node cli.mjs tests/conformance/typed-smoke/base-u32.bend --run
npm run build
```

The compiler has **17,014 physical / 14,529 nonblank Bend lines in 66 modules**:
236 more physical lines (+1.41%) than Phase30, 34 additional definitions and no
new datatype declarations. Generated artifacts and experiment tools are separate.
The [release manifest](dist/release.json) binds source, genuine checked parent,
guarded derived API, Base, runtime and host. Compiler changes use the
[checked workflow](../docs/PHASE5_DEVELOPMENT.md); ordinary compilation has no
upstream TypeScript fallback.

This is an experimental compatibility port. Checking, proof trust, backend
execution and independent proof validation are distinct. `--verdict` remains
unsupported. Historical self-hosted fixed points and older compilation ratios
are not measurements of this release; no new H image or fixed point is claimed.

The [ledger](../experiments/ledger.md), [strategy](../experiments/STEERING.md) and
[preservation index](../experiments/PRESERVATION.md) retain failures and decisions.
The earlier [architectural trials](../implementation/phase7/architecture-report.md)
remain research artifacts; their larger/slower alternatives were not promoted.

## Use the typed compiler

Node.js 24 or newer runs the supplied generated API. The host shell handles
files, arguments and processes; parsing, elaboration, checking, specialization,
normalization and emission execute code generated from the Bend2 modules.
There is no fallback to upstream TypeScript in ordinary compilation.

```sh
node cli.mjs tests/conformance/typed-smoke/base-u32.bend --check-only
node cli.mjs tests/conformance/typed-smoke/base-u32.bend
node cli.mjs tests/conformance/typed-smoke/base-u32.bend --run
node cli.mjs tests/conformance/typed-smoke/base-u32.bend -o program.mjs
node cli.mjs tests/conformance/typed-smoke/base-u32.bend --native --run
```

Native execution requires Clang 14 or newer. `--native` selects a GPU build
for bang calls when the host has the supported SDK; `--cpu` forces CPU execution.
`--metal` and `--cuda` explicitly select those platforms and fail when their
toolchain is unavailable. GPU builds need Clang 19 or Apple Clang 17, plus the
platform SDK. The native build shell links the platform libraries requested by
foreign effects. Actual GPU execution has not been verified in this workspace.

The default checks the file, then interprets `main` (or reports declarations when
there is no `main`). `--interpret` selects this explicitly; `--run` executes the
JavaScript backend. Runtime arguments can follow the input or `--`.

Use `-o program.c` to write C, `-o program.js` or `-o program.mjs` for JavaScript,
and another output suffix to build a native executable. Multiple `-o` outputs are
supported. `--library -o library.mjs` emits a JavaScript library. `--checkup`
checks and runs each directly imported module independently.

The parser reports source errors separately from type errors. A rejected check
stops executable generation. Host effect implementations necessarily use
JavaScript or native platform code; that runtime is separate from the compiler.

## Source organization

| Directory | Responsibility |
|---|---|
| `src/core/` | First-order terms, substitution, weak/strong evaluation, conversion, term readback |
| `src/front/` | Lexer, declarations, expressions, desugaring, nested patterns, validation, fresh binder IDs |
| `src/load/` | Module graph, namespaces, aliases and foreign-source paths |
| `src/check/` | Dependent checking, quantity accounting, recursion, template instances and typed annotations |
| `src/diagnostic/` | Structured checker errors, context rendering and source provenance |
| `src/back/js/` | JavaScript generation, literal lowering, typed readback and foreign linkage |
| `src/back/native/` | Runtime layouts, segments, continuations, closures, erasure and C generation |
| `src/runtime/js/` | JavaScript primitive and effect runtime, including foreign marshalling |
| `src/runtime/native/` | Pinned upstream native execution runtime and effects |
| `src/driver/` | Compiler queries shared by the host shell |
| `tools/` | Bootstrap, source assembly, command shell and validation tools |
| `tests/` | Component regressions and upstream conformance reports |

`src/compiler.json` is the canonical module manifest. `tools/assemble.mjs`
orders type declarations, forward laws and function bodies into one bootstrap
input, with a source map back to editable modules. It does not parse or compile
user programs. See [the architecture notes](docs/ARCHITECTURE.md).

## Rebuild and validate

Prepare the exact upstream checkout once as described in the
[compiler guide](../docs/BEND-IN-BEND.md#rebuild-the-default), then run:

```sh
npm run build
npm run verify:release
```

For a custom upstream location or focused selection, pass a development JSON
configuration and a fresh attempt path to `npm run build -- CONFIG NEW_ATTEMPT`.
For experiments that should leave the default intact, use the
[maintained development workflow](../docs/PHASE5_DEVELOPMENT.md).

Full self-reproduction is a separate integration gate using a genuine checked
parent. Follow [the current reproduction instructions](../docs/BEND-IN-BEND.md#full-self-reproduction-and-component-checks)
and [final Phase 5 proof](../implementation/phase5/final-selfhost.md). A derived
API must not acquire a bootstrap sidecar. Low-level bootstrap commands need an
explicit fresh `BEND_TYPED_API` path; running them against the default replaces
its artifact kind and invalidates release verification.

Runtime, ABI and harness checks remain available:

```sh
npm run test:runtime
npm run test:abi
npm run test:harness
```

The [conformance protocol](tools/conformance/README.md) documents full inventory,
exact selections, resource limits and retained failures. Negative syntax
rejection is not automatically correct type rejection, and GPU execution needs
actual hardware evidence. Use a fresh report path and preserve the artifact
identities; historical reports do not validate later source just because paths
have the same names.

Historical self-emitted distributions and their original reproduction reports
remain in `dist/selfhost/`; the [preservation index](../experiments/PRESERVATION.md)
and [experiment ledger](../experiments/ledger.md) identify their exact scope.
They are not alternate defaults. The current release can run after relocation
without an upstream checkout, as verified by its
[Phase30 installed/relocated CLI checks](../implementation/phase30/release-cli.json).
The earlier [Phase5 clean-package evidence](../implementation/phase5/relocated-cli-evidence/README.md)
applies to that historical artifact.

## Earlier prototype

`src/compiler.bend`, `dist/bend2c.mjs` and `legacy-cli.mjs` retain the earlier unchecked
single-file JavaScript path. Its stage-2/3/4 fixed point applies to that
prototype, **not automatically to the new typed compiler**. Use the typed driver
above for the new work. The original behavior and bootstrap are documented in
[the legacy notes](docs/LEGACY-PROTOTYPE.md).

## Provenance

The new compiler modules follow the pinned upstream semantics. The standard
library and native runtime/effects retain upstream source and licenses. The
native runtime is not claimed to have been rewritten in Bend. See `NOTICE`,
`UPSTREAM-LICENSE`, and `src/runtime/native/ORIGIN.md`.
