# Phase10 deep-pattern layout investigation

The [prospective experiment](../../experiments/phase10/P10-003-layout.md) targets
shared backend validation work independently reproduced during Phase9. No
production source or installed artifact is changed by this investigation.

The isolated combined candidate removes two measured repeated-work mechanisms.
Checked source and selected backend gates pass within the limits below; root owns
review, promotion and the controlled final comparison.

## First discriminating observation

The original counter series retained under `selfhost/build/phase10/layout-01`
confirms three nested costs. Depths 8/16/32/64/128 trigger respectively
36/136/528/2,080/8,256 constructor visits: default-arm reconstruction itself is
quadratic. Each visit asks `j_find_ctor` to scan unrelated book entries; its
counts are 20,880/70,992/260,304/995,280/3,890,640. Failed Nat literal recognition
rescans each open suffix, with 156/952/6,512/47,840/366,016 `j_nat` calls, a cubic
series. These are instrumented actual Bend helper entries, not an abstract model.

The first capture used pipe-backed spawnSync and reported EPERM despite successful
child status and complete result files. Those observations are retained; their
wall times are not promoted. The corrected supervisor uses file-backed capture.
All diagnostic cases passed ordinary checking and the real layout gate, then
intentionally stopped before emission. The stop is explicitly an error result.

## Constructor-only candidate

`layout-candidate-01` starts from the immutable Phase9 integrated03 snapshot.
Only `back/js/validate.bend` changes: local expected-ADT lookup finds its constructor
instead of scanning every book entry, with the original scan as fallback for an
unknown shape or missing constructor. The ordinary checked-source invariant is
unique constructor names; an unchecked malformed book with duplicate constructors
is outside this optimization contract. The source checker already rejects such
books. No universal raw-API equivalence is claimed.

Genuine checked B1 construction and the default 21 controls pass, retaining the
same 12 known exact differences. Depth128 eliminates all 3,890,640 constructor-scan
entries and reduces lookup entries 4,150,710 →25,290; the 366,016 Nat-recognizer
entries are unchanged. At depth 300 the independent residual reaches 4,590,250
Nat-recognizer calls. This distinguishes the mechanisms rather than attributing
them to one change.

All eight maintained layout fixtures preserve their exact status/error and emitted
JS bytes. Nat32 and Nat300 also emit identical JS bytes and execute to 38n and 306n.
Both baseline and candidate complete Nat300 in this environment: 34.20s/29.41s
compile observations, including layout 10.22s/5.27s. Concurrent single observations
are development evidence, not a controlled speed ratio. The historical Phase9
70-second timeout is not reproduced under these current conditions.

## Authorized second ablation

Root requested a bounded follow-up after the count result: avoid full literal
recognition specifically for checked native Nat Zero/Succ nodes while retaining
ordinary constructor-field traversal. This visits a dynamic tail and its references;
it does not skip arbitrary Nat-valued terms or alter String/U32 handling. The guard
requires normalized native Nat and exact Zero/Succ arity. Recognition-only and
combined isolated snapshots retain constructor-only as a fallback. The next gates
are a genuine checked build, operation counts, exact layout/error/emitted-byte
controls and actual deep JS/native execution. No production source is changed.

## Combined result and exact scopes

Both new ablations pass genuine checked construction and the same 21 focused
controls, with 12 retained exact differences. At depth 128, actual helper entries
separate the two changes:

| Variant | Constructor scan entries | Nat recognition entries | Layout term visits |
| --- | ---: | ---: | ---: |
| Phase9 | 3,890,640 | 366,016 | 17,302 |
| Constructor lookup only | 0 | 366,016 | 17,302 |
| Recognition avoidance only | 3,890,640 | 0 | 17,302 |
| Combined | 0 | 0 | 17,302 |

At depth 300, the recognition-only ablation still scans 21,089,264 book entries;
the constructor-only ablation still performs 4,590,250 recognizer entries. Combined
retains 92,122 layout term visits and 45,150 field visits, but both targeted counts
are zero. The remaining quadratic reconstruction is **not** removed. All counted
cases accept types and produce an empty layout error before the deliberate probe
stop. Corrected file-backed runs complete without supervisor errors.

The combined code adds 21 Bend lines in one module, with no emitted-program or
runtime implementation changes. Every successful JS emission in the 13-case
combined selection is byte-identical to Phase9. Eight maintained layout fixtures
preserve success or the exact open-Array error; a dynamic Nat tail, explicit Nat
constructors, Nat32 and Nat300 execute to 4n, 2n, 38n and 306n respectively. Nat300's
single concurrent compile observation is 33.09s baseline versus 24.33s candidate,
with layout 9.51s versus 0.839s; neither is promoted as a controlled speed ratio.

The thirteenth control initially expected a custom Nat library to compile. Both
compilers instead reject the compiler-owned name Nat before layout with the exact
same diagnostic. The two failed oracle rows remain in`layout-controls-combined-01`.
A separate corrected two-observation gate,`layout-custom-refusal-02`, requires
that existing refusal and passes. The original result is not relabeled a pass.

Disposable views of the two checked images provide six exact helper fallback
controls and eight native-Nat guard controls. They cover absent types/constructors,
non-ADT types, custom Nat provenance, wrong constructor names and invalid arities.
An intentional seventh helper case gives different constructor results for an
unchecked book that declares the same constructor under two ADTs. This records
the optimization's checked-source uniqueness assumption explicitly. It is not
full equivalence for arbitrary forged JavaScript compiler graphs. The normal
source checker must run before this backend path; the isolated prototype never
weakens its duplicate-constructor rule.

## Native boundary and residual emitted-code expansion

The actual canonical upstream Nat300 source passes native emission with the
combined compiler. Emission takes 30.66s in this concurrent development observation,
including 0.88s layout. The emitted C is 20,589,858 bytes, SHA256
`70ec351988836f23b1182dbb7d854627ed6d5265158765a95ea4e2073f32c4d6`.
Clang16 `-O3` then reaches its separate 90-second bound and is killed; no binary or
native Nat300 runtime success is claimed. The unchanged backend's code expansion
and external C compilation are an independent remaining cost. The exact source,
commands, successful emission, failed build and timeout remain under
`layout-native-combined-01`. The smaller Nat32 program passes actual native emission, Clang16 build and
execution to `38n\n` in `layout-native32-combined-01`; its combined API identity
and inputs remain unchanged. This does not turn the Nat300 timeout into a pass.

## Candidate identities and handoff

All candidates derive from Phase9 integrated03; its selected API is
`d27968f11fa322bf3685ff0d276d9577a3b589b9cbae80784f5e4d404f7c3529`.

| Isolated attempt | Selected checked-B1 equality derivative SHA256 |
| --- | --- |
| `layout-candidate-01` | `cecb3ac81bf534deb13e37ce0893644b025bbe6551d68aa5f141787db266b6ba` |
| `layout-recognition-01` | `ebd8a89f0cef7830c84c5f554fdad1f2c971d52a621df0b68d532eb6906cb697` |
| `layout-combined-01` | `512cc11851e8adab6cfc73c3d979c59b46c353547bac3453e28930f2952b71e0` |

The one-module patch is`selfhost/build/phase10/layout-combined-01/source.patch`.
Root owns independent review, source integration, broader final correctness gates,
controlled measurement and release. No production source or dist file was changed
by this investigation. This work improves a backend gate; it earns no whole-source
checking or TypeScript-relative speed claim.

The reusable scripts are under`selfhost/tools/performance/phase10/layout*`.
`layout-controls.mjs OUT API [CASE_NAMES]` reruns selected exact baseline/candidate
observations;`layout-native.mjs API OUT [FILE EXPECTED CPU]` emits, builds and runs
native code with 90-second phase bounds. `layout-matrix.mjs API OUT CPU` prepares
validated per-variant Base caches outside timing, then runs fresh-process Nat300
JS baseline/candidate/candidate/baseline on one CPU, requiring 306n and identical
emitted bytes. The caller must pause competing compiler jobs before that matrix.
The harness records compile, layout and complete process boundaries separately.
It is prepared for root's final artifact; no controlled matrix has run here.

Initial and superseded harness recipes, raw observations, checked snapshots,
compiler identities, fixtures, logs and failed attempts stay in the named
`selfhost/build/phase10/layout-*` directories for root's phase evidence collector.
An ignored local path alone is not a durable archive; preservation and commit are
root-owned and must be completed before the phase is reported as released.

## Independent review and dynamic dependency refusal

Root's independent reviewer found no blocker in the checked-source invariant.
Before final runner freeze, root requested one additional combined boundary:
`Succ{tail()}`, where `tail` returns Nat through a call to `keep(wrap(U32,3))`
and polymorphic `wrap` allocates an Array with an open element type. Both baseline
and combined candidate accept the ordinary types, then refuse in the compile
phase with exactly `Error: an open Array element type`. The two observations,
exact pair comparison and stable input identities pass under
`layout-dynamic-refusal-01`. This directly checks that the optimized Nat path
still follows a dynamic tail's live dependency to the layout violation.

Root has integrated the reviewed patch into its final candidate. The layout
owner has stopped compiler jobs. The final reusable control runner also fails
its own process when a selected observation, pair equality, supervisor outcome
or input identity fails; it does not rely on console PASS output alone. Final
integrated gates and controlled measurements remain root-owned.
