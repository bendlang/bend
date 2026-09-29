# Representation costs before semantic migration

Two isolated changes prepare a simpler source of truth for error order: the
[checker world](instance-world-representation.md) and the
[parser cursor](parser_state_options.md). Neither changes the installed Phase17
compiler. Their first experiments change transport only, so complete observable
results must agree with their parent, including existing conformance gaps.

The question is whether either representation imposes a material cost before
its intended removal of duplicate work. A successful transport experiment is
permission to investigate the semantic migration, not a release or a measured
conformance improvement.

## Measurement contract

Use the unchanged `selfhost/tools/performance/phase16/check-matrix-v2.mjs` with
new Phase18 inputs and outputs. Each candidate uses the installed Phase17 checked
attempt `find-worker-build-01` as baseline, its own genuinely checked attempt,
and exactly the same assembled candidate source in every lane. Verify complete
host membership and bytes before running; include runtime, Base, derivation,
source and tool identities in the receipt. No instrumentation enters timed APIs.

Run fresh processes in TS/B/C/C/B/TS order on CPU0, Node24.18.0, a4MiB stack and
4GiB heap. Close competing compiler, compression and recovery jobs first and
record their owners' acknowledgements. Preserve each observation, including
failures. TypeScript checks Base; each Bend artifact has its separately validated
Base cache. OS caches are not flushed. Request timing wraps the compiler adapter;
process timing also includes startup, hashing and output capture. The request
checks the complete source and reports the expected unsafe-definition trust
refusal; it neither emits code nor benchmarks generated programs.

Run only after focused equivalence, transport and demand controls pass. If a
lane fails, retain that attempt and investigate before measuring a fresh one.
Compare complete results and identical unsafe-definition sets before reading
speed ratios. Two samples per lane are a bounded screening experiment, not a
precise general performance estimate.

## Prospective decisions

- At most5% added process time, with no unexplained demand or substantial memory
  regression: proceed to a small semantic slice and measure the resulting whole
  change. This does not justify installing transport by itself.
- Above5%: identify whether allocations, projection dispatch or another specific
  operation causes the cost. Prefer a cheaper representation before migrating
  semantic ownership. A close or order-sensitive result is inconclusive and
  needs a justified new measurement rather than selective sample removal.
- Any changed observable behavior in this inert stage blocks it, irrespective
  of timing. A source/concept increase must be reported as an increase; possible
  later adapter deletion is not current simplification.

For checker state, source03 is the first candidate with all reviewed propagation
corrections. Its prospective matrix inputs are
`selfhost/build/phase18/instance-world-matrix-inputs-01/`. Earlier build attempts
and their failures remain evidence. For the cursor, freeze the corresponding
inputs after the checked build and focused boundary controls close.

After measurements, write outcomes under `implementation/phase18/` and update
the strategy. Keep all Phase17 release and preservation inputs immutable.
