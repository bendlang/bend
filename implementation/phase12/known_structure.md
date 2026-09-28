# Phase12 known-structure investigation

The checked combined candidate removes duplicate literal recognition and reuses
the checked ADT for three JS constructor lookups. It preserves the tested emitted
JS bytes and actual outputs while deleting eight Bend lines and one private
wrapper. Root accepted the frozen source for integration; final combined release
gates and exclusive performance comparisons remain root-owned.

Two prospective records precede their experiments:
[P12-004](../../experiments/phase12/P12-004-known-structure.md) for literal-result
reuse, then [P12-005](../../experiments/phase12/P12-005-js-constructor-lookup.md)
after the original counter screen exposed the larger constructor-search cost.
Baseline is Phase11 `f8244c9`, API `63c861e9…`, unchanged upstream `b2111cf`.

The narrow opportunity is duplicate literal recognition in JS constructor
emission. `j_constructor_mode` evaluates `j_literal_typed` before its Boolean
branch, then `j_constructor` immediately recognizes the same term again in the
ordinary/literal branch. The generated Phase11 checked API confirms this eager
call shape. Sharing the result preserves the first call's evaluation position
and sends identical text into the existing literal emitter; no new provenance
assumption is needed. The upstream `comp.ts` constructor path instead binds its
ADT/scalar observation once.

Expanded word/String core trees remain a larger architectural difference from
upstream's compact Lit representation. The current bounded work does not justify
that rewrite: P6-012's raw metadata counterexamples and 273-line certificate,
plus P7's semantic-value demand-order failures, remain relevant negative evidence.
P6-005's native constant-field retention is separately known and unpromoted;
repeating it requires a deliberate current-workload priority, not a new label.

## Source and demand contract

`j_constructor_mode` now binds its literal result once, at the same evaluation
position as the original eager Boolean operand. Its existing literal emitter
receives that result directly. The sole-caller private `j_constructor` wrapper
is removed; the selected public export set is unchanged. For a closed String,
U32 or F32 this avoids a second full recognizer traversal. An open constructor
in tail position already used the build branch and does not gain that reduction.

At the three nonliteral constructor sites in `j_constructor_mode`,
`j_constructor_literal` and `j_l_children`, the candidate calls the existing
Phase10 `j_layout_ctor`. The normalized expected ADT supplies the local
constructor telescope. Unknown/non-ADT types and missing local constructors
retain the general lookup. No cache, new helper, type, private tag or ownership
rule is added. Literal branches do not newly demand type normalization.

The intended domain is finite checked annotated books with unique constructor
ownership and their complete immutable type context. The existing Phase10 raw
duplicate-owner counterexample still differs intentionally: an earlier forged
owner is selected by the old global search, while the typed local path selects
the named ADT's constructor. Source checking rejects such conflicting ownership.
This is not equivalence for arbitrary malformed or reflective host objects.
For the local lookup, type normalization now precedes the constructor search;
ordinary valid checked data must satisfy the existing type/context invariant.

The existing `ks(wnf(book,ty))` specialization remains, so the three sites can
normalize that type twice. Root reviewed this explicit small remaining cost.
An additional shared helper was deferred to retain the minimal candidate;
the dependent-family alias control passes. Match-arm telescope lookup and
repeated failed Nat recognition in lifted-function traversal remain unchanged.

## Operation counts and ablations

Four instrumented checked images run the same 8/16/32/64 Nat and String families.
Each case performs ordinary checking, actual JS emission and execution with an
exact output oracle. These 32 runs are concurrent diagnostic evidence, not a
timing comparison. All code hashes match across the four variants for each
fixture; all actual outputs match.

| Nat depth | Baseline / reuse constructor-search entries | Lookup / combined entries | Baseline / lookup Nat recognizer entries | Reuse / combined entries |
| --- | ---: | ---: | ---: | ---: |
| 8 | 22,272 | 5,104 | 158 | 158 |
| 16 | 72,384 | 8,816 | 954 | 954 |
| 32 | 522,000 | 31,552 | 13,026 | 13,026 |
| 64 | 1,991,952 | 61,248 | 95,682 | 95,682 |

At depth64 the local lookup removes 96.9% of the observed `j_find_ctor` entries.
The remaining entries include unchanged match-arm/readback paths. The literal
reuse proposal has essentially no benefit on this open-Nat family: it removes
only three `j_literal_typed` calls and leaves recursive Nat recognition unchanged.
This negative finding is why lookup was isolated as a separate hypothesis.

For closed String lengths8/16/32/64, literal recognition calls fall2→1, String
walker entries fall18/34/66/130→9/17/33/65, and word-reader entries fall
528/1,056/2,112/4,224→264/528/1,056/2,112. The lookup-only variant preserves
the old String counts; the combined variant retains both independent effects.

## Checked and boundary controls

All three source ablations complete genuine checked B1 construction, the guarded
v4 derivative, and the maintained21 paired controls with the same12 known exact
reference differences. They are independent snapshots, not patches to generated
compiler code. Instrumented copies are used only for counters.

The combined raw gate has six equivalent constructor/fallback cases, one
preserved duplicate-owner counterexample and12 tail/non-tail literal/malformed
emission comparisons. Finite malformed literals retain their original text or
exception; this does not grant malformed source acceptance.

The public paired gate covers18 distinct cases, with baseline and candidate
observations, export names and code bytes compared exactly. Cases cover erased
constructor fields, U32/F32 literal patterns, mixed readback, empty/non-BMP and
dynamic strings, normalized type aliases, a parameterized dependent-family
alias, invalid-character order, ten user-owned primitive constructor spellings
in one no-Base library, imported ADTs, erased versus live overflowing arguments,
and the dynamic-tail/open-Array refusal. Three cases compare native C bytes;
they do not run Clang and are not additional native execution claims.
Successful JS programs execute; runtime refusals match their precise expected
message/exit, and the library's makers/matcher preserve their named values.

`structure-audit-02/report.json` verifies all24 candidate-versus-baseline ladder
pairs and18 public control pairs. Ladder fixture files live in different output
directories, so only each generated source path is normalized to its verified
identical source SHA for observation comparison. All other metadata and paths
remain exact. The main control pairs use the same physical fixture path and
compare complete observations directly.

## Directional public-emission screen

`structure-matrix-01` runs eight fresh workers in baseline/reuse/lookup/combined/
combined/lookup/reuse/baseline order, CPU1, Node24.18.0, 4MiB stack/4GiB heap and
30s per subprocess. Each variant's validated Base cache is prepared first. The
fixed Nat128 source, runtime, driver, API and worker identities stay unchanged.
Every emitted program is byte-identical and executes to `134n`.

| Variant | Mean public compile request (ms) | Mean JS emitter stage (ms) | Mean process wall (ms) | Maximum RSS (KiB) |
| --- | ---: | ---: | ---: | ---: |
| Phase11 baseline | 3,052.9 | 1,830.5 | 3,397.1 | 188,076 |
| Recognition reuse | 3,097.5 | 1,864.4 | 3,439.9 | 182,628 |
| Local lookup | 1,873.5 | 651.7 | 2,215.9 | 179,540 |
| Combined | 1,875.2 | 650.7 | 2,215.8 | 179,728 |

This is a concurrent directional screen with two samples per variant, not an
exclusive whole-compiler benchmark or confidence interval. Process wall includes
startup/imports and actual emitted execution; the public request ends at JS
output, with an identical wrapper measuring its emitter stage. OS caches are
not flushed. The screen supports the lookup mechanism. It provides no Nat128
speed benefit for recognition reuse, whose value is less code and fewer closed
literal scans. No checking throughput gain or generated-program runtime gain
is claimed; the JavaScript is unchanged.

## Preserved failures and deferred directions

- The first dependent-family fixture used parentheses instead of angle brackets
  for type parameters. Both checked compilers rejected it during parsing.
  `structure-controls-01` and its original tool remain failed. Only that fixture
  was corrected and rerun in `structure-controls-02`; the other17 cases were not
  repeated. The audit explicitly records which observation supersedes which.
- `structure-audit-01` initially required equal fixture paths across independently
  generated ladder directories. Source bytes, output bytes and execution already
  matched; the failure was solely input-path metadata. The original audit/tool
  remain intact. Audit02 permits only the explicit hash-verified fixture-path
  correspondence described above.
- Compact strings and P6-012 annotation bypass were not implemented. The fresh
  root profile does not justify that larger contract/representation change in
  this round. The earlier273-line certificate and forged-native counterexamples
  remain evidence against silently skipping required annotation.
- P6-005 native constant-field retention remains a separate unpromoted historical
  result. It is not included in this source or credited with these measurements.
  P7 semantic-value and unconditional checked-output trials remain rejected.

Six exact historical read inputs, including dirty/untracked Phase6 markdown,
are copied with SHA and working-tree status into `structure-history-01`.
Their originals were neither edited nor staged. Preservation of these consumed
bytes is distinct from claiming those old prototypes were promoted.

## Frozen source and handoff

Only `src/back/js/emit.bend` changes, from951 to943 physical lines and29,222 to
29,121 bytes: **−8 lines, −101 bytes, −1 helper**, no new runtime concepts.
The [patch](../../selfhost/tools/performance/phase12/structure-candidate.patch)
comes from the immutable baseline and checked combined snapshot.

| Artifact | SHA256 |
| --- | --- |
| Baseline JS emitter source | `1bc5354f644fb59a7112ecd1574078bea84a09f5f2a8d0b738daec2590c73d21` |
| Combined checked JS emitter source | `d979511d259305b6ac77bd858137808c3af431a53c7e1cec817e7f68e218f68a` |
| Recognition-only selected API | `c176c8909db4f7f1901864a014d6da2f3fd658d393a718cc2d50327e1c27a14a` |
| Lookup-only selected API | `fa19f8f4850308696ad84dee5cc6b85a2843b95d7f23f37477333fc3188b70cd` |
| Combined selected API | `a00c85240e67d5e94e0dce86135ee08f8331cca5b1054ad13f47a0150adb9bac` |

Evidence paths above are under `selfhost/build/phase12/`. The combined checked
source is `structure-combined-01/attempt/snapshot/src/back/js/emit.bend`.
The maintained `selfhost/tools/performance/phase12/structure-*` tools reproduce
preparation, counters, raw/public controls, audit and screen in fresh directories.
All agent-owned compiler jobs stopped before root integration/final measurements.
Root independently reviewed and integrated the exact preimage/hash-guarded
source; final release evidence belongs in the root Phase12 report.

## First integrated correctness gate

The completed root `integrated-01` selects API
`fcd23771a4e070fb4610d26ce0269e327e1a0d7029bd4f4f354a572219dae479`.
Fresh `final-structure-controls-01` compares it against the unchanged Phase11
baseline on all18 public cases: all36 observations pass, paired observations and
export names match exactly, and JS/native C bytes are unchanged. Actual JS
outputs, library constructors/matcher and expected runtime errors retain their
oracles. The corrected dependent-family fixture is included in this full fresh
gate. `final-structure-raw-01` also passes all seven constructor-selection cases
(including the deliberate malformed-owner difference) and12 emission comparisons.

These are correctness checks, not another timing sample. They test the integrated
combined source and maintained derivative rather than only this owner's isolated
candidate. All compiler jobs ended before evidence preflight and root's exclusive
comparison. The independent full frontend gate subsequently found that this
first integrated derivative overflows the 4MiB stack on the 6,000-character
string case. Thus these passing focused controls do not authorize promotion;
the failed integration remains evidence, and a corrected integration needs fresh
controls. The causal isolation in [calls.md](calls.md#broad-stack-gate-and-causal-ablation)
attributes that fresh-worker failure to the rejected broad choice-lowering
derivative, rather than these JS emitter source changes.

## Second integrated gate: focused passes were insufficient

Root's completed `integrated-02` selects the restricted leaf derivative API
`b132e10300274616b118dcd7daec5d856fa4759e73d7235239f28772129316e4`.
Fresh `final-structure-controls-02` passes all18 public pairs /36 observations
against the unchanged Phase11 baseline, with all input identities verified.
Observations, exports, JS bytes, three native C outputs and actual JS behavior
remain exact. Fresh `final-structure-raw-02` also passes all seven lookup
controls and12 emission comparisons, retaining the documented deliberate
forged-owner difference. Native-byte controls do not compile or execute C.

One short-selection history overflowed the unchanged 4MiB stack on both Phase11
and this candidate. That observation could not waive a different full-suite
history where Phase11 passes. The full `frontend-02` gate subsequently exposed
exactly that regression. Matched 53-request and 60-request histories reproduced
baseline acceptance and candidate failure, with every preceding result exact.
The source ablations then isolated the seed cleanup: seed-only failed while
this owner's JS-only candidate passed. The seed cleanup was rejected. See
[normalizer.md](normalizer.md) and [calls.md](calls.md) for the complete failed
vectors and attribution. Earlier passing component controls remain evidence of
their bounded scope, not release acceptance or general stack safety.

## Final integrated component gate with the original seed

Root's completed `integrated-03` selects API
`0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697`.
Its normalizer source is the unchanged Phase11 implementation; the candidate
combines these JS changes with restricted leaf lowering. No seed optimization
is included or claimed.

Fresh `final-structure-controls-03` on CPU2 passes all 18 public pairs / 36
observations against Phase11, with verified input identities. Complete results,
export keys, emitted JS, three native C outputs and actual JS behavior are exact.
Fresh `final-structure-raw-03` passes all seven lookup controls and 12 emission
comparisons, including the intentionally different forged duplicate-owner case.
These remain correctness gates; the three native rows compare C bytes without
running Clang, and no timing result is inferred.

The public harness now accepts `STRUCTURE_CPU` (default 1) and records it; its
cases and oracles are unchanged. `structure-history-02` preserves the exact
previous harness and owner report. All owner component jobs and report producers
are closed after this gate. Root owns full frontend/backend results, controlled
measurements, release and the eventual explicit evidence freeze.
