# Phase12 normalizer investigation

**Reject initial fallback reuse; defer delayed reconstruction.** The seed-only
cleanup passes narrow controls but regresses the long-string resource boundary
under an exactly replayed worker history. The larger protocol does not earn its
added complexity in the concurrent full-source screen. Neither proposal is
recommended for production. No reliable isolated speedup is claimed.
The [prospective experiment](../../experiments/phase12/P12-002-normalizer.md)
is restored byte-for-byte to its original plan; outcomes are recorded here.
Production source and distribution remain unchanged by this owner.
All abbreviated build paths below are under `selfhost/build/phase12/`.

## Initial construction/use counts

`normalizer-counts-01` passes 12 controls on the unchanged Phase11 compiler:
five raw successful calls and five valid parsed/loaded/checked proof programs at
arities 0/1/4/16/64 each construct one reference fallback, traverse exactly that
many arguments, then never consume it. Two raw stuck/Efq controls each construct
and consume exactly one fallback. These actual helper counts do not measure
allocations or predict a whole-compiler speedup.

## Isolated delayed-spine candidate

`normalizer-candidate-01` changes only `src/core/normalize.bend`: a pending
fallback is a List whose head is the original reference and whose tail shares
the original arguments. `norm_restore(left,spine)` reconstructs it through the
unchanged `norm_apply` only when pending arity is nonzero. Existing `norm_stuck`
and all `graph.bend` calls retain their materialized KTerm interface. There are
13 additional physical lines, 12 nonblank lines, 506 bytes and one helper, with
no new law, declared type or core term tag.

The initial Nil fallback is never restored with nonzero pending arity through
public `wnf`: zero pending arity remains zero until `norm_ref` installs its own
nonempty fallback spine. This invariant excludes arbitrary calls to the internal
evaluator with inconsistent state. Nested references intentionally replace the
earlier fallback, as in the baseline.

`normalizer-checked-01` is a genuine checked B1 workflow followed by maintained
v4 derivation. It passes 21 focused controls, with 12 retained exact TypeScript
differences. Its selected API is
`bb7c19dcacb1ec55c3fe380ec87b53206e2330753d0f85a23f6b5fcbb5e94e24`.
Its completed exact observation, private boundary and diagnostic performance
gates are recorded below. The original B1 sidecar, frozen source and maintained
derivative records remain distinct; no self-hosting fixed point is claimed.

## Retained harness failure

`normalizer-controls-01` passed all 26 finite exact normalizer cases and four
bounded demand/host-boundary cases before the supplementary prior checker gate
failed. The export-only control view mistakenly exposed `infer` with three
arguments; the actual function takes five. The baseline itself then lost the
requested erased-demand argument. This is a harness arity error, not a candidate
failure. The original tool is retained as `normalizer-controls-01/tool.mjs` with
all observations and child logs. The corrected five-argument export passes in
fresh `normalizer-controls-02`; the earlier attempt remains failed. No compiler
algorithm changed to fix the harness error.

## Initial fallback reuse: retained prospective rationale

Written before building or probing this ablation. The invariant above permits
an even smaller change independent of delayed reconstruction: baseline `wnf` can
pass its original input `t` as the initial KTerm fallback instead of constructing
`atom("Absent")`. That value cannot be observed while pending arity is zero;
every transition that makes pending arity positive also replaces the fallback.

The planned ablation changes only that expression, preserving the original
fallback type and all evaluation functions. It adds no line, helper, type or tag.
Compare its actual checked artifact and the delayed-spine artifact separately
against Phase11, so a gain from deleting the initial unused allocation is not
misattributed to the added delayed-spine representation. Required discriminators
are the same exact weak-normalization/demand controls, original focused public
observations, and a bounded no-reference/short-call/public-proof size screen.
This is a prospective opportunity, not a measured or promoted result.

The paragraph above preserves the pre-execution rationale. Its original report
bytes are retained in `normalizer-seed-candidate-01/prospective-report.md`;
completed outcomes and the subsequent integration decision follow.

## Actual artifacts and exact observations

Both isolated variants are genuine checked B1 builds followed by the maintained
v4 derivation, not generated algorithm substitutions or fixed-point builds.

| Object | SHA-256 |
| --- | --- |
| Phase11 baseline API | `63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f` |
| Seed-only selected API | `2d8df40471f8f9342b752323d82db03d0f9d45862bf62adf343fb9bff88f320e` |
| Baseline normalizer source | `8d4deb08685dfd9284850afb478ce5b30674f1fe53c4a7144f481f2bf4ed10ec` |
| Delayed-spine source | `51e8e3705416ef1317d1c6f48f2856ba6032df93071f99faf9a83d4f61018219` |
| Seed-only source | `9206f76b080ae5898f783188ac8551cf630e620352bfe113fb9ec2376547ccf4` |

The rejected seed-only frozen file is
`normalizer-seed-checked-01/snapshot/src/core/normalize.bend`. The exact change is
`norm_eval(book, t, Nil{}, 0, atom("Absent"))` →
`norm_eval(book, t, Nil{}, 0, t)`: 13 fewer bytes, zero added physical/nonblank
lines, helpers, laws, types or tags. Exact source preimages and replacements are
in both candidate manifests. Neither candidate is recommended for integration.

Both actual checked workflows pass the same 21 focused controls with 12 known
exact TypeScript differences. `normalizer-observations-01` separately verifies
all 21 complete candidate result/verdict/evidence objects against the original
Phase11 observations for each variant, including diagnostics and type/trust
metadata. Acceptance-only agreement is not substituted for that exact gate.

## Private controls, demand and counted mechanism

`normalizer-controls-02` and `normalizer-seed-controls-01` each pass:

- 26 exact finite term controls covering opaque/foreign/under-applied references,
  matching/default arms, Efq, partial and extra applications, original head
  metadata/argument order/raw scrutinees, nested fallback replacement,
  constructor fields extending pending arity, annotations, rewrites and lets.
- Two returning demand controls: unused omega stays unforced; an early stuck
  match preserves a later omega unchanged. A demanded omega reaches the same
  1.2-second child deadline in both variants. Its loop binders have distinct IDs.
  Timeout agreement is a bounded observation, not a termination theorem.
- One explicit reflective-host boundary: private `norm_ref` receives an argument
  spine whose tail getter throws on its third read. Baseline and seed-only throw;
  delayed-spine reads it twice and succeeds. Finite immutable compiler data have
  no such getter. Arbitrary host/proxy/malformed-value equivalence is excluded;
  cyclic and malformed spines were not exhaustively explored.
- The same 43 kernel, 31 normalization and 19 prior checker-demand assertions:
  **93 distinct maintained assertions**, repeated across variants. They include
  divergent reflexivity, arity-before-demand, binder capture, quantity/context
  boundaries and shared demands. The existing private unvalidated-goal
  prerequisite remains unchanged.

These controls use export-only views of actual checked APIs. They append wrappers
around existing functions without changing compiler bodies. They are not installed
artifacts or independently checked component builds. Original/view/tool/input
identities and complete child status/error/signal/output records are retained.

`normalizer-delayed-counts-01` passes 13 instrumented candidate controls: ten
successful raw/public calls now reconstruct zero fallbacks; needed stuck and Efq
cases each reconstruct exactly one. A zero-pending stuck case enters the restore
adapter once and reconstructs none, retaining its ignored Absent construction.
These helper/spine counts are neither allocation nor timing measurements.

## Concurrent full-source screen and decision

Root requested the same-source screen before accepting additional protocol cost.
`normalizer-screen-01` uses baseline → seed → delayed, followed by reverse order
in `normalizer-screen-02` because the initial difference was small. Each row is a
fresh Node24.18.0 process on CPU2 with 4 MiB stack and 4 GiB heap, the unchanged
Phase8 check-worker, verified Base cache, and identical frozen Phase11 compiler
source (`705f1b3bbd7ab304143aace90a6dc0025458421ec5684d225a916311ae71e26e`).
Other development jobs may run on other CPUs; this is a diagnostic concurrent
screen, not the final controlled matrix.

All six ordinary type-checking/expected unsafe-proof-trust gates pass, with
identical unsafe-definition sets. All input/affinity/launch-error/signal guards
pass. Complete observations and logs are preserved.

| Variant | Forward process / request seconds | Reverse process / request seconds | Mean process seconds |
| --- | ---: | ---: | ---: |
| Baseline | 31.210 / 29.974 | 31.607 / 30.387 | 31.409 |
| Seed only | 31.164 / 29.939 | 30.631 / 29.414 | 30.898 |
| Delayed spine | 30.544 / 29.325 | 30.493 / 29.276 | 30.518 |

Process wall includes startup, hashing and output capture. Request time wraps
the adapter and includes lazy API import; emission is excluded. Maximum RSS
varies around 1.35–1.36 million KiB with no material isolated-memory conclusion.
Delayed-spine is only about 1.2% ahead of seed-only by mean process wall, which
does not justify its extra helper/state protocol. Seed-only's roughly 1.6%
favorable direction against baseline is not a reliable isolated speed claim.

Root initially accepted seed-only as a local removal of unused work and deferred
the larger candidate. Pinned TypeScript's delayed `lhs.t` motivated the investigation; its
frame machine was not ported. Phase11's duplicate-exact candidate and Phase7's
semantic-value evaluator remain deferred/rejected. Fresh profile shares are not
used to assign runtime/GC costs or to predict a whole-compiler gain.

Root owns broad combined gates, controlled final measurements, installation and
preservation. No further normalizer optimization is planned. No new TypeScript
ratio, proof-kernel/GPU result, overall conformance or user-runtime claim is made.

## Combined-artifact check and stack regression isolation

`normalizer-final-controls-01` repeats all 26 finite, four bounded/raw and 93
maintained assertions against the initial combined Phase12 `integrated-01`, API
`fcd23771a4e070fb4610d26ce0269e327e1a0d7029bd4f4f354a572219dae479`, and passes.
This is the normalizer gate only: the full frontend run separately found a
long-string stack regression in that combined v5 artifact. These local passes
do not authorize promotion past that broader blocker.

Root requested an independent seed-only isolation. `normalizer-stack-01` runs
four fresh isolated check workers on CPU2 in Phase11 → seed-v4 → seed-v4 →
Phase11 order, all at the same 4 MiB stack / 4 GiB heap, with identical frozen
driver/runtime helpers and the canonical pinned 6000-character
`check/string_literal_long.bend` fixture. All four checks report type acceptance
and passed proof trust (`kernelChecked:false`). Full observations, stack/error
logs, exact command/environment records and before/after input identities are
preserved. The source comparison proves the seed expression is the sole module
change in that ablation.

Seed-only therefore does not reproduce the combined-v5 stack regression in these
fresh workers. This does not establish preservation under other histories,
general stack safety, or identify the precise
V8 mechanism in the separate v5 investigation. No time ratio is inferred from
these correctness checks. CPU2 was released after completion; no further jobs
are running from this owner.

## Second integrated candidate and narrow gate

`normalizer-final-controls-02` runs the unchanged corrected control tool in seed
mode against the subsequently rejected `integrated-02` and Phase11 baseline.
That candidate's API SHA256 is
`b132e10300274616b118dcd7daec5d856fa4759e73d7235239f28772129316e4`.
All 26 finite cases, four bounded/raw boundary cases, and 93 distinct maintained
assertions pass; the maintained assertions run against both artifacts. All 14
child execution records pass their expected status/signal/error checks, including
the deliberately bounded divergent cases. Input identities are unchanged. Exact
command, resource settings, outputs and API identities are retained in the fresh
run directory and `normalizer-final-controls-02-launch.*` files. As before, private
export views preserve compiler bodies and are not new checked component builds.

The earlier owner report is preserved byte-for-byte at
`normalizer-final-controls-02/owner-report-before-final-02.md`. Earlier failed and
successful reports were not rewritten to describe the new artifact.

The separate small native-choice fallback revealed a worker-history boundary:
appending the long-string source to 21 prior checks overflows at 4 MiB in both
the candidate and the unchanged Phase11 baseline. Root's
`baseline-focus22-01/report.json` preserves the baseline failure;
`baseline-focus22-first-01/report.json` passes all 22 when the same long-string
case runs first. Fresh isolated checks also pass. This inherited boundary is
distinct from the initial combined candidate's failure in isolated workers;
neither is a semantic-equivalence claim or a reason to increase the resource
limit. The second integrated focused gate passes with the regression case first.
That local pass does not settle the broad or matched-history gates.

This was the narrow gate's status before the broad corpus and matched-history
investigation below. It did not establish preservation across worker histories.

## Final decision: reject the seed cleanup

The second integrated artifact and the A-only fallback each completed all 2,996
frontend observations but regressed the long-string check compared with the
recorded Phase11 release. `frontend-A-01/baseline-comparison.json` contains exactly
one changed observation and no missing rows; all other 2,995 observations match.
Its semantic triage accepts 1,000/1,001 positive fixtures and refuses all 482
validation negatives. Passing the fixture in isolation or first in the focused
selection does not waive this broader regression.

The earlier appended-22-case experiment demonstrated an inherited history where
both releases fail. It could not explain away another history where the baseline
passes. The call owner subsequently replayed the exact failing worker history:
Phase11 passed while current-source v4, A-only and leaf candidates failed, with
all 52 preceding observations matching. Source changes alone were sufficient.

Root then authorized two genuine source ablations in
`normalizer-prefix-replay-01`. The prospective plan is
`normalizer-prefix-replay-01-plan.json`; the tool is
`normalizer-prefix-replay.mjs`, adapted from the call owner's validated replay
framework only by changing the variant map, order and CPU description. It
verifies the original 53-request session and its input hashes before substituting
the compiler image and a private project/cache bound to that image. Host helpers,
runtime, Base, request sequence and 4 MiB stack / 4 GiB heap are unchanged.

| Genuine checked ablation | API SHA256 prefix | First 52 results | Long-string result |
| --- | --- | --- | --- |
| Seed-only v4 | `2d8df40471f8f934` | Exact original digests | Stack overflow |
| JS-only v4 | `a00c85240e67d5e9` | Exact original digests | Accepted; proof trust passed |

Both runs complete with unchanged inputs, no worker recycling, and no launch or
protocol errors. Neither reports proof-kernel checking. The seed expression is
the sole source change in its previously frozen ablation. This is direct evidence
that the cleanup can change an observable resource boundary despite passing the
finite/demand controls and fresh-process fixture checks. The evidence does not
identify a precise V8/JIT mechanism, establish universal stack behavior, or assign
the earlier combined candidate's regression solely to tail inlining.

**Reject the seed cleanup and retain the original `atom("Absent")` seed.** The
larger delayed-spine proposal remains deferred for insufficient measured benefit
relative to its extra state protocol. This normalizer investigation therefore
contributes no production optimization. Root restored the original source bytes
(`8d4deb08685dfd9284850afb478ce5b30674f1fe53c4a7144f481f2bf4ed10ec`)
with the change recorded in `normalizer-rejection.json`, and owns validation of
the resulting combined candidate. All previous raw reports remain
unchanged; report/experiment text before this outcome is preserved inside
`normalizer-prefix-replay-01`. The experiment's temporarily appended outcome is
also preserved there, followed by an exact restoration of the prospective file
recorded in `experiment-restoration.json`. All owner CPU jobs are closed.

## Restored-seed integration gate

`normalizer-final-controls-03` passes against `integrated-03`, API SHA256
`0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697`.
Its frozen `src/core/normalize.bend` is byte-identical to Phase11. This candidate
combines the separately owned JS/leaf changes with the original fallback seed;
it does not reinstate either rejected/deferred normalizer proposal.

The gate repeats all 30 boundary cases and 93 distinct maintained assertions
against Phase11 and this candidate. All assertions and expected child outcomes
pass, with unchanged inputs. It uses the same export-only views and resource
limits as the earlier gates. The control tool's only change is child affinity
from CPU2 to CPU1, recorded with both tool identities in
`normalizer-final-controls-03-tool.json`. The actual launch, 14 child executions,
outputs and full identities are retained. This is concurrent correctness work,
not a timing result or a new bootstrap/fixed-point claim.

The previous owner report is preserved as
`normalizer-final-controls-03/owner-report-before-final-03.md`. The prospective
experiment remains unchanged. All owner producers and CPU jobs are complete;
root owns the final full-corpus result, controlled measurements and release.
