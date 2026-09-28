# Phase10: remove the next measured sources of repeated work

Date: 2026-09-28. Prospective design; no Phase10 speed gain is claimed.
Baseline: committed Phase9 release `f21e9f0`, preserved checked attempt
`selfhost/build/phase9/integrated-03`, selected API
`d27968f11fa322bf3685ff0d276d9577a3b589b9cbae80784f5e4d404f7c3529`.
The upstream target remains `b2111cf43244e65f76ddc278ee695e669f720cbf`.

## Objective and boundaries

Repeat the successful Phase9 investigation method: identify expensive callers,
demonstrate unnecessary work with small growing inputs, make bounded changes,
validate their semantic boundaries, then measure the complete checking workload.
The user authorizes another implementation/report cycle, including the existing
commit/push workflow. No earlier time budget is renewed.

The starting compiler checks the final Phase9 source in 66.84 s versus 2.94 s for
pinned TypeScript in the recorded controlled workflow. It accepts 1,000/1,001
positive fixtures and rejects all 482 validation negatives; 731 exact reference
differences, long strings and four imported-law trust cases remain. Those counts
are the baseline, not evidence for a new candidate. Full compilation, generated
program execution and self-reproduction are separate measurements/gates.

## Ordered phases

1. **Refresh the evidence without changing production.** Verify the installed
   release and profile its exact immutable attempt. The previous residual profile
   predates the final string-equality optimization. Use 10 ms CPU sampling with
   the streaming summarizer, record actual source/API/runtime/Base/host and tool
   identities, preserve raw profile and failures. Sampling time is diagnostic;
   it never substitutes for an uninstrumented comparison.
2. **Run independent bounded hypothesis screens.** Loader membership, generated
   calls/allocation and deep-pattern layout have distinct owners and isolated
   directories. Each writes its falsifiable plan before probes. Prefer small
   4/8/16 or similar size series and visited-node/call counts, with exact baseline
   observations, before a checked build. Read historical failures before revisiting
   an idea. Stop an initial screen after a decisive result or about 15 minutes,
   report it, and choose follow-up from evidence.
3. **Implement surviving changes separately.** Use genuine checked B1 builds and
   explicit equality profiles against unchanged pinned upstream. Keep source
   overlays, bootstrap inputs, focused controls, failure histories and exact
   outputs. Root independently reviews invariants and integrates only passing
   candidates. Do not weaken an oracle to promote a speed result.
4. **Validate the combined compiler and measure it.** Run maintained focused
   controls, appropriate backend execution witnesses for emitter/layout changes,
   and the full 2,996-row frontend comparison against the preserved Phase9 vector
   and same-pin reference. Retained expected strict failures remain failures.
   Freeze final source and stop intentional competing compiler jobs before the
   serial TS/baseline/candidate/candidate/baseline/TS comparison on one CPU.
5. **Release and report.** Promote only justified changes, verify installed and
   relocated CLI operation, record source-size/complexity costs and remaining
   gaps, update compiler documentation and experiment frontier, preserve the
   evidence durably, then commit and push. A rejected or inconclusive hypothesis
   receives a report without becoming a production change.

## Hypotheses and stopping rules

| Record | Hypothesis | Cheapest decisive observation | Promotion boundary |
| --- | --- | --- | --- |
| P10-001 | Final-release profiling can identify current expensive callers. | Completed profile with stable inputs and correctly interpreted physical callers. | Diagnostic evidence only. |
| P10-002 | Loader declaration membership repeatedly scans lists or executes checks that their guards do not require. | Count visits/calls as modules and names grow; compare complete loader outputs. | Preserve aliases, imports, namespaces, chronology and error order for supported inputs. |
| P10-003 | Deep-pattern layout validation repeats work on the same structure. | Small depth series, exact results, pass-specific counts and bounded emission. | Preserve layout validity checks, failure behavior and generated program results. |
| P10-004 | Generated call/allocation costs expose avoidable source-level work. | Attribute current callers; count a proposed operation and reproduce a small control. | Preserve evaluation/ownership/ABI semantics; no unguarded generated rewrite. |

Compact strings are a possible subsequent semantic/representation experiment if
the refreshed evidence and available bounded work justify it. They are not to be
folded into an unrelated optimization or assumed to repair long strings without
explicit parse/check/readback/emission controls. Imported-law trust and exact
diagnostic parity stay visible; this phase does not promise complete conformance.

## Measurement and correctness policy

Use Node 24.18.0, a 4 MiB stack and 4 GiB heap for comparable measured workers.
Record actual nested-bootstrap settings instead of assuming parent flags propagate.
Pinned Base and output runtime stay equal. Each compiler uses its own verified
disk Base cache; TypeScript checks Base as in Phase9. Fresh process wall includes
startup/provenance work, request time has its separately stated boundary, and OS
caches are not flushed. Keep every attempted row, timeout and stderr. Two samples
per variant are a descriptive paired comparison, not a confidence interval.

Operation counts explain mechanisms; microbenchmark factors are not compiler
speed factors. The final combined comparison does not allocate improvement to
each change unless an actual whole-workload ablation is measured. Peak RSS is
not an allocation count. Reprofile only when a new finding justifies it.

Use the roughly 27-second checked/focused workflow for routine edits. Broad
conformance and full-source checks are integration gates. Do not mutate the
Phase9 baseline, pinned checkouts, failed attempts, or unrelated Phase6 work.
Root owns integration, controlled measurements, release, evidence publication
and commits. Changes that increase complexity must earn their cost through
demonstrated behavior or measured work reduction; no new line-reduction claim
is implied. A checked B1 derivative is not a new self-hosted fixed point.

The canonical outcome will be
[`implementation/phase10/repeated_work.md`](../../implementation/phase10/repeated_work.md),
with one linked record per hypothesis and explicit correctness, measurement and
promotion decisions.
