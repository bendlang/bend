# S3: one authoritative checker result

Status: complete; see the [S3 report](../../implementation/phase7/s3-report.md).
Design committed as `ab9e136` before implementation. Baseline: S2 commit `7474b0b`,
15,826 physical lines / 13,209 nonblank lines / 491,193 bytes.

## Scope and rationale

Keep the existing `KChecked` failure and trace through definition/template
checking. One chronological event worker must produce the verdict and diagnostic
together. The public String-returning checker APIs project the error from that
result. The detailed APIs keep their current `DResult`, diagnostic and book shapes.
Delete the String-only event loop, duplicate prefix loop and diagnostic replay's
duplicate definition/template checker. The host consumes the authoritative result
once when the compiler explicitly advertises version 1 of this capability.

The prior [structured-checker experiment](../../implementation/phase7/s0-evidence/phase6-structured-checker.txt)
provides a concrete patch and falsifiers, not validation of this revision. Its
patch applies to S2 unchanged: kernel -17 lines, prefix -29, producer -94,
host +2. Add the requested explanation that ADT/foreign legacy String checks use
empty error as success even when packed by `bad`; callers must test `good/ce`,
not infer acceptance from a payload tag. Expected Bend savings are 139 lines
with that comment. Record actual physical/nonblank/byte and host deltas.

Retaining types through specialization is deferred. The 400-line annotation
module cannot be deleted without replacing its dependent and erased-argument
reasoning, template-instance context and freshness handling. Earlier exact-input
instrumentation did not justify a generic annotation cache. No typed-fact table,
new term variant or source-location ABI is introduced in this phase. The original
10,500-line S3 forecast remains unsupported; completing this bounded reduction
does not establish that forecast or either overall milestone.

## Invariants and cost gate

- Preserve first-event/first-error order, duplicate declarations/constructors,
  forward laws, unsafe fills, template environments, quantities, termination,
  foreign signatures and final unresolved-hole/TODO checks.
- Keep the exact prefix comparison and full-check fallback, including a prefix
  longer than the entire book. A trusted cached prefix remains compiler/source
  bound and validated by `check_book`; it is not an unchecked bypass.
- Keep original failure metadata. Diagnostic formatting/location must not change
  the authoritative error or accept a rejected program.
- Old artifacts without the new capability retain the guarded legacy host path.
  The host tests the exact capability version; do not infer it from a function's
  mere existence or from diagnostic text. Add the capability to selected exports.
- Require at least 130 fewer Bend lines (at most 15,696), fewer nonblank lines and
  bytes, and a decrease after charging host support. No compiler work may move
  into the host. Count any compatibility code and test/tool additions separately.

## Sequential validation

1. Apply the reviewed patch only to the three Bend modules and typed driver.
   Add the clarification comment. Check residual references and update misleading
   replay documentation. Build a fresh checked B1 and equality derivative through
   the maintained workflow, preserving the existing 21 focused controls and their
   known exact differences.
2. Run maintained components and `diagnostic-reuse.mjs` against frozen S2. The
   latter compares complete diagnostic/book results, prefix mutations, source
   locations and real Base behavior. Keep the actual new host in scope.
3. Reuse the observational check-call counter with S2/current attempt identities.
   Demonstrate four checks of the selected failing body becoming one in early
   and late no-Base fixtures. Require identical accepted/rejected host results,
   exact oversized-prefix fallback, no call to the String checker on the new
   host branch, and continued legacy behavior for the S2 artifact.
4. Collect fresh full parse/check vectors for S2 and candidate with identical
   pinned corpus, Node/resources and maintained host snapshots. Compare all
   2,756 observations exactly, including all 459 negative check fixtures and
   919 positive check fixtures. Existing strict failures stay explicit; a
   completed preservation vector is not complete upstream conformance. Do not
   approve any new acceptance, changed first diagnostic, timeout or missing row.
5. After correctness passes, run the existing controlled core-workload pilot
   serially: accepted library compilation and early/late rejection, four fresh
   processes each in ABBA order, CPU 0, Node 24.18.0, 4 GiB heap/4 MiB stack.
   One frozen conditional host supports both artifacts; prime each API-specific
   Base cache and verify decoded graphs, exact output hashes and input identities.
   Accepted request/process cost must stay within 5%; peak RSS/generated size
   growth beyond 10% requires explanation and resolution before promotion.
6. Independently review the changed paths and actual costs, install the validated
   attempt, verify release integrity, and run ordinary check/interpreter/JS smoke.
   Unchanged backend generation retains its previous execution scope. No native
   execution is claimed while Clang is absent. Full source B1→H→H remains a
   milestone gate, not something inferred from a checked B1.

The original evidence scripts are unpromoted historical worktree inputs. Snapshot
their exact consumed bytes and hashes with current results; do not silently stage
unrelated Phase 6 research or rewrite failed historical attempts. Prefer existing
controls over a second framework. Timing starts only after correctness preflights
and runs without competing intentional compiler/archive/hash jobs.

## Deliverables

Write `implementation/phase7/s3-report.md` with exact deletions, the retained
single-check invariant, host compatibility, full frontend comparison, controlled
timings, resource costs and limitations. Preserve raw evidence and the usable
release, update the compiler guide/ledger/steering, then commit and push before
S4. S4 must confront the still-large gap to 8,254 lines; these smaller completed
phases do not make the 50% goal evidence-backed.
