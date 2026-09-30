# Current compiler experiment strategy

The [Phase27 compiler](../implementation/phase27/constructor-arm-prebinding.md) is
installed at upstream018751270e800bc222a93dad7f257083ee53a5f7, after2.0.34.
Authorization covers continued optimization/conformance/simplicity work and pushes
to rom1504/bend selfhost/bootstrap; no new PR comments without explicit request.
No historical multi-hour budget is renewed. Preserve the103 unrelated starting paths.

## Released frontier

Installed API5a89c775, genuine checked parent25c38e3f, guarded profile6;
runtime40823818, sourcef3097523. Selected constructor arms prebind projected
fields into the same partial descriptor through a shared runtime callback.
No public arity/demand/representation change. Unknown/erased/lifted/eta-short
and exact-saturation shapes retain the old matcher.

Final short-window membership median improves1.026× (ranges overlap); longer-warm
membership1.059× and Boolean traversal1.042× have nonoverlapping observed ranges.
Substitution is flat in both protocols. The inline version's20% short-window
regression remains rejected, with its135+45 samples and traces retained.
Shared variant135+45 samples use identical sources/inputs and per-window serial
CPU3/Node24 comparisons. Five samples are not confidence bounds. No compiler/H
throughput gain is claimed. Canonical source15,944physical/13,612nonblank,
62modules,1726defs,640laws,68types: +58 Bend lines and11 runtime lines.
Fresh36focused,15upstreamJS,23library/127point,72arm observations, numericcontrols
and22real-component oracles pass overlapping scopes. Independent timing audit and
release verification pass; the report records exact identities and recovery.

Phase26's native U32 decision rule remains. Its prior table/wide/direct numeric
measurements improved11.80×/3.66×/50.25× with no whole-compiler claim. Final Phase27
rechecks numeric behavior; previous TypeScript gaps remain large in emitted loops.

The following broader conformance and ordinary-cost figures are Phase24 evidence:
No TypeScript fallback in ordinary compilation. The same contextual frontend,
loadABI2, graph evaluator, persistent index and uniform array representation remain.
A negative scope-index lookup now avoids unnecessary local declaration scans;
hits retain first-event semantics. A Boolean membership worker removes per-miss
closures through existing tail-cycle lowering. No new cache, datatype or scopefield.

The shared emission check now rejects foreign/constructor name collisions after
reserved-name checks, before reachability. Constructor scans occur only for foreign
definitions. Native function identifiers reuse existing scalar encoding and preserve
case/punctuation identity; longer generated C identifiers are a recorded cost.

Final image:36focused exact, main3026/3026exact and broader196/196exact, with stable
identities and healthy workers. The broad gates explicitly reuse the pinned reference
acquisition. Raw main statuses still2525pass/497observed/4fail for later-emission
oracles. Fresh request histories226paired+2fresh are exact. Backend pilot81/81exact
repairs two measured gaps; its77execution rows do not cover all2,654 eligible
positive/expected-error execution opportunities. Extra focused controls and release
checks are detailed in the report; overlapping counts must not be summed.

The two old TCP oracle gaps now have exact supported-host comparisons (upstream
Bun1.2.22, candidateNode24) on unchanged Phase23 emissions. Matching Clang16 TSan
passes8 saved-program executions including two-core shared atomics, plus clean/racy
capability controls. This does not establish universal race freedom, all-platform
compatibility or a fresh Phase24 sanitizer compilation. Bun import failures remain.

Final serial15-sample cost screen (3/image): TS3.7370s, old11.7300s,
local11.2990s, membership11.0856s, final11.1565s. Final process−4.89%, request−5.58%,
peakRSS−0.03%vsold. Same-window process ratio3.139→2.985×TypeScript; request4.043×.
Three samples are not a general/statistical bound. Process includes startup and
manifest-union hashing; compare within the same window, not across historical screens.
No generated-program speedup is claimed. Canonical source15,776physical/13,467nonblank,
588,084bytes,1,703defs,640laws,60modules,68types: +28lines/+3helpers, same representations.

## Next priorities

1. The [Phase28 broader comparison](../implementation/phase28/broader-program-comparison.md)
   is complete with the installed Phase27 compiler unchanged. All11 outputs agree.
   Existing algorithms are111–1391× slower than TypeScript output in the original
   warmed JS window; tiny mixed tests55–107×. Longer warmup on all four drift-flagged
   cases gives1271× Mandelbrot,100× sorting,61× morning,82× Map/Set, with residual
   drift. HVM's whole process is201ms versus69ms,2.90×; keep that startup-inclusive
   scope separate. All150 timing samples plus56 check/calibration processes pass
   independent audit. Neither window is a production average or guaranteed steady
   state. Ordinary compiler throughput remains the older Phase24 evidence above.
2. Prioritize separate generated-code ablations for saturated private workers/loops
   across match boundaries, guarded primitive inlining and direct native constructors
   and matches. The [inspection](../implementation/phase28/emission-findings.md)
   observes generic dispatch/descriptor/forcing overhead but does not quantify its
   contribution. Both outputs already use tail jumps and native JS strings.
   Start with one real emitted helper and preserve public partial descriptors,
   argument demand, unsigned arithmetic and deep-construction stack behavior.
   Check both warmup windows before broad timing. Existing full ten-library timing
   costs816s and the four-case follow-up189s; use focused replay during iteration.
3. Continue backend acquisition in deterministic bounded batches. The inventory
   is current but largely unexecuted; frontend equality alone missed both repaired
   backend defects. Distinguish candidate semantic differences, shared upstream
   failures, expected refusals and environment limitations.
4. Profiled remaining ordinary costs include contextual materialization, repeated
   book updates/traversals, generated dispatch and source-range validation. Use
   counters and boundary witnesses before another index or broad rewrite. The prior
   index's winner differs from first-event lookup: never replace full definitions
   with it without a consumer-specific proof.
5. Keep the checked B1 development loop: final bootstrap+Base+36focused gates were
   about27.6s of observed concurrent phase execution. Reuse attempts for fixture
   changes; reserve broad tests/reproduction for integration. A new fixed point,
   independent kernel and GPU/device work remain explicit separate capabilities.
6. Prefer removing duplicated responsibility over compressing lines. Historical
   50%/75% source-reduction targets remain unachieved. Native source-size overhead
   from scalar identifiers is measurable; optimize only while retaining injectivity
   and reserved-runtime separation.

## Operating rules and retained failures

Read experiments/README.md. Freeze hypotheses before probes; preserve attempts,
resources, full observations and counterexamples. Genuine checked B1, guarded
derivative and self-emitted H are distinct. Unknown identities/profiles fail closed.
The new capsule reuses Phase23 durable prerequisites; ignored paths/hashes alone are
not preservation. Recover included bytes independently before publication.

Phase24 retains the old profiler's incorrect success assertion, allocation-report
serialization failure, rejected local-match syntax, sandbox history launch, eager
collision-check candidate, invalid foreign-FID controls and environment failures.
The frontend chronology/materializer invariants remain unchanged. Phase13 worker
lifting and earlier generic simplification failures remain reasons to demand fresh
evidence; they are not blanket rejections of specific, measured improvements.
