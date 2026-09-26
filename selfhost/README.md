# Bend2 compiler port in Bend2

Use the [compiler guide](../docs/BEND-IN-BEND.md) for the consolidated default:

```sh
# From selfhost/, with Node.js 24 or newer:
npm run verify:release
node cli.mjs tests/conformance/typed-smoke/base-u32.bend --run
# Rebuild source using the pinned upstream checkout:
npm run build
```

The default retains the validated Phase 5 API, with guarded native string
equality, rebuilt from the [smaller S1 source](../implementation/phase7/s1-report.md).
S1 removes 548 obsolete lines; both generated APIs remain byte-identical.
Its [release manifest](dist/release.json) binds source, API, Base,
runtime and host; verification works after checkout relocation. Compiler edits
use the [maintained development workflow](../docs/PHASE5_DEVELOPMENT.md) for
checked builds and short paired selections. Ordinary compilation has no upstream
TypeScript fallback.

The [Phase 5 report](../implementation/phase5/report.md) records 919/919 positive
frontend fixtures, 318 remaining strict check failures and 444 exact live
TypeScript differences. The [controlled full-source comparison](../implementation/phase5/full-source-comparison.md)
measures 60.25s for pinned TypeScript and 363.39s for this optimized compiler
(6.03×), under its documented cache policy. The [checked fixed point](../implementation/phase5/final-selfhost.md)
and [final artifact frontend gate](../implementation/phase5/final-artifact-frontend.md)
provide separate reproduction and equivalence evidence.
That fixed-point evidence belongs to the pre-retirement all-definition source;
S1 has a fresh checked bootstrap and component gates, not a new full fixed point.

Historical reports apply to their recorded artifacts. The
[experiment ledger](../experiments/ledger.md), [current strategy](../experiments/STEERING.md)
and [preservation index](../experiments/PRESERVATION.md) retain decisions and
failed experiments. Read the [experiment workflow](../experiments/README.md)
before a new optimization investigation.

This project targets Bend2 2.0.21 at upstream revision
[`6018e28ecc67cf1fffc0c20c64b11023474c2df8`](https://github.com/bendlang/bend/tree/6018e28ecc67cf1fffc0c20c64b11023474c2df8).
It contains a modular typed compiler written in Bend2, plus the earlier
self-hosting surface compiler used as a regression baseline.

**The typed port is under compatibility validation. Do not treat its presence
as a claim of full upstream equivalence or use its checker as a trusted proof
verifier.** The reports distinguish implemented components, measured passes,
incorrect behavior, and targets that have not been tested on hardware.

The supplied baseline's recorded full run covers all 1,378 upstream fixtures. All 919 positive
programs parse and check; every eligible positive interpreter, JavaScript and
native CPU probe either matches its expected result or its exact upstream
output exemption. Negative compatibility still includes diagnostic rendering,
different rejection phases/rules, and unproven intended-rule coverage. See the
[compatibility matrix](docs/COMPATIBILITY-MATRIX.md) and
[negative-test audit](docs/NEGATIVE-COMPATIBILITY.md).
The typed compiler also passed a complete checked, byte-identical self-rebuild;
see [the self-hosting report](dist/selfhost/seed-verification/report.json).
Those are historical baseline observations. The current release's
[broad JS/native report](../implementation/phase5/broad-backends.md) records its
remaining negative diagnostic failures and one large-record native timeout.

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
[clean-package CLI checks](../implementation/phase5/relocated-cli-evidence/README.md).

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
