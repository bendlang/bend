# Phase23: upstream update and graph conversion

The compiler is updated to upstream
[`018751270e800bc222a93dad7f257083ee53a5f7`](https://github.com/bendlang/bend/tree/018751270e800bc222a93dad7f257083ee53a5f7),
after Bend 2.0.34. The migration implements graph conversion, current Base
compatibility, the new backend fixes and shared-array atomics. It preserves one
contextual frontend and the existing term, graph and array representations.
The exact final image is installed and passes the final corpus and cost gates. The [design](../../design/phase23/upstream-graph-conversion.md)
records the plan and prospective acceptance criteria.

## Baseline and migration boundary

Phase22 through `fb42457` was pushed and the remote verified before this work.
The exact upstream merge adds 29 commits and 15 direct fixtures, with no merge
conflicts or edits to old reference checkouts. The human-written upstream
`bend2/bend.ts` was merged, never hand-edited. The pin stays frozen throughout
this campaign. The [start inventory](start-state.json) protects 103 unrelated
pre-existing files, including Phase6 work and four older release histories.

Storage initially had about 41 MiB free. Eight redundant `/tmp` recovery trees
were removed only after all 150,527 members exactly matched their retained
manifests and the archive/prerequisite hashes were verified. Original evidence
and archives remain. This reclaimed 4,049,702,912 allocated bytes. The
[receipt](storage-reclamation.json) and [member verification](storage-recovery-verification.json)
record exactly what was removed and how it can be restored.

Before algorithm edits, the [controlled comparison](initial-comparison.json)
ran old TypeScript, new TypeScript and the unchanged released Bend compiler in
alternating serial order on the same frozen source. Mean process times were
3.496 s, 3.539 s and 11.646 s, respectively. Each had two fresh-process samples,
identical ordinary observations, its own revision's Base and the established
cache policy. The new upstream alone did not materially change this ordinary
checking workload. These measurements exclude emission.

## What changed and why

Conversion now uses the graph evaluator already used by strong normalization.
It first compares with definitions held rigid, then retries against the real
book. Each policy starts with a fresh heap. Completed equality obligations copy
a forced cell value into the other cell; directional subtype success never
merges cells. The existing worklist schedules sharing only after the necessary child
comparisons succeed. Deferred binder bodies stay outside cells until opened.
This removes repeated unfolding and revisiting of shared terms without adding a
second graph representation, persistent cache or global comparison state.
[Implementation and component controls](graph-conversion.md),
[independent source review](root-review.json), and the
[final image audit](final-conversion-review.md) document the invariants.

The old release exhausted a 1 GiB heap on both new depth-32 conversion programs
in approximately eight seconds. The final compiler passes both with the same
heap cap and ten-second deadline: observed cold CLI times were **1.36 s and
1.41 s**, with a peak RSS across the two runs of 126,368 KiB, recorded in the
[final resource controls](public-depth32-final.json). These concurrent validation
runs establish bounded completion; they do not establish a controlled speedup
ratio from the failed old runs. The earlier assessment and candidate01 controls
remain separately preserved.

The refreshed Base removed `String.eq.fin` and changed the string equality
chain. Guarded profile6 checks the new `String.eq`, `Cmp.is_eq`, `String.order`,
`Pair.snd`, `String.cmp` and lower helper bodies before applying the existing
transformation. Its runtime prefix is unchanged. Selection uses the runtime and
public equality body together, preventing an old profile from being selected
merely because runtime bytes agree. Historical profiles1–5 replay exactly.
The [independent profile review](profile-review.md) covers that dependency
closure. Controls check 151,084 primitive string pairs, nonprimitive fallback,
nine refusal cases, and exact historical replay.

Backend work ports U32-to-Nat widening, substitution that respects foreign
comments and strings, zero-size TCP refusal, and the CPU scheduler's row
allocation correction. The two new shared-array programs also exposed missing
atomic operations. The separately planned
[bounded extension](../../experiments/phase23/P23-002-uniform-array-atomics.md)
implements all nine atomics using existing uniform array slots and native
reference counting. Shared destructuring retains owned children before dropping
the old handle. A surviving alias exposed reversed native `Array.clone` results:
expected119 versus actual199. Returning the original first fixes that defect.
The [backend report](backend.md) details the operations, ownership review,
regression fixtures and environmental limits.

## Final artifact and correctness evidence

Installed derivative:
`5596f914fd245a5085a614b81099360aeaf601ed61f16357fc491c85106c1102`.
Genuine checked parent:
`5f539f81bace8e5783a7cdd8c82606e106fe85813638d7725bff84a943d57c8a`.
Assembled source:
`77da4991d6673b88a0a30183810ae3221c5b37e2aa4372c8844f20a22dfb85b0`.
The production commit is
[`ab246cd`](https://github.com/rom1504/bend/commit/ab246cdd24e7695a14d3b725d5323b95c5f5892b).
The [release manifest](../../selfhost/dist/release.json) binds source, Base,
runtime, host, checked bootstrap and exact transformation. The former default
and its original lineage are retained under `dist/release-history/ade8ef02…`.
Installation and relocated verification create no new bootstrap evidence.

| Gate | Result and artifact scope |
| --- | --- |
| Checked build + maintained focused frontend | Final03: 36/36 exact |
| Full new-target frontend | Final03: 3,026/3,026 exact |
| Retained broader parser selection | Final03: 196/196 exact |
| Retained integration selection | Candidate01: 198/198 exact |
| Original request histories and fresh long-string checks | Final03: 226 paired observations + 2 fresh checks, exact |
| Graph component | 31 normalization controls + 26 exact differential controls |
| Foreign scanner | 4,116/4,116 exact against the new upstream emitter regex |
| JS effect contracts | 16/16 pass |
| New and scoped JS/native execution | Final03: 24 candidate passes; 22 exact pairs, 2 reference-environment limits |
| Retained array/closure/fork execution | Final03: 18/18 exact |
| Native repetitions | Final03: 100/100 across one, two, three and four workers |
| Installed and relocated CLI | Final03: 42/42 pass |
| Maintained runtime, compiler ABI and harness | Pass; harness 114/114, localhost runtime checks require socket permission |
| Advertised `npm run verify` | Final component runner: 18/18 steps pass in37.74 s, including a genuinely checked API |

Selections overlap. Raw main-corpus statuses are 2,525 pass, 497 observed and
four fail on both frontends. The four fixtures expect later emission errors;
frontend agreement does not turn them into raw passes. The
[frontend report](frontend-validation.md) preserves all verdicts, exact
comparison fields, worker health and explicit reference reuse. The
[history report](history-controls.md) retains the original request order and
resource policy, with no diagnostic exception, worker failure or recycling.

Maintained validation tools now target the current contracts. Harness fixtures
bind the new pin and mandatory load ABI2, and still refuse unknown checker
capabilities. The component runner replaces retired parsed-source exports with
completed-source equivalence. Its fixtures use the existing `KWorld`/`KEnv`
layout, source-origin intervals and integrated template checking. Exact
source-span assertions are retained or strengthened. Historical fixture files
and every failed maintenance attempt are preserved. `npm run verify` supplies
the documented stack/heap limits; no compiler behavior was changed to satisfy
these test repairs.

The two nonexact execution pairs are JS TCP programs: the candidate produces
the expected output, while upstream requires `bun:ffi`, unavailable under the
Node reference environment. Their strict paired reports remain false. All nine
atomic operations and the clone/boxed ownership witnesses are exercised.
ThreadSanitizer could not execute: GCC10 could not compile Clang's `musttail`,
and Clang16 instrumentation could not link the installed older sanitizer
runtime. These failures are retained; no race-detector pass is claimed.

## Cost and complexity

The [first combined cost screen](initial-cost-screen.json) compares four bundles
in eight alternating exclusive rows. New TypeScript averaged 3.835 s, Phase22
11.442 s, unchanged compiler source refreshed at the new pin 11.433 s, and
candidate01 11.635 s. Candidate process cost rose1.69% and request cost1.90%
against the old release, within the prospective3% screen. This is near-neutral
ordinary checking cost while fixing the pathological conversion cases.

The [final03 controlled screen](final-cost-screen.json) passed with complete
observation equality and stable identities:

| Bundle | Mean process | Mean request | Peak RSS, KiB |
| --- | ---: | ---: | ---: |
| New pinned TypeScript |3.552 s|2.359 s|485,688|
| Released Phase22 |10.971 s|9.743 s|714,192|
| Phase22 source refreshed at the new pin/profile |10.920 s|9.691 s|774,140|
| Final Phase23 |11.013 s|9.793 s|767,924|

The final process/request change versus the old release is **+0.39%/+0.52%**,
within the prospective3% screen. Against the refreshed baseline it is
+0.86%/+1.05%. Peak RSS is7.52% higher than the old release but0.80% lower than
the refreshed baseline; this does not isolate a graph-allocation effect. The
remaining process-time gap to new TypeScript is **3.10×**. Ordinary throughput
is near-neutral; the decisive gain is bounded conversion on shared terms.

The final run uses the same frozen source, four bundles and alternating order.
All other compiler tests/builds and archive hashing were paused. The
[independent measurement review](measurement-review.md) checks its boundaries. Process time includes startup, identity hashing
and output capture; request time includes lazy API loading. Bend uses validated
Base caches; TypeScript checks Base. Each bundle carries its own actual host,
runtime and revision's Base. Two samples are a cost screen, not a statistical
bound or a generated-program speed result. Identity-hashing scope differs from
the initial six-row baseline; compare variants within each acquisition.

The reproducible [source census](source-census.json) counts only the canonical
60 Bend modules: **15,748 physical lines, 13,442 nonblank lines, 586,637 bytes,
1,700 definitions, 640 laws and 68 datatypes**. Against Phase22 this is +148
physical lines (+0.95%), +137 nonblank, +6,173 bytes, +9 definitions and +2 laws;
module and datatype counts are unchanged. Conversion adds one worklist case,
while atomics reuse existing arrays/reference-counting machinery. Functionality expanded with
modest source growth. This phase does not claim source reduction or the older
50%/75% goals. The final checked bootstrap took13.52 s, Base preparation2.18 s
and focused selected execution14.87 s in their observed concurrent runs;
roughly31 s of these phases is an iteration observation, not an exclusive loop
benchmark.

## Preserved failures and remaining scope

The evidence retains the initial component syntax failure; scanner sandbox,
syntax and omitted-dependency failures; early JS TCP harness errors; missing
atomic observations; invalid scoped fixture syntax/float output comments; the
real clone-order failure; both sanitizer attempts; the history sandbox failure;
and stale maintained-harness assumptions. Corrections add new attempts rather
than rewriting failed reports or counting invalid launches as compiler results.
The unavailable `/usr/bin/time` launcher failed before executing its compiler;
the corrected public resource harness uses Python's child-resource accounting.

The new pin is an implementation target, not universal language equivalence.
Independent BendTT `--verdict`, GPU hardware, hub functionality and a new
self-hosted fixed point remain outside this release. Arbitrary simultaneous
structural array reads and atomic writes have no race-safety claim. Existing
numeric representation bounds remain. The compiler runs ordinary compilation
without a TypeScript fallback. Follow the linked
[compiler guide](../../docs/BEND-IN-BEND.md) for use and rebuilding.

The [preservation guide](evidence/README.md) identifies the complete Phase23
capsule and its historical/Git/toolchain prerequisites. Independent recovery
verified all **66,245 members /55,119 files /382,078,181 file bytes**, including
exact original producer membership, restored bytes, modes and types. The
[receipt](evidence/recovery-01.json) distinguishes restoring this capsule from
re-executing tests or restoring every external prerequisite. The compressed
capsule is18,532,332 bytes. Original build evidence remains in place.

The next performance investigation should profile the final ordinary checking
workload; the depth-32 repeated-conversion defect is now addressed.
