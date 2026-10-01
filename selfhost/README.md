# Bend2 compiler port in Bend2

Use the [compiler guide](../docs/BEND-IN-BEND.md) and
[Phase36 report](../implementation/phase36/README.md). **Checked03 is installed;
release verification and all 42 ordinary/relocated CLI checks pass.** The
[release record](../implementation/phase36/release-03.md) and
[manifest](dist/release.json) bind source, genuine checked parent, derived API,
Base, runtime and host. Ordinary
compilation executes the Bend implementation without a TypeScript fallback.
Prior releases retain their evidence.

The unchanged fifteen-point generated-JavaScript benchmark measures **3.653×
faster symbolic regression and 2.319× faster raytrace** versus Phase35 in the same
run. Their remaining TypeScript gaps are **3.834× and 23.473×**. The other thirteen
points have overlapping observed ranges. The map/set point was 3.19% slower in
the full run and 0.52% faster in a separate five-round follow-up; both are retained
with their overlapping ranges. All thirteen other generated program bodies are
byte-identical after removing verified runtime prefixes. Generic programs retain
large gaps; these cases do not define average application speed. The complete
run took 401.55 seconds.

Private tree producers reuse existing continuation frames and finite selectors,
preserving original tagged values, ordered children and sharing. Scoped guard
reuse amortizes host and dependency checks only within a separately proved pure
source graph; error reentry suspends the proof and native array graphs are
refused. Public calls and guarded fallback retain their original behavior.
Normal checked-library request medians change −1.56% for pair, +0.42% for
Mandelbrot, +4.50% for symbolic regression and +4.02% for raytrace; all observed
ranges overlap across three rotated samples. These
[compiler costs](../implementation/phase36/compiler-cost.md) are separate from
program execution. All 24 separate CPU/allocation captures complete; see the
[profile findings](../implementation/phase36/profile-findings.md). Source contains
**18,174 physical / 15,545 nonblank Bend lines in 69 modules**, up 124 physical
lines (0.687%), with 2,024 definitions, 640 laws and 71 types. See
[admission](../implementation/phase36/performance-admission.md) for the complete
performance and complexity decision.

The [final closure](../implementation/phase36/final-conformance/gates.md) passes
**all 15 postinstallation audit groups**, following 38 preinstallation steps:
226 canonical source files, 36 focused checks, 15 inherited owner-control groups,
**3,026 main + 196 broader exact frontend observations**, inherited
execution/library controls and 42 installed/relocated CLI checks. Seven new
owner groups cover scoped proof, callbacks, complete producer trees, shared
identity, actual private entry and refusal. Backend outcomes remain **69 pass / 8 not
applicable / 4 shared failures** across 81 rows. Counts overlap; exact agreement
does not turn shared failures into passes. [Conformance](CONFORMANCE.md) records
the scopes. Full backend/GPU and independent proof validity remain unestablished;
`--verdict` is unsupported. No new self-emitted fixed point is claimed.

The target remains upstream
[`018751270e800bc222a93dad7f257083ee53a5f7`](https://github.com/bendlang/bend/tree/018751270e800bc222a93dad7f257083ee53a5f7),
after Bend 2.0.34.

```sh
# From selfhost/, with Node.js 24 or newer:
npm run verify:release
node cli.mjs tests/conformance/typed-smoke/base-u32.bend --run
npm run build
```

Use the [checked workflow](../docs/PHASE5_DEVELOPMENT.md) for compiler edits.
Checked03 plus its 36 focused checks took **42.3 seconds**; the actual
one-case symbolic-regression screen took **8.03 seconds**. The
[execution suite](tools/performance/programs/README.md) offers 20/60/300/600-second
ceilings and independent case selection; [diagnostics](tools/performance/programs/DIAGNOSTICS.md)
add separate profiles and JavaScript analysis. Heavy jobs run serially with
explicit heaps, RSS/deadline bounds and a free-memory floor.

The [ledger](../experiments/ledger.md), [strategy](../experiments/STEERING.md) and
[preservation index](../experiments/PRESERVATION.md) retain failures and decisions.
The [performance guide](../docs/BEND-IN-BEND-PERFORMANCE.md) explains the admitted
representations and fallback boundaries.

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
They are not alternate defaults. The current release runs after relocation
without an upstream checkout, as verified by its
[42 ordinary/relocated CLI checks](../implementation/phase36/release-03.md).
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
