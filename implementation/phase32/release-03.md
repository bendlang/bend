# Phase32 selected compiler and release closure

Status: checked03 is installed and verified. All 14 final pre-install gate
groups pass, all 223 canonical snapshot files match, and all 42 ordinary/relocated
CLI checks pass. The final evidence capsule is verified and all 103 unrelated
starting files remain unchanged. The [independent review](independent-release-review.md)
records its separate evidence and release assessment.
This report separates generated-program performance from compiler throughput.
The [phase index](README.md) links the investigations and rejected alternatives.

## Artifact identity

| Item | SHA256 |
| --- | --- |
| Selected API | `8be506d811f627fe6346a5eaba07050c36db70e2704608adcfd781b85a3a7f92` |
| Genuine checked parent | `c3cc54c1e7e4a8470547e7488df4a58fec17195e0889e1eb458df34104bed20b` |
| Assembled Bend source | `e3cc44245444ac2509431d44c8909692c9223cd977968ffb087771c1ae2859ae` |
| Embedded runtime | `4121f338a7e4e115bae557343cd3d194a26ed26589bc47d82094969284181e10` |
| Base | `c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661` |

The upstream pin remains `018751270e800bc222a93dad7f257083ee53a5f7`, after
Bend 2.0.34. The candidate is the maintained guarded version6 derivative of a
genuine TypeScript-produced checked parent from the same Bend source. Ordinary
compilation executes the Bend implementation without a TypeScript fallback.
This phase does not establish a new H self-emission or compiler fixed point.

## Finding and performance decision

The productive change removes short-lived representation work inside already
proved closed regions. Return-position unpacking uses scoped statements; a typed
bridge joins a canonical array read to its immediate private pair consumer;
private constructors use ordered field vectors when the existing type and escape
proof admits them. Public terminal scalar records remain boxed. Input capture,
read order, unused reads, native provenance and public entry guards are preserved.
The [mechanism report](local-representation.md) and
[independent review](review-vector03.md) describe the exact admitted cases.

| Generated program | Phase31 checked07, ms | Checked03, ms | Improvement | Checked03 / TypeScript |
| --- | ---: | ---: | ---: | ---: |
| Original four-pair edit distance | 72.2661 | 20.3976 | 3.54× | 4.09× |
| Complete single-pair fixture | 18.5348 | 4.92542 | 3.76× | 3.78× |
| Independent array fold | 0.65053 | 0.32914 | 1.98× | 8.13× |

Every successive local ablation has disjoint observed ranges on both local
fixtures. The final increment also bypasses canonical Sigma constructor dispatch;
fold has no ordinary record-shell change, so its gain cannot be attributed solely
to removing such shells. The original edit-distance TypeScript gap falls from
14.49× to 4.09× in the same window. Original Mandelbrot and RLE retain exactly the
previous JavaScript bytes and overlapping timing ranges; their candidate gaps
remain 4.46× and 76.22×. The other seven historical original programs were not
freshly timed. No average generated-program speed is inferred from this sample.

The local confirmation retains five rotating fresh processes per variant, at
least 100 calls and three seconds of warmup, and a 300 ms timing target. Original
program transfer uses five samples with at least three calls and one second of
warmup. Imports, first calls, full ranges, output identities and half-sample drift
remain in the raw reports. One candidate fold sample improves 27.07% between its
measured halves; the result is not labeled steady state. The faster-looking short
screen is preserved but does not replace the longer confirmation.

All three scalar/mixed regression canary ranges overlap. Normal Mandelbrot
compilation nevertheless costs an additional **36.75 ms / 1.91%**, with disjoint
request-time ranges; peak-RSS medians rise 0.39%. Edit-distance compilation changes
by −0.45% with overlapping ranges. Candidate request-only gaps remain 5.56× and
4.90× TypeScript respectively. Imports and supervised process wall are distinct
boundaries. This is a generated-program improvement, not a general compiler
throughput gain. The [admission decision](../../design/phase32/admission.md)
explicitly accepts these costs conditional on release closure; the
[measurement summary](final-measurements/measurements.md) preserves their scope.

The other investigations were closed without production shortcuts. Structured
checker projection improves selected private H17 helpers 1.44–1.76×, but public
getter/mutation witnesses invalidate a general shortcut. Dependency-complete
semantic checkpoints skip work but cost too much to compare and retain. Scoped
4k/16k memo tables fail their prospective speed criteria. Duplicate stop-list
reuse also fails its proposed ownership boundary under a concrete public API
mutation. The runtime and driver receive no cache or ownership assumption from
these experiments.

## Correctness and installation

The focused checked build passes 36 exact tests. Six added control groups cover
complete pair arrays and all 328,966 ordered native events, independent fold
oracles, actual read-bridge ordering, nested binding scopes, public boxed records
and aliases, and compiled layout predicates. Deliberately weakened alternatives
remain distinguishable where the reports claim them. These finite controls do
not prove arbitrary-program equivalence.

Fresh main 3,026 and broader 196 candidate observations agree exactly with the
attested pinned TypeScript reference acquisitions. Main raw outcomes remain
2,525 pass / 497 observed / 4 shared failures; broader remains 195 pass / 1 observed.
The main gate completed once, in 836.25 seconds. A server restart interrupted the
initial broader acquisition after 151 saved responses. Its original directory and
unfinalized receipt remain intact; the separately identified broader retry passes
all 196 observations in 39.97 seconds. The restart did not justify repeating the
completed main gate or selecting a partial broader result.

The fresh backend pilot initially records 17 paired Clang `EPERM` failures in
the restricted execution context. The unchanged 21-row native subset then runs
in the approved context and reproduces 17 passes / 4 not-applicable outcomes.
Combining those 21 retries with the 60 accepted original rows preserves all
**81 historical observations: 69 pass / 8 not applicable / 4 shared failures**.
The consolidation is `final-plan-03/backend/closed-03/report.json` under the raw
evidence root. The original campaign remains failed and visible; this is not a
claim that its initial 81-row execution passed. Its outer run takes 274.66 seconds
and peaks at 633 MiB; the separate approved retry takes 89.27 seconds and peaks
at 619 MiB. Neither acquisition records a supervisor memory stop.

Fresh inherited gates pass 15 selected upstream JS cases, 56,205 primitive
executions, 3,759 worker executions, 144 nested cases, 1,129 primitive refusal
controls and 23 libraries / 127 points. Added worker admission passes 40 guards
and two execution witnesses; all 22 compiler component observations and the
complete 42-byte HVM output also pass. Counts overlap and must not be summed as
unique tests. The [pre-install audit](final-conformance/gates.md) closes all
14 gate groups and confirms that all 223 canonical snapshot files match the
checked attempt. Its [machine-readable receipt](final-conformance/gates.json)
binds the artifacts, gate reports and explicit broader/backend replacements.

The maintained release tool installs the exact checked03 artifact and verifies
its selected API, genuine checked parent, assembled source, Base, runtime and
host lineage. The [installation receipt](release-installation.json) binds the
installed release manifest, six installed artifact files and 122 checkout files.
The prior Phase31 release remains preserved in release history. No source change
follows candidate selection.

All **42 ordinary/relocated CLI checks** pass, covering version, checking,
interpreter, JS emission/execution, CPU emission/build/run and integrity before
and after. The outer acquisition takes 42.188 seconds and peaks at
604,889,088 bytes (577 MiB). The [complete CLI receipt](release-cli.json) is copied
byte-for-byte from `final-plan-03/release-smoke/checks/report.json` under the raw
evidence root. Native checks use the approved Clang16 execution context and
1 GiB Node heaps. Relocation supplies no upstream checkout; historical absolute
provenance paths remain metadata, not a claim of OS isolation. Previous-phase
results are not counted as fresh candidate passes.

No optional 811-case JS expansion, GPU campaign, independent proof-kernel
coverage or new bootstrap fixed point is inferred from this release scope.

## Complexity, resources and preservation

The compiler contains **17,071 physical / 14,580 nonblank Bend lines**, 1,884
functions, 640 laws, 70 types and 66 modules. Relative to Phase31 this adds 57
physical lines (0.335%), 51 nonblank lines, six functions and two private plan
tags; there is no new datatype, law or module. Maintained runtime core remains
245 lines. Pair/fold emitted cohort modules grow 4.21% / 1.08%, mostly from read
bridges, including some eligible but unused bridges. This is a small complexity
increase with measured benefits, not a line-count reduction.

The [resource summary](resource-summary.json), produced by the retained
[summary tool](../../selfhost/tools/performance/phase32/resource-summary.py),
hashes every bounded-run receipt present at its stated snapshot and separates
successful acquisitions, failed acquisitions, expected supervisor stops and
unfinalized receipts. Archive capture is recorded separately because its outer
receipt lives outside the archived raw tree. A caller-supplied closure label is
context, not an additional correctness audit. The final snapshot contains 53
successful raw-tree acquisitions, one completed backend acquisition with the
preserved Clang permission failure, two expected supervisor stops and one
interrupted receipt. No other unfinalized acquisition remains. The successful
archive capture is reported separately. Heavy jobs run
serially under an execution lock, explicit heaps, process-tree RSS budgets,
deadlines and a 2 GiB available-memory floor. Checked03 builds in 39.57 seconds;
its 1,078,702,080-byte peak is about 1.005 GiB. Main/broader frontend peaks are
about 628 / 645 MiB. These are observed process-tree sums, which can double-count
shared pages, rather than a hard kernel memory ceiling.

The supervisor's deliberate 128 MiB memory-limit control is stopped in 0.105
seconds at 171.27 MiB, demonstrating polling overshoot. Its one-second deadline
control stops in 1.011 seconds; both tracked children are absent afterward.
These are expected safety-control outcomes, not failed optimization candidates.
No completed ordinary bounded job at the current resource snapshot exceeds its
RSS budget or records a supervisor resource stop. The interrupted broader receipt
contains no finalized peak; its initial zero is not a zero-memory observation.
Current cgroup OOM counters are zero, but they do not establish the earlier
server's state or the cause of either interruption. See the
[recovery receipt](resumption-02.json) and [supervisor controls](supervisor-controls.md).

The verified [evidence capsule](evidence/README.md) retains **20,807 files /
207,091,523 logical bytes** in a 33,930,135-byte gzip archive. Capture compares
the live inventory before and after, then independently reopens the tar stream
and verifies every member by exact name, size, SHA256 and mode. Archive SHA256
is `390a34356eb14b2792643969f8728be3ab6b84ac2d67ee8cdfa85be729b14925`.
Capture takes 23.809 seconds and peaks at 118,263,808 bytes (113 MiB); its outer
receipt is deliberately outside the archived raw tree. Failed, superseded and
interrupted acquisitions remain visible alongside successful results.

The [final protection audit](protected-files-final.json) verifies all 103
unrelated starting files unchanged after installation and capture. The preserved
Phase31 release history matches its pre-phase contents exactly. Git staging,
commit and push are separate publication steps; this report does not infer them
from test or capture success. No PR comment is authorized or posted as part of
this phase.
