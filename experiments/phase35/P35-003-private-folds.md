# P35-003 — Remove generic dispatch from closed structural sum consumers

- Owner / independent reviewers: research agent; regions and vectors agents;
  root owns all compiler builds, execution, measurement and final admission.
- Started / evidence cutoff / timebox: 2026-10-01; checked09 complete generated
  confirmation, all final owner groups and installed release closure.
- User objective served: faster generated programs and a fast optimization loop.
  Investigator approach: saturated private folds on unchanged local tagged sums.
- Correctness status: corrected saved-output prototype passes 71 independent
  oracle cases, 121 public-boundary comparisons and separate admission counters.
  Actual compiler owner gate passes 675 small result comparisons, two deep local
  tree points, 57 public boundaries, 24 recognizer cases and four entry witnesses.
  All 15 final postinstall gate groups, including 42 CLI checks, also passed.
- Measurement status: valid short mechanism screen for original symreg, followed
  by complete checked09 confirmation across 15 selected generated-program points.
  The symreg result below is a combined phase gain, not isolated fold attribution.
- Decision: retained in installed checked09 with the phase's explicit
  compilation-time/output-size tradeoff.
- Related attempts: [design](../../design/phase35/private-sums.md),
  [canonical implementation report](../../implementation/phase35/sum-review.md),
  [literature](../../design/phase35/literature.md); shared partial-region purity
  proof belongs to the regions workstream.

## Claim and cheapest disproof

**Hypothesis:** symbolic regression spends much of its time repeatedly crossing
generic function and constructor-match boundaries inside recursive eval/size.
Saturated private consumers of a locally produced Expr should substantially
reduce the unchanged original benchmark, even without changing tree layout.

**Invariant:** a separate typed first-order purity proof admits the generic
producer and its entire dependency graph. It fully materializes finite inert
tagged records before traversal. Every reachable public wrapper and host protocol
is checked before entering the region; caller-provided/mutated producers retain
the original path. Complete constructor coverage, strict operand order, unchanged
scalar parameters, alias preservation and public staged callback shape remain.

**Falsification:** a changed result, order/error/ABI counterexample, inactive
optimization, no substantial gain from eval/size saturation, or unacceptable
compiler/memory cost stops promotion. The initial greater-than-twofold screen
threshold was a discriminator, not a promised speedup.

**Alternatives:** test a private dataset loop first as the cheaper change;
compare direct consumers second. Changing representation or adding destructive
reuse would obscure the cause and requires stronger ownership facts. General
recursive region planning/SCC rewriting is larger than the measured opportunity.

## Controlled setup

- Pinned source target: `018751270e800bc222a93dad7f257083ee53a5f7`.
- Saved original module SHA256:
  `551e61d6ccbeca827650038d31d93dc5866f59a11283bff9bc6a6ca59e05d875`.
- Fixed original workload: symreg `bench(6,42)`, result `2490246820`.
- Factors: untouched output; matched exact-entry wrapper; private dataset loop;
  loop plus direct eval/size. The generic depth-five generator, tree format and
  complete original benchmark remain unchanged. Pinned TypeScript is a fifth
  reference, not the semantic oracle for public JS mutation behavior.
- CPU3, serial fresh Node v24.18.0 processes, 4096 KiB stack, 1024 MiB heap;
  prototype supervisor ceiling 1536 MiB, available-memory floor 2048 MiB.
  Three rotating samples, 350 ms warmup and 150 ms target execution samples.
- Timing excludes checked acquisition and diagnostic counters. All attempts run
  through the shared execution lock; agents perform only read/review/producers.
- Evidence manifests: `selfhost/build/phase35/sum-02/derive.json`,
  `sum-controls-02/report.json`, `sum-witness-02/report.json`,
  `sum-screen-01/report.json`; full hashes/configuration retained by root.

```sh
# Prototype derivation only; execute through the campaign supervisor.
node selfhost/tools/performance/phase35/sum-derive-v2.mjs \
  selfhost/build/programs/reference-preparation-01/modules/symreg.mjs NEW_DERIVED
node selfhost/tools/performance/phase35/sum-controls.mjs NEW_DERIVED NEW_CONTROLS
node selfhost/tools/performance/phase35/sum-witness.mjs NEW_DERIVED NEW_WITNESS

# Final compiler owner gate owns its supervisor; do not nest execution locks.
python3 selfhost/tools/performance/phase35/fold-final-controls.py ATTEMPT NEW_OUT
```

## Gates and observations

| Attempt | Correctness / measurement | Interpretation |
|---|---|---|
| `sum-01`, controls01, witness01 | 71 oracle/121 boundary pass; zero optimization admissions | Invalid as an optimization test. NaN descriptor equality made the guard always false. |
| `sum-02`, controls02, witness02 | Same 71/121 pass; required loop/eval/size admissions pass | Corrected prototype eligible for timing. |
| `sum-screen-01` | Original 109.263 ms; matched baseline 110.844; loop 110.485; sums 20.223; TS 1.111 | Direct consumers support 5.40× mechanism gain; loop alone does not. Still 18.20× TS. |
| checked09 initial combined screen | Exact original output; baseline 123.336 ms, candidate 17.403, TS 1.268 | Actual compiler transfer: 7.09× combined gain, 13.72× TS; not isolated fold attribution or final confirmation. |
| checked09 complete confirmation | All 15 selected results pass; symreg baseline 106.609 ms, candidate 15.529, TS 1.108 | Longer combined result: 6.87× gain, still 14.02× TS. |
| checked09 recursive-fold owner | 675 small result comparisons, depths 4,096/50,000, 57 boundaries, 24 recognizer cases, four admitted-fold witnesses pass | Concrete final API provenance audited; this does not replace broader release gates. |

All three prototype sum samples lie below every untouched sample. Some original
samples show sizable within-sample drift; the retained raw screen justified the
longer confirmation reported above. The 15.175-second mechanism screen demonstrated a useful
iteration loop without running the full catalog on every hypothesis.

## Independent audit

Regions and vectors separately reviewed generic local generation, full forcing,
source arithmetic/order, public guard/fallback and unchanged tree aliases. No
additional prototype blocker was found after the inactive NaN guard. Root's
admission witness found that failure despite all output controls passing; v2
uses captured `Object.is` for descriptor values, preserving signed-zero identity.

The production subset differs from the hand-written evaluator: it recognizes
only complete monomorphic U32/self-field sums, exact once-per-child saturated
selfcalls and unchanged extra U32 arguments. It rechecks the rewritten scalar
combiner and emits a reusable explicit postorder stack. Both reviewers requested
host guard activation for every fold, not just paths also containing a generic
producer. Research identified absent-slot and inherited numeric prototype
observability; checked09 incorporates root's conservative prototype-name guard.
Final runtime controls exercised those cases successfully. The separate
[provenance audit](../../implementation/phase35/fold-final-provenance-audit.json)
rehashes checked09 API/attempt, checked source/emission and all fold-control inputs.

## Decision and next discriminating test

The saved-output evidence justifies the small compiler subset. It does not
justify new public tree admission, arbitrary mutually recursive lowering,
destructive data reuse or a universal fusion optimizer. Final checked09
owner controls, depth-50,000 local generation/traversal, shared child and reversed
order oracles, refusal controls, public mutation boundaries and longer actual
symreg confirmation have now passed. Broader final-image gates and all 42 ordinary/
relocated CLI checks subsequently closed on that same installed image. Abandon
or restrict the subset on
any counterexample; do not erase failed attempts to make the screen appear clean.

The [independent release assessment](../../implementation/phase35/release-assessment.md)
records the complete decision and compiler-cost tradeoff. This experiment's
mechanism screen alone was not sufficient to promote the installed compiler.

## Preservation

Tracked sources are the design/report, prototype v1/v2, oracle and witness tools,
proposed `private-sums.patch` and its source/order manifest, plus compiler-owned
`fold.bend` and the final source/synthetic control producers. Failed v1 controls
and witness retain their identities. The patch source is the pre-checked09
proposal; root's later frame/host-guard repairs are recorded in checked snapshots.

Large generated modules/raw process logs remain under ignored `selfhost/build`.
The complete [verified Phase35 capsule](../../implementation/phase35/evidence/README.md)
now preserves those raw artifacts, failed producers and exact manifests/results.
The final owner gate records all inputs and a checked emission recipe. Archive
capture/reopening is complete; Git publication is a separate root action.
