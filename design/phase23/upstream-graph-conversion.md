# Phase23: update upstream and preserve shared conversion

Status: plan frozen before implementation. The user authorized the complete
update, validation, documentation, commits and pushes on 2026-09-29.

## Target and baseline

Move from `b2111cf43244e65f76ddc278ee695e669f720cbf` to the inspected
`018751270e800bc222a93dad7f257083ee53a5f7` (2.0.34 plus subsequent fixes).
Freeze this revision even if upstream advances during the work. The Phase22
release at `fb4245719005f3c84000a4ff710ddfd180179e01` is pushed and remains the
old-target reference. Its genuine checked B1 and version5 derivative are distinct
artifacts. Preserve historical reference checkouts and all unrelated Phase6 and
release-history files. Never hand-edit upstream `bend2/bend.ts`.

Inspection found29 commits,15 added direct Bend fixtures, no changed existing
fixtures and no parser syntax change. Main frontend inventory grows from1498 to
1513 files, yielding3026 parse/check observations. Source overlap is confined to
nonoverlapping README edits. The current compiler passes the new object-key
regression, but both new depth32 conversion regressions exhaust a1GiB heap in
about8seconds. These bounded assessment probes are failures, not timing samples.
The previous3.1623x checking ratio applies only to the old pin.

## Sequential integration stages

1. **Preserve and measure before changing compiler code.** Inventory the current
   release, dirty paths and source. Reclaim only independently recoverable,
   verified duplicate compiler scratch, retaining archives and restoration
   metadata. Materialize a separate exact reference with bounded storage. Run a
   controlled old/new TypeScript comparison and the unchanged released Bend
   compiler on the same frozen source, with explicit Base and startup boundaries.
   Acquire all15 new fixtures against the new reference; bound pathological
   conversion cases rather than spending unbounded time reproducing failures.
2. **Merge and establish the new build boundary.** Merge the exact revision,
   update the active manifest/version and default reference path, refresh Base,
   and build a genuine upstream-checked B1 before deriving any optimizations.
   New emitted runtime/String/Cmp bodies require a separately reviewed profile;
   retain exact replay of versions1–5. Unknown shapes must continue to fail closed.
3. **Port independent observable fixes.** Widen U32.to_nat to u64 before native
   arithmetic. Scan foreign identifiers only in code, skipping quoted text and
   comments in both emitters. Reject zero-length TCP receive/poll with EINVAL.
   Correct CPU work-distribution capacity for arbitrary supported thread counts.
   Preserve our runtime/ABI and uniform array representation; test upstream's
   array/layout witnesses without importing an unrelated packed-array design.
4. **Reuse graph evaluation for conversion.** First compare without unfolding
   definitions, then retry with the real book. Preserve sharing through the
   existing graph evaluator and merge cells only after equality succeeds. Keep
   the explicit comparison worklist, binder identity, kind alternatives and
   directional subtyping. No new parser authority, TypeScript fallback or
   unrestricted global cache. Validate each bounded change before combining.
5. **Validate, measure, simplify and release.** Run all new tests and retained
   frontend/backend/import/history/ABI controls. Acquire new-target full exact
   comparison independently; do not relabel old reports. Compare the frozen
   source against new TypeScript and the preserved old release, recording each
   Base/runtime/profile difference. Count canonical source and retire superseded
   comparison workers when tests establish equivalent behavior. Install and
   verify a relocated usable release, update docs/README/report/ledger, preserve
   failures and reproducible artifacts, and commit/push explicit owned paths.

Implementation work in stages3–4 may proceed in parallel after stage1; integration
and promotion gates remain sequential. Source owners are disjoint. Only the
lead owns pin changes, bootstrap profiles, default installation and Git writes.

## Hypotheses and falsifiers

- **Rigid comparison avoids premature expansion.** Compare alpha/beta-equivalent
  symbolic calls with an empty definition book using the same conversion rules.
  Reject the change on altered negative verdicts, subtype direction, first-error
  behavior or repeated rigid passes at every recursive node.
- **Graph conversion removes exponential revisits.** Existing GHeap/GState and
  g_wnf provide memoized evaluation. A proved EQ pair can share a representative;
  successful LE must never imply symmetric equality. Test depth scaling, unequal
  leaves, later mismatches, alternative branches, fresh binders and stack depth.
  Evaluation caches must not cross rigid/full books, requests or incompatible
  binder scopes. A node pair must not be marked equal before its proof completes.
- **Selective runtime ports preserve the existing ABI.** Execute numeric overflow,
  foreign-comment/string, socket and thread-count witnesses. Header/source shape
  alone cannot establish runtime conformance. Keep unsupported platform outcomes
  visible and compare environmental failures with upstream.
- **A reviewed successor profile retains fast iteration.** Check generated body,
  runtime, source and export identities. Re-run string/choice/stack histories and
  refusal controls. Never grant genuine bootstrap provenance to a derivative.

## Measurement and preservation

Use fresh processes, identical frozen input, Node24, CPU affinity,4MiB stack and
4GiB heap; retain exact commands, hashes, all outcomes, wall time and peak RSS.
Record request versus process timing and Base-cache preparation separately.
Use alternating serial runs, with no competing builds during performance gates.
Small repeated screens guide decisions; do not infer a universal speedup or a
generated-program performance gain from checker measurements.

Routine checked build plus selected controls is the edit loop (~33seconds in
Phase22). Broad frontend acquisition (~6minutes previously) belongs at integration
checkpoints. New graph cases start under explicit resource limits. A failed
attempt remains immutable; correct the source and create a new attempt.

Each hypothesis gets an experiment record and linked implementation evidence.
Durable compressed evidence must include exact restoration instructions and
independent byte checks. Storage reclamation requires proof that the removed
files are redundant recoverable scratch, not the sole retained evidence.

## Scope and acceptance

The goal is a usable compiler conforming to the new pinned frontend and supported
interpreter/JS/native behavior, with bounded shared equality and a fast edit loop.
Independent BendTT --verdict, hub publication and untested GPU hardware remain
separate capabilities. The update neither silently implements them nor claims
universal soundness or a new self-hosted fixed point.

Accept only complete, identity-stable reports. Keep raw negative fixture verdicts
separate from exact reference agreement. Investigate every newly lost match and
any representative checking slowdown; do not mask it with changed inventories,
cache policies or faster pathological examples. Report final source size and
conceptual changes alongside speed and conformance.
