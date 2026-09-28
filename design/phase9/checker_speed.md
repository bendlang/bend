# Faster checking with preserved semantics

Date: 2026-09-28. User authorization: design, implement and report the checker
performance work proposed after the upstream migration. This phase has no renewed
historical time budget. Implementation, measurement and promotion are separate
decisions; a hypothesis may end in a retained counterexample.

## Objective and baseline

Reduce the cost of running the compiler written in Bend, while retaining its
current semantics and upstream target. Keep the short checked-B1 development
workflow. Avoid using a complete self-check as the inner iteration loop.

The baseline is Phase8 release07 at repository checkpoint `bc322d9`, targeting
upstream `b2111cf43244e65f76ddc278ee695e669f720cbf` (Bend 2.0.32 era). Preserve
that release and its immutable attempt before edits. API SHA-256 is
`e928f77778de9dc72267e26b6a7ccb029cac318ccd35dd8f9248da1c6374bbe4`; source is
`0f5425ac8a2298f444b0907632088b406da61420407331e80708d9fea6a47822`.

The controlled checking workflow took 205.26 seconds versus 2.804 seconds for
TypeScript, 73.20 times the process wall. It excludes emission. The separate
coarse profile placed 183.69 of 221.37 seconds in the checker, but does not
identify a causal cost breakdown. The short bootstrap plus 21 focused controls
took 26.94 seconds in one integration attempt.

The current 2,996 frontend observations contain 997/1,001 positive type
acceptances, 481/482 determinate negative refusals and one negative timeout.
Seven of eleven proof-trust refusals reach the intended phase. There are 734
exact TypeScript differences. Do not hide these baseline gaps behind pass
percentages. Preserve the old TypeScript reference and candidate vectors.

## Stage 0: record opportunities without changing production

Inspect the exact installed generated code and upstream checker. Record one
hypothesis per experiment under `experiments/phase9/`, with prospective controls
and falsification criteria. Preserve initial worktree state, especially unrelated
Phase6 work. No hand edits to upstream `bend2/bend.ts` or frozen checkouts.

Code-visible opportunities are:

1. String.eq calls generated String.cmp, allocating character/tuple results and
   rebuilding strings. Native equality previously improved another artifact;
   its old guarded transform rejects the new body correctly.
2. Lambda checking always rechecks the domain's kind, while upstream does so
   only for an affine-to-unrestricted quantity promotion.
3. Conversion computes fresh binder bounds before its exact equality shortcut.
4. Successful variable inference performs the same context lookup twice.
5. Substitution rebuilds trees, ordinary weak-head evaluation lacks the graph
   evaluator's sharing, and context/usage lists require repeated scans.
6. Compact literal representation is absent at several checker boundaries and
   contributes to remaining literal termination/stack failures.

These are hypotheses about cost, not an allocation of the measured 73x gap.
The previous demand-order failures of the general semantic-value prototype and
the generic binder-walker regression remain valid reasons for narrow experiments.

## Stage 1: bounded benchmarks and independent candidates

Freeze small representative workloads before recording their timings. Include
closed data, increasingly deep binders, repeated conversion, variable lookup,
substitution and real compiler declarations. Target seconds per small experiment.
Retain an uninstrumented timing lane. Instrumented operation counters and CPU
profiles are attribution evidence and must not be mixed into speed ratios.

Benchmark outputs must be consumed and checked. Positive results, refusal phase,
quantities, binder freshness and demanded errors are observations, not only
execution time. Size series should distinguish fixed overhead from repeated or
quadratic work. Report startup, request and operation timing separately where
applicable. Do not claim a whole-compiler speedup from a helper microbenchmark.

### P9-001: guarded native equality

Extend the maintained derivation helper to recognize the exact current checked
String.eq/String.cmp dependency contract. Preserve legacy verification. Unknown
bodies and missing provenance must still fail closed. Keep checked parent and
derived API as different artifacts; never copy a bootstrap sidecar to a derived
API or label a derivation a bootstrap.

Validate empty/equal/unequal strings, prefixes, ASCII, Unicode, surrogate cases
and public ABI. Run actual frontend and emitted-program controls. Compare exact
selected emitted bytes where the compiler source is unchanged. Any semantic
difference rejects the candidate. The old 43% full-compilation improvement is
motivation, not a predicted gain for the current checking workload.

### P9-002: remove unnecessary checker work

Keep three ablations reproducible before combination:

- Conditional lambda-domain kind checking, matching upstream's promotion rule.
  Prove the already-valid-goal invariant at callers and retain quantity, unsafe,
  matcher and malformed-input counterexamples. A newly accepted invalid program
  rejects the candidate.
- Delay fresh-bound scans until exact comparison fails. Preserve alpha-renaming,
  shadowing, cached book bounds and error/demand behavior; an early equality must
  not skip an otherwise required semantic check.
- Reuse a successful variable lookup, preserving unbound-variable diagnostics
  and usage accounting. Do not replace the context representation prematurely.

Use genuine checked B1 builds of each ablation, focused paired controls and a
representative checking capsule. Record source size and generated API changes.
Avoid adding a general framework around these small changes.

## Stage 2: residual cost and compact literals

After Stage1 survives its controls, profile the combined candidate. Select a
deeper change only when a retained profile or size/counter experiment identifies
the bottleneck. Candidate directions are usage/context indexing, reduced copying
substitution and direct generated control flow. Do not promote a broad evaluator
rewrite merely because it looks smaller.

Independently investigate compact Nat/string literals with the exact new upstream
fixtures: string_literal_descends, string_literal_long, nat_pattern_deep,
nat_literal_unfolds and invalid literal_descent_linear. The representation must
unfold on demand in matching, conversion and descent, and remain compatible with
parsing, annotation, pretty printing and both emitters. Never weaken termination
checking or drop literal payload precision to obtain a passing fixture.

First discriminate representation cost from duplicated descent recursion. The
initial read-only review finds repeated child comparisons and a retry of the
same failed child during suffix search; upstream remembers the failed index.
Test a matching small traversal repair independently before a new literal IR.

Start with an isolated, checked prototype at the narrowest viable boundary.
Actual semantic falsifiers decide promotion. If the representation requires an
unvalidated cross-compiler redesign, retain the prototype/diagnosis and explicit
unresolved obligations rather than silently expanding or accepting the risk.

## Stage 3: integrate and measure the real workflow

Integrate only independent survivors. Build a fresh checked parent and, if
validated, its maintained equality derivative. Use final assembled source as the
same input for baseline, candidate and pinned TypeScript. Freeze source, API,
Base, host, runtime, harness, Node and cache identities before measurements.

For the final full-source checking comparison use fresh processes in serial
order TS/baseline/candidate/candidate/baseline/TS on one fixed CPU, with no other
intentional compiler workload. Use Node24.18.0, 4MiB stack, 4GiB heap and a
600-second child deadline. Base-cache policy matches Phase8: each Bend artifact
has a separately validated disk cache; TypeScript checks Base afresh. OS caches
are not flushed. Report all observations, mean request/process times and peak
RSS. Two samples are descriptive, not a confidence interval. Failed rows cannot
be omitted to manufacture a mean.

All variants must accept ordinary types, find no holes, and agree on the unsafe
definition set for the compiler source. Measure checking/trust reporting only;
do not call it full compilation or runtime performance of emitted programs.
Preserve any preflight or concurrent profile separately from controlled timing.

Run the complete new-target frontend inventory and compare against both the
unchanged Phase8 vector and pinned reference. Preserve exact diagnostics and
timeouts. Run applicable checker components and selected interpreter/JS/native
execution controls, including quantity/termination adversaries. Known source-
caret differences remain visible. A changed semantic observation needs an
explicit upstream-supported explanation, not an automatically relaxed oracle.

## Stage 4: release, report and preserve

Install a candidate only after provenance, scoped correctness and full-inventory
regression assessment. Preserve the Phase8 release and genuine checked parent.
Validate ordinary and relocated CLI use; document the chosen default build
profile. No new self-hosted fixed-point claim without running and auditing that
separate procedure.

Write `implementation/phase9/checker_speed.md` with measured gains, unchanged or
improved conformance, source counts, rejected attempts, residual profile and next
priority. Update the compiler guide, README link, experiment ledger and steering.
Archive small reproducers, exact commands, sources, APIs, outputs, failures and
raw measurements durably; reuse prior capsules by identity when appropriate.
Do not generate an archive of unrelated build directories or duplicate the
entire historical archive. Verify recovery and distinguish external toolchains.

Commit the prospective design before experiments. Checkpoint independent
results, then commit and push the integrated compiler, documentation and report
to the authorized `selfhost/bootstrap` fork branch. Preserve unrelated work.

## Ownership and resources

Root owns design, integration, final measurement, release and commits. One agent
owns the equality helper, one the three bounded checker changes, and one the
compact-literal investigation. Source edits have disjoint ownership. Agents use
CPU1/2/3 for non-controlled development only; all stop during the final CPU0
measurement. No nested broad compiler jobs or competing full-source benchmarks.
