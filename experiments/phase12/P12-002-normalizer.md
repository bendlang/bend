# P12-002 — Demand-driven normalizer fallback reconstruction

Prospective record, 2026-09-28, written before Phase12 probes. Owner: normalizer
investigator; integration, controlled timing and release: root. Baseline is
Phase11 `f8244c9`, immutable `selfhost/build/phase11/integrated-01`, selected API
`63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f`.
Pinned upstream remains `b2111cf43244e65f76ddc278ee695e669f720cbf`.
Outcome report: [normalizer.md](../../implementation/phase12/normalizer.md).

## Hypothesis and historical boundary

`norm_ref` eagerly rebuilds the entire reference application with
`norm_apply(t,args)` before evaluating every saturated definition body. Successful
unfoldings discard that fallback. Only an Efq encountered before the definition's
declared arity is consumed, or a stuck match at that stage, returns it.
Retaining the original head and immutable argument spine until one of those
branches demands the term may remove application reconstruction on the common
successful path without changing normalization or conversion rules.

Pinned TypeScript `term_wnf` instead keeps `lhs.t`, a delayed reconstruction
function; its full frame/cell machine is not the proposed replacement. Phase11
already counted wasted fallback reconstruction on constant-body raw terms. Those
old counts are motivation, not new-release evidence or a measured benefit. Its
duplicate-exact shortcut remains deferred. Phase7's rejected semantic-value
evaluator and its All-demand counterexample are not reopened.

## Static scope and candidate choices

Start with actual Phase11 emitted-function counts: how many reference fallbacks
are built, how many spine entries they traverse, and how many are consumed. Use
finite raw terms with known results plus small valid parsed/loaded/checked source.
Root's fresh profile determines whether the exposure warrants a source candidate.
No compiler or counter jobs run while its exclusive profile occupies the slot.

The preferred source mechanism is a private delayed pair containing head and
argument spine. It trades one small record per unfolding for zero rebuilt Apps
until demand. A separate pair of function parameters avoids that record but adds
an argument throughout the evaluator; a closure reduces explicit data but adds
its own closure/trampoline and affine typing obligations. Choose at most one
initial representation after counts, and record its actual type/helper/line cost.
Do not conceal added state as a fake ordinary core term tag.

`core/graph.bend` also calls the current `norm_stuck` with an already materialized
KTerm fallback. Preserve that existing interface in a narrow isolated normalizer
candidate, using a small delayed adapter if necessary. All other consumers and
references must be enumerated before edits. Do not change the graph machine,
substitution/binder representation, fallback selection rule, pending-arity count,
argument order, foreign opacity or exact conversion in this experiment.

## Equivalence domain and cheapest falsifiers

The intended domain is finite immutable well-formed compiler books/terms and
ordinary public checked-source operations. Terms may contain an unevaluated
divergent subterm: removing fallback allocation must not force it, alter which
branch is selected, or lose original head/spine metadata. The reconstruction
itself traverses only the finite argument list, not argument terms.

Compare exact complete returned terms and public observations, not just accepted
types or normalized semantic equality. Required discriminators include:

- Successful saturated calls at arities 0/1/4/16/64, including unused arguments;
  opaque/foreign/under-applied calls must retain the old structure.
- Matching and nonmatching constructors, neutral scrutinees, exhausted matcher
  defaults, Efq, annotated arms, zero-arity definitions and extra applications.
- Nested unfolding where a later reference replaces the earlier fallback;
  partially consumed declared arity and constructor fields extending that count.
- Exact preservation of the original raw argument when a scrutinee weak-head
  normalizes but the match remains stuck.
- Unused omega, early stuck demand and divergent demanded scrutinees, each in a
  separate child with a fixed timeout. Preserve malformed/null/cyclic argument
  spine witnesses separately; do not imply arbitrary-host-value equivalence.
- Maintained normalization/kernel assertions and prior exact-demand/capture
  boundaries, followed by the checked B1 workflow's complete focused observation
  comparison against this Phase11 baseline.

Reject or defer the candidate if the fallback adapter merely shifts allocation,
adds material overhead on no-reference/short-call workloads, loses any supported
observation, or needs a broad state-machine rewrite. A useful operation count
does not justify promotion without actual checked source and measurement.

## Evidence, resources and decision

Only owned `normalizer-*` tools/build trees and this experiment/report may change.
Production source, distribution and upstream remain untouched. All attempts use
fresh output paths, exact source/API/driver/Base/Node identities and before/after
input verification. Record complete child error/signal/status and logs; status0
alone is not success. Freeze each candidate before checking or measuring it.

After root releases the CPU slot, use the allocated CPU for small counters and
controls. Announce actual checked builds. Supplemental private-export components
are identified separately from B1 and derivatives. Any bounded alternating size
screen consumes verified results and states concurrency, warmup and process
reuse. No whole-compiler or allocation/RSS claim follows from counters/profile
percentages. Root owns combined correctness, controlled full-source comparison,
release/preservation and git. No historical time budget is renewed.
