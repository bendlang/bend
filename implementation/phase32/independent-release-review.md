# Independent release review of checked03

Review cutoff: checked03 is installed and verified. All 14 pre-install gate
groups and all 42 ordinary/relocated CLI checks pass. Evidence capture and
protected-file preservation are verified. Root's final staging audit, commit and
push remain pending. This reviewer read the
production diff, frozen sources, designs and retained receipts, and recomputed
hashes/counts/arithmetic. No compiler, generated program, test or benchmark was
executed. [Review identities and checks](independent-release-review.json).

**Decision:** no static semantic or measurement-reporting blocker found for the
selected emitter changes. The declared integration, installation and post-install checks are complete;
evidence preservation also checks out. Final publication remains root-owned. The real
Mandelbrot compilation cost is explicitly accepted by
[the conditional admission decision](../../design/phase32/admission.md).
The production emitter changes were implemented separately from these reviews.
The initial reviewer owned the reuse/compact investigations; a separate resumption
reviewer closed the release evidence and adapted the backend receipt auditor,
as disclosed below.

## Source and artifact identity

All66 current manifest modules match checked03's immutable source snapshot.
Only `back/js/local.bend`, `back/js/region.bend` and `back/js/emit.bend` differ from
Phase31 commit `5f3015d1a84ce822d3ee1a8bcb899a517d7f8aec`. Recounting gives:

| Metric | Phase31 | Checked03 | Change |
| --- | ---: | ---: | ---: |
| Physical Bend lines |17,014|17,071|+57 (+0.335%)|
| Nonblank Bend lines |14,529|14,580|+51|
| Definitions |1,878|1,884|+6|
| Laws / datatype declarations / modules |640 /70 /66|640 /70 /66|0|
| Canonical Bend source bytes |660,570|664,214|+3,644|

These counts exclude generated images, experiment tools and documentation.
JReadCall and JVector are two additional private plan tags; no new datatype
declaration or replacement compiler IR is introduced. This is a small source
increase, not a line-count simplification result.

Checked03 is the maintained derivative of a genuinely checked B1:

- Selected API: `8be506d811f627fe6346a5eaba07050c36db70e2704608adcfd781b85a3a7f92`.
- Untouched checked parent: `c3cc54c1e7e4a8470547e7488df4a58fec17195e0889e1eb458df34104bed20b`.
- Assembled source: `e3cc44245444ac2509431d44c8909692c9223cd977968ffb087771c1ae2859ae`.
- Runtime: `4121f338a7e4e115bae557343cd3d194a26ed26589bc47d82094969284181e10`.

The runtime bundle, runtime core, typed driver, stage0-library helper and module
manifest are byte-identical among the committed Phase31 baseline, checked03
snapshot and working tree. No query cache, event checkpoint, direct checker
projection shortcut or stop-list CSE entered production. The upstream pin remains
`018751270e800bc222a93dad7f257083ee53a5f7`. This is not a newly self-emitted H image
or a new fixed point.

## Semantic scope

Return-position JUnpack captures its input outside the fresh field-binding
scope, then reads all fields in order before the arm. Expression-position
unpacking and the initial-zero rebinding mechanism keep their existing paths.
Nested bindings and parallel-let scopes do not inherit the removed IIFE's
accidental parameter scope.

JReadCall admission requires an already proved canonical Array.get as the final
argument and a completed private helper that fully unpacks the corresponding
Array<U32>/U32 pair. The bridge preserves prefix-argument order, original erased/
array/index evaluation, arraydata lookup, Number conversion, modulo and indexed
read before the consumer. The captured scalar is read even if unused. Other
producers keep their tuple path; the bridge's suffix is separate from the encoded
ordinary helper name. Existing graph/type/native guards remain required.

JVector is produced only after successful local-type, constructor, telescope and
argument analysis. Construction and both unpack forms use the same normalized
layout predicate. Eligible ordinary records excluded by the public terminal
record rule can lose their outer shell; aliases to public flat scalar records
remain boxed. Native U32 arrays cannot store these records, and the closed graph
admits no external container/function callback that could expose their layout.
Canonical Sigma retains its existing array layout while avoiding constructor
dispatch. The original public and unsupported generic paths remain intact.

The previously completed six control groups provide narrower dynamic evidence
for these claims: complete array states/native schedules, read ordering, scopes,
boxed public aliases and compiled type predicates. The review does not convert
those controls into a proof of full-language or backend conformance.

## Measurements and tradeoffs

The selected report's linked attempt and five raw measurement receipts hash-match
the retained files. I independently recomputed runtime/canary medians, reported
ratios and range-overlap flags, and compiler-request medians. The published
arithmetic agrees:

- Original four-pair edit distance improves3.5429×, to20.3976ms; its remaining
  same-window TypeScript ratio is4.0894×.
- The separately measured full pair and fold improve3.76× and1.98×, with remaining
  TypeScript ratios3.78× and8.13×. They are not interchangeable workload ratios.
- Original Mandelbrot and RLE emitted bytes remain identical to07, with overlapping
  timing ranges. Their small time differences are not attributed to an emitter
  improvement. All three scalar/mixed canary ranges overlap.
- The02→03 fold gain is not an ordinary-record-shell result: it removes three
  private canonical Sigma constructor-dispatch sites. The report and explicit
  vector-ablation clarification preserve that distinction.
- One candidate fold sample retains approximately−27% half drift; longer warmup
  did not establish converged throughput. All samples remain in the reported
  medians and ranges. The first-call/import boundaries remain separate.

Normal Mandelbrot compilation adds36.75ms, or1.9127%, with disjoint request-time
ranges. This is a real measured cost, although smaller than the local experiment's
3% regression screen. That local criterion concerns generated-program points;
it does not establish that compiler throughput improved. Edit-distance compilation
changes−0.4457% with overlapping ranges. The request-only TypeScript ratios5.555×
and4.896× include different import placement; the report correctly also gives
import-plus-request and supervised process boundaries. No general compiler
throughput gain should appear in final release wording.

Root's conditional admission explicitly retains the small compilation cost,
0.39% peak-RSS increase and source/module-size increases in exchange for the
demonstrated generated-program gains. I read and hash-bound that decision after
raising the documentation requirement; it is now addressed. These measurements
do not require reopening the successful local experiment, nor do they excuse a
failed conformance gate.

The cache/checker prototypes remain separate. Both scoped memo capacities fail
their frozen speed criteria. Event checkpoints preserve22 outcomes but include
two parse refusals, which do not test event-level duplicate/order rejection.
The stop-list ownership shortcut has an executable default-module mutation
counterexample. None is silently bundled into checked03.

## Release closure

| Required receipt | Status at this review cutoff |
| --- | --- |
| Checked build and focused local controls |Completed; retained receipts reviewed|
| Original programs, canaries and compiler-cost measurements |Completed; scope/arithmetic reviewed|
| Main frontend agreement and module-layout audit |3,026 exact observations; one worker, zero worker failures/timeouts; receipt and input hashes reviewed|
| Broader frontend agreement |196 exact observations in separately preserved retry; one worker, zero worker failures/timeouts; receipt and input hashes reviewed|
| Backend historical-outcome admission |81 exact historical observations: 60 retained plus 21 approved-context native retry rows; scope and row arithmetic reviewed|
| Inherited/additional integration gates |All accepted in the 14-group pre-install audit; receipt identities reviewed|
| Installation and installed/relocated42 CLI checks |Installed checked03; all 42 checks pass, output logs and ordinary/relocated identities reviewed|
| Installed release verification |PASS; six installed and 122 checkout files hash-match the release manifest|
| Closed-producer evidence archive and independent archive verification |20,807 members preserved; producer reopens every member; reviewer independently verifies compressed SHA256 and producer behavior|
| Final preservation audit |All 103 protected files unchanged; all seven prior default-release files preserved exactly|
| Final staging audit and commit/push |PENDING; root-owned publication step|

All 103 protected starting-file hashes match their inventory after installation
and archive work. Their exact bytes and the seven preserved previous-default
release files were independently rechecked. The capsule and installed checked03
identities are now closed; final Git staging and publication remain separate.
No new PR comment is authorized by this review.

## Resumption audit

The completed main frontend receipt and all listed input hashes were rechecked
after the server restart. The incomplete broader receipt does not satisfy the
release gate. The final gate auditor now accepts an explicit
`--frontend-broader-report` path so a retry can keep the interrupted output intact.
This option changes only the selected receipt path. Exact checked-attempt identity,
scope, API identity, agreement counts, worker health and resource checks still
apply. The auditor now asserts scope and checked-attempt identity directly for
both frontend suites. Python syntax was parsed without executing any compiler or
benchmark. No other admission predicate was relaxed.

The separately retained `frontend-broader-resume-02/report.json` now completes all
196 exact observations. I verified its scope, checked-attempt/API identities,
every listed input hash, single-worker configuration, 1024 MiB heap/RSS recycling
limits and zero worker failures/timeouts. The first incomplete run remains
recorded as interrupted and contributes no accepted observations.

## Scoped backend closure

The first 81-row campaign completed but failed its historical-outcome gate:
17 native programs reported paired `clang-16 EPERM` on both compilers. The
21-row native subset was rerun with the same fixtures, selected checked03 image,
frozen helper, Clang environment and expectations in the separately authorized
execution context. All 17 executable cases passed and four remained not
applicable. The original failed campaign remains unchanged.

I compared all six behavioral fields of every consolidated row directly with
the frozen historical rows and verified the exact unique 81-key set. The closure
combines 60 accepted original rows with 21 retried rows: 69 passes, eight not
applicable and four retained shared check failures. This is two provenance
groups, not one successful 81-row execution and not broad native conformance.

The retry used one worker, 1024 MiB heap/RSS recycling limits and a 4 MiB stack.
Its bounded outer run completed in 89.27 seconds, peaked at 648,556,544 bytes of
process-tree RSS and did not trigger its 3 GiB cap or 2 GiB headroom floor. I
rehashed the named original/retry/closure reports, frozen retry plan, historical
rows, configuration and producer identities. Bulk child archives were not
re-read in this intermediate review; the closure binds their prior verification.

This reviewer adapted the Phase31 closure auditor, which root executed. The
subsequent direct receipt comparison recomputes the historical rows independently
of its result, but should not be described as an independently implemented
closure tool. Production emitter changes remain authored separately.

## Final pre-install gate review

All 14 declared gate groups are accepted in
[the final conformance audit](final-conformance/gates.md). I rehashed each gate
receipt and checked its completion/failure fields. I also rehashed every one of
the 223 live and frozen source pairs in the selected attempt; all match. The
23-library corpus contains 127 returned values, each directly equal to its
recorded expected value. No compiler or test was rerun.

This closes the focused 36 probes, main/broader frontend agreement, scoped
81-row backend admission, 56,205 primitive points, 3,759 worker points, 144
nested cases, 1,129 primitive guards, 15 selected upstream JS probes, corpus,
40 worker guards plus two witnesses, 22 component observations, exact 42-byte
HVM output and the six local owner-control groups. These scopes overlap and
are not a sum of unique tests. The four shared check failures remain failures.
Post-install integrity/CLI checks and evidence preservation are separate.

## Installed compiler and CLI review

The installed selected API is `8be506d811f627fe6346a5eaba07050c36db70e2704608adcfd781b85a3a7f92`,
matching checked03. I rehashed all six installed artifacts, all 122 checkout
files listed by the release manifest and all 134 copied relocation files.
The genuine checked parent, assembled source and runtime retain their declared
identities; installation does not claim a new bootstrap or fixed point.

The [CLI receipt](release-cli.json) is byte-identical to its raw counterpart.
All 42 steps have zero exit status and successful assertions, with no timeout,
log overflow or signal. I rehashed every saved stdout and directly compared
all literal expected outputs. Saved structured-predicate assertions remain
true; their predicates were not re-executed during this review. Fixture,
ordinary/relocated input and generated output hashes also match.

Ordinary and relocated checks each cover integrity before/after, version,
checking, interpretation, JS emission/execution and CPU compilation/execution.
Relocation copies no upstream checkout; preserved absolute provenance paths
remain data, so this is not an OS isolation claim. All three supervised
installation/verification/smoke receipts finish with code zero and no memory
or deadline stop. The complete smoke outer run took 42.19 seconds and peaked
at 604,889,088 bytes of process-tree RSS. Archive and final preservation review
remain separate.

## Evidence and preservation closure

The completed [evidence capsule](evidence/README.md) contains 20,807 regular
files and 207,091,523 logical bytes. Its 33,930,135-byte compressed stream has
SHA256 `390a34356eb14b2792643969f8728be3ab6b84ac2d67ee8cdfa85be729b14925`,
which I independently recomputed with bounded streaming reads. Receipt member
counts, unique paths and summed byte totals agree.

I verified the archive producer is exactly the Phase31 producer with phase-name
substitution. Inspection confirms that it rejects symlinks, compares all live
identities and the file set before/after capture, then reopens every tar member
and checks its name, byte count, SHA256 and mode. The complete receipt is written
only after those checks. Capture completed in 23.81 seconds at 118,263,808 bytes
peak process-tree RSS. The reviewer did not perform a second full decompression
or execute any archived experiment.

All 103 protected starting files retain their exact bytes and hashes. The seven
files of the prior installed default in its new release-history directory match
their pre-install Git versions. This independently confirms the recorded final
preservation audit. The remaining action is root's staging audit, commit and
push; this review does not claim those future operations already occurred.
