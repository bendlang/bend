# Phase10: repeated-work investigation

Completed compiler changes, 2026-09-28. The combined release checks the same
final compiler source in **51.75 seconds**, versus **67.04 seconds** for Phase9:
**1.30× faster**, or **22.8% less process time**. Pinned TypeScript takes
**2.89 seconds**, leaving a **17.93× gap** on this checking workload. The deep-Nat
JS workload improves **1.38×** overall; its layout pass improves **19.09×**.
All 2,996 frontend observations remain exactly equal to Phase9. Conformance and
peak-memory gaps remain; this is a bounded speed improvement.

The [prospective design](../../design/phase10/repeated_work.md), committed as
`1449aaf` before integration, defines the baseline, hypotheses and release gates.
The production baseline for this comparison is Phase9 commit `f21e9f0`.
Separate [membership](membership.md), [layout](layout.md) and [index/overhead](overhead.md)
reports retain component evidence, failed attempts and scope limits.

## Integrated changes

### Loader: make the guards conditional

Alias ambiguity checking used a Boolean conjunction whose operands are evaluated
eagerly in this compiler pipeline. It searched for both spellings even when no
alias changed the name. Membership itself used an eager disjunction, continuing
through constructors and the remaining declaration list after a successful hit.
Two expression changes use the existing conditional helper instead. There is no
new cache or name representation and no added source line.

For valid two-module inputs with 4/8/16/32 ordinary declarations per module,
visited list cells change from 294/902/3,078/11,270 to 14/26/50/98. Alias-only and
scanner-only counter ablations distinguish the mechanisms. Real alias changes
still perform ambiguity checks; missing names still search the relevant scope.
These are operation counts, not elapsed-time factors. The complete public loader,
trace, provenance and checking observations agree on 16 additional cases, including
acceptances and existing import refusals. The final integrated compiler repeats
that exact gate successfully. See [membership](membership.md).

The early returns preserve membership for finite well-typed data. Two malformed
private JavaScript-object controls intentionally have different demand: an unused
null scope/tail is no longer visited. They are recorded explicitly; arbitrary
host-injected objects, getters, cycles and resource failures are not covered by
the valid-source equivalence argument.

### Index: expose the loop to the existing compiler

The persistent exact-name index is unchanged. Its lookup previously expressed
each branch as a pair of closures passed to `kc`. The final-source profile
identifies lookup itself as a substantial cost. Three small workers receive
Boolean parameters and match directly; the child selector also matches directly.
On the pinned upstream emitter, the mutually tail-recursive workers become one
`for`/`switch` loop. This removes repeated closure/trampoline construction on the
lookup path without editing generated output or changing the runtime.

The syntactically shorter proposal to match a locally computed Boolean still
fails in pinned upstream; its checked rejection is retained. The surviving source
adds 36 physical lines, 33 nonblank lines and three helpers. Hashing, collision
buckets, insertion order, duplicate selection and source event lists stay intact.
All 5,769 persistent/collision controls and 21 malformed/demand/deep controls pass,
including a 10,000-level tree. Complete observations on the maintained 21 public
cases match Phase9. Eight fresh ABBA/BAAB component workers measure 1.77–2.21×
full lookup improvements for 16/256/4,096-entry indexes. This concurrent component
screen is separate from the controlled full-source comparison below.
See [overhead investigation](overhead.md).

### Layout: use known types and traverse each Nat layer

Deep patterns reconstruct overlapping default-arm terms. Their layout validation
searched the entire book for each constructor and repeatedly tried to recognize
open Nat suffixes as complete literals. The two costs have separate checked
ablations and a combined implementation in `back/js/validate.bend`.

Typed constructor lookup uses the normalized expected ADT to find its own
constructor telescope. Unknown/missing shapes retain the general fallback.
For native Base Nat, exact Zero/Succ arities permit ordinary field traversal
without recognizing the whole suffix. Dynamic tails are still visited, including
their executable dependencies. The implementation retains type specialization,
erased/live field rules and open-Array validation; it does not skip the layout gate.

At depth128, the combined probe removes 3,890,640 whole-book constructor-search
calls and 366,016 failed Nat-recognition calls, preserving all 17,302 layout term
visits. The source adds 21 lines and two helpers. Independent review confirms
the checked-book uniqueness/provenance invariant. One malformed unchecked book
with duplicate constructor names intentionally differs, and is retained rather
than advertised as raw-API parity. Existing layout acceptances/refusals, dynamic
tails and emitted JS bytes remain exact in the isolated controls. The added
combined witness checks successfully but still refuses emission when a Succ tail
calls a function that reaches an open-Array allocation.
See [layout investigation](layout.md).

Nat300 JS executes correctly. Native emission succeeds but produces approximately
20.59 MB of C; Clang16 at `-O3` reaches the 90-second bound. This remains a failed
native build observation, not a native execution pass. Nat32 native execution
passes. The earlier Phase9 deep-pattern timeout is not reproduced under the
current JS conditions: the current baseline also completes. The controlled
comparison must therefore report measured improvement, not claim a newly repaired
timeout or transfer old concurrent durations into its ratio.

## Final gates and controlled measurements

The final `integrated-01` compiler passes the maintained 21 selected controls,
with the same 12 known exact TypeScript differences. Its checked build plus
focused validation completes in one observed 26.19-second development interval;
this concurrent observation is not a controlled developer-loop speedup claim.

The fresh full frontend gate completes all 2,996 parse/check observations for
1,498 fixtures. Every observation matches the preserved Phase9 vector exactly:
zero changed rows, zero missing rows and no timeout. The same-pin TypeScript
reference is reused and its fixture/target identities are checked; this is not
a claim of a newly rerun full reference sweep. Positive parse acceptance remains
1,001/1,001; positive type acceptance remains 1,000/1,001. All 482 validation
negatives determinately refuse, with zero observed invalid acceptances. Strict
checking remains 1,005 passes / 493 failures. Exact upstream differences remain
731, comprising 198 parse and 533 check differences.

The long-string stack overflow and four imported-law trust cases that fail early
are unchanged. Seven of eleven trust refusals reach the intended phase; three
match exact output. No Lean kernel verification is claimed. These gaps remain
visible even though the optimization regression comparison passes exactly.

The final integrated artifact also passes 16 complete loader/import observations
against Phase9 and 26 layout observations (13 exact pairs). The latter retain
open-Array refusals, erased/dead paths, dynamic Nat tails and exact emitted JS;
applicable emitted programs execute their expected results. Nat300 gets the
separate controlled compile-and-execute matrix below. Initial invalid import
fixtures, provenance-argument mistakes, custom-Nat oracle errors, malformed-data
boundaries and the native Clang timeout remain in the individual reports and
evidence rather than disappearing from the experiment history.

The controlled same-final-source comparison improves process wall by **1.30×**:
**67.04 s → 51.75 s**, a **22.8% reduction**. Pinned TypeScript takes **2.89 s**,
leaving a **17.93× process-wall gap** (23.23× for the Phase9 artifact on this same
new source). Request times have a different boundary: the final request is
50.556 s versus TypeScript's 1.808 s, about 27.97×.

| Compiler | Mean request | Mean process wall | Maximum observed RSS |
| --- | ---: | ---: | ---: |
| Pinned TypeScript | 1.808 s | 2.887 s | 421.8 MiB |
| Phase9 | 65.849 s | 67.045 s | 1531.7 MiB |
| Final Phase10 | 50.556 s | 51.751 s | 1535.5 MiB |

All six retained rows, in actual execution order:

| Compiler | Request | Process wall |
| --- | ---: | ---: |
| typescript | 1.790 s | 2.873 s |
| baseline | 65.765 s | 66.959 s |
| candidate | 50.605 s | 51.810 s |
| candidate | 50.507 s | 51.691 s |
| baseline | 65.932 s | 67.131 s |
| typescript | 1.826 s | 2.901 s |

Fresh processes run serially on CPU0, in TS/baseline/candidate/candidate/baseline/TS
order. All other intentional compiler and archive jobs are paused. Node is
24.18.0, stack4MiB, heap ceiling4GiB, per-child deadline600s. Each Bend compiler
uses its own validated disk Base cache; TypeScript checks Base. OS caches are not
flushed. Request time includes adapter probing/lazy API loading; process time
also includes startup, hashing and capture. The worker excludes emission.

All six rows pass ordinary type acceptance and the expected unsafe proof-trust
refusal, with the same complete unsafe-definition set. Source/API/Base/runtime/
host/harness identities are verified before/after; no failed row is excluded.
The same final assembled source is supplied to every compiler. Two samples per
variant are descriptive, not a confidence interval. Memory remains about 1.5 GiB
for Bend; no allocation or peak-memory improvement is claimed.

The result measures the combined release; component/count ablations do not assign
fractions of the full-source gain to individual changes. This comparison uses
new final source, so historical Phase9 66.84s/2.94s values and earlier full-
compilation ratios must not be substituted into its ratios. Complete raw evidence
is under `selfhost/build/phase10/final-matrix-01/`.

The independent Nat300 JavaScript matrix runs baseline/candidate/candidate/baseline
serially on CPU0, with Node24.18.0, 4MiB stack, 4GiB heap and a 90-second deadline.
It explicitly prepares each variant's validated Base cache before timing and
pauses other intentional compiler/archive work. All four runs pass exact public
observations, produce the same 1,026,258-byte JS (SHA-256
`3fc007fa2d90a84800568a7fdc78ba58d6bc5c45a7f96ea8bb3f5972dde947cf`), and execute
with exactly `306n` plus newline. Inputs remain unchanged.

| Nat300 JS boundary | Phase9 mean | Phase10 mean | Speedup |
| --- | ---: | ---: | ---: |
| Layout pass | 9.475 s | 0.496 s | 19.09× |
| Public compilation through emitted JS | 32.914 s | 23.488 s | 1.40× |
| Process, including startup and emitted-program execution | 34.169 s | 24.742 s | 1.38× |

Process samples in actual order are 34.379/24.793/24.690/33.959 seconds. Two samples
per variant are descriptive, not confidence intervals. This isolates a different
workflow from full-source checking; neither ratio replaces the other. Identical
emitted bytes do not establish faster generated-program execution. The separate
native Nat300 Clang timeout remains unresolved. Complete records are in
`selfhost/build/phase10/layout-matrix-01/`.



## Release, source size and preservation

The integrated source has 15,107 physical / 12,895 nonblank Bend lines across
59 modules, 494,969 bytes, 1,483 definitions, 792 laws and 63 types. Compared with
Phase9 this adds 57 physical lines, 52 nonblank lines, 1,712 bytes and five helpers;
there is no new core type or index representation. Declaration/line counts do
not prove conceptual complexity, and the earlier 50%/75% reduction goals remain
unmet. The selected generated API is 755,713 bytes, versus 750,872 previously.

The selected API from immutable `selfhost/build/phase10/integrated-01` is installed
as the default. The installer verifies the checked source/host/recipe identities
and exact equality derivation; it preserves the previous Phase9 release under
`dist/release-history/d27968f11fa322bf3685ff0d276d9577a3b589b9cbae80784f5e4d404f7c3529/`.

| Artifact | SHA-256 |
| --- | --- |
| Selected/default API | `ff876a357db2d44d3e1fbd37ab694a16d2fa0f47d60c9d500603e634c8c645f9` |
| Genuine checked parent | `ae802300026df1d242b94cba8b3332960454abf6a7309385c69d10153bad27d7` |
| Assembled Bend source | `d7e5c7c4897b6a8c95e3eedc6bebc0fcc0496c28d9a1c49eaa4197edb0e7a661` |
| Unchanged runtime | `1766d6d674f5c64eb481a647fe1d7bf751529d6861d4d4f4697999f005e772f0` |
| Unchanged Base | `00c751b6cd045361a80f214c9c36bd4ec637e9ec86109b194e55cd57ca63ab94` |

The final installed/relocated smoke run passes **42/42** steps. Both locations
verify release integrity before/after and run the three Base-U32, user-owned
`Clo.apply` and compact-Nat boundary programs through `--check-only`, interpreter,
JS emission/execution and native emission/build/execution. It clears Bend/Node
configuration overrides and copies no upstream checkout. Relocation is observed
behavior, not an OS filesystem-isolation claim. Source, fixture and copied-file
identities stay unchanged. The final API separately emits, builds with Clang16
and runs the Nat32 witness with exactly `38n` plus newline.

`release-install-01`, `release-smoke-02` and `integrated-native32-01` retain those
records. The first `release-smoke-01` run retains its six native-launch `EPERM`
failures (36 steps, 30 passes); the identical runner succeeds in a fresh directory
with permitted execution. No failed record is overwritten. This is a checked B1
with the existing guarded equality derivative, `newBootstrap:false`; there is no
new B1→H→H fixed point, Lean proof or GPU validation.


The [evidence index](evidence/README.md) explains the
[final capsule](evidence/capsule-01/manifest.json), required historical capsules,
external toolchains, omitted rebuildable caches and exact recovery commands.
[Publication](evidence/publication.json) records capture, byte verification and
independent restored-file/mode checks. It preserves the raw CPU profile, complete
frontend vector, all measured rows, original rejected/malformed probes, isolated
checked candidates, final source/API/lineage and both failed and successful
release checks. Historical unavailable inputs remain explicitly labeled; archive
success does not upgrade any compiler verdict. Unrelated live Phase6 work is not
part of this promotion.


## Baseline profile that selected the work

The fresh `current-profile-01` diagnostic run completes with unchanged input
identities and the expected ordinary-type/unsafe-proof-trust result. It uses
10 ms sampling on CPU0 and retains 6,547 samples. Its 71.17-second process wall
is instrumented and potentially concurrent; it is not a replacement for the
Phase9 controlled 66.84-second measurement.

A small lexical-owner summary groups anonymous generated closures under their
enclosing top-level function. This is exclusive lexical ownership, not logical
caller attribution: GC and runtime dispatch remain separate. All sample counts
and weighted time reconcile exactly with the streaming summary.

| Owner | Exclusive sampled time |
| --- | ---: |
| `(garbage collector)` | 12.19% |
| `$index_find$` | 12.07% |
| `run_loop` | 9.58% |
| `run_tail` | 5.38% |
| `$norm_eval_node$` | 4.51% |
| `$lookup$` | 3.99% |
| `$f_declared$` | 3.24% |
| `$f_find$` | 2.84% |
| `$core_subst_stable$` | 2.60% |
| `$check_node$` | 2.42% |

The baseline profile redirects the overhead investigation toward index traversal.
The two largest anonymous `index_find` frames alone account for 11.23%; its
complete lexical group is 12.07%. This establishes a target for discriminating
source probes, not the amount of whole-compiler time an optimization will save.
The retained profile SHA-256 is
`d26c4e1931c0f42d7d66daa7690d10ebcb21273b7703e03c96eabdf7e06fb071`.

The production release verified successfully before profiling, with the same
Phase9 API/source identities specified in the design. No source changes were
needed for these observations.

## Lessons and next bounded work

The useful common pattern is work avoided before allocation: do not ask a
membership question when the alias did not change; express a hot recursive
branch in a form the pinned emitter can make into a loop; use a constructor's
already-known type instead of rediscovering it by scanning the entire book.
The layout result also shows the limit: removing nearly all of one pass's cost
produces a smaller whole-compilation gain because other work remains.

A future speed phase should start with a fresh profile of this final artifact.
The old profile no longer establishes its hottest functions. Reconstructed deep
pattern terms and the 20.59 MB native output are concrete candidates for reducing
both work and output size; they require new semantic and emission controls.
Compact string representation and imported-law fills remain the separate
conformance priorities. Preserve the short checked-build loop, exact regression
vectors and serial integration measurements instead of using full self-emission
as the routine feedback cycle.
