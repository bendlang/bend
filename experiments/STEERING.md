# Current compiler experiment strategy

Phase14 is active under its [design](../design/phase14/conformance_and_dispatch.md):
fix imported-law semantics, classify exact differences and correct one shared
cause, with a bounded source-level normalizer dispatch pilot. Phase12 remains
installed until integration gates pass. Dispatch feasibility is capped at 90
minutes; no prior multi-hour budget is renewed. Preserve unrelated Phase6 work.
[Current report](../implementation/phase14/conformance_and_dispatch.md).

Phase13 is complete; integration is deferred. The
[report](../implementation/phase13/structured_rewriter.md) and
[evidence](../implementation/phase13/evidence/README.md) preserve all pilots.
Named-worker lifting is 1.01% slower; one-owner selector fusion uses 6.63% less
checking time; six-owner fusion uses 10.56% less (27.36→24.47s). The latter passes
bounded controls and exact 53/60-request histories, but its self-contained helper
adds 239 lines/7,010 bytes. It misses the roughly 20% target without a compensating
complexity reduction. Phase12 remains installed; no conformance change is claimed.

Phase12 completes the user's next avoid-redundant-work round on2026-09-28.
No historical time budget is renewed. Preserve unrelated Phase6 work.
The [design](../design/phase12/avoidable_work.md),
[report](../implementation/phase12/avoidable_work.md) and
[evidence](../implementation/phase12/evidence/README.md) record the decisions.

## Released Phase12 frontier

The selected compiler is integrated-03, API
`0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697`.
Upstream remains b2111cf. Typed local constructor lookup and literal reuse
remove8Bend lines and one wrapper. The equality profile version5 adds native
choices and164restricted returned-branch blocks, with161terminal calls using
the existing trampoline message. Runtime and public forcing stay unchanged;
versions1–4 replay authentic original artifacts exactly.

Controlled same-source checking is **29.56→26.90s**, **1.10× faster**. Pinned
TypeScript is **2.86s**, leaving a **9.42×** process gap. The1.2–1.5× planning
estimate is not met for checking. Nat300 JS is **15.73→7.90s (1.99×)**;
native C emission is **3.71→2.78s (1.33×)**. JS and C bytes remain identical,
and actual execution returns306n. Native timings exclude Clang. Each matrix
uses serial fresh processes with intentional competing compiler/archive jobs
paused; historical ratios are not multiplied into a new claim.

The final2996frontend observations match Phase11 exactly: all1001positive cases
check, all482validation negatives reject, and no invalid acceptance/timeout is
observed. There remain730exact TS differences (198parse/532check), strict
1006pass/492fail, and four imported-law trust cases fail early. The37paired
backend rows pass with three known exact differences. Current and relocated
CLI checks are separately bound to the installed release. No H→H fixedpoint,
proof-kernel, GPU or general generated-program runtime gain is claimed.

Source is15130physical/12916nonblank Bend lines across59modules,496386bytes,
1484defs/793laws/63types. The host transformation adds23lines/5802bytes and
its tests add37lines/4368bytes; source reduction does not remove that complexity.
The50%/75% simplification targets remain open. The checked build plus22focused
cases spans27.59s; it is not a paired gain versus Phase11's21-case observation.

## Rejected candidates and next experiment boundary

The seed cleanup is rejected even though finite semantic and fresh-worker
controls pass: under exactly53requests it overflows while baseline and JS-only
pass, with all52preceding results exact. Broad returned-branch inlining also
fails fresh and matched-history controls after restoring the normalizer.
Both initial integrations remain failed. The final no-seed leaf candidate
passes both53/60request histories at4MiB, all predecessors exact.

A different history (old21focused cases before the string) can overflow even
Phase11. The maintained22-case selection puts the string first for its
fresh-worker comparison. Do not use that inherited failure to excuse a changed
result under a history the baseline accepts. Preserve actual histories and
resource policy; fixture order is not general stack-safety evidence.

Delayed normalizer spine reconstruction remains deferred for weak benefit and
added protocol cost. Larger term/compact-string changes need new discriminating
evidence. Do not broaden branch inlining or revive the seed cleanup without
addressing the retained counterexamples. Phase13 profiles this final API: exclusive samples assign 14.55% to dispatch and
13.47% to GC. Removing intermediate work helps; shifting closures to capture
arrays alone does not. Reuse the preserved prototype and profiles before another
rewriter trial; broader grammar needs new evidence of substantial savings or
cheaper maintenance. Imported-law semantics and exact diagnostics remain priorities.

## Historical evidence and operating rules

[Phase11](../implementation/phase11/known_work.md) retains checker/offload and
native-Succ improvements, [Phase10](../implementation/phase10/repeated_work.md)
the loader/index/layout changes, [Phase9](../implementation/phase9/checker_speed.md)
the compact-Nat/checker work, and [Phase8](../implementation/phase8/upstream_and_conformance.md)
the upstream migration. Their measurements use their recorded source/artifacts.
S4's simplifications and older genuine fixedpoints remain in the
[Phase7 report](../implementation/phase7/s4-report.md). Rejected binder and
semantic-value trials remain research evidence, not installed mechanisms.

Routine edits use [checked B1 development](../docs/PHASE5_DEVELOPMENT.md).
Keep checked B1, guarded derivative and self-emitted H distinct. Unknown
profiles/bindings/input identities must fail closed. Completed capture is not
a correctness pass. Preserve rejected attempts and superseded consumed tools.
Pause intentional compiler/archive jobs for controlled timing; check launch
errors, signals, timeouts and overflow as well as status and semantic oracles.
Frozen plans stay unchanged; outcomes go in reports, ledger and this frontier.
