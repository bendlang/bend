# P7-A01: checked output consumed by the existing backend

Status: the isolated full compiler passes a genuine checked B1 build and all 21
focused controls, with the same seven existing exact differences. Direct-output
controls pass 148 assertions across 16 groups, including nine pairs of generated
JavaScript programs actually executed. On the bounded workload, check plus
annotation becomes 16.85–17.67% faster, while check-only becomes 25.39–25.45%
slower and uses 44.74–46.36% more peak RSS. Candidate 01 is therefore unsuitable
as a global replacement. Production source and the installed release are
unchanged.

## Hypothesis and bounded implementation

The existing checker computes child terms, types and quantity uses, then commonly
returns the original parent term. The annotation pass reconstructs the backend's
typed terms afterwards. This experiment changes successful result construction
for `Ref`, `Var`, `App`, `Lam`, `Ctr` and explicit `Ann`, retaining the checked
children and attaching their already known types. It does not add a type cache.

`co_typed` wraps the successful result's term while retaining its existing type
and quantity uses. Failures return unchanged. Application, lambda and constructor
assembly use the children returned by existing checking calls, with their original
argument evaluation and error precedence. Telescope result terms now carry the
checked arguments. Their type, uses and failure contracts remain the same.

The prototype uses the existing annotation-shaped `KTerm` contract deliberately:
it can be consumed by the unchanged JavaScript backend, without inventing a new
IR or adapter. This tests whether an existing owner can supply the needed facts;
it does not test the minimum-size or minimum-allocation final representation.

The full source candidate is produced by [prepare.py](prepare.py), which freezes
one changed kernel under [candidate-01](candidate-01/kernel.bend). Root copies it
into an isolated full compiler project and runs the maintained checked B1
workflow. The installed compiler, pinned upstream and all production modules
remain untouched.

## Deliberate boundaries

This slice does not yet reconstruct `Let`, `Mat` or `Rwt` results. Existing let
checking returns its checked body without rebuilding the outer bindings; matcher
checking drops checked arms. Their successful result terms cannot be assumed to
be executable output. The controls preserve explicit unsupported witnesses.

Template checking currently validates closed arguments but does not return an
updated instance book. That state ownership is unchanged. One positive control
uses the existing specialization pass first; it earns no specialization deletion
credit. Another records the unsupported pre-specialization boundary.

Chronological source validation remains a separate prerequisite. Checking a
definition against the final book does not replace the law declaration/fill and
forward-reference rules. Tests retain negative chronological witnesses and
validate the original source before checking specialized output.

Keeping checked output also adds allocations to ordinary check-only requests.
The measured cost below is material. A production design needs an output policy
or a smaller fact representation. Omitting annotation alone is not a sufficient
promotion argument.

## Source accounting

The frozen [source counts](candidate-01/source-counts.json) show:

| Kernel source | Physical lines | Nonblank lines | Bytes |
| --- | ---: | ---: | ---: |
| Baseline | 1,152 | 987 | 33,907 |
| Candidate 01 | 1,175 | 1,005 | 34,890 |
| Difference | +23 | +18 | +983 |

There are five new helper definitions. No module, pass, datatype or production
line has been retired. Annotation and specialization remain in the full compiler.
The script and control harness are additional research infrastructure, counted
separately; they are not a route for hiding compiler logic outside Bend.

The preparation, control and measurement programs are listed and counted in
[research source counts](research-source-counts.json). The complete candidate
kernel is a frozen source snapshot, not another maintained implementation.
The four experiment programs total 315 physical / 305 nonblank lines / 23,715
bytes at this checkpoint.

## Validation protocol

[controls.mjs](controls.mjs) appends only test exports of existing genuine checked
function bodies. It does not rewrite them. Positive observations compare exact
type/use/error results, typed term trees, unchanged backend output bytes, and
actual generated JavaScript process output. Negative observations compare
chronological rejection and complete failed `KChecked` values, including their
structured `DTrace` terms. Source books are checked for input mutation.

The passing positive domain includes dependent application, dependent constructor
telescopes, erased arguments, higher-order arguments, explicit annotations,
constructor fields and an existing specialized template. Unsupported forms remain
visible rather than being silently routed through annotation in the direct path.

No full conformance improvement, whole-compiler speedup, self-reproduction or net
simplification is claimed by this experiment. Those would require separate
integration evidence.

## Checked build result

Root built the isolated project in
`selfhost/build/phase7/architecture/checked-project-01` using the maintained
workflow. The successful attempt is
`selfhost/build/phase7/architecture/checked-attempt-01`. Its genuine checked API
SHA256 is `5efa1b35c7b3585731fc0937fcb26e3a50a1af3ffcb983bd52a83cdeaebf245b`.
The baseline checked API is the S4 B02 image, SHA256
`f201bdea7ea4041483b40704f622703945858e981c404a4d7e50979b74370110`.
All 21 focused observations pass; the seven existing exact differences are
unchanged. This is a bounded checking/host gate, not a fixed-point proof.

## Direct-output results

The root-run controls are preserved in [controls-01.json](controls-01.json), copied
byte-for-byte from `selfhost/build/phase7/architecture/checked-controls-01/report.json`.
All 148 assertions pass. Nine positive groups have exact annotation-shaped
terms, identical emitted JavaScript bytes, and identical successful runtime output
from both the baseline and direct-output path. The candidate route in those
controls makes no annotation call. Outputs include ordinary constructors,
`Box{Off{}}`, `Bag{On{}, Off{}}`, and higher-order/dependent applications.

Seven negative groups preserve the chronological rejection. Six direct failed
definition results compare exactly, including `DTrace`. The forward-reference
group has no final-book direct failure, as expected: its rejection depends on
chronology. The test keeps that distinction explicit rather than treating
final-book acceptance as the source-language verdict. Source inputs remain
unchanged across the positive comparisons.

The three unsupported boundaries remain visible. Let and matcher output differ
from full annotation output. The pre-specialization template term actually
matches annotation output, but neither supplies a materialized instance book.
That case establishes why annotation equality alone cannot justify deleting
specialization. No unsupported boundary is claimed to execute correctly.

## Bounded cost protocol

[timing.mjs](timing.mjs) and [timing-worker.mjs](timing-worker.mjs) freeze a separate
comparison: one immutable definition containing 128 nested identity calls.
Checking-only compares the two checker implementations. The compile-preparation
lane compares baseline checking plus annotation against the candidate's direct
checked output. Existing backend emission and actual `On{}` execution are exact
preflight oracles, outside the request timing boundary.

Each lane runs A/B/B/A in four fresh CPU-0 workers. Each worker performs three
warmup batches and seven measured batches of 32 requests. Output hashes are
checked outside the timed batches. Workers record every batch duration, peak RSS,
affinity and API/fixture/tool identities, and check input immutability separately
for each variant. Loading, parsing, whole-book chronology, backend emission and
process startup are excluded from the request timing; whole process duration is
retained separately.

## Bounded cost results and decision

All eight fresh workers completed successfully. Their full raw report is
[timing-01.json](timing-01.json), copied byte-for-byte from
`selfhost/build/phase7/architecture/checked-measure-01/report.json`. Every measured
batch passes the output hash oracle; both preflight generated programs execute
and print `On{}` with byte-identical generated code. Each worker's own frozen
fixture remains unchanged.

| Lane | First candidate/baseline time ratio | Reverse-order ratio | Peak-RSS ratios |
| --- | ---: | ---: | ---: |
| Check only | 1.25454 | 1.25392 | 1.46358 / 1.44740 |
| Check + annotation versus direct checked output | 0.82329 | 0.83155 | 0.99516 / 1.01284 |

These are ratios of seven-sample per-worker median batch times in opposite-order
pairs. Each batch contains 32 requests. Baseline check-only batches take about
206 ms versus candidate 259 ms. Baseline check-plus-annotation batches take
310–314 ms versus candidate 258 ms. The candidate's direct path computes useful
output sooner, but its unconditional output allocation is paid by all checks.
Peak RSS is the individual worker process's high-water mark, including setup
and warmup; it is not a per-request retained-heap measurement.

All batches, including slower samples and the candidate's later lower times,
remain in the raw report. Two opposite-order pairs on this one synthetic
successful definition establish a bounded cost signal, not statistical
significance or representative whole-compiler throughput. No TypeScript speed
ratio or generated-program performance gain follows from this measurement.

**Decision:** retain the checked-output idea as feasible, reject Candidate 01 as
a global compiler change. The next cheap discriminator is an explicit output
policy: verify-only calls must avoid constructing executable terms, while a
compile entry retains the checked children. It must preserve the same failed
results and chronology, then repeat both measured lanes. No larger rewrite is
justified until that boundary is demonstrated. Let/match/rewrite reconstruction
and template-instance ownership remain separate required work.

## Read-only next-step design assessment

An output/discard field in `KEnv` would touch 14 constructor/pattern source lines
across `kernel.bend`, `annotate.bend` and `specialize.bend`, including the six
existing environment accessors. It would also change the environment ABI used
by component tests and require a compatibility decision. Four to six successful
result helpers currently lack the environment and would need the policy passed
explicitly. Guards must precede term construction: guarding only the returned
result after eagerly constructing a term does not eliminate the allocation.

The legacy definition-check entry should select discard; a distinct compile entry
should select output. Definition types and domain proof checks can remain in
discard mode even during compilation. The template-checking helpers construct
fresh environments, so their recursive transitions must preserve the selected
policy. A rough initial implementation budget is another 30–70 lines plus ABI,
export and test adapters, not a deletion promise. No policy code has been written.

A comptime Boolean parameter might specialize the policy branch, but threading
it through every recursive helper is broader than adding an environment field.
Its generated size, instance behavior and bootstrap compatibility must be tested;
we cannot assume the current template mechanism makes it free.

Compact facts offer a later option: most emitter decisions need effective
quantity, instantiated constructor identity, live fields or a runtime shape,
rather than an `Ann` wrapper containing the complete dependent type. Erased
arguments still need checking and type-level substitution, but often need no
executable output subtree. Such a compact contract would require changes to the
backend consumer and an erasure/dependency specification. It is deliberately not
implemented or credited in this existing-backend compatibility experiment.
