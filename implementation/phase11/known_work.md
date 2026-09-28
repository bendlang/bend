# Phase11: using known information to avoid compiler work

Phase11 cuts controlled full-source checking from **51.44 s to 29.73 s (1.73×)**
and resolves the retained deep-Nat native code expansion case: emitted C shrinks
from **20.59 MB to 269 KB**. All 1,001 positive frontend fixtures now check at the
same resource limits; all 482 validation negatives still reject.

The [prospective design](../../design/phase11/known_work.md) was committed before
implementation. It compares against Phase10 `5f561c4` and unchanged pinned
upstream `b2111cf43244e65f76ddc278ee695e669f720cbf`. The checked, derived compiler
is installed as the default; exact identities and preservation are recorded below.

## Evidence and decisions

Independent upstream/Bend comparisons, failed attempts, candidate gates and
controlled results are linked below. The [evidence index](evidence/README.md)
explains exact byte preservation and recovery, separately from compiler verdicts.

## Fresh final-release profile

Installed Phase10 release verification passes before profiling. The unchanged
Phase9 diagnostic runner checks immutable Phase10 `integrated-01` on CPU0 with
10ms samples, Node24.18.0,4MiB stack and4GiB heap. The ordinary type/expected
unsafe-proof-trust gate and all input identities pass. Its instrumented56.09s
process time is excluded from speed ratios. Raw evidence is in
`selfhost/build/phase11/current-profile-01`; historical tool schema names remain.

Exclusive lexical-owner grouping retains runtime/GC separately; it is not logical
inclusive caller attribution and does not measure allocation counts.

| Lexical owner | Exclusive sampled time |
| --- | ---: |
| `(garbage collector)` | 12.51% |
| `run_loop` | 9.83% |
| `$norm_eval_node$` | 5.64% |
| `$lookup$` | 4.46% |
| `run_tail` | 4.41% |
| `$f_find$` | 3.89% |
| `$norm_match$` | 3.29% |
| `$core_subst_stable$` | 2.94% |
| `$index_find$` | 2.80% |
| `$subst$` | 2.80% |
| `$check_node$` | 2.60% |
| `$index_remove$` | 2.04% |
| `$check_ctr_found$` | 1.85% |
| `$norm_max_term$` | 1.62% |
| `$terms_at$` | 1.46% |

The 5196 samples reconcile exactly with the streaming summary. Raw profile SHA-256:
`36a861431f01365cced5498811e39d232f5e44d2ca3169ba206023559ab87069`. Index lookup is now a smaller share; the current
normalization and branch/dispatch costs justify fresh investigations without
assigning old whole-workflow gains to these sample percentages.

## Integration decision

Root independently reviewed and integrated the explicit offload scope guard,
shared constructor telescope, native open-Succ compaction, and guarded version4
choice derivative. The exact-comparison shortcut is deferred: its small and
inconsistent measured benefit does not justify another helper in this release.
Delayed normalizer fallback and eager dead-context rewrites remain unimplemented.

The combined attempt is `selfhost/build/phase11/integrated-01`; exact preimage and
checked-snapshot hashes are in `integration-01/report.json`. Production copies
come from immutable checked snapshots, including the updated maintained transform
regression test. The combined gates and all three controlled comparisons pass;
the maintained release installer preserves the previous default and lineage.

The new `equality` profile name remains a compatibility identifier. Version4 adds
structurally guarded literal choice lowering to existing native string equality.
It preserves the exact runtime/trampoline and public exports. The generated code
creates only the selected branch arrow and bypasses two wrapper constructions;
this is an operation-shape claim, not a measured V8 allocation count. This is an explicit
checked-B1 derivative, not a new bootstrap, self-hosted fixed point, or change to
emitted user-JS behavior. Historical versions1/2/3 retain exact replay.

Independent review and authentic historical replay pass. The initial maintained
helper-generation attempt failed on a replacement-string escaping bug before
promotion; original source, preparation script, bootstrap and error are retained.
Only the corrected callback-based insertion from maintained02 is integrated.

## What rereading TypeScript changed

Three concrete comparisons were useful, without changing the pinned compiler:

1. Upstream `comp.ts`'s `tpl_nat` combines successor increments. Our native
   backend reconstructed each open `Succ` layer through another continuation.
   The [native experiment](patterns.md) keeps the dynamic tail once and lowers
   its known prefix to a bounded offset. Nat300's C falls from 20,589,858 to
   269,358 bytes (98.69%); this changes emitted native code, not just the host.
2. Upstream `term_check` binds an instantiated constructor telescope once. Our
   `check_mat_ctr` computed it twice for the left-hand side and arm goal. The
   [checker experiment](checker.md) shares this immutable result while retaining
   the same unknown-constructor guard and recursive checking order.
3. The checked B1 image builds both branch arrows and two `run_clo` wrappers
   before calling a known Boolean-choice helper. The [call experiment](calls.md)
   proves the relevant generated shapes and selects the raw literal arrow before
   the existing `run_tail` boundary. It transforms 1,190 sites in the final image;
   its runtime, exports, currying and forcing protocol remain unchanged.

The fresh profile also led to the [scope guard](scope_guard.md): make the
offload condition lazy before looking through the declaration book. That change
adds no helper, cache or source line. Operation counts are preserved separately
from timing; no individual hypothesis gets credit for the combined speedup.

The earlier exact-comparison proposal duplicates less work on synthetic deep
terms, but its realistic gains were inconsistent. It is deferred. Delaying the
normalizer's fallback term might avoid allocations, but requires a broader
demand-order audit and was not implemented. The existing first-order core and
checker remain; this phase does not claim an architectural simplification.

## Correctness and the unexpected string improvement

The final combined checked artifact passes all 21 maintained focused controls
(12 known exact reference differences). The full corrected backend selection
passes all 37 rows for both compilers, with three exact diagnostic differences.
Native identity, count, closed-literal and arithmetic controls are described in
the native report. The arithmetic screen includes 136 compiled-C comparisons
covering zero, U32 limits, the 48-bit native Nat cap and malformed U64 tails.
The implementation preserves the first checked increment before adding the
remaining bounded offset; a zero-count underflow in candidate01 was caught and
fixed in the separately checked candidate02 before promotion.

The final frontend run records all 2,996 parse/check observations for 1,498
fixtures. It has no input/adapter drift, worker failures or timeouts. All 1,001
positive programs parse and now accept types; all 482 validation negatives
reject, with zero observed invalid acceptance. The sole change from Phase10 is
`check/string_literal_long.bend`: its previous stack overflow becomes a successful
check. The other 2,995 observations match exactly. There are 730 exact upstream
differences (198 parse, 532 check), and strict checking still has 1,006 passes and
492 failures. The four imported-law fixtures still fail before the intended trust
phase; 7/11 reach that phase and 3/11 have exact expected diagnostics. Four
emission-error fixtures accept types as expected; frontend evidence alone does
not establish their subsequent execution behavior.

The harness's `complete`/`selectedComplete` fields remain false because its strict
fixture gates contain known failures. The orchestration report's `complete:true`
means all requested observations and comparisons finished, not full conformance.
Both representations and the full failed observations are preserved.

[Six fresh isolated string checks](checker-stack.md) repeat the old overflow
twice and the final acceptance twice. A choice-v4-only artifact with byte-identical
Phase10 Bend modules also passes twice. Thus the call/closure change alone is
sufficient for this 6,000-character fixture at the same 4 MiB stack limit.
Its failing trace traverses recursive substitution. This does not establish
compact-string support, exact V8 frame sizes or general stack safety.

The combined artifact also passes all 14 maintained derivation regression groups
and repeats the scope guard's four public families, 24 direct cases and two
explicit malformed-host boundaries. Genuine historical v1/v2/v3 replay passes.
No independent proof kernel, GPU hardware or new self-hosted fixed point was run.

## Costs and retained failures

The same source counter records 59 modules, 15,138 physical / 12,923 nonblank
Bend lines, 496,487 bytes, 1,485 definitions, 793 laws and 63 declared types.
Compared with Phase10 this adds 31 physical lines, 28 nonblank lines, 1,518 bytes,
two helpers and one law. The native pass adds two private `KTerm` tags, `NNatAdd`
and `NNatSum`; a stable declared-type count does not mean no new concepts.
The maintained derivative grows by 34 physical lines and its tests by 16 lines,
adding a guarded transformation/replay obligation. The 50%/75% source-reduction
goals remain open.

Every failed or superseded attempt stays in the evidence selection:

- Native candidate01's zero-count underflow; a malformed host-Boolean identity
  probe; native sandbox launch failures; and corrected rejection-phase oracles.
- Checker component setup initially omitted two maintained tests from a snapshot.
  Corrected controls freeze those actual files and hashes.
- The first scope probe bypassed public elaboration, so its raw parsed book failed
  before comparison. Corrected probes use the full public loader.
- The first maintained transform preparer misused JavaScript replacement-string
  escaping. Its generated bytes and failure are retained; callback insertion fixes it.
- The first call selection copied an incomplete host without `src/compiler.json`;
  its setup failure precedes the corrected fresh selected run.
- Call microbenchmarks and the first tiny release controls had `EPERM` launcher
  errors despite status zero and populated worker files. Their timings and
  status-only pass claim are invalid and excluded. Corrected launchers check
  errors/signals; fresh permitted release controls pass. Same-process operation
  counts remain valid, separately from those invalid timings.
- Root's first final equality-test invocation omitted the report parent directory.
  All 14 groups ran, but the reporting hook failed. `integrated-equality-02`
  reruns with a fresh existing directory, `--test`, retained process logs and an
  explicit passing report; the earlier failure is not counted as a passing gate.
- The first string follow-up wrapper mistook a strict failed-fixture `complete`
  field for missing execution. Its actual overflow observation and failed wrapper
  are preserved; the corrected fresh attempt checks row coverage and identities.

These are compiler, harness and environment failures with different implications;
preserving a run does not turn its verdict into a success.

## Controlled full-source comparison

`selfhost/build/phase11/final-matrix-01/report.json` uses the unchanged Phase9
matrix/Phase8 worker against the exact final assembled source. Node24.18.0,
CPU0, 4 MiB stack and 4 GiB heap are identical. Other intentional compiler,
profiling and archive jobs were paused. Each sample is a fresh process;
separately validated Bend Base caches are prepared, while TypeScript checks Base.
OS caches are not flushed. These are two descriptive samples per compiler, not
a confidence interval or a language-wide benchmark. All launches, source/API/host
identities, ordinary checking and expected unsafe-definition sets pass.

| Serial order | Request (s) | Process wall (s) |
| --- | ---: | ---: |
| TypeScript | 1.681 | 2.731 |
| Phase10 | 50.602 | 51.741 |
| Phase11 | 28.647 | 29.775 |
| Phase11 | 28.548 | 29.682 |
| Phase10 | 50.016 | 51.145 |
| TypeScript | 1.790 | 2.839 |

| Compiler | Mean request (s) | Mean process (s) | Maximum RSS (KiB) |
| --- | ---: | ---: | ---: |
| Pinned TypeScript | 1.736 | 2.785 | 444,552 |
| Phase10 | 50.309 | 51.443 | 1,567,464 |
| Phase11 | 28.598 | 29.729 | 1,458,124 |

The mean process improvement is **1.7304×**, a **42.21%** reduction; request cost
falls **43.16%**. The same-source gap to TypeScript moves **18.471× → 10.674×**.
Request time includes lazy API loading inside the adapter; process wall also
includes startup, hashing and output capture. This is checking/trust reporting,
not emission, self-reproduction or generated-program execution. Do not multiply
earlier different-source ratios into these measurements.

Routine iteration still uses the checked B1/focused path. The recorded combined
build plus all 21 controls spans **23.54 s** from build start to validation end.
That single development observation includes a different workload and is not a
controlled loop-speed ratio. The full frontend integration vector took about
176 s with four persistent workers; it is not required on every small edit.

## Controlled Nat300 emission comparisons

Two additional serial ABBA matrices compare Phase10 and Phase11 on the unchanged
`compile/nat_pattern_deep.bend` fixture, using CPU0, Node24.18.0, 4 MiB stack,
4 GiB heap and separately prepared validated Base caches. Other intentional
compiler/archive jobs remain paused; no profiler runs inside these measurements.
All process-error, deadline, observation and recorded input-identity gates pass.
These workloads are distinct from full-source checking above.

| Workflow | Phase10 mean | Phase11 mean | Improvement |
| --- | ---: | ---: | ---: |
| JS process, including emitted-program execution | 24.450 s | 15.611 s | 1.566× |
| JS compilation request | 23.315 s | 14.478 s | 1.610× |
| Layout validation inside that request | 0.486 s | 0.297 s | 1.636× |
| Native C emission process | 27.032 s | 3.609 s | 7.491× |
| Native compilation request through C emission | 26.660 s | 3.483 s | 7.654× |

`layout-matrix-01` retains every request/result and actual emitted JS execution.
All four outputs are exactly 1,026,258 bytes with SHA-256
`3fc007fa2d90a84800568a7fdc78ba58d6bc5c45a7f96ea8bb3f5972dde947cf`
and return `306n`. This is faster compilation of identical JS, not a faster
user-JS runtime. The matrix's diagnostic layout wrapper is identical in both
variants; it records the stage without changing its returned observation.

`native-matrix-01` retains actual C bytes and the complete native compile
observations. Phase10 emits 20,589,858 bytes; Phase11 emits 269,358 bytes, **98.69%
less**. Maximum observed worker RSS falls 1,139,948 → 355,016 KiB. Within each
variant both C hashes agree; the final C hash is
`98fea0974c8168c4f38e4a90468dd5962b4400608f7b6773bd6bfe635bcec52e`.
Native matrix timing excludes Clang and program execution.

The independent `integrated-native300-01` correctness gate produces that exact
same C hash, builds it with Clang16 `-O3`, and executes it with exact `306n`
stdout. Its observed build time is 2.15 s. Phase10's retained native build hit
the 90 s bound; those build observations are not a controlled Clang speed ratio.
This resolves this program's C expansion/build blocker without establishing
general native runtime superiority or conformance for all programs.

## Release, reproduction and evidence

The installed compiler is a guarded version4 derivative of genuine checked B1,
with `newBootstrap:false`. The runtime, pinned upstream and Base are unchanged.

| Artifact | SHA-256 |
| --- | --- |
| Selected API, 762,897 bytes | `63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f` |
| Genuine checked parent | `707d1307f5019b86648ec86784acbcdddfc9fbd2382d3e52e4bf3a3d4ed2d57d` |
| Assembled final source | `705f1b3bbd7ab304143aace90a6dc0025458421ec5684d225a916311ae71e26e` |
| Output runtime | `1766d6d674f5c64eb481a647fe1d7bf751529d6861d4d4f4697999f005e772f0` |
| Base | `00c751b6cd045361a80f214c9c36bd4ec637e9ec86109b194e55cd57ca63ab94` |

The exact maintained installation is in `install-01`. The previous Phase10 API,
Base and lineage remain under `selfhost/dist/release-history/ff876a357db2d44d3e1fbd37ab694a16d2fa0f47d60c9d500603e634c8c645f9`.
The [compiler guide](../../docs/BEND-IN-BEND.md) and
[development guide](../../docs/PHASE5_DEVELOPMENT.md) describe ordinary use,
rebuilds and the versioned derivation. `npm run verify:release` verifies the
installed source/API/host/lineage, including exact transform replay after relocation.

`release-smoke-01` passes **42/42** checks across the ordinary installation and
a relocated copy: integrity before/after, version, checking, interpretation,
JS emission/execution and native emission/build/execution for Base U32, user
`Clo.apply` and compact Nat fixtures. Child errors are checked alongside exit
status, and all recorded source/release/fixture identities remain unchanged.
The relocated copy has no upstream checkout supplied or created. This proves
that bounded relocation/use case, not OS-level isolation from all historical paths.

The [evidence publication](evidence/README.md) binds all attempts, consumed tools,
complete profiles, observations, timings, final source and release checks. Its
publication record supplies capsule hashes and independent restored-byte/mode
verification. Seven bound historical capsules supply shared objects. Rebuildable
Base caches are explicitly omitted by identity; toolchains remain external
prerequisites. The existing unrelated Phase6 dirty files remain untouched and
unstaged, checked against `start-state.json`.

The most useful lesson is to remove work where the compiler already knows the
answer: demand before lookup, share an instantiated type, choose a branch before
constructing wrappers, and preserve a known arithmetic prefix instead of expanding
it into continuations. Further throughput work should start from a fresh profile
of this final artifact; the earlier profile proportions no longer describe its
cost distribution. Imported-law fills and exact diagnostics remain the clearest
conformance work. No new architectural rewrite is justified by these results alone.
