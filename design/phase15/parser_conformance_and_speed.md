# Phase15: parser conformance and measured checking speed

Status: prospective design, frozen before compiler probes or edits. The user
authorizes all three recommended next steps, documentation, validated integration,
commit and push. Earlier multi-hour budgets are not renewed. Phase14 and its
raw evidence remain immutable. Outcomes belong in the implementation reports,
ledger and steering rather than retrospective edits to this plan.

## Baseline and objectives

Start from commit `bb251853bf1974e439b8c71d50574a782f50e544`, installed Phase14
`combined-01`, API
`9136be92928eda4b3b8e9c99e4e35d62504a825b458ff237c514d4e99f21206b`.
The genuine checked B1 parent, version5 derivative, source, runtime, Base and
host remain separately identified in the release manifest. Pinned upstream is
`b2111cf43244e65f76ddc278ee695e669f720cbf`; do not edit the human-written TypeScript.
Preserve all75unrelated Phase6 dirty files and their original status.

The current full frontend vector has603exact differences across409fixtures:
194parse and409check observations. All1,001positive cases accept types,
all482validation negatives refuse, and all11trust refusals match exactly.
The remaining20non-diagnostic differences cover10fixtures: nine import errors
reported during load instead of parsing, and a malformed erased-let binder
accepted by parsing then rejected by checking. These are behavior/error-order
gaps, not demonstrated invalid type acceptances. Another66fixtures/132observations
otherwise match except for absent parser carets. That is a ceiling for a shared
rendering repair; supplied spans may expose additional origin errors.

Current same-source checking takes24.9781s versus TypeScript2.8118s (8.8834×gap).
Those measurements describe Phase14's recorded source/hosts. Obtain a fresh
profile of that exact release before selecting one further optimization. Do not
multiply prior percentages or promise an unmeasured gain. Source is15,264physical
lines across59modules; complexity must include maintained hosts/tests separately.

## Stage0: validate causes before changes

1. Verify the installed release and genuine selected attempt. Freeze baseline
   identities, current dirty-work hashes, pin, source and Node/resource policy.
2. Reclassify remaining differences using the exact preserved reference and
   current vectors. Separate result axes, diagnostic shapes and unique fixtures;
   original pass/fail oracles and strings remain unchanged.
3. Inspect pinned parsing/import/error behavior and reproduce the10named gaps
   through the maintained paired workflow. Identify validation order, not just
   matching error text. Build small boundary/precedence counterexamples.
4. Inspect token coordinates and existing checker DSpan rendering. Establish
   whether parser rendering can share existing machinery without inventing spans
   or changing parsing/evaluation order.
5. Run an exclusive fresh CPU profile of the current full-source checking path.
   Freeze the measured source/API/host and unchanged worker. Attribute samples
   to actual owners before choosing a candidate. Profiles/counts are diagnostic
   evidence, not elapsed-time comparisons or universal bottleneck claims.

Three independent owners work in isolated snapshots. Initial source inspection
can overlap profiling preparation; all compiler/archive jobs stay paused during
the exclusive baseline profile. Afterward correctness jobs use assigned CPUs1–3.
Root owns integration, full gates and any production installation.

## Stage1: concrete parser/load behavior

P15-001 handles the malformed binder and import validation ordering. Validate
invalid syntax before filesystem operations where pinned semantics require it.
Keep valid local/relative/absolute/aliased imports, canonical identity, cache
behavior and first-error priority intact. Do not classify every filesystem failure
as a parser error merely to change its phase label. Compiler-language logic should
remain in Bend; any required host orchestration change must be explicit and small.

Use the10target fixtures plus positive/negative boundary controls first. Run a
genuine checked B1 and the maintained26focused cases. Preserve exact diagnostics
and result fields separately from an acceptance/phase oracle. Publish intended
full-corpus delta allowances before integration; unforeseen changes fail review.

## Stage2: shared parser caret rendering

P15-002 targets the66fixtures/132observations using existing source coordinates.
Prefer a shared snippet primitive when coordinate contracts agree, removing
duplication where justified. Reusing a name or copying the checker formatter
without validating parser coordinates is insufficient.

Direct controls include tabs, UTF-16/supplementary characters, empty input, EOF,
blank/multiline spans, token widths, absent spans and first-error precedence.
Compare against pinned upstream output. An incorrect originating span remains a
separate failure; do not guess widths to make a fixture pass. A partial strict
family result remains failed while a narrower invariant gate can independently
pass. Report physical/nonblank/byte/helper changes, including removed duplication.

Behavior and caret owners may touch one parser file only in their separate
snapshots. Root composes reviewed hunks and validates the combination. Each
isolated result remains preserved with its genuine checked parent.

## Stage3: one profile-selected optimization

P15-003 gets an initial90-minute feasibility window after profiling is authorized.
Rank the actual hot operations and freeze a candidate-specific plan before any
candidate probe. Prefer eliminating repeated work/allocation through a narrow
Bend source change. A larger representation/rewrite needs evidence of materially
greater savings and proportionate maintained complexity, not extrapolation from
Phase14's successful tag workers. No requirement forces promotion of a weak idea.

Retain normalizer seed allocation and rejected branch-boundary counterexamples.
Source workers can alter native call depth even when selected values agree.
Demand/error order, public ABI, canonical imports, cache validity and declaration
chronology are invariants. Instrument copies to count eliminated work; never time
an instrumented image as the release candidate. Checked B1,26focused controls,
independent operation controls and exact fresh/53/60-request histories precede
an exclusive ABBA pilot. Keep4MiBstack/4GiBheap and actual request order; no silent
recycling or resource increase. Report memory, source/host/test costs and failures.

An optimization may be rejected while the conformance release proceeds. Another
untested rewrite is not a substitute for completing this bounded investigation.

## Stage4: combined release gates and controlled comparison

Freeze candidate artifacts before integration. If speed survives, retain separate
conformance-only and combined checked attempts to isolate its behavior under the
new host/diagnostics. Reuse the generic paired history gate, recording historical
diagnostic/host changes but requiring every result/predecessor to agree between
the two current variants. Keep the long-string witness first in routine tests.

Run one complete candidate frontend inventory against the unchanged reference:
1,498fixtures/2,996observations. Preserve all1,001positive type accepts,
482negative refusals,11exact trust refusals and later-emission expectations.
Require no lost exact reference matches, no timeout/invalid/missing/input-drift
observations, and a prospective explanation for every baseline delta. Classification
normalization never changes the exact oracle. Attribute improvements by changed
fields/isolated evidence rather than assigning all checker improvements to rendering.

Run applicable41paired backend rows, genuine/current/historical helper replay
controls, and42ordinary/relocated release checks including actual native execution.
Do not run a full self-emitted fixed point or unavailable GPU/kernel suite without
a concrete change requiring that additional gate. Maintain separate checked B1,
derived API and historical self-emission claims.

The final serial matrix compares pinned TypeScript, Phase14 and the selected
candidate on identical final source, with the unchanged timing worker, explicit
host deltas, separate validated Base caches, fixed CPU/resources, two samples per
variant and intentional competing jobs closed. Account for any host corrections;
do not label differing workflows identical-host. A current TS ratio comes only
from this matrix. Keep compiler throughput, routine developer latency and generated
program execution performance separate. Reuse frozen attempts for fixture-only
changes and focused gates for ordinary iterations.

## Stage5: documentation, preservation and promotion

Promote one usable compiler only after relevant gates pass. Preserve the previous
default and checked lineage. Update the compiler guide, architecture, conformance,
README links, implementation reports, ledger and steering with exact boundaries,
complexity, measured gain, remaining gaps and rejected attempts.

Close all producers before capture. Preserve consumed tools, failed preparations,
raw results/histories, exact artifacts and commands. Reuse existing capsules for
shared objects; omit unrelated Phase6 payloads while retaining their identities.
Record external toolchains and regenerate derived caches explicitly. Validate
archive recovery including bytes/modes and zero unresolved consumed repository
references. Follow the user's standing authorization to commit and push compiler
work/reports; the user also explicitly approved compiler experiment evidence to
the same `rom1504/bend` bootstrap destination. Keep payload scope confined to this
compiler project. An evidence capture is not an additional correctness result.
