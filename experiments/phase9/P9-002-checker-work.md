# P9-002 — Remove bounded redundant checker work

- Owner: `research_binders_semantics`; independent reviewer: root.
- Started: 2026-09-28. Prospective plan, frozen before candidate builds or timings.
- Objective: faster correctness iteration on the compiler written in Bend.
- Correctness: untested changes; current installed Phase8 checked B1 is baseline.
- Measurement: not run; structural opportunities are not performance attribution.
- Decision: investigate three separately reproducible source ablations.
- Design: [checker speed](../../design/phase9/checker_speed.md).
- Outcomes: [checker work](../../implementation/phase9/checker-work.md).

## Claims and cheapest disproof

1. **Lambda kind:** ordinary lambda checking repeats the function domain's kind
   check, although the goal was checked before its body. Match upstream's extra
   check only when an explicit unrestricted lambda promotes an affine goal.
   Preserve the extra check, first error, unsafe fill behavior, usage accounting,
   generated match goals and chronological declarations. A changed acceptance or
   rejection on a valid source program disproves the proposed invariant.
2. **Exact conversion:** `compare` scans both terms for fresh binder IDs before
   its existing exact comparison. Move that exact test before fresh-ID discovery;
   leave the unequal-term path and direct `norm_compare` caller unchanged. Exact
   equality needs no fresh binder, normalization or book lookup. Capture on a
   nonidentical pair, changed demand/termination, or repeated exact traversal on
   the unequal path invalidates this version.
3. **Context lookup:** successful variable inference performs the identical
   linked-list lookup twice. Bind its result once. Preserve nearest matching
   binding, unbound errors and occurrence usage. Any changed result rejects it.

These changes precede representation changes because each removes visible work
without introducing a cache, a new AST, a runtime ABI or normalization strategy.
Stop and report a failed invariant instead of expanding into those designs.

## Controlled setup

- Pin: `b2111cf43244e65f76ddc278ee695e669f720cbf`, upstream 2.0.32, immutable
  `selfhost/.bootstrap/upstream-phase8`.
- Baseline API: `e928f77778de9dc72267e26b6a7ccb029cac318ccd35dd8f9248da1c6374bbe4`.
- Source ownership: only `src/check/kernel.bend` and `src/core/normalize.bend`.
- Freeze the complete baseline source before other Phase9 work. Each isolated
  ablation changes one factor against that source; preserve its patch, module
  identities and complete checked-build provenance. Test the combined candidate
  only after the individual gates, then allow root integration with other work.
- Maintained checked-B1 workflow, CPU1, absolute Node v24.18.0, 4096 KB stack,
  4096 MB heap. No benchmark concurrent with another CPU workload without root's
  explicit allocation. Builds and correctness probes are not timings evidence.
- Record source/API/Base/runtime/helper/upstream identities and commands with
  each attempt. Do not overwrite failed attempts.

## Correctness gates

Each ablation must genuinely bootstrap with the pinned checker and pass focused
paired source controls plus the maintained development selection. Supplemental
checked component exports may exercise private `check`, `infer` and `compare`;
they are labeled as components, not installed B1 or fixed points.

Boundary controls include ordinary dependent and erased lambdas, unrestricted
promotion with permitted and forbidden domain kinds, unsafe versus safe fills,
invalid signature rejection before a lambda body, affine repeated use, context
shadowing/unbound variables, alpha equivalence and high free IDs, exact divergent
terms, unequal divergent siblings with discriminating heads, removed constructor
sets, application/eta behavior and directional kind ordering. Retain current
normalizer and kernel regression groups. Some raw malformed goals are outside
the checked-goal precondition of private checker entry points; distinguish those
from source-language correctness instead of silently changing the domain.

## Measurement and decision gates

Root owns final controlled comparison and integration. Supply separately usable
checked ablation APIs and immutable scripts; only report throughput gains from
alternating, repeated identical workloads with verified outputs and identities.
Counts or eliminated calls alone do not establish a speedup or explain the full
73.20× process-wall gap. A source-only win must survive the root's selected
semantic, conformance and full-source checking gates before release promotion.

## Preservation

Track this plan, bounded controls, ablation patches/manifests and the outcome
report. Root records durable evidence packaging and checkpoint identity. No
measurements or success claims are asserted by this pre-execution plan.
