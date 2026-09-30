# Enclose a histogram chunk and its nested scalar loop

Prospective generated-JavaScript experiment after checked attempt05 coverage.
The original Mandelbrot `hchunk` is the most concrete larger pure region: its
state consists of a Nat countdown, a U32 position, a Nat iteration count and
eight U32 counters. It calls `pix`, which calls the already-admitted `mit` loop,
and returns one `Hl` constructor containing the eight final counters. It reads
no input record, array or string and performs no projection. Its only record is
the terminal result. No compiler source edit is authorized by this design.

The complete closure is `hchunk`, `pix`, `bkt`, `mit`, `asr8`, `sel`, `sel.go` and
`b2u`. Only `hchunk` and `mit` have recursion, each an exact self-tail call on a
Nat predecessor. All other helper edges are acyclic. Preserve Number/BigInt
representations, existing primitive expressions, argument order and every loop
iteration. Do not change histogram logic, the pixel coordinates or benchmark
inputs. Keep recoloring's separate `rcol` tree recursion generic.

## First discriminator: generated output only

Freeze an exact corrected current compiler output for the original Mandelbrot
fixture, preferably the independent constant-shift candidate once it is checked.
Use four prospective variants if derivation remains small:

1. Unchanged output.
2. Private `hchunk` countdown with the original public helper calls, including
   `mit`. This isolates the outer loop transfer while retaining inner guards.
3. The same outer loop and private acyclic helpers, but the original public
   `mit` invocation. This isolates outer helper descriptors from inner admission.
4. A complete private chunk with private nested `mit`; one closure guard at the
   outer entry, and no descriptor guard inside the proven closure.

Every fast variant requires exact application permission at the public successor
callback, original slot reads once, valid primitive scalar inputs and an intact
snapshot of the entire closure, including the `hchunk` and `mit` public matchers.
Use the corrected `exactCode` entry mechanism. Raw, borrowed, overapplied,
malformed-input and failed-guard paths execute the original generic callback,
never an earlier defective Nat worker. Capture origin descriptors when their
definitions are constructed; public descriptor shape and identity stay intact.

Preserve the original terminal `build("Hl", [...field thunks...])` expression and
the runtime's forcing boundary. Bind final fields to immutable values before
creating thunks. Do not replace the constructor with a flattened array, eager
plain object or earlier field projection. `Hl` has no public callable G binding
in the current output; the native/user constructor owner and layout must be
validated from the checked book for a compiler implementation. Reusing the same
constructor emitter/runtime avoids a new constructor-lookup optimization claim.

The private nested `mit` accepts its original, unprojected Nat argument. Preserve
zero handling and its BigInt countdown exactly. Only the public outer entry
guards the entire closed graph; inner functions receive values whose scalar
provenance follows from already admitted operations. No arbitrary recursion,
callbacks, foreign calls, input records, arrays or computed global constants may
enter this proof. Existing stable-host-intrinsics/prototype checks still apply.

## Controls and measurements

Compare full eight-counter `Hl` results, not only a checksum, over zero/one/many
pixels, zero/one/many inner iterations, diverse coordinates, U32 wrapping and
nonzero initial counters. Include the original small workload and `bench(0,0)`.
Use an independent scalar oracle and the unchanged output. Exercise raw and saved
partial callbacks, overapplication/copy-length observations, owner and helper
replacement before first call, metadata/call accessors, slot getters/reentrancy,
boxed/Proxy/throwing scalar inputs, and failures while forcing the terminal
constructor. Explicitly compare the generic fallback to a pre-worker reference
where a previous transformation already had a scheduling defect.

Keep dynamic guard/application/allocation counters separate from clean timings.
Freeze screen and long-warm confirmation configurations before measurement and
obtain the exclusive timing slot. Measure the complete original computation and
the chunk fixture; retain startup, output bytes, failures and drifting samples.
Do not infer a speedup from the following structural opportunity.

For `bench(0,0)`, the first histogram pass evaluates 64 pixels in one chunk and
recoloring evaluates another 64. The full variant would replace 64 first-pass
`mit` guards with one chunk guard; the 64 second-pass guards remain. Entry checks
would therefore fall from 128 to 65, although the outer closure checks eight
descriptors instead of five. At the documented small input the analogous count
is 512→260 (four chunks). This nearly halves guard entries, but does not predict
the reduction in total runtime. Outer matcher/partial-application calls and
histogram helper descriptors offer an additional, separately measurable saving.

## If the experiment survives: minimal compiler extension

Reuse checked KTerm copies, the existing scalar grammar, argument emitter,
snapshot registry, exact-entry runtime and Nat-loop transfer emitter. Two new
admission concepts are needed:

- A terminal closed Data constructor whose fields are validated native scalars.
  It is allowed only as the worker's final result, with no record inputs or
  intermediate projection. Keep the ordinary constructor KTerm/emitter.
- A private nested Nat countdown helper. Prove its two-arm shape and exact
  predecessor self-tail call with existing Nat-worker checks; retain its original
  Mat/Lam shape in the private KDef rather than introducing another IR. Treat
  that proved self-edge as a loop, while keeping the dependency graph between
  helpers acyclic and under the existing count/depth/fuel limits.

Permit native Nat in the relevant helper signatures, with outer input validation
and derived scalar provenance. This is required for `pix`, `bkt` and `mit` but
is insufficient alone. No general SCC lowering, record ownership model, array
provenance scheme, new primitive semantics or second pattern compiler is needed
for this first case. Implementation size is still unmeasured; avoid promising a
line count until the prototype establishes benefit.

## Why this before F32 or opaque carried records

F32 type/literal admission is a small prospective edit and would admit 17 more
scalar signatures in the raytracer. It still leaves its Nat lookup selectors,
residual Boolean matches, record result/input and binary forks outside the current
worker grammar. Its first useful original-region extension is therefore larger
than the scalar-type diff suggests. Keep F32's exact fround, NaN, infinity and
signed-zero controls as a separate follow-up.

The opaque-record row experiment targets edit distance's four record/array-carrying
countdowns and has broader structural coverage. Its generic cell can observe or
mutate host state, so live binding checks are required at each iteration and the
first deferred recursive boundary must remain. It cannot amortize the closure
guard by purity. That alternative deserves its own measured comparison; it should
not share the closed-region proof or silently inherit its weaker mutation rules.
The terminal-record chunk is a narrower way to test larger closed regions before
introducing general record-carrying admission.
