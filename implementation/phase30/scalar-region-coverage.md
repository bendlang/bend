# Coverage identifies the next region boundary

Checked attempt05 emits a private scalar region for only one definition across
the ten Phase28 library programs: Mandelbrot's `mit`. Extending the list of scalar
types alone will not substantially broaden current coverage. The strongest
concrete next experiment is enclosing `hchunk → pix → mit`, with an unchanged
terminal `Hl` construction and a private nested countdown.

The [prospective coverage plan](../../design/phase30/scalar-region-coverage.md)
preceded acquisition. `inspection-region-coverage-01` retains all ten original
fixture observations, including the known rejection of raytrace's first appended
wrapper (`+rr = 6n` cannot be inferred). The separate `inspection-region-coverage-02`
uses the previously documented `raytrace-typed.bend` wrapper (`U32.to_nat(6)`), with
the exact original algorithm prefix. It compiles successfully. No full workloads
were run and no speed figures were collected for this analysis.

| Library | User definitions | Private regions | Direct self-tail Nat candidates¹ | Principal extra requirement |
| --- | ---: | ---: | ---: | --- |
| Mandelbrot | 18 | 1 (`mit`) | 2 | `hchunk` terminal record; nested `mit`; `rcol` has binary recursion |
| Raytrace, documented typed wrapper | 33 | 0 | 0 | F32 plus Nat selectors, residual Boolean matches and record boundaries |
| Edit distance | 23 | 0 | 4 | Array/Dp carried state and observable cell calls |
| Tree sorting | 19 | 0 | 0 | Tree matching and recursive forks |
| Lexer | 29 | 0 | 0 | String/state construction, residual matches and recursive forks |
| Symbolic regression | 23 | 0 | 2 | Expr input or helpers producing/consuming Expr/Sel |
| Morning mixed test | 14 | 0 | 0 | Strings and collections; no matching countdown entry |
| Evening mixed test | 16 | 0 | 0 | Tuples/arrays/collections; no matching countdown entry |
| Compression roundtrip | 15 | 0 | 0 | List construction/destruction |
| Map/Set operations | 29 | 0 | 0 | Collection representations |

¹ A bounded syntactic inventory of checked user definitions whose leading Nat
Zero/Succ successor body ends directly in a call to itself after lambdas/lets.
This is not a full admission proof, a dynamic call count or a claim that every
definition contributes equally to the benchmark. Residual Bool matches in both
raytrace folds mean they are outside this particular shape even though their
individual branches recurse structurally. There are 219 emitted user definitions
across the ten successfully acquired libraries, after the explicit wrapper retry.

`mit` guards itself and `b2u/asr8/sel/sel.go`. The original `hchunk` has only scalar
state but returns `Hs`; `pix` and `bkt` require Nat parameters, while `mit` requires
admission of a proven nested self-loop. This isolates two additional concepts:
terminal scalar-record construction and nested scalar countdowns. Reuse existing
Nat checks, KTerm copies, primitive emission and the ordinary constructor emitter.
The [chunk experiment design](../../design/phase30/terminal-record-nested-region.md)
specifies four generated-JavaScript variants before compiler implementation.

That complete chunk could reduce `bench(0,0)` guard entries from 128 to 65: one
guard replaces the first pass's 64 per-pixel `mit` entries, while recoloring's 64
remain. The outer guard has a larger eight-descriptor closure. This is a structural
opportunity, not a forecast of total speedup; most arithmetic remains unchanged.

F32-only admission would add 17 scalar helper signatures in the original raytrace
source, but no additional current loop entry. `nearest.t` also needs finite Nat
selectors (`sx/sy/sz/sr`) and a residual Bool column. `nearest` returns a Hit record;
`trace` consumes one. `rowf/colf` fork recursively. The existing F32 primitive
emitter provides a useful future foundation, but the smallest source patch is
not necessarily the fastest route to a materially faster original program.

The opaque-state row prototype is a separate promising track: it addresses four
edit-distance countdowns without flattening records. Independent static review
found no new blocker in the guarded probe's stated scope. It preserves the first
original deferred step, captures each recursive target before argument effects,
and rechecks live bindings each iteration because generic cells may mutate them.
Those per-iteration guards require honest measurement and cannot use the closed
chunk's guard-once reasoning. Any compiler port must use repaired exact-entry
scheduling and a pre-prebinding reference; comparing only against the inherited
Phase29 prebinding behavior would retain its known defect.

The acquisition tool is `selfhost/tools/performance/phase30/inspect-region-coverage.mjs`.
It verifies the immutable attempt, records API/runtime/Base/source identities,
captures checked annotated user-definition summaries, and saves emitted modules.
It accepts a fresh output directory and attempt directory, with optional
`raytrace-typed` for the explicit retry. Raw checked-emission acquisitions took
roughly 0.8–1.8 seconds per program here; these are descriptive CPU5 observations,
including checking and static collection, not controlled compiler throughput.
Reproduction requires the retained attempt05 snapshot and API; ignored artifacts
are not durably preserved by these paths alone.
