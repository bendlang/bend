# Phase12: reuse checked structure and preserve cheap call boundaries

The [design](../../design/phase12/avoidable_work.md) repeats the previous
profile–count–ablate–validate–measure process on released Phase11 `f8244c9`, with
upstream `b2111cf43244e65f76ddc278ee695e669f720cbf` unchanged. The selected compiler
keeps typed constructor lookup and literal reuse in the JS emitter, plus a narrow
version5 calling transformation in the maintained checked-B1 derivative. It
rejects both the normalizer seed cleanup and broad returned-branch inlining.

The compiler is installed as the default after the full correctness gates and
three controlled comparisons. Checking takes9% less time, deep-Nat JS compilation is
1.99× faster, and native emission is1.33× faster than Phase11 on the measured
workloads. Generated JS/C bytes stay unchanged.

## Selected implementation

The [JS investigation](known_structure.md) reuses facts the compiler already has.
Three nonliteral field-traversal sites use the constructor's normalized ADT and
the existing `j_layout_ctor`, instead of searching the whole definition book.
Unknown types and missing local constructors retain the general search. A checked
book gives constructors unique owners; intentionally ambiguous raw host books
are outside this equivalence boundary. Constructor entry also reuses its computed
literal text. Recognition still happens at the original point, and nonliteral
field work stays delayed. One wrapper disappears; no cache or representation is
added. Repeated normalization of nonliteral types remains.

The [call investigation](calls.md) extends guarded literal choice lowering to
`nt_choose`, then removes a restricted set of returned branch closures. Each
branch must be a single return without nested call work. A terminal generated
call is eligible only with call-free arguments; it returns the existing `$JMP`
message so the original trampoline performs the call. Other branches keep their
closure boundary. Condition evaluation, Unit capture, argument order, lexical
bindings and public forcing are preserved within the reviewed generated-code
contract. Optional calls are recognized and excluded from call-free arguments.
Unsupported protected bindings or lexical dependencies fail closed. No runtime
bytes or public wrappers change; private unforced message identity, reflection
and modified JavaScript prototypes are outside this contract.

The final API has 1,419 lowered literal choices, 164 returned branch blocks and
161 deferred generated calls; 1,033 branches keep the prior boundary. Historical
versions1–4 replay their authentic original artifacts exactly. This remains an
explicit derivative of a genuine checked B1, not a new self-emitted fixed point.

## Evidence that selected the changes

A fresh profile of unchanged Phase11 on CPU0, Node24.18.0, 4MiB stack and 4GiB
heap records 2,929 samples. Its instrumented 32.467s process is excluded from
speed ratios. Lexical exclusive owners are `run_loop`14.26%, GC13.75%,
`norm_eval_node`5.20%, `lookup`4.59%, `index_find`3.31%, `f_find`2.92%,
`norm_match`2.70%, `check_node`2.67%, `subst`2.46%, `update`2.24%, and
`index_remove`1.87%. These do not assign all allocation/runtime time to any
particular optimization. Raw profile SHA-256:
`f61c41949cb2b86b07aff19c27ad091242dda877a28b1326c563c822b2e91ba1`.

The JS ablations separately check literal reuse, typed lookup and their
combination. Nat64 reduces recursive constructor-search entries from 1,991,952
to 61,248, a 96.9% reduction in that counter. String recognition is halved on the
measured 8/16/32/64 ladders. Thirty-two emitted ladder programs retain exact bytes
and execution results. An eight-process, reversed-order Nat128 diagnostic gives
3052.9ms baseline, 3097.5ms literal-only, 1873.5ms lookup-only and 1875.2ms combined.
Those concurrent screening times selected a candidate; they are not the final
performance comparison.

Early broad call controls reduce runtime message counts, but their reductions
do not describe the narrower released transformation. The narrow leaf diagnostic
checks the same source in A–leaf–leaf–A order at 29.759s versus 27.020s mean
process wall. This concurrent diagnostic includes the subsequently rejected seed
change in both arms and is likewise excluded from the final speed claim.

## Rejected work and the stack counterexample

The [normalizer report](normalizer.md) preserves two proposals. Delaying fallback
spine reconstruction adds a protocol for a small, noisy diagnostic gain and is
deferred. Reusing the input term instead of allocating initial `Absent` looks
simpler and passes finite demand/boundary controls. It nevertheless regresses a
real resource boundary, so the original normalizer is restored byte-for-byte.

Both initial integrations pass focused/component/backend gates but fail the full
frontend corpus on `check/string_literal_long.bend`; the other 2,995 observations
match Phase11. `integrated-01` uses broad branch inlining plus the seed cleanup;
`integrated-02` narrows inlining but still includes the seed. Neither is released.
The first frontend tool only recorded completed coverage. Its exact consumed
version is preserved, and subsequent gates require exact baseline observation
equality. Capture completion never upgrades those failed candidates to passes.

A standalone string check was insufficient: seed-only passes four fresh-worker
checks, while replaying the exact 53-request history produces a stack overflow
for seed-only and success for baseline and JS-only. All 52 preceding results are
byte-exact. Current-source v4, native-choice-only and leaf variants with the seed
also fail that history. Replaying the old 60-request history reproduces baseline
success and seed-containing candidate failure. This establishes a source-level
operational regression under controlled history; it does not prove its internal
V8 cause.

Broad inlining has an independent problem. Rebuilding it from the JS-only checked
parent, with the original normalizer restored, still fails both a fresh string
check and the matched 53-request history. Bytecode inspection finds larger
frames, including `check_node`40→248bytes and `tele_check_static`48→136bytes;
these are interpreter-frame observations, not optimized machine-stack proof.
Removing declarations or unused Unit bindings does not fix that candidate.
Broad inlining stays rejected. The final no-seed leaf compiler passes both
53- and 60-request histories with every predecessor exact and the same 4MiB limit.

The long-string witness is added to the maintained selection, before its prior
21 cases. Appending it after those cases also overflows Phase11, a separately
retained inherited history boundary. Running it first preserves a meaningful
fresh-worker comparison. Neither ordering is evidence of general stack safety;
the full corpus and both matched histories remain independent integration gates.
Cold stack-hook experiments that fail even on baseline and invalid launcher
observations remain excluded from causal or performance claims.

## Final correctness and usable release

Selected attempt: `selfhost/build/phase12/integrated-03`.

| Identity | SHA-256 |
| --- | --- |
| Selected API, 766,097 bytes | `0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697` |
| Genuine checked parent | `a8453133f37a0965b7291795af2e06c7c65e3ee7c97a8ff4b14b98cfba2e5568` |
| Assembled Bend source | `828e6f650faf5bfb5fb1974f49facb6aaca850d2e002cb3afec8adc1335b2825` |
| Maintained derivation helper | `84a065f61b9c6c6c1ebd8cdfe10dca1a8017f40d19302a84515e1c3a2cc356d9` |
| Runtime, unchanged | `1766d6d674f5c64eb481a647fe1d7bf751529d6861d4d4f4697999f005e772f0` |
| Base, unchanged | `00c751b6cd045361a80f214c9c36bd4ec637e9ec86109b194e55cd57ca63ab94` |

The final frontend gate completes all 2,996 observations over 1,498 fixtures and
requires exact agreement with Phase11. All 1,001 positive programs check and all
482 validation negatives reject, with no observed invalid acceptance or timeout.
There remain 730 exact TypeScript differences (198parse, 532check), and strict
checking has 1,006 passes/492 failures. Seven of 11 declaration-only trust cases
reach the proper phase; four imported-law fills still fail early. Semantic
acceptance, proof trust, exact diagnostics and full-language conformance remain
distinct. No proof kernel or GPU gate is claimed.

Final controls pass 22 focused cases, 16 maintained derivation groups, five
current/historical replay checks, 30 normalizer boundary cases with 93 assertions,
18 paired public structure cases, seven lookup controls, 12 raw emission controls
and a 37-row paired backend selection (three existing exact differences). These
sets overlap and are not additional unique language fixtures. Native Nat300 is
actually emitted, built with Clang16 and run to `306n`. The first final backend
launch omitted `CC`, leaving both compilers' native lanes unsupported; its failed
attempt is retained, and `backend-04` reruns unchanged gates with explicit Clang.

The selected API is installed under `selfhost/dist/`; the original Phase11
release and lineage are retained in `dist/release-history/63c861e9…`.
All 42 ordinary/relocated CLI checks pass, covering integrity before/after,
version, checking, interpretation, emitted JS execution and actual CPU build/run
for Base-U32, user `Clo.apply`, and compact Nat fixtures. The relocated package
copies no upstream checkout and removes `BEND_*` environment overrides. Original
bootstrap paths remain historical data, not a new relocated proof. Use the
[compiler guide](../../docs/BEND-IN-BEND.md); `npm run verify:release` verifies
installed integrity and lineage, while `npm run build` makes a fresh checked
attempt and runs the maintained focused gate.

## Controlled performance

All timing processes run serially on CPU0 with other intentional compiler and
archive jobs paused, Node24.18.0, 4MiB stack, 4GiB heap and per-API validated Base
caches. OS caches are not flushed. Same-source checking uses unchanged Phase9
tools in TS–old–new–new–old–TS order; JS and native emission use old–new–new–old.
Every row passes launch, input-identity and semantic checks. Means have two
samples per compiler, so these are bounded workflow measurements.

| Workload (mean process wall) | Phase11 | Phase12 | Improvement |
| --- | ---: | ---: | ---: |
| Complete final source: checking/trust, no emission | 29.558s | 26.897s | 1.099×; 9.00% less time |
| Nat300 JS compilation workflow | 15.728s | 7.902s | 1.990×; 49.76% less time |
| Nat300 native C emission | 3.713s | 2.784s | 1.334×; 25.02% less time |

Pinned TypeScript checks the same final source in **2.855s**.
The remaining process ratio is **9.421×**, versus
10.353× for Phase11 in this matrix. Bend reuses validated disk
Base caches while TypeScript checks Base; this is a workflow comparison.
Checking request time is 28.431→25.775s; maximum recorded RSS is
1,440,260→1,374,620KiB. Both candidate samples improve over both controls.
The planning estimate of1.2–1.5× is not reached for full-source checking.

JS request time is 14.576→6.770s. Process wall includes startup,
loading and execution of emitted JavaScript. All four generated outputs are
identical at1,026,258bytes, SHA-256
`3fc007fa2d90a84800568a7fdc78ba58d6bc5c45a7f96ea8bb3f5972dde947cf`, and return306n.
Native request time is 3.595→2.660s; its timing excludes Clang
and program execution. All four C outputs remain identical at269,358bytes,
SHA-256`98fea0974c8168c4f38e4a90468dd5962b4400608f7b6773bd6bfe635bcec52e`;
the separate actual native gate builds that output and returns306n.
These are compilation gains, not faster generated user programs or a new code-size
reduction. Historical ratios are not multiplied into an unmeasured aggregate.

Raw matrices: `check-comparison-01`, `js-comparison-01`, and
`native-comparison-01` under `selfhost/build/phase12`, recovered through the
[evidence capsule](evidence/README.md).

## Complexity and iteration cost

Only the ordered linked Bend modules are counted, using the unchanged Phase10
counter against both frozen attempts. The compiler remains 59 modules and moves
from 15,138 to 15,130 physical lines, 12,923 to 12,916 nonblank lines, and 496,487
to 496,386 bytes. Definitions decrease 1,485→1,484; laws remain793 and types63.
No new compiler representation is introduced. The separately maintained host
transformation grows 23 physical lines/5,802bytes; its regression tests grow
37lines/4,368bytes. Physical line counts therefore do not describe all complexity:
version5 adds a guarded transformation and its validation obligations. The old
50%/75% simplification targets remain open.

The final genuine checked build plus 22 focused cases spans 27.591seconds in the
recorded attempt. This is an observed development loop, not a paired speedup;
Phase11's recorded loop used 21 cases. Use that short workflow for routine edits.
Preserved worker histories make the costly string regression reproducible in a
bounded prefix instead of repeated full-corpus runs. Keep full-source and broad
backend gates for integration.

## Preservation and next frontier

The [evidence index](evidence/README.md) explains recovery of exact source, APIs,
checked proofs, profile, plans, frozen tools, failures, observations and emitted
programs. Its [publication record](evidence/publication.json) binds the final
capsule and independent byte/mode recovery; capture is separate from every
correctness verdict. Eight prerequisite capsules, Node/Clang/toolchain identities
and omitted rebuildable Base caches are explicit. Failed preflights are retained.
Unrelated Phase6 dirty work is excluded and its original 75 hashes are preserved.

This round supports typed local lookup and carefully limited allocation removal.
It also shows that fewer allocations can worsen effective stack behavior: a
small source edit and broad inlining each failed real programs despite local
semantic tests. Further speed work should profile this final artifact and retain
both fresh and matched-history stack controls. Do not revive the rejected changes
without a new mechanism and a cheap falsifying test. Imported-law semantics and
exact diagnostics remain independent priorities. No new H→H fixed point or
universal generated-program runtime gain is claimed.
