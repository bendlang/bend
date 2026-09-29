# Phase24: measured ordinary speed and execution coverage

Frozen plan, 2026-09-29. The user accepted the next phase: profile the released
compiler, improve measured costs, and inventory execution conformance in parallel.
Existing commit/push authorization applies; no earlier multi-hour budget is renewed.

## Baseline and boundaries

Start at 8eb2cc01145041ce7c0dce199daaf7087038e962, installed API5596f914,
checked parent5f539f81, upstream018751270e800bc222a93dad7f257083ee53a5f7.
Preserve the103 unrelated paths recorded in start-state.json. Historical pins and
human-written bend.ts stay unchanged. Ordinary compilation stays in Bend.
The last two-sample ordinary screen was11.0135s versus3.5518s TypeScript (3.10x).
Its ratio is a workflow comparison, not proof of where time is spent.

## 1. Diagnose without production edits

Root profiles the released frozen attempt on CPU0 against the exact previously
used fac06128 compiler source. Reuse the existing inspector CPU tool; capture a
separate allocation-sampling profile after validated Base preparation. Profiles
are diagnostic, never speed samples. Record complete results, input hashes,
API spans, generated function ownership and GC share. Rank repeated traversals,
allocation, generic dispatch and conversion only after observing evidence.
Start with one CPU and one allocation profile, then a cheap discriminating probe.

## 2. Improve one measured responsibility

Before editing production, freeze a distinct hypothesis with its invariant,
falsification criteria and boundaries. Prefer removing repeated work or using
an existing representation over another cache/IR. Retain failed candidates.
Build a genuinely checked B1 with profile6, exact maintained focused gates and
specific semantic counterexamples. Independent review challenges evaluation,
binder capture, diagnostics, ownership and cache identity as applicable.
Abandon an optimization if it needs substantial complexity for unproven benefit.

## 3. Current execution inventory in parallel

Backend owner inventories upstream tests and runs affordable interpreter/JS/native
lanes against the installed image, beginning with four later-emission failures,
new and retained runtime controls. An environment owner separately investigates
the two Bun-dependent reference comparisons and compatible sanitizer availability.
Record expected refusal, environment failure, candidate failure and exact match
separately. Do not count unsupported GPU or independent proof-kernel capabilities
as tested; do not edit emitted programs merely to make an environment run.
Owners use CPUs3-8 and bounded disk; pause CPU work during controlled measurements.
A census can expose new work rather than promise every language/platform gap closes.

## 4. Measure and integrate

Freeze baseline/candidate/TypeScript bundles before serial alternating runs on
CPU0 with4MiB stack,4GiB heap and validated Bend Base caches. Use the same source
and host identities; record process wall, request wall and peak RSS separately.
Use at least three samples per promoted variant where feasible; preserve every
failure and all result fields. Distinguish whole-process and request ratios.
Instrumented profiles and concurrent tests never substitute for controlled costs.

Promote only a measured, reviewed improvement after broad current-pin frontend
and relevant backend gates; otherwise keep the usable release and report a
negative experiment. A new fixed point is a separate bounded integration gate,
not required for every edit. Update compiler documentation, source census,
experiment ledger and steering with exact scope and remaining gaps.

## Evidence and publication

Retain commands, raw results, failed attempts, config and manifests. Reuse the
Phase23 durable capsule/prerequisites instead of copying its whole history.
Archive new consumed artifacts compactly, independently verify recovery, and
record regeneration prerequisites for external tools. Commit explicit owned paths,
push selfhost/bootstrap, and verify the remote commit. Reports separate correctness,
measurement and promotion; historical matching tests do not establish universality.
