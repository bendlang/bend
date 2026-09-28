# P9-005 — Cache bounds for the chronological event index

- Owner: `research_binders_semantics`; reviewer/integrator: root.
- Date: 2026-09-28. Prospective record before instrumentation or source edits.
- Correctness: untested hypothesis. Measurement: not run. Decision: investigate.
- Source ownership for candidate: `selfhost/src/diagnostic/produce.bend` only,
  initially an isolated project. Root must approve production application.
- Reports: [checker work](../../implementation/phase9/checker-work.md); a separate
  chronological-cache result section will preserve failures and exact evidence.

## Hypothesis and discriminating evidence

The diagnostic checker has two separate persistent books: `done` contains all
declared signatures and chronologically available bodies; `seen` contains only
events already encountered for duplicate/law-fill guards. `done` starts with a
BookCache carrying the immutable full-source binder bound, but `seen` starts Nil.
`event_error(seen, d, old)` calls `compare(seen, old.typ, d.typ, False)` for a law
fill. Alpha-renamed, non-exact signatures therefore cause `norm_book_bound(seen)`
to scan all earlier definitions and bodies, despite `done` having a valid bound.

Cheapest falsifier: instrument a disposable copy of an already checked component
to count `norm_max_book` invocations and input sizes on 4/8/16 valid alpha-renamed
law-fill pairs. Run the unmodified component on identical inputs and require
identical verdicts. Counters are explanatory evidence only, never timing data.
If no repeated scans occur, stop this hypothesis and inspect profile callers.

## Proposed isolated source change

Compute the full-source bound once, construct an immutable empty BookCache once,
and use that empty seed independently for `done` predeclarations and `seen`
chronology. Persistent updates must leave their namespaces separate. Reuse one
seed helper for normal and exact-prefix checking, preserving prefix validation
and fallback. Do not replace `seen` with `done`: that changes duplicate detection,
future-definition visibility and law-fill semantics. Do not change cache ABI,
normalization, signature comparison, binders or the public checked-book output.

The bound remains sound because every declaration in either chronological index
comes from this same complete immutable source book. Template-local extensions
and their existing bound discipline remain untouched. Internal BookCache entries
must never become user declarations or appear in original-book output.

## Gates

1. Preserve counter script, input generators, original/derived artifact hashes,
   exact hooks, counts and unmodified output controls. No compiler build needed.
2. Freeze an isolated source candidate against the tested P9-002 combined source;
   preserve its patch and module identities, then genuinely bootstrap checked B1
   with pinned upstream `b2111cf43244e65f76ddc278ee695e669f720cbf` on CPU1.
3. Reuse the 40 original checker fixtures and compare full diagnostics, phases,
   checked/type/trust metadata and outcomes against the baseline. Known upstream
   diagnostic differences remain separate failures. Add alpha law-fill size
   controls, changed signatures, duplicate events, future safe/unsafe calls and
   validated-prefix success/fallback. Check sentinel non-exposure and independence
   of the chronological and globally declared maps explicitly.
4. Run uninstrumented checked components on a law-fill size series. Repeated
   forward/reverse workers, verified results and input/API/tool identities are
   required. Concurrent operation screens are not whole-compiler speed ratios.
5. Root independently reviews and chooses whether to apply production source.
   Broader integration and final exclusive whole-source timings remain root's
   release gates. No source promotion solely from counters or microbenchmarks.

Stop on changed valid-source acceptance, wrong rejection phase, capture,
chronology/prefix leakage, observable metadata, or unexplained exact diagnostic
change. Preserve all first failures and rejected alternatives in fresh evidence
directories. Do not broaden this into a new environment representation.

## Outcome checkpoint — 2026-09-28

Original plan bytes remain in
`selfhost/build/phase9/chronological-cache-01/prospective-plan.md` (SHA-256
`1b28f8b57044ee0986d43aad4d287db9136cf944291962416cea52e5ddcfca28`).

The hypothesis is confirmed: 4/8/16 alpha-renamed law-fill pairs trigger 5/9/17
whole-book bound scans and 117/307/927 term-node visits. Seeding the independent
chronological cache reduces these to one scan and 43/79/151 visits. Ordinary
outputs and original artifacts remain unchanged. Derived counter images are
explicitly not timing or bootstrap evidence.

The first genuine B1 preserved 40 selected observations but failed one of 14
new controls: a raw empty constructor name collided with an internal cache index
node. Its failure is retained. Root approved a minimal additional
`constructor_exists` guard against BookCache metadata before the corrected
isolated edit. Independent review confirmed this obligation.

Corrected B1 `4acd7244f1a937cf38fc985ce3154c35c9f334a73049d86eb745b7e9376e67d3`
preserves all 40 observations, passes all 14 additional actual-B1 controls and
all 93 supplemental component assertions. The original strict upstream
diagnostic discrepancies remain unchanged. Production application was authorized
by root and verified against unchanged preimages and checked candidate bytes;
only the cache seed and constructor metadata guard were applied.

Decision: promote to root integration. No timing gain is inferred from counters
or inherited sample attribution. The isolated law-fill timing series is deferred
to root's decisive integrated comparison; broad correctness and controlled final
full-source timing remain pending. Exact artifacts, failure history, commands,
review, scope and source counts are in the linked implementation report.
