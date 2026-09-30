# Phase 29: isolated arithmetic and private-loop experiments

The extracted Mandelbrot helper confirms two removable costs. After the prescribed
longer warmup, the arithmetic prototype is **1.957× faster**, the private-loop
prototype **1.377× faster**, and their combination **3.702× faster** than unchanged
output. The checked compiler's arithmetic rule reproduces the result at **1.945×
faster**. The private-loop rows here measure disposable JavaScript experiments;
the [main report](generated-program-fast-loop.md) separately covers the production
compiler implementation. Even the combined prototype remains **230.95×** slower
than the TypeScript compiler's output on this particular small fixture.

The six-output initial screen takes **10.721921 s**. It gives a useful direction
quickly, but its large within-sample drift overstates the confirmed speedups. The
six-output confirmation takes **125.908752 s**. Both windows are retained; neither
is represented as a typical-program average or a guaranteed asymptotic limit.

## Fixture and invariant

The [fixture](../../selfhost/tools/performance/phase29/fixture-mandelbrot.bend)
copies `b2u`, `sel.go`, `sel`, `asr8` and `mit` verbatim from pinned upstream
Mandelbrot. Extraction metadata records the original Git blob and source-slice
hash. Two new adapters expose variable coordinates/state: `bench(size,seed)` and
`point(n,cr,ci,zr,zi,esc,it)`. The timed input is `bench(128,524800)`, returning 128:
128 iterations at the zero complex coordinate. This isolates the real inner
function, not the entire renderer or a representative set of application inputs.

The selfhost variants all retain Number U32 values and BigInt Nat counters.
Unsigned wrapping, arithmetic shifts, the fixed iteration count and escape-freeze
algorithm remain unchanged. The pinned TypeScript output uses its normal emitted
representation; this experiment does not estimate the separate cost of BigInt
versus Number Nats.

| Output | How obtained |
| --- | --- |
| TypeScript | Checked compilation of the same fixture by pinned upstream 01875127 |
| Unchanged | Checked compilation by unchanged Phase 27 attempt 02 |
| Arithmetic prototype A | Replace selected saturated U32 calls in `sel`, `asr8`, `mit` only |
| Private-loop prototype B | Replace only the saturated `mit` Succ callback body with a local-slot loop |
| Combined prototype A+B | Apply both disposable transformations |
| Compiler arithmetic | Checked Phase 29 attempt 01 emits the fixture through the new general arithmetic rule |

A inlines U32 `add`, `sub`, `mul`, `or`, `is_gt`, `is_zero` and `shrn`. Shift
templates retain the BigInt `>=32n` guard and Number conversion of the shift
count; expressions preserve left-to-right argument evaluation and use every
operand once. This source-specific prototype does not itself supply the general
native-identity/erasure guard required by a compiler rule. The checked compiler
candidate is separately identified and reviewed in the parent phase report.

B copies the original public Zero/Succ matcher and callback binders unchanged.
The Zero arm is untouched. The Succ callback receives its predecessor and six
remaining arguments only after the existing runtime satisfies its descriptor
arity, then calls `p29_mit(predecessor+1n,...)`. Thus the public first argument is
still matched immediately; partial descriptors retain their arity, null
environment and bound prefix. The loop compares/decrements BigInt Nat and computes
`r2,i2,e2,nzr,nzi,sr,si,nextIt` in the original order, then updates local slots.
It retains generic arithmetic/helper calls unless A is also applied. Entry adds
one BigInt predecessor+1 operation per saturated invocation.

This B transformation is specific to valid checked Nat/U32 values and the visible
helper definition. It is not a general solution for arbitrary foreign values,
erased arguments, lifted closures, dependent matching or mutual recursion. The
public invalid-input controls below check the retained boundary; they do not
extend the private loop's supported domain to malformed Nat representations.

## Correctness evidence

The [independent oracle](../../selfhost/tools/performance/phase29/fixture-oracle.py)
uses Python integer arithmetic with explicit modulo 2^32 and signed two's-complement
right shift. Its 120 expected results were frozen before acquisition and are
reproducible without loading compiler output: 48 structured state/boundary points,
64 deterministic random points and 8 benchmark-adapter points. These cover zero
iterations, escape flags, initial counter wrapping, coordinate/state boundaries
and varying sizes/seeds.

All 120 points pass upstream, unchanged, A, B and A+B. The separately acquired
checked compiler arithmetic output also passes the same 120. These are overlapping
uses of 120 distinct inputs, not 720 independent test cases. The controlled timing
harness additionally checks the complete timed result on every invocation.

The [public-boundary control](../../selfhost/tools/performance/phase29/prototype-boundary.mjs)
passes 48 observations for each of unchanged/A/B/A+B, **192 overlapping
observations**. It compares initial descriptors, all one-at-a-time prefixes and
grouped prefixes for Nat 0/1/7, exact arity/environment/bound fields, full results,
oversaturation failures, and invalid first-argument errors before reaching later
argument evaluation. The raw report records exact commands, tool/module hashes
and observations. No prototype acquisition, derivation or correctness failure
occurred in these attempts. No broader conformance claim follows from this set.

## Clean timing results

Both windows use fresh Node 24.18.0 processes, serial rotating output order on CPU 3,
4 MiB stack and 1 GiB heap, sanitized environment, separate import/first-call timing,
and uninstrumented emitted bytes. Time below is median milliseconds per complete
`bench` invocation, excluding import and warmup, including the exact result check.
Speedups divide the unchanged median by the candidate median within the same
window; ratios were computed from unrounded raw values.

| Output | Short median ms | Short speedup | Longer-warm median ms | Longer-warm speedup | Longer-warm / TypeScript |
| --- | ---: | ---: | ---: | ---: | ---: |
| TypeScript | 0.001746974 | — | 0.001711672 | — | 1.00× |
| Unchanged | 2.787280848 | 1.000× | 1.463403634 | 1.000× | 854.96× |
| Arithmetic prototype A | 1.007394252 | 2.767× | 0.747721861 | 1.957× | 436.84× |
| Private-loop prototype B | 1.358686494 | 2.051× | 1.062706555 | 1.377× | 620.86× |
| Combined prototype A+B | 0.435517823 | 6.400× | 0.395314662 | 3.702× | 230.95× |
| Compiler arithmetic | 0.992025348 | 2.810× | 0.752489340 | 1.945× | 439.62× |

The short screen has three fresh samples per output, at least 8 warmup calls
**and** 100 ms, a 150 ms timed target and 60 s child deadline: 18 timing samples plus
12 check/calibration processes, **10.721921 s total**. The longer confirmation has
five samples per output, at least 100 warmup calls **and** 3000 ms, a 300 ms timed
target and 120 s deadline: 30 timing samples plus 12 check/calibration processes,
**125.908752 s total**. Both use separate calibration to 50 ms, a one-million-call timed repetition
cap and preserved first/second timed halves. No failed samples were excluded.

Longer-warm observed ranges are 1.445876–1.468328 ms unchanged,
0.743667–0.753867 ms A, 1.055961–1.071089 ms B, 0.391099–0.401464 ms A+B,
0.739202–0.771015 ms compiler arithmetic, and 0.001704135–0.001723930 ms TypeScript.
These sample ranges are not confidence intervals.

First-call medians remain a separate scope:

| Output | Short-window first call ms | Confirmation first call ms |
| --- | ---: | ---: |
| TypeScript | 0.748845 | 0.744523 |
| Unchanged | 10.454915 | 10.623619 |
| Arithmetic prototype A | 7.572517 | 7.581708 |
| Private-loop prototype B | 9.437291 | 9.235834 |
| Combined prototype A+B | 6.345655 | 6.313328 |
| Compiler arithmetic | 7.459234 | 7.512918 |

The short screen has substantial drift despite narrow cross-process ranges.
Relative per-call cost in the second timed half is **126.0–132.8% higher** for
unchanged, 18.5–19.9% lower for A, 18.6–26.5% lower for B, and 19.1–34.1% lower for
compiler arithmetic. A+B rises 4.1–6.3%; TypeScript rises 2.6–2.8%. Thus the short
**6.400×** A+B speedup cannot be presented as stabilized performance.

In the longer window all 30 second/first half changes are within **1.71%**.
Unchanged stays within 0.64%, A within 0.57%, B within 0.55%, A+B within 1.34% and
compiler arithmetic within 0.53%. This removes the large observed intra-block
drift on this run; it does not prove universal JIT convergence. No JIT/GC cause
is assigned without a separate diagnostic establishing it.

The confirmed worker benefit remains after arithmetic: A/A+B is **1.891×**.
Arithmetic also helps the worker: B/A+B is **2.688×**. The two changes interact;
neither an isolated speedup nor a runtime-operation percentage should be treated
as the fraction of the original program's total slowdown caused by that mechanism.

## Untimed operation counts

Counter copies are separate from measured modules. The diagnostic verifies the
exact Phase 27 runtime 40823818 prefix and all original/derived module hashes before
executing ten calls to the same 128-iteration point on CPU 6. Every result is 128.

| Runtime operation, ten calls | Unchanged | A | B | A+B |
| --- | ---: | ---: | ---: | ---: |
| `apply` | 70,540 | 37,260 | 60,310 | 27,030 |
| `fn` descriptors | 16,700 | 16,700 | 7,750 | 7,750 |
| Bound `fn` descriptors | 7,730 | 7,730 | 60 | 60 |
| `call` | 56,450 | 27,010 | 48,770 | 19,330 |
| `jump` | 14,090 | 10,250 | 11,540 | 7,700 |
| `apply` argument-array copies | 70,540 | 37,260 | 60,310 | 27,030 |
| Copied `apply` argument slots | 142,430 | 83,550 | 105,380 | 46,500 |

A reduces generic calls without changing descriptor counts. B removes **99.22%**
of bound descriptors. The combination still performs **2,703 `apply` operations
and creates 775 descriptors per 128-iteration invocation**, including unchanged
helper calls and Boolean matching. That substantial residual work supplies a
specific next hypothesis; it does not establish how much time removing it saves.

These are named runtime-operation counters, **not total allocation accounting**.
Argument literals, projection arrays, arbitrary closures, BigInts, allocation
bytes and host JIT/GC behavior are outside the counters. The private loop adds no
explicit object container beyond remaining helper argument arrays, but its
BigInt decrement remains and entry reconstructs `n` once. Instrumented execution
time is not used for any performance claim.

## Evidence and next step

All raw paths below are within `selfhost/build/phase29/` and are preserved through
the parent phase's capsule/reproduction workflow:

- `prototype-01/report.json`: checked upstream/baseline acquisition and 120-point checks.
- `prototype-derived-01/{derivation,correctness}.json`: exact disposable transformations and checks.
- `fixture-candidate-01/{candidate.mjs.json,correctness.json}`: checked compiler arithmetic output; API bf578858, runtime 40823818, emitted module a89a975e.
- `prototype-boundary-01/report.json`: 192 public-boundary observations.
- `prototype-diagnostic-01/report.json`: ten-call operation counts.
- `prototype-screen-01/report.json`: 18 original timing samples and 12 checks/calibrations.
- `prototype-confirm-01/report.json`: 30 longer-warm timing samples and 12 checks/calibrations.

The first measured loop succeeds at a **10.72 s six-output screen** once modules
exist; a 5-second paired edit/build/emission/measurement loop has not been measured
by this experiment. Compiler build and acquisition costs remain separate.

The arithmetic result justified implementing and validating its guarded compiler
rule. The worker experiment supported further call/match lowering, while a
production rule still required a sound recognizer and focused semantic controls.
A conservative private worker can require a native-Nat Zero/Succ match, fully
visible unlifted live-lambda telescopes with equal residual arity, and exact
saturated self-tail calls. Keep the public matcher and fallback for every other
shape. Pure-argument call grouping is a smaller independent alternative; widening
arity alone can move a later argument ahead of an early failing match. The
prototype evidence alone does not establish either proposal's suitability for
promotion; production controls and decisions belong to the main report.
