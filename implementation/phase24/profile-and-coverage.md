# Phase24: ordinary lookup cost and execution gaps

The installed compiler takes **4.89% less process time** on the controlled compiler
workload, moving from 3.139× to **2.985× the pinned TypeScript compiler** in the same
measurement window. Two backend conformance gaps are fixed. Frontend comparisons
remain exact, and the bounded backend pilot is now 81/81 exact. This adds 28 Bend
lines and three helpers without a new representation; backend coverage remains
partial. The release, evidence and limits are detailed below.

The first measured opportunity is avoiding local declaration-list scans when the
existing contextual index proves a name absent. A hit retains the complete old
scan: the index cannot safely replace first-event lookup for duplicate headers.
The checked candidate passes36 focused exact comparisons. Independent private
controls cover21 named cases plus567 comparisons across63 publication states,
including hash collisions, aliases, duplicates and temporary headers. Deliberately
inconsistent private states demonstrate the invariant boundary rather than being
silently accepted as equivalent.

## Initial diagnostic findings

The released image's corrected CPU profile02 attributes5.019s to source completion
and3.343s to diagnostic checking in a9.857s warmed request. f_find owns623.8ms
exclusive samples; its parent stacks chiefly identify local header/signature
lookups. Runtime dispatch17.27%, GC8.78%, span validation5.31% are visible too.
These are instrumented concurrent diagnostics, not controlled timings. CPU0 and4
are SMT siblings; all agent CPU work pauses for comparative timing.

Separate allocation sampling at1MiB estimates9.296GB allocated (including objects
collected during the request), not peak or retained memory. Lexical owners include
context materialization8.28%, has_name5.01%, index_remove3.89%, lexer cursor3.81%
and missing3.57%. The samples diagnose candidates, not exhaustive counts.

Retained failed tools: profile01 expected status ok, but this compiler source is
correctly typeAccepted with an unsafe proof verdict; the old assertion failed.
Allocation01 exhausted JSON string serialization on its giant sampling tree.
Allocation02 uses a coarser interval and frame aggregation, retaining sample
records and exact call-frame allocation totals. Sampling stops after CPU-profile
serialization, so totals include profiler/report overhead as well as compilation.
Neither tool failure changed the compiler.

See [design](../../design/phase24/profile-and-coverage.md),
[local absence hypothesis](../../experiments/phase24/P24-002-local-absence.md),
[independent review](profile-review.md). The following sections record final comparison, conformance scope and release decision.


## Compiler changes and independent review

The local absence guard uses a producer invariant: each local declaration also
publishes a mapped header in the existing scope index. It never reuses a possibly
different prior-event definition from that index. The first isolated screen finds
1.50% process and1.58% request improvement, with no overlap between its three-sample
baseline/candidate ranges. This modest result does not justify a broader lookup
rewrite. See [cost screen](local-cost-screen.json) and [review](profile-review.md).

Membership's first attempt used a local Boolean match. The pinned language
rejects local match scrutinees, so that checked build fails and remains retained.
The next attempt passes the same Boolean to one worker; the existing bootstrap
lowering produces a single two-state loop without branch closures/trampoline
messages. It preserves first-hit demand and String.eq. Its independent controls
cover18 examples,1,152 deterministic cases,15 deep probes and7 demand/error cases.
No new intermediate representation, cache, datatype or parser field was added.

The backend pilot finds and repairs two gaps. Emission now rejects foreign/constructor
name collisions after reserved-name validation and before reachability, using a
lazy constructor lookup only for foreign definitions. Native function IDs reuse
existing scalar encoding rather than folding case/punctuation; MAIN_FID and foreign
symbolic references use the same mapping. The [backend report](backend-census.md)
retains the failed baseline and complete scope, while the independent
[patch review](backend-patch-review.json) checks first-error/identifier invariants.
Longer identifiers are a real source-size cost: the saved nat_ops C output grows
220,154→269,190bytes (+22.27%). No generated-program speed improvement is claimed.

## Controlled final cost

Other compiler builds, tests, profilers and environment probes paused for15 serial
observations on CPU0: three per bundle, in the frozen alternating order. Light
documentation/metadata work continued; this is not a reservation of the whole host. Same fac06128 compiler source,4MiB stack,
4GiB heap, validated Bend Base caches and actual per-bundle host/runtime identities.
TypeScript checks its Base. No emission/program execution is inside this ratio.
All complete observations agree; there are no discarded failures or changed inputs.

| Bundle | Mean process | Mean request | Peak RSS KiB |
| --- | ---: | ---: | ---: |
| Pinned TypeScript |3.7370s|2.4290s|498,780|
| Released Phase23 |11.7300s|10.4004s|730,352|
| Local absence only |11.2990s|9.9718s|727,948|
| Plus membership worker |11.0856s|9.7560s|730,492|
| Final, with backend fixes |11.1565s|9.8205s|730,132|

Final is **4.89% faster by process wall** and **5.58% faster by request wall**
than the released compiler in this screen, with essentially flat peak RSS
(−0.03%). The process ratio against TypeScript improves3.139→**2.985×**; the
request ratio remains4.043×. Membership adds1.89% over the local-only candidate;
the final backend image costs0.64% versus that membership image on this workload.
These are three-sample screens, not statistical/general speed guarantees.

The first local-only screen measured1.50%, while this window measures3.67% for
that same step; do not add or multiply percentages across runs. Process timing
includes startup, hashing the union of all variant inputs and capture; request
includes lazy API loading. The manifest union differs between screens, so their
absolute process numbers are not a standalone startup trend. OS caches are not
flushed. [Final raw summary](final-cost-screen.json) and independent review retain
full order, ranges, resource boundaries and attribution limitations. The independent
[measurement review](measurement-review.md) found no blocker.

## Correctness and practical scope

Final checked attempt `combined-build-02` selects API
`7b523bdffc0acde702dda1005a5e8201f7b65b2e432d1be95b07f2cfcc0346fa`, genuine checked
parent`e8d99da33b31420f225f92278b2347d00bab57c7269159e8f778a5b98e15c049`, source
`1c634e72f3b473dfdef449daaf3c5559486757302fee45c29f9d5010dd76916e`, unchanged Base,
runtime and pin0187512. The guarded derivative remains distinct from its checked
parent; there is no newly self-emitted fixed point or TypeScript fallback.

The final image passes36 maintained exact controls, main3026/3026 exact and
broader196/196 exact. The latter two explicitly verify and reuse the original
pinned reference acquisition; candidate observations are fresh. Main raw statuses
remain2525pass/497observed/4fail on both sides because four complete-program
fixtures expect later-emission errors. No raw status is rewritten. All worker
health and input identity gates pass. Fresh paired history53/history60 plus fresh
6,000-character controls pass226paired+2fresh observations, without exceptions.
The first history launch was blocked by sandbox spawnSync git EPERM; its exact
escalated rerun passes, and both attempts remain. The first release smoke likewise
retains sandbox Clang-spawn EPERM failures before its unchanged escalated rerun. These selections overlap.

The current backend inventory contains2,644 positive execution opportunities,
plus10 expected-error execution rows. The bounded pilot has77 execution rows
and4check boundary rows: final81/81 exact. Unexecuted rows remain explicitly
uncovered, not inferred passes or counted semantic failures. The two repaired
categories do not imply complete backend conformance.

The [environment report](backend-environment.md) closes two earlier TCP oracle
gaps using upstream/Bun and candidate/Node24 on unchanged Phase23 emissions.
It preserves default-Bun SIGILL and same-Bun candidate import failures. Matching
Clang16 TSan passes clean/racy capability controls and8 saved generated-program
executions including a shared atomic witness on two physical cores. This is
finite sanitizer coverage, not a general race-safety result or a fresh Phase24
emission claim. Independent proof-kernel, GPU/device, full backend coverage and
a new self-hosted fixed point remain separate work.

## Size and iteration loop

Canonical compiler source is15,776physical/13,467nonblank lines,588,084bytes,
1,703definitions,640laws,60modules and68datatypes. Against Phase23 this adds
28physical lines(+0.18%),25nonblank lines,1,447bytes and3helpers, with unchanged
modules/laws/datatypes. This is a small performance/conformance change with reused
representations, not a line-count reduction or the historical50%/75% simplification
goal. The [census](source-census.json) records exact module membership and hashes.

Final checked bootstrap11.26s + Base preparation2.07s +36 focused probes14.28s
is about27.6s of observed phase execution. This is a concurrent development-loop
observation, not an exclusive speed benchmark or a reason to run broad sweeps for
each edit. Fixture-only reruns continue to reuse checked attempts.

## Release and focused backend integration

Installed/relocated CLI42/42 pass on API7b523bdf after the preserved sandbox
Clang-spawn failure and exact escalated rerun. `release.json` preserves the genuine
checked parent, original bootstrap evidence and guarded derivation; the Phase23
release is archived separately. There is one installed default compiler.

The backend pilot is supplemented by11 direct ownership controls and targeted
source controls. Two invalid foreign-FID fixtures are preserved: constants were
removed by both emitters in the first, and the second consumed an affine IO value
twice. The final live-recursive-function fixture passes all4 lanes exactly.
The maintained native script passes22 executable cases at1/4workers,4diagnostics,
foreign effect dispatch and6,006 decision-tree controls. Its old isolated fixture
assembly needed the existing scanner type module and List constructor descriptors;
those test-only repairs and failed attempts remain explicit. The display-only
PASS total was corrected after execution without changing assertion bodies.

## Evidence recovery

The37,539,248-byte primary capsule contains24,601members/20,503files and
392,226,124file bytes, including failed attempts. Independent extraction verifies
all included bytes, modes, types and original producer membership. Its SHA256 is
`acd3f41227ac55368cd1a771827b2a9664b053a1901b0ad22803ed17ac69a1da`.
The [recovery receipt](evidence/recovery-01.json) is distinct from compiler tests.
Six external Bun/Clang package/runtime files are explicitly excluded with exact
official recovery prerequisites; no experiment result is excluded for failing.
A small [installed-cache supplement](evidence/cache-supplement-01/README.md) retains
the current produced CLI cache outside those roots, with separate exact recovery
and an explicit limit: the original smoke did not individually record its hash.
The independent [preservation review](evidence/preservation-review-01.json) verifies
both recoveries and the exclusions, and resolves 4,187 external input identities
within its bounded scope. The two required design plans accompany this report in
the final commit.

## Preservation and next priorities

The [capsule index](evidence/README.md) separates new artifacts, historical
prerequisites and external tools. Failed profiles, the rejected direct local match,
the first eager backend-check candidate, invalid foreign-FID control and environment
failures remain visible. Existing Phase23 evidence is reused rather than copied as
new results;103 preexisting unrelated paths remain protected.

Further ordinary speed work should follow the measured costs: contextual
materialization, repeated book traversal/update, dispatch and source-range
validation. Preserve chronological error/evaluation order when proposing changes.
Continue backend acquisition in deterministic bounded batches; this pilot already
shows why frontend equality alone cannot establish execution conformance. Avoid a
large representation rewrite until a smaller counterexample or profile supports it.
