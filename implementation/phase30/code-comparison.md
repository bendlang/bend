# Comparing corresponding JavaScript functions

Agent-generated investigation, Phase30. This note concerns static inspection of
the installed Phase29 compiler against pinned TypeScript output. It does not
report new program timings, execution counts, or optimized compiler results.

The important difference is execution machinery around the algorithm, not an
orders-of-magnitude difference in algorithm source size. Across 99 corresponding
source-defined functions, the emitted algorithm bodies are only 1.21–1.36 times
as many bytes as upstream, yet Phase29's measured algorithm gaps are far larger.
These byte counts are descriptive: the emitters have different formatting and
representations, so they are not a code-complexity score.

## Reproducible inventory

Run `python3 selfhost/tools/performance/phase30/inspect-output.py --out NEW_DIRECTORY`.
The tool writes hashes, names, line boundaries, body hashes, static sites, and
selected exact function excerpts. It does not compile or execute a Bend program.
The canonical first inventory is
`selfhost/build/phase30/inspection-02/report.json`. It uses:

- upstream commit `018751270e800bc222a93dad7f257083ee53a5f7`;
- Phase29 API `10510efda268bac1f31cc8fed87a9315e8f9edfa15aad6b90b0d96756c217b11`;
- checked Phase29 `transfer-04` candidate emissions and exact Phase28 upstream
  emissions, all already acquired from the same source;
- runtime `40823818afd57a6c37e055272dc332f461955a7cd225f67d66194f0d43ec823f`,
  verified as the exact 43,346-byte candidate prefix and excluded from counts.

Source definitions are matched by their original Bend names. Base definitions,
constructor metadata, runtime functions and public export adapters are excluded.
The `main` function is absent from upstream library output and excluded on both
sides. The inspector fails on unexpected missing names or changed emission
shapes. It is a format-specific lexical inspector, not a JavaScript AST parser.
It masks string literals/comments before counting helper-call tokens.

The first inventory, `inspection-01`, accidentally counted upstream function
headers as direct-call sites. Its bytes and original inspector are preserved;
`inspection-02` corrects that count. Other counts were unchanged. Only the latter
inventory supports the table below.

| Program | Matched functions | TS body bytes | Bend body bytes | TS direct calls | Bend `call`/`jump` sites | Bend matcher sites | Loops TS/Bend |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Mandelbrot | 17 | 9,406 | 12,053 | 44 | 111 | 16 | 2 / 1 |
| Edit distance | 22 | 5,567 | 6,731 | 23 | 75 | 23 | 4 / 0 |
| Lexer | 28 | 7,431 | 10,125 | 45 | 76 | 56 | 1 / 0 |
| Ray tracing | 32 | 19,475 | 25,678 | 104 | 271 | 132 | 3 / 0 |

These are static sites across every branch, not counts per invocation. A matcher
site may create a descriptor repeatedly. Conversely, a helper present in a file
might never run. `get` references are also recorded by target function, making it
possible to select the narrowest actual source slice for a dynamic experiment.

## Three mechanisms worth separating

### 1. Expose direct, saturated helper calls

Mandelbrot's `mit` is already a local-variable loop in both outputs. Each loop
body calls `asr8` three times, `b2u` twice and `sel` twice. Upstream makes seven
ordinary JavaScript calls; our output makes seven `call(get(G,...), args)` calls.
Those helpers then contain further calls/matchers. Our `sel` delegates to a
Boolean matcher through `sel.go`. This is an especially useful experiment because
we can keep loop lowering, arithmetic and state representation exactly fixed.

The smallest first ablation bypasses generic application only for fully applied
leading-lambda helpers `asr8` and `sel`. `b2u` is a matcher and is deliberately not
included in that admission rule. Keep live global lookup and unchanged public
descriptors; guarded fallback must handle replacement/mutation. A separate later
ablation can expose the Boolean selection helper. Do not call the combined result
a test of application dispatch alone.

The original helper fixture and full Mandelbrot library are useful transfer
checks. Small inputs should cover zero iterations, escaping/non-escaping points,
U32 wraparound and every Boolean result. Compare the complete observable result.
Keep long tail depth controls even when only helper calls change.

### 2. Consume complete match/parameter chains

Edit distance's `cell`, `cell.f1` through `cell.f4` each starts with `fn`, returns a
one-constructor matcher, and then constructs a field-consuming `fn`. The five
functions total ten explicit `fn` sites and five matcher sites. Their arrays and
record state are already separate from that application structure. A private
worker can retain the existing `project`, `build`, `Array.get` and `Array.set`
behavior while removing the repeated partial-function chain. This is the cleanest
record-aware ablation and remains the primary broadening experiment.

Ray tracing provides a demanding transfer case. `nearest` contains 34 generic
`call` sites, including twelve consecutive stages on each self-call; upstream
contains ten ordinary helper-call sites and a self-tail loop. `nearest.t` has
30 generic sites and ten-stage self-calls; its upstream version also loops. A
trailing Boolean match interrupts the leading lambda chain, and `nearest` returns
a record, so neither matches Phase29's scalar countdown rule. A direct entry must
preserve the demand boundary before this trailing match, not merely increase the
public arity.

Ray tracing also reveals a separate non-tail opportunity: `colf` and `rowf` have
two six-stage recursive calls each. Their source adds the two results, so turning
only self-tail recursion into loops cannot remove this overhead. Direct saturated
calls across a proven Nat match can reduce it, while recursion/stack safety needs
its own control. Use small exported `colf` inputs rather than rerunning the full
1,048,576-probe raytrace case for every edit.

### 3. Lower constructor/matcher administration after calls

Lexer `step.at` has 15 matcher sites, 14 explicit `fn` sites and 24 scheduled
`build` sites. Upstream has direct tag branches and 24 ordinary record literal
sites. This does not mean 24 allocations occur per character: these are mutually
exclusive branches, often with a nested mode record inside a pair.

Lexer `lex` uses SNil/SCon, Chr and Tuple matchers, then a generic recursive call;
upstream extracts the same logical values into local variables and loops. Both
already use native JavaScript strings. Keep strings fixed and test one layer at
a time: direct match-aware entry, tail transfer, then direct record construction
or temporary-pair elimination. Preserve Unicode scalar checking, surrogate pair
consumption, empty-string behavior, tuple projection and nested construction order.

An initial straight-line record-construction ablation should leave deep recursive
`build` sites on the trampoline: replacing every build with nested eager JavaScript
calls can lose bounded-stack behavior. Likewise, replacing `project` with `.a`
access must preserve ownership and foreign getters before it is a general rule.

## Other real differences, held fixed initially

Upstream uses JavaScript Number for internal Nat values within its checked range,
while ours uses BigInt. For example, upstream `mit` compares/decrements `0` and
`1`; the Phase29 loop uses `0n` and `1n`. Arithmetic shifts also retain BigInt shift
counts in our native-expression rule. This is a plausible later experiment, but
changing it together with call structure would prevent attribution. Nat overflow,
foreign/public BigInt conversion, constructor behavior and exactness at the
48-bit limit require a distinct design.

A 43 KB common runtime and Base/foreign definitions contribute to our complete
module size. Removing unused support may reduce import/parse/startup, but cannot
be assumed to remove warmed per-cell dispatch. Measure startup independently.
Do not interpret a whole-module diff as an instruction-count diff.

## Dynamic evidence before implementing a broad rule

For each small source fixture, first compare full outputs and error/effect order.
Use isolated instrumented modules to record `apply`, `call`, `fn`, bound descriptor
creation, copied argument slots, `project`, `build`, `ctor` and forced jumps. Reset
counters after import and label all counts as named-site observations, not a heap
allocation census. Do not time those modules as optimized performance.

Then compare pristine immutable modules with the existing serial rotated-process
harness. Use both the short mechanism screen and longer warmup confirmation when
the screen shows drift. If counts drop but time does not, investigate before
expanding admission:

- V8 CPU profiles after warmup can separate time in generic application,
  projection/construction, array helpers and arithmetic; preserve profile files
  and sample intervals, and do not mix profiling overhead into clean timings.
- Optimization/deoptimization logs can test whether a new private helper becomes
  monomorphic/inlined, rather than assuming a lower source count implies this.
- GC traces and allocation sampling can distinguish fewer transient descriptors
  from expensive long-lived arrays. They give different evidence from maximum
  RSS; preserve the scope and profiling overhead.

The success criterion is a correct, faster implementation on the small fixture
and a second workload, with a general admission rule and bounded complexity.
Static differences alone do not establish their shares of the remaining gap.
