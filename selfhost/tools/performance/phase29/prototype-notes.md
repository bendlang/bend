# Disposable Mandelbrot mechanism experiment

These tools change copies of generated JavaScript. Their outputs are experimental
prototypes, not improvements emitted by the Bend compiler. See the Phase29 design
and report for separately identified production changes and clean timings.

`fixture-mandelbrot.bend` copies the pinned upstream definitions of `b2u`,
`sel.go`, `sel`, `asr8` and `mit` verbatim. Its two new adapters accept variable
U32 inputs: `bench(size,seed)` derives coordinates; `point` accepts all seven
iteration-state components. `fixture-mandelbrot.json` records extraction identities.
`fixture-oracle.py` reproduces the120 frozen expected values independently using
Python integer arithmetic, explicit modulo2^32 and signed arithmetic shifts.
All120 pass the checked pinned TypeScript and unchanged Phase27 emissions, and
all four disposable variants. This includes zero iterations, coordinate/state
boundaries, escape flags, counter wrapping and deterministic random points.

## Four variants

| Variant | Change |
| --- | --- |
| unchanged | Exact checked Phase27 JavaScript bytes |
| arithmetic | Inline saturated U32 add/sub/mul/or/is_gt/is_zero/shrn in `sel`, `asr8`, `mit` only |
| worker | Replace only the selected `mit` Succ callback body with a private saturated BigInt loop |
| combined | Apply both transformations |

The arithmetic templates preserve unsigned wrapping, Number U32 values, BigInt
Nat shift counts, the `>=32n` shift guard, Number conversion of shift counts and
left-to-right operand evaluation. They do not rewrite general Base definitions,
the benchmark adapters, other user functions or the runtime. These source-specific
rewrites are not a general guard against user definitions shadowing native names.

The worker keeps the original public Zero/Succ matcher and all callback binders.
The Zero arm remains unchanged. The Succ arm's callback receives the predecessor
plus six remaining arguments only after unchanged `apply` satisfies its arity;
it enters `p29_mit(predecessor+1n,...)`. Thus public partial applications still
match the first argument immediately and retain the original descriptor arity,
environment and bound-prefix representation. The private loop uses BigInt Nat
comparison/decrement and generic calls for arithmetic and helper functions.
It computes `r2,i2,e2,nzr,nzi,sr,si,nextIt` in the original order and updates local
slots before repeating. The transformed recursive calls stay internal to `mit`.
The prototype does not establish a safe general recognizer for arbitrary matches,
foreign objects, dependent erasure, effects, mutual recursion or lifted closures.

The extra `prototype-boundary.mjs` control compares actual staged public descriptor
shapes and early failure against the unchanged output. All48 observations per
module pass for unchanged/arithmetic/worker/combined:192 overlapping observations,
covering initial and staged/grouped prefixes, full values, oversaturation and
invalid first-argument failures. Exact commands and results are recorded in
`selfhost/build/phase29/prototype-boundary-01/report.json`.

## Untimed diagnostic

`prototype-instrument.py` creates distinct counter copies. The diagnostic launcher
requires every original variant to begin with the exact Phase27 runtime40823818
bytes and checks module identities before running ten calls on CPU6. Every call
uses `bench(128,524800)` and checks the complete result128. These instrumented
times are never used as speed claims.

| Runtime operation, ten calls | unchanged | arithmetic | worker | combined |
| --- | ---: | ---: | ---: | ---: |
| `apply` | 70,540 | 37,260 | 60,310 | 27,030 |
| `fn` descriptors | 16,700 | 16,700 | 7,750 | 7,750 |
| Bound `fn` descriptors | 7,730 | 7,730 | 60 | 60 |
| `call` | 56,450 | 27,010 | 48,770 | 19,330 |
| `jump` | 14,090 | 10,250 | 11,540 | 7,700 |
| Copied `apply` argument slots | 142,430 | 83,550 | 105,380 | 46,500 |

The operation counts show separate mechanisms: arithmetic removes generic calls
without changing descriptor counts, while the worker removes99.2% of bound
descriptors. Combined output still executes2,703 `apply` operations and creates775
descriptors per128-iteration call, mainly around unchanged helper calls/matches.
This is not complete allocation accounting: argument literals, projection arrays,
arbitrary closures, BigInts, allocation bytes and JIT/GC behavior are excluded.
The worker adds no explicit object container beyond its existing helper argument
arrays; BigInt decrement remains, and entry adds one BigInt predecessor+1.

Acquisition, derivation, correctness and counter receipts live under
`selfhost/build/phase29/prototype-{01,derived-01,counters-01,diagnostic-01}` and are
included by the parent phase's preservation workflow. Clean timings belong to
the root-owned campaign, never these acquisition or diagnostic process durations.
