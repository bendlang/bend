# Checker speed, compact literals and the released compiler

Date: 2026-09-28. Final measured compiler installed and release gates complete.
The prospective [design](../../design/phase9/checker_speed.md) was committed and
pushed as `e7b2846` before experiments. The final source is the genuine checked
`integrated-03` build and its version-3 equality derivative, targeting unchanged
upstream `b2111cf43244e65f76ddc278ee695e669f720cbf`.

## Result

The compiler now accepts 1,000/1,001 positive upstream fixtures, up from 997.
All 482 validation negatives reject, including the previous timeout. The only
remaining positive checking failure is the long-string stack overflow. All other
frontend observations are preserved, including known diagnostic and trust gaps.
The source grows 73 lines, or 0.49%, across the same 59 modules.

The principal performance repair caches the binder bound used while checking
chronological law fills. It removes repeated scans of preceding definitions.
Smaller changes remove unnecessary checker work and native string-equality
validation. Compact Nat literals and a termination traversal repair resolve the
three positive failures without weakening decreasing-call checks.

## Controlled checking comparison

The final compiler is **3.12× faster** than the preserved Phase8 compiler on the
same final assembled source: **66.84 s versus 208.22 s**, a **67.9% process-wall
reduction**. Pinned TypeScript takes **2.94 s**, leaving a **22.74× process-wall
gap**. The measured request itself remains about **35.07×** TypeScript's request;
process startup and provenance hashing contribute a larger share of the much
shorter TypeScript process. These are checking/trust-reporting costs, not full
compilation or performance of emitted programs.

| Compiler | Mean request | Mean process wall | Maximum observed RSS |
| --- | ---: | ---: | ---: |
| Pinned TypeScript | 1.873 s | 2.940 s | 430.3 MiB |
| Preserved Phase8 | 207.061 s | 208.224 s | 1504.5 MiB |
| Final Phase9 | 65.681 s | 66.844 s | 1523.5 MiB |

All six retained rows, in execution order:

| Order | Compiler | Request | Process wall |
| --- | --- | ---: | ---: |
| 1 | typescript | 1.854 s | 2.922 s |
| 2 | baseline | 211.106 s | 212.273 s |
| 3 | candidate | 65.941 s | 67.108 s |
| 4 | candidate | 65.421 s | 66.579 s |
| 5 | baseline | 203.016 s | 204.175 s |
| 6 | typescript | 1.892 s | 2.958 s |

Fresh processes run serially on CPU0 with other intentional compiler jobs paused:
TS/baseline/candidate/candidate/baseline/TS. Node is 24.18.0, stack 4 MiB, heap
ceiling 4 GiB, and each child has a 600-second deadline. All rows accept ordinary
types, report the expected unsafe proof-trust refusal, and agree on the complete
unsafe-definition set. Source/API/Base/runtime/host/harness identities remain
unchanged. The same final source SHA is recorded below. No failed row is omitted.

Each Bend artifact uses its own validated disk Base cache; TypeScript checks
Base afresh, matching the Phase8 workflow policy. OS caches are not flushed.
Request timing includes adapter probing and lazy compiler loading; process timing
also includes startup, hashing and output capture. Two samples are descriptive,
not a confidence interval. Peak memory is effectively unchanged: about 1.5 GiB
for Bend versus 430 MiB for TypeScript. This measures the combined release;
individual full-source ablations do not allocate the gain among its changes.

Raw requests, outputs, process supervision and identities are under
`selfhost/build/phase9/final-matrix-03/`, durably included in the evidence capsule.
The historical 6.03× full-compilation figure has a different artifact and timing
boundary; it is not interchangeable with these checking-only ratios.


## What changed and why

### Repeated whole-book scans

The checker already cached its global declaration environment. Its separate
chronological event environment started as an ordinary list. A law fill compares
its signature with the prior law, often using different binder IDs. That
comparison searched for a fresh ID by scanning all earlier declarations and
bodies. Repeating this for successive fills created quadratic work.

The source now computes the full input's binder bound once and uses the same
immutable empty cache to seed two independently updated environments. This
shares a bound, not declaration visibility. Future signatures and chronological
bodies retain their distinct rules; exact-prefix validation and fallback remain.
A 4/8/16-law-fill experiment reduces full-book scans from 5/9/17 to 1/1/1, and
term visits from 117/307/927 to 43/79/151. These are operation counts, not times.

An initial proposal exposed an internal empty-named cache node to constructor
lookup. A retained raw-API witness caught the changed diagnostic. Constructor
search now skips BookCache metadata. The corrected candidate preserves all
14 targeted diagnostic records, 40 public observations, and 93 component checks.
See [checker work](checker-work.md), [caller attribution](profile-attribution.md),
and [P9-005](../../experiments/phase9/P9-005-chronological-cache.md).

### Smaller checker and equality changes

- Exact conversion returns before fresh-bound scans. Unequal terms retain the
  ordinary comparison worker.
- Lambda-domain kind checking follows upstream's quantity-promotion condition.
  Public book checking validates signatures first. Raw checking against an
  unvalidated goal is a separate, explicitly recorded internal boundary.
- Successful variable inference reuses its first context lookup.
- Guarded native String.eq retains exact runtime, dependency-body, public-ABI,
  bootstrap, Base and upstream-pin checks. Version 3 compares primitive strings
  directly under the current emitter's semantics; other inputs retain the
  original fallback. Versions 1 and 2 remain exactly replayable.

The exclusive small-operation screen measures 1.37× for exact conversion,
1.73× for nested lambda checking and 1.94× for successful deep lookup. Missing
lookup is approximately unchanged. A complex lambda-body case improves 29.74×,
while checking its **complete synthetic book improves 1.57×**. The body number
must not be presented as compiler speed. The final equality screen improves
1.72–5.41× on its ordinary string workloads; it is a same-process operation
screen, not the controlled full-source comparison.

For the current runtime, code-point decomposition is injective even for lone
surrogates; its protected comparison path does not validate them through
char_new. The legacy runtime does, so its validation stays in place. Differential
controls cover 2,381,689 string pairs, all single UTF-16 code units and valid
surrogate pairs, deterministic fuzz, and 27 fallback/error observations. Final
maintained checks pass 13 current groups and 12 applicable legacy groups. An
original recursive-equality stack overflow under Node's default stack is retained;
the final groups use the compiler workflow's 4 MiB stack. Resource exhaustion,
reflection and modified built-ins are outside the equality equivalence claim.

See [native equality](native-equality.md),
[current equality guard](current-equality-guard.md), and
[P9-002](../../experiments/phase9/P9-002-checker-work.md).

### Descent and compact Nat

Termination descent remembers its first failed field and does not repeat that
comparison during subterm search. For one increasing-Nat control, 9,841 recursive
calls become 9 at size 8. Structural parity, erased-column and decreasing versus
increasing source controls preserve the intended rule. The string-descent fixture
now checks; the increasing literal fixture determinately rejects.

Nat literals use one canonical LitNat core form with a U32 payload in the quantity
slot, never the binder-ID slot. Matching, conversion and descent expose one
constructor layer as needed. Native Base Nat checking retains the compact value;
custom types use ordinary constructor checking. Annotation, readback and both
emitters handle the form. Overflow keeps dynamic construction rather than
wrapping. Source payload width is unchanged; this is not arbitrary-precision
source-literal support, and wider runtime Nat values remain representable.

Both former Nat-300 type failures now pass. The final 40-row literal suite agrees
semantically with pinned TypeScript and preserves all observations from the
independent candidate: 35 strict passes, five existing strict failures, and
11 exact reference differences including custom-oracle diagnostics. Four native
boundary programs and the applicable interpreter/JS cases execute correctly.
These categories overlap and must not be added as unique programs.

The broad integrated02 run caught another omission: an unannotated compact Nat
without constructors in scope received a generic inference error. The final
inference fallback unfolds one constructor layer, matching upstream's route.
Six sources, including zero, one, custom Nat and missing Succ, now preserve the
complete baseline diagnostic/status/trust record. The final full vector restores
that diagnostic too. The integrated02 regression vector remains preserved.

Deep Nat patterns still have a backend scaling problem: compilation reaches
30–70-second bounds, including about 22 seconds in layout validation. Equivalent
explicit-constructor programs on the pre-compact compiler also time out in JS
and native compilation. This is an independently reproduced existing backend
limit, not a successful execution claim for that fixture. Long strings remain
unresolved. See [literal feasibility](literal-feasibility.md) and
[P9-003](../../experiments/phase9/P9-003-compact-literals.md).

## Final conformance and release gates

The fresh `frontend-03` vector contains all 2,996 parse/check observations for
1,498 fixtures, plus the unchanged support-file inventory. It uses the retained
same-pin TypeScript reference and Phase8 candidate vector with exact fixture,
path and target identities. No worker/input/artifact changes or missing rows were
observed. This is a fresh candidate sweep, not a claimed fresh full reference sweep.

| Observation | Phase8 | Final Phase9 |
| --- | ---: | ---: |
| Positive parse acceptance | 1,001/1,001 | 1,001/1,001 |
| Positive type acceptance | 997/1,001 | 1,000/1,001 |
| Determinate validation-negative refusal | 481/482 | 482/482 |
| Unexpected invalid acceptance observed | 0 | 0 |
| Strict check passes / failures / timeouts | 1,002 / 494 / 2 | 1,005 / 493 / 0 |
| Exact TypeScript differences | 734 | 731 |
| Exact parse / check differences | 198 / 536 | 198 / 533 |
| Trust refusals reaching intended phase | 7/11 | 7/11 |

Exactly four baseline frontend observations change: string_literal_descends,
nat_pattern_deep and nat_literal_unfolds now pass, and literal_descent_linear
changes from timeout to refusal. All other observations are unchanged. Four
imported-law trust cases still fail early; only three of the eleven trust cases
match exact output. Carets/text and some error phases remain substantial gaps.
No Lean kernel validation is claimed.

The final checked build passes the maintained 21 controls with 12 known exact
reference differences. Its bootstrap, Base preparation and focused validation
complete in one observed 26.98-second development loop. This is a single
concurrent development observation, not a controlled improvement over Phase8's
approximately 27-second loop. Routine development continues to use short checked
builds and focused controls; full-source checks and broad suites are integration
gates. The previous forty-minute workflow is unnecessary for a routine edit.

The final compiler is installed as `equality-derived-b1`, preserving its genuinely
checked parent and the exact version-3 transformation. The installer preserves
the preceding Phase8 release under `dist/release-history/`. Integrity verification
replays the recorded transformation version, including historical version 2.
Installation records `newBootstrap:false`: deriving from checked B1 does not
constitute a new B1→H→H self-reproduction proof.

| Final identity | SHA-256 |
| --- | --- |
| Assembled Bend source | `dbab2d33de96f6d29baa027acefdf0061e557c14f6b09a87e2c66c1baaf81c2b` |
| Checked parent API | `ab43f0ed4f007edbc83dad4b75318a047d1460612f0abacac42d0dd658b15eec` |
| Installed derived API | `d27968f11fa322bf3685ff0d276d9577a3b589b9cbae80784f5e4d404f7c3529` |
| Paired runtime | `1766d6d674f5c64eb481a647fe1d7bf751529d6861d4d4f4697999f005e772f0` |
| Pinned Base | `00c751b6cd045361a80f214c9c36bd4ec637e9ec86109b194e55cd57ca63ab94` |

All **42 installed/relocated release checks pass**, with unchanged input and
fixture hashes. Both locations verify integrity before and after execution,
report the CLI version, and check/run Base U32, user-owned `Clo.apply`, and Nat
boundary programs through the interpreter, emitted JS and compiled CPU C. Nat
outputs include 0, 256, 257, 300 and 4,294,967,295. The relocated package contains
no upstream checkout and clears compiler override and Node injection variables.
Native execution uses the recorded Clang 16 toolchain. The complete commands,
generated programs, binaries and outputs are retained under
`selfhost/build/phase9/release-smoke-03/`; installation is recorded separately in
`release-install-03/`.

For ordinary use, follow the [compiler guide](../../docs/BEND-IN-BEND.md):

```sh
cd selfhost
npm run verify:release
node cli.mjs tests/conformance/typed-smoke/base-u32.bend --check-only
```

`npm run build` now selects the validated equality derivative by default. The
isolated development workflow retains its checked profile default, and either
entry accepts an explicit profile. This changes the shipped compiler's checking
cost without claiming a general speedup in emitted user programs.

## Profiling and reproducibility

The original baseline sampling run completed ordinary type/trust checking, then
its Node summarizer failed on the 1,573,317,008-byte CPU profile. A streaming
recovery preserves that failure and two failed recovery attempts. Four parser
controls pass. The exact profile is retained as a lossless gzip with independently
verified byte-for-byte recovery. Its original launch recipe is preserved from
commit `08016da`, rather than pretending the later streaming launcher ran it.

Physical caller attribution places 33.662% of total baseline sampled time in
freshness helpers under chronological checking. The independent count series
establishes the repeated-scan mechanism. The integrated02 residual profile uses
10 ms sampling, versus 1 ms in the baseline, and runs concurrently with validation.
The two maximum-ID helpers fall from 34.13% to 0.86% of weighted samples. String.eq
accounts for 14.28%, GC 11.30%, run_loop 6.99%, f_declared 4.93%, and run_tail
2.85%. Anonymous generated frames also remain prominent. These profiles locate
work; different sampling intervals, inlining, scheduling and instrumentation
prevent treating the percentages as controlled speedups or allocation counts.
The residual profile predates the final diagnostic repair and version-3 equality.

The preserved first combined preflight still took about 193 seconds concurrently.
That disappointing result prompted the cache investigation. Neither it nor the
concurrent literal/profile timings is substituted for the final controlled runs.
Rejected bootstraps, overflow/readback counterexamples, sandbox failures, resource
limits and diagnostic regressions remain in the evidence.

The [preservation index](checker-evidence/README.md) links the final
[capsule manifest](checker-evidence/capsule-01/manifest.json), recovery instructions
and publication verification. It retains the Phase9 attempts and failures,
measurement rows, frozen inputs, full frontend observations, exact prospective
plans and release lineage. Previously archived byte objects are reused by hash,
with their archives listed as prerequisites. The separately retained baseline
[CPU profile](profile-evidence/README.md) restores the complete raw profile;
the residual profile is included in the main capsule. Rebuildable caches and
external toolchains are explicitly accounted for. Archive verification proves
preserved byte identity, not an upgrade of any failed compiler observation.

## Source size and remaining work

| Linked Bend source | Phase8 | Final Phase9 |
| --- | ---: | ---: |
| Modules | 59 | 59 |
| Physical / nonblank lines | 14,977 / 12,779 | 15,050 / 12,843 |
| Bytes | 489,150 | 493,257 |
| Definitions / laws / types | 1,470 / 790 / 62 | 1,478 / 792 / 63 |
| Selected generated API bytes | 739,211 | 750,872 |

This phase adds one compact literal form, a small descent result and a shared
cache seed using the existing indexing model. It does not replace the binder,
normalizer or compiler architecture. Declaration counts and lines are descriptive,
not a proof of conceptual complexity; generated output and historical unlinked
sources are counted separately. The earlier 50%/75% reduction goals remain unmet.

The next performance investigation should measure the remaining loader membership
scans (`f_declared`), generated-call/allocation overhead and deep-pattern layout
validation with small size series. The next semantic work is coherent compact
string handling and the four imported-law fills. Exact diagnostic parity is a
separate backlog. Full checked self-reproduction, broad native/runtime equivalence
and GPU execution remain separate gates. Native Process still depends on a libc
symbol unavailable on this host, which also blocks the pinned TypeScript lane.
No general runtime speedup for emitted programs or new self-hosted fixed point
is claimed by this checking-focused phase.
