# P13-004 — Controlled structured-rewriter comparison and replay

Prospective plan, frozen before compiler probes on 2026-09-28. Owner:
`/root/p10_layout`; implementation coordination: `/root/p10_membership`; reviewer:
root. Baseline is released Phase12 commit `9a4e109`, immutable
`selfhost/build/phase12/integrated-03`, selected API
`0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697`.
Upstream remains `b2111cf43244e65f76ddc278ee695e669f720cbf`.
Outcome report: [measurement](../../implementation/phase13/measurement.md).

## Claim and cheapest disproof

A structured replacement for the current generated-image rewriter may improve
reviewability and compiler-host speed, but neither follows from fewer lines in
one file. Compare the actual selected artifact against Phase12 under identical
host, cache and resource policy. Initially this owner performs static work only
while root profiles CPU0. Any compiler launch needs root's resource release.

First establish current-image parity or exact output differences, then exercise
the retained stack counterexamples before spending time on full-source timing.
One changed acceptance, diagnostic, demand/order result, missing prefix row or
new resource failure rejects the candidate at that gate. A complete capture or
successful child launch cannot upgrade a failed semantic observation.

## Gates, in order

1. Bind the candidate to its genuine checked parent and reviewed transformation.
   When source is unchanged, an explicit derived image is adequate for cheap
   screening; it is not relabeled a new bootstrap. Preserve candidate source,
   helper, parser dependencies, runtime, Base, host and toolchain identities.
2. Reuse the existing public/guard/boundary controls owned by the implementation
   and semantic reviewers. Include runtime/export drift, lexical bindings,
   callee/argument order, Unit captures, generated tail calls, nested/nonterminal
   and optional calls, returned closures, currying and errors. Do not recreate
   a second competing semantic suite in this measurement owner.
3. Run the pinned 6,000-character string check once per image in a fresh unchanged
   conformance worker. Use the original oracle, actual check phase and ordinary
   proof-trust result. No stack hook, synthetic expected acceptance or raised
   limit. Per-image Base caches must already be validated before workers start.
4. Replay both exact persistent histories, current Phase12 and candidate, in
   separately fresh sessions. The 53-request history originates in
   `phase12/frontend-02/candidate.json.artifacts/477/request.json`; the 60-request
   history is the explicitly reconstructed
   `phase12/call-prefix-input-01/phase11-passing-request.json`. Original session,
   request and rolling prefix digests must verify before substitution. Retain
   every predecessor's original complete-result digest and compare every row.
   The first history's original target is a rejected seed-containing compiler's
   failure: preserve that failure as evidence, while the current Phase12 target
   must accept. Do not accidentally use the failed target as the success oracle.
   The 60-request original target accepts. Preserve current baseline-versus-
   original, candidate-versus-original and candidate-versus-current comparisons.
5. Only a surviving artifact receives any short performance screen. Its selection
   and process/request boundary must be frozen before launch, all samples kept,
   and concurrent screens labeled diagnostic. Root owns full-source and final
   emission matrices. Prefer unchanged Phase9 `check-matrix.mjs`, using final
   same source and TS–old–new–new–old–TS order. No speed claim from counts,
   profiling, warm-up, selective reruns or rejected compiler images.

## Fixed replay and measurement policy

Node24.18.0, 4MiB stack, 4GiB heap; 30s per replay request, 64-request recycling
and 4GiB RSS cap. Replay preserves request order, test bytes, lane, original
host and runtime bytes, canonical Base path and relevant environment including
trace behavior. Affinity is assigned by root. No new memo, unchecked cache or
resource increase is introduced. Use one newly started runner per historical
session and assert its expected generation/index: an early restart is a failed
history, not a continuation with a clean stack.

Use separately verified, immutable API-specific Base caches. Verify API, cache
bytes and book hash, copied host inputs, fixtures and Node before and after the
run. Output/project/cache identities may differ and must be recorded explicitly;
complete compiler result objects must not be path-normalized to hide changes.
Persistent worker errors, crashes, timeouts or protocol failures reject the run.
Outer launches use the unchanged supervisor and `requireExecution`, rejecting
spawn errors, signals, overflow and deadlines even when exit status is zero.
Preserve all stdout/stderr and partially completed vectors on failure.

Matching recorded request history controls a major confound; it does not recreate
the historical V8 optimization schedule. Reproduce the current baseline in the
same setup rather than assuming its historical result. The old 21-case history
followed by the string is an explicit Phase11 resource boundary, not grounds to
waive a candidate failure on a history the current baseline accepts.

## Complexity accounting

Count physical/nonblank lines, bytes and named transformation stages separately
for production Bend, active rewriter/parser, retained historical replay paths,
maintained semantic tests, experimental harnesses and generated artifacts. Report
both active-path and aggregate maintained-helper totals. Moving the old helper
into a legacy module does not remove its maintenance burden; hiding parser code
in a new dependency is not a line reduction. List lexical/AST representations,
matching rules, guarding, rewriting/printing, ABI and provenance obligations.

Baseline helper is 296 physical lines / 27,345 bytes; maintained helper tests
are 207 lines / 17,679 bytes. Record actual new counts instead of promising a
percentage reduction. Historical v1–v5 releases must replay authentic bytes;
current behavior, historical reproduction and experimental prototypes are
separate surfaces. Source counts do not prove concept complexity or correctness.

## Preservation and decision

Owned tools and raw work stay under `selfhost/tools/performance/phase13/measure-*`
and `selfhost/build/phase13/measure-*`. Preserve consumed predecessor tools,
original histories, complete failure vectors and exact candidate identities.
No production edits, release promotion or archive capture belongs to this owner.
The plan remains unchanged after execution; results and limitations go in the
linked implementation report. Stop after a decisive regression and report the
smallest reproducer; do not run a broad suite to compensate for a failed cheap
gate. Root decides integration and final controlled measurement.
