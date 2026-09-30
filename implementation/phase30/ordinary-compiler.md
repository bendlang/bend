# Ordinary scalar roots in the checked compiler

The [design](../../design/phase30/ordinary-root-compiler.md) is implemented in
attempt11 after the isolated ordinary-root experiment confirmed a 1.338× gain
on its original small Mandelbrot point. The compiler reuses the same analysis,
helper cache, fuel, entry permission and guards. A completed nested Nat loop is
required before an ordinary scalar lambda root receives a private region.
There is no new runtime helper, IR tag or analysis-state field.

The input guard now explicitly distinguishes a projected predecessor from an
ordinary Nat input. The latter accepts the full existing 48-bit range; successor
callbacks retain their strict projected upper bound. Original slot reads happen
once before either path, and raw entry keeps the generic callback behavior.

Attempt11 passes all 36 focused exact gates. Build plus those gates took
38.147 seconds; checked original Mandelbrot emission took 5.176 seconds. These
are descriptive acquisition durations with parallel independent acquisition,
not a controlled compiler-throughput comparison.

Actual emitted output against attempt10 passes 92 independent scalar/original
oracles and 225 ordered public-interface observations. These include both pix
and rpix, mutations of every helper descriptor, saved partial applications,
slot getters, raw and forged entry, reentry, constructor calls and coercions.
Independent admission testing passes 28 books and 44 executions, including the
maximum unprojected Nat in unused state and refusal cases. See the independent
review for its exact scope and retained harness correction.

The terminal-record semantic suite also passes 200 full histogram states and
129 boundaries. The first counter adapter incorrectly used attempt10 as the old
baseline while asserting the pre-terminal baseline must return an internal
bounce. That internal-shape assertion failed, after all public semantic checks
passed. The untouched failed receipt remains in `terminal-compiler-controls-11`.
The original counter suite against its intended attempt08 baseline passes in
`terminal-compiler-controls-11b`, including both delayed-build field controls.
No compiler edit was made to accommodate that counter expectation.

Separate instrumentation on original `bench(2,0)` measures generic applications
12,112 → 6,224, function descriptors 7,742 → 5,438 and jumps 1,815 → 535.
Both outputs have eight builds and 260 guard evaluations. The second pass now
guards the larger rpix closure once per leaf instead of the smaller mit closure.
These are named administrative events, not total allocations or cost shares.

The clean actual10-versus11 confirmation took 63.94 seconds. On original
`bench(2,0)`, five rotating fresh-process medians are 4.995417 ms for terminal10,
3.633858 ms for ordinary11, and 0.0454074 ms for pinned TypeScript. The actual
incremental improvement is **1.375×**, leaving **80.03×** the TypeScript cost.
Ranges are [4.920979–5.008208], [3.570331–3.851380] and
[0.0453273–0.0457179] ms. Terminal and TypeScript timed halves stay within 0.83%
and 0.46%; ordinary11 has three within 0.36% and two improving 2.93% and 6.06%.
These are protocol-specific execution results, not a universal steady-state
claim. The installed release remains Phase29 until final integration.
