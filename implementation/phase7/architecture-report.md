# Architectural experiments: choose checked-output ownership next

The [prospective design](../../design/phase7/architectural_experiments.md) records
eight ideas. We implemented and measured the recommended first three in isolated
Bend prototypes. **Checked output is the best next investigation**, because it
demonstrates a path to retiring a complete annotation pass using information the
checker already owns. Its first implementation still makes verification slower,
so it is not installed. The semantic evaluator has a useful substitution-heavy
result but expensive ordinary values and more correctness obligations. The
generic binding traversal is larger and slower than the two routines it replaces.

This is a completed comparison of bounded architectural trials, not completion
of their full compiler implementations. No production code, release artifact,
conformance verdict or source-line reduction is changed. S4 and the 50%/75%
milestones remain open.

## Results at the tested boundaries

| Experiment | What ran | Measured result | Size and decision |
| --- | --- | --- | --- |
| [A01: checked output](architecture-evidence/checked-output/report.md) | Full compiler with modified checker, genuine checked B1, 21 focused controls, 148 direct-output assertions, nine generated program pairs executed | Check plus annotation preparation takes 16.85–17.67% less time; checking alone takes 25.39–25.45% more time and 44.74–46.36% more peak RSS | +23 physical lines, five helpers; no pass deleted. Continue the idea, reject unconditional output construction. |
| [A02: semantic values](architecture-evidence/semantic-values/report.md) | Checked evaluator component; 100 selected controls pass, but a later All-domain demand witness fails | On candidate05, substitution-heavy normalization takes 46.7% less time; closed constructor data takes 3.415× as long. Median process peak RSS is about 1.95× | 547 lines, 12 datatypes, plus 194 retained helper lines for an incomplete evaluator domain. Reject as a general replacement; preserve the narrower closure hypothesis. |
| [A03: shared binding traversal](architecture-evidence/binding-schema/report.md) | Checked component; freshening and template ID shifting; 965 observations including scope, metadata and deep terms | Freshening takes 18.6–22.6% more time; shifting takes 81.2–81.7% more time | Optimistic replacement adds 22 physical / 15 nonblank lines / 510 bytes. Reject this runtime traversal. |

These workloads differ and their percentages cannot be added or compared as
whole-compiler speedups. All use code generated from actually checked Bend source.
Only A01 is a full checked compiler candidate. A02/A03 are checked stage0
components, not self-hosted compiler releases. No emitted-program speedup or new
TypeScript ratio was measured. A01's emitted programs match the existing output.

## What the experiments teach us

**Sharing semantic ownership looks more promising than sharing traversal shape.**
A01 lets checking retain facts it already computed, and the existing emitter can
consume those facts without a second annotation traversal for the supported
slice. This demonstrated compatibility is stronger than estimating deletion from
similar-looking source. However, retaining every checked term imposes allocations
on verification-only requests. The output policy is part of the architecture,
not a later micro-optimization.

**Closures avoid repeated substitution, but a universal heap is costly.** A02
keeps arguments suspended in first-order environments and shares repeated forcing.
The measured beta chain benefits. A closed constructor tree has little
substitution to avoid; wrapping and managing its cells adds substantial cost.
The old compiler already has sharing machinery, so demonstrating sharing alone
does not establish an improvement. The heap, environment, freshness, quotation,
short-circuiting and conversion contracts must all be included in the comparison.

**A generic walker can move complexity into conventions.** A03 replaces six
typed freshening frames with one frame plus mode, shape and sentinel rules. Two
operations share a loop, but their distinct scoping and metadata obligations
remain. The prototype makes shifting stack-safe at large depth, an additional
capability, yet it misses both the size and ordinary cost goals. Generated
specialization remains a different, untested proposal; this result cannot be
relabelled as evidence for it.

## Correctness results and preserved failures

A01 retains the chronological source-validation prerequisite and exact failed
checker results. Positive controls exercise dependent application, constructor
telescopes, erased arguments and higher-order terms. Its direct path makes no
annotation call. Let and matcher output still differ from annotation output;
rewrite reconstruction remains unimplemented. A pre-specialization template can
match the annotated term while lacking the required instance book. Annotation
equality alone therefore cannot justify retiring specialization.

A02's first 49 passing controls were insufficient. Stronger controls found bound
variable display-name loss, malformed shapes admitted by its scope guard, and
conversion visiting a divergent later argument before an earlier mismatch.
The latter is observable even when final values would be definitionally equal:
the original comparison returns false while the prototype times out. Candidate05
fixes those findings and passes 90 controls. Independent review then raised
reflexive divergent terms and unequal arities as further demand-order witnesses.
The [A02 report](architecture-evidence/semantic-values/report.md) records their
separate attempts and final status. Candidate07 passes 100 selected controls,
including corrected globally unique binder-ID demand witnesses. A final
All-domain comparison still returns false in the old implementation and times
out after two seconds in the new one. Both inputs pass the prototype's syntax
guard; its conversion demand contract therefore remains incorrect for the
admitted raw-term domain. We stopped extending this rejected prototype. A
separate predicted codomain difference was not established: both implementations
timed out, which remains recorded as inconclusive. Candidate05's normalization
measurements stay attached to candidate05, not a corrected API.

A03 passed 805 initial observations; adding 160 input-immutability checks gives
965, not 1,770 distinct tests. The controls compare unchanged Bend comparators and
include independently expected parallel-let scope. A first measurement generator
accidentally constructed an All node with three children. Its matching raw-API
measurements are preserved, but the headline numbers use the corrected two-child
workload. That workload has valid arities; it is synthetic syntax rather than a
type-checked Bend program.

No bounded suite proves the complete language. In particular A02 uses an empty
definition book and excludes matcher/rewrite/reduction behavior required for a
full compiler. It assumes the core's globally unique binder IDs; its syntax
guard does not prove that invariant. Its head observer is not a drop-in weak-head normalizer: an
unquoted closure/spine cannot be replaced by its syntax field. The independent
[semantic review](architecture-evidence/checked-output/semantic-values-independent-review.md)
and per-experiment reports make these boundaries explicit.

## Measurement and reproducibility

Production baseline is S4 B02, source commit
`22f6e8e21be5390d50831f9cbe4aab1147ff217d`; the design was committed and pushed as
`4b2e4c7` before results. Upstream stays pinned to
`6018e28ecc67cf1fffc0c20c64b11023474c2df8`. Builds and measurements used
Node24.18.0 and were serialized on CPU0. Agents prepared code and reviewed results
in parallel; no competing compiler/benchmark job was intentionally launched.

A01 has separate check-only and compile-preparation lanes. Each uses four fresh
ABBA workers, three warmup batches and seven measured batches of 32 requests.
The timed boundary excludes parsing, whole-book chronological validation,
emission, loading and process startup. Actual code generation and execution are
preflight correctness checks outside the request timer.

A03 uses four fresh ABBA workers per operation, three warmup requests, then seven
requests of 100 transformations. A02 uses eight fresh workers in two ABBA blocks;
each measures both workloads after ten warmups, with three batches of 100/50
normalizations. The entire new public normalization boundary includes scope
validation and fresh-ID initialization. A02's oracle is definitional equality
using the original Bend comparator, not byte-identical term readback. Its samples
show warmup trends; treat the ratios as a directional feasibility screen, not
steady-state estimates or statistical significance. The large closed-data
regression occurs in every worker.

Memory numbers are individual worker process high-water marks, including setup
and controls, not per-request retained allocations. All raw samples remain,
including slower workers. The experiments make no new hardware-general claim.

The [evidence capsule](architecture-evidence/README.md) contains all raw attempt
directories, source snapshots, consumed APIs, tools, fixtures, output programs,
failures, logs and measurement samples. Every regular member is hashed and the
archive is reopened to verify its contents: 1,869 regular members, 6,227,562
compressed bytes, all verified. Per-experiment reports give fresh-path
reproduction commands and distinguish executable dependencies from archived data.

## Source and context accounting

The installed compiler remains **59 Bend modules, 14,667 physical lines,
12,505 nonblank lines and 470,062 bytes**. That is the previous 11.16% physical
reduction from 16,509, with another 6,413 lines still needed to reach 50%.
Final release verification and all baseline source/artifact hash comparisons pass.
The previous frontend result remains 318 strict failures with 2,756 preserved
observations; this research does not rerun or improve that full gate. The
historical 6.03× TypeScript ratio belongs to Phase5, not these trials.

Prototype source, adapters and test/preservation machinery are additional research
context. Their counts are retained separately. A02's partial implementation
cannot be subtracted from the 985 lines of normalize/graph as if it replaced both
modules. A03's budget retains its shared FFresh, renaming and definition-list
helpers. A01 still includes annotation and specialization. No prototype deletes
a production concept or earns net source savings yet.

## Recommended next bounded decision

1. **Separate verification from executable checked output in A01.** Add an explicit
   output/discard policy, with guards before allocations; preserve the old
   check-only entry and expose a compile entry. Read-only analysis estimates
   another 30–70 lines plus ABI/test adapters across three modules. Repeat both
   lanes and the same exact failure/chronology controls before extending coverage.
   A smaller ablation can test whether inference-root Ann wrappers are redundant;
   this is a hypothesis, not an earned saving.
2. **Prove one complete deletion boundary.** Extend the chosen output representation
   through let/match/rewrite and dependent template-instance ownership, then show
   the real compiler route no longer calls the old pass. Count reconstruction,
   adapters, tests and remaining legacy routes before claiming annotation removal.
   Compact backend facts may be cheaper than full type-bearing Ann wrappers but
   require an explicit erasure/dependency contract.
3. **Keep semantic environments as a narrower alternative.** A closure-based
   telescope-checking probe or a closed-value path without heap cells could test
   the observed mechanism. Require a baseline for the retained utilities and
   short-circuit demand rules before a broad evaluator rewrite. Two coexisting
   evaluators would add complexity unless a concrete old path is retired.
4. **Do not expand the rejected runtime walker.** A later generated traversal
   needs a deletion budget including its generator and a third genuinely distinct
   operation. Stable identities, staged grammar, shared executable IR, exact
   support and interpreter staging remain explicitly deferred in A04–A08.

The first experiment to attempt next is therefore A01's output policy. This is
the smallest supported step toward removing duplicate work and an entire pass.
It still needs to earn lower total code and concept cost; none of these results
funds the much larger 50% or 75% target by itself.
