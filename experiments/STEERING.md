# Current compiler experiment strategy

The [Phase 29 compiler](../implementation/phase29/generated-program-fast-loop.md)
targets upstream 018751270e800bc222a93dad7f257083ee53a5f7, after 2.0.34.
Authorization covers continued compiler work and pushes to rom1504/bend
selfhost/bootstrap. No new PR comments without an explicit request. The user now requests at least seven hours beginning2026-09-30 07:28 UTC,
through14:28 UTC; see the Phase30 design. Preserve the103 unrelated starting paths.

## Active Phase30 campaign

[Design](../design/phase30/direct-generated-code.md): compare saved JS, isolate
private direct calls on a small edit-distance row, independently challenge
semantics, then generalize only measured wins. Coordinate all clean CPU3 timings
through the lead. Phase29 remains installed until a reviewed candidate passes.

## Released frontier

API 10510efd, genuine checked parent 37218b8a, guarded profile 6, source 191df20c;
runtime 40823818 and Base c742fae9 unchanged. The compiler emits 54 identified,
saturated native U32/F32 operations as JS expressions and turns supported scalar
Nat countdowns into private local-slot loops. Public matchers, partial descriptors,
argument demand and runtime representations remain. Unknown shapes fall back.

The real Mandelbrot helper fixture improves 3.65× with longer warmup, from 1.455
to 0.399 ms; it still costs about 234× TypeScript output. A short window suggests
6.66× but intersects substantial warmup drift; retain both. The paired screen
costs 4.706 s end to end, the checked build plus 36 focused gates cost 33.341 s,
fixture emission 4.825 s and its 120-point check 0.165 s: about 43 s before
additional feature controls.
Acquisition durations are descriptive, not comparative compiler throughput.

The report preserves all original-program results, first calls and warmup regimes.
A 27.4% short-window regression on the evening mixed test triggers a prospective
longer-warm follow-up: the same bytes improve1.167× there with stable timed
halves and comparable first calls. Keep both windows. HVM whole-process cost is
flat (196.86→198.39ms, overlapping ranges), still2.895× TypeScript. Broad integration is run
once per surviving candidate, not on every edit. Algorithms are selected small
inputs, not a production average, and HVM remains a whole-process measurement.

Separate counters on compiler-produced fixture output show generic applications
70,540 → 26,970, bound descriptors 7,730 → 60 and copied slots 142,430 → 46,390 over ten
calls. These are named-site counts, not total heap allocation or instrumented speed.
Canonical source: 16,207 physical / 13,839 nonblank lines, 64 modules, 1,762
definitions, 640 laws and 68 types. The phase adds 263 lines, 36 definitions and
two guarded emitter concepts; no new IR, datatype, cache, runtime helper or representation.

Fresh gates pass: 36 focused exact checks, 15 upstream JS executions,
23 libraries / 127 points, ten original libraries plus HVM, 22 actual-component
oracles and independent scalar/ABI controls.
Primitive controls: 56,205 scalar executions, 1,129 guards, 25 order/error observations.
Worker controls: 3,759 scalar executions, 14 transcripts, 40 guards, two let witnesses,
144 nested-Nat regression observations. Counts overlap and include multiple emitters.
These scopes do not establish complete backend conformance or a new fixed point.

The runtime and native emitter are unchanged. Earlier Phase 26 direct U32 decisions
and Phase 27 selected constructor-arm prebinding remain, with their historical
measurements separate. No whole-compiler throughput improvement is inferred.

## Historical wider coverage and ordinary checking cost

The Phase 24 release has 3,026/3,026 main frontend and 196/196 broader exact reference
observations, plus 226 paired request histories and two fresh string checks.
Raw main statuses remain 2,525 pass / 497 observed / 4 fail because later-emission oracles
are observed at an earlier frontend stage. Backend pilot 81/81 exact covers 77
execution rows, not all 2,654 eligible positive/expected-error opportunities.

Supported-host TCP comparisons and Clang 16 TSan controls remain separately scoped
historical evidence. They do not establish universal race freedom, platform
compatibility, a new sanitizer compilation or current complete backend coverage.
Independent BendTT --verdict, GPU/device execution and package fetching remain
unsupported or unvalidated as documented in selfhost/CONFORMANCE.md.

Last ordinary checking screen: TS 3.7370 s versus final 11.1565 s, process 2.985× and
request 4.043× TypeScript. It used three samples/image, includes startup and manifest
hashing, and excludes emission. It was not renewed by generated-program timing.
No TypeScript fallback occurs in ordinary compilation. The contextual frontend,
graph evaluator, persistent index and uniform arrays remain unchanged.

## Next priorities

1. Use the [fast loop](../implementation/phase29/README.md): immutable checked
   outputs, one mechanism per ablation, independent expected results, public ABI
   controls, clean paired screens and longer-warm confirmation. Keep failed cases
   and both lifecycle windows; a short-window win is not convergence evidence.
2. The [remaining-cost inspection](../implementation/phase29/remaining-costs.md)
   prioritizes private saturated workers across complete parameter/match chains.
   Start with edit distance's cell/record/tuple pipeline, keeping project/build
   and arrays unchanged. Then test record-carrying loops and trailing Boolean
   matches. Static call counts do not quantify runtime contribution.
3. Preserve sequential argument-demand boundaries, parallel-let scope, escaping
   closure aliases, native identities and deep stack behavior. Explicit kc gates
   are required before guarded recursion: Bend && is eager. Removing those gates
   for fewer lines recreates the retained stack-overflow failure.
4. Continue backend acquisition in deterministic bounded batches. Frontend
   equality alone missed earlier backend defects. Separate candidate differences,
   shared upstream failures, expected refusals and environment limitations.
5. Ordinary compiler cost still includes contextual materialization, repeated
   book traversal, dispatch and source-range validation. Use boundary witnesses
   before another index or broad rewrite. Existing scope-index winners cannot
   replace full definitions without a consumer-specific proof.
6. Prefer eliminating duplicated responsibility over compressing source. Historical
   50%/75% line-reduction targets remain unachieved. No new self-hosted fixed point,
   independent kernel or native/device speed claim follows from this phase.

## Operating rules and retained failures

Read experiments/README.md. Freeze hypotheses before probes, preserve exact
attempts and resource limits, and distinguish genuine checked B1, guarded derivative
and self-emitted H. Unknown identities/profiles fail closed. Capsules preserve
bytes independently; ignored paths or hashes alone are not preservation.

Phase 29 keeps rejected source syntax in 02 and recognizer overflows in 03. The
small regression fails on 03 and passes on 04; all eight previously successful
original outputs remain byte-identical after the guard repair. Earlier rejected
inline-arm startup regression, generic architectural trials and Phase 24 failures
remain in linked historical reports and capsules. Do not silently recycle them
as evidence for a new image.
