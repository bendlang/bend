# Phase 7: a smaller, simpler selfhosted Bend2 compiler

Status: design, not an implemented change. Written 2026-09-26 after the user
redirected work from the interrupted performance/conformance campaign toward
architectural simplification. This document sets the next implementation order;
it does not resume the previous campaign's elapsed time budget or promote its
candidates. The user has now authorized sequential execution: design, implement
and report each phase. [S0's completed audit](../../implementation/phase7/s0-report.md)
supports the first 548-line retirement and records the later budgets as unproven.

The objective is to keep the same compiler purpose and language target while
progressively reducing maintained source, repeated work and the knowledge needed
to change it. Begin with a read-only phase that challenges the hypotheses without
changing the implementation. Every subsequent completed phase must reduce both
net source size and conceptual complexity. The first group of implementation
phases targets at least 50% fewer compiler lines; the later group targets at least
75%. These are objectives to validate, not established feasibility claims.

## 1. Baseline and scope

The reference is Bend2 2.0.21, upstream
`6018e28ecc67cf1fffc0c20c64b11023474c2df8`. Repository HEAD at this audit is
`ce3cbed`; the production compiler modules are unchanged from `a6459af`.
Unpromoted Phase 6 candidates and pending evidence are separate from this baseline.
The human-written `bend2/bend.ts` and pinned upstream remain unchanged.

Read the [current architecture](../../selfhost/docs/ARCHITECTURE.md),
[conformance contract](../../selfhost/CONFORMANCE.md),
[compiler guide](../../docs/BEND-IN-BEND.md), and
[maintained development workflow](../../docs/PHASE5_DEVELOPMENT.md) alongside this
design. They describe the existing implementation; the architecture below is a
proposal.

### Measured source size

Membership is the 59 modules in `selfhost/src/compiler.json`. Physical lines
include blanks and comments; bytes are UTF-8 source bytes.

| Component | Physical lines | Nonblank lines | Bytes |
| --- | ---: | ---: | ---: |
| Core | 2,786 | 2,319 | 75,574 |
| Checking, specialization, annotation | 2,987 | 2,477 | 78,091 |
| Frontend | 4,255 | 3,525 | 127,575 |
| Loading | 1,185 | 1,006 | 34,381 |
| Diagnostics | 1,079 | 951 | 35,136 |
| JavaScript backend | 1,802 | 1,491 | 56,442 |
| Native backend | 2,209 | 1,864 | 97,497 |
| Bend driver | 206 | 170 | 5,241 |
| **Total** | **16,509** | **13,803** | **509,937** |

There are 1,526 definitions, 1,280 laws and 66 datatype declarations. Multiline
signatures occupy 6,273 lines; standalone `@unsafe` markers occupy another 1,526.
These are useful size measurements, not a count of language concepts. Reformatting
signatures can reduce physical lines without removing a mechanism or much text.

For context, the pinned TypeScript implementation has 3,870 lines of language
implementation and 3,278 lines of compiler-oriented backend code: 7,148 lines,
6,650 nonblank lines and 237,023 bytes. This excludes `main.ts` and the large
embedded runtime sections of `comp.ts`, but includes small primitive snippets.
The comparable Bend subtotal without its driver is 16,303 lines: 2.28 times as
many lines and 2.13 times as many bytes. Our frontend/core/checking/loading/errors
subtotal is 3.18 times the TypeScript counterpart; the backend subtotal is 1.22
times. The TypeScript backend also implements native optimizations we do not yet
have. It is a useful architectural reference, not proof that its line count is
attainable with Bend's host-language constraints.

The earlier recount classifies another 12,919 lines as support/runtime/test code;
that bucket includes legacy material and some generated runtime duplication.
Experimental performance tools now contribute 15,824 lines. Neither bucket is
part of the 16,509-line compiler target. Split authored runtime, maintained host,
tests, generated artifacts and historical tools before claiming savings there.
Moving code between these buckets is not a reduction in total implementation.

The existing [source recount](../../implementation/phase5/code-size-evidence/recount.py)
records file membership and hashes. From the repository root, a fresh read-only
audit can be written outside the source tree:

```sh
python3 implementation/phase5/code-size-evidence/recount.py \
  a6459af /tmp/bend-simplification-recount.json
```

### Existing behavioral and performance evidence

The [Phase 5 release](../../implementation/phase5/report.md) records 919/919
positive frontend fixtures, 318 strict check failures and 444 exact live
TypeScript differences. The full frontend artifact comparison covers 2,756
observations from 1,378 fixtures. These are different metrics with different
denominators. They are historical evidence for identified artifacts, not fresh
results from this design.

The [full-source comparison](../../implementation/phase5/full-source-comparison.md)
measured 363.39 seconds for the optimized release versus 60.25 seconds for pinned
TypeScript, or 6.03 times slower under its stated cache policy. A checked API
rebuild took 14.63 seconds in the final integration. Compiler throughput,
edit/build/test latency and generated-program speed must remain separate.

## 2. Functionality that survives every phase

The target remains the pinned Bend2 language, with complete conformance as an
objective. Existing gaps stay visible; simplification must not redefine them as
unsupported features to improve a score.

- Keep parsing, imports/aliases, declaration order, patterns, dependent types,
  affine quantities, erasure, termination, templates, proofs and conversion.
  Preserve the distinction between parse, check, compile and runtime failures.
- Keep checking, interpretation, JavaScript execution/library emission and native
  generation, including foreign interfaces, parallel tasks and CPU/Metal/CUDA
  generation paths. Actual GPU execution remains unverified without hardware.
- Keep supported CLI operations, public compiler queries, diagnostics and output
  behavior. Rejected programs must not reach executable generation. Correct
  diagnostic locations and first-error selection are part of the target.
- Compiler decisions remain implemented in Bend. The host handles IO, processes
  and representation adaptation. Ordinary compilation gains no upstream fallback.
  Existing platform runtimes remain separately identified and licensed.
- Keep a checked bootstrap and genuine self-reproduction. Simplifying commands
  must preserve distinctions between checked B1, derived images and self-emitted H.
- Preserve sharing, bounded stack behavior and large-input capabilities. Replacing
  worklists with short recursive functions is acceptable only if equivalent
  operational behavior is demonstrated.

Refactors use the old compiler as a regression reference, and pinned TypeScript
as the language reference. A known old bug is not an invariant: an intentional
repair must name its changed observations and demonstrate the intended reference
behavior. No newly failing case can be hidden by an equal number of new passes.

## 3. What we mean by less complexity

About fourteen broad responsibilities are shared with TypeScript: parsing,
elaboration/patterns, imports, binding, normalization/equality, dependent checking,
quantities/erasure, termination, templates, diagnostics, reachability,
representation/foreign interfaces, JS generation and native/parallel generation.
We are simplifying their implementation, not promising to delete half the language.

Use a small dashboard, with the same definitions at each checkpoint:

| Measure | Rule |
| --- | --- |
| Source | Physical/nonblank lines and bytes, by fixed responsibility and language; report additions as well as deletions. |
| Mechanisms | Named inventory of representations, binding models, reconstruction passes, cache validity rules, ABI modes and maintained workflows. A retirement names its replacement and deleted callers. |
| Dependencies | Public interfaces, internal cycles and cross-component access. Textual call counts are estimates, not semantic complexity scores. |
| Change context | For three fixed tasks, list the implementation, contracts and tests needed for a review; count their union of files and bytes. Record the selection rationale. |
| Behavior and cost | Per-case conformance changes, checked build plus focused-test latency, representative compile time/memory, generated size and program execution cost. |

The three context tasks are: repairing a parser's first-error choice; changing a
dependent application check; changing constructor lowering across JS and native.
Phase S0 establishes their baseline sets. Use the same task descriptions and an
independent reviewer after migration. These are review-context proxies, not
measured human effort or universal model-token counts.

Initially inventory these removable or reducible mechanisms:

1. Implicit string-tag and child-position conventions in `KTerm`.
2. Whole-program binder renumbering and repeated binder-aware traversals.
3. Source-origin reconstruction and structural matching after transformations.
4. Rechecking a rejected program to reconstruct its diagnostic.
5. Reconstructing types for emission after checking discarded usable facts.
6. Superseded traversal/normalization implementations with remaining scaffolding.
7. Repeated host representation branching throughout compiler consumers.
8. Multiple ad hoc commands for equivalent development operations.

This is an audit list, not a claim that all eight can disappear. Each has an owner,
consumers and a deletion condition. More datatype variants can mean fewer implicit
rules; fewer functions can mean worse coupling. Neither is a standalone success.

## 4. Intended architecture

The intended flow is:

```text
source graph + source identities
  -> parse/elaborate with provenance
  -> explicit first-order core + ordered declaration events
  -> authoritative checking result
       failure: structured error -> diagnostic renderer
       success: checked definitions + retained type/usage facts
  -> specialize terms and their dependent facts
  -> select live output using the complete semantic context
  -> JS lowering                 -> native lowering
  -> existing JS runtime         -> existing CPU/Metal/CUDA runtime
```

Keep a small set of ownership boundaries: syntax/loading owns provenance and
declaration events; core owns terms, binding and evaluation; checking owns semantic
facts; backends consume those facts; the host owns effects. Directory count is not
a goal. A component boundary is useful when it prevents consumers from reaching
into another component's internal state.

### Representation and binding

Replace the generic string-tag/positional-child term with explicit first-order
variants and named fields. Keep explicit binder IDs initially. Separate parser
errors, administrative sentinels, evaluation cells and specialization state from
language terms. The language node schema should state what each field means.

Do not simultaneously adopt TypeScript's function-valued binders. Bend's current
`Data` representation intentionally has no function-valued fields. Changing the
binding model, sharing model and node schema together would make failures hard to
localize. Consider fewer freshening passes only after binding invariants are
explicit and capture tests cover imports, shadowing, templates and parallel binds.

Share small binder-aware primitives where they remove repeated rules. A generic
visitor framework is not automatically smaller or faster; dependent checking,
evaluation, freshening and erasure have different traversal requirements.

### Information produced once and kept valid

`KChecked` already contains a term, type and usage information. The missing
contract is how useful facts survive checking, specialization and emission.
Define checked definitions that preserve the information consumers require.
Compare annotated nodes and a compact side table using existing evidence in S0;
test the surviving choice in a bounded slice inside S3. Include lookup/allocation
cost and invalidation rules in that choice.

Facts belong to a particular node, binder environment and book revision. Structural
similarity is not sufficient authority to reuse them. Substitution, freshening
and template materialization must transform their dependent types and identities,
or explicitly invalidate and recompute the affected facts. Source templates must
remain available for conversion. The complete indexed semantic book remains
available even when emitted definitions are pruned by reachability.

Use one authoritative structured checking failure, with rendering as a consumer.
Retain source identity and UTF-16 offsets through parsing and transformations.
Specify generated-node, substitution and ambiguous-origin behavior. Locations may
be absent when no defensible origin exists; they must never be invented by a
structural match to an unrelated occurrence. Measure successful compilation's
metadata cost, not just improved rejected-program diagnostics.

### Shared backend decisions, distinct lowering

Share facts that really have the same meaning: live definitions, erased arguments,
constructor identity, foreign signatures and result/readback descriptions.
Reachability, annotation/fact selection and layout validation must agree on
backend-specific intrinsic stops. Preserve backend-specific lowering: native
ownership, segments and fork/join continuations differ from JS closures and
trampolines. Avoid replacing two comprehensible emitters with one flag-driven
emitter that exposes both models everywhere.

## 5. Phases and decision gates

S0 is the only phase that does not change or shrink the implementation. S1–S4
target at least 50% fewer lines; S5–S7 then target at least 75% fewer lines, both
relative to the original 16,509-line compiler including its Bend driver. A further
25 percentage points means halving the implementation remaining at the 50% mark.

The intermediate ceilings are provisional allocations of the goal, not forecasts
backed by measured replacement code. S0 must identify concrete deletion candidates
and replacement costs before endorsing those allocations. Adjacent phases can be
rebalanced when dependencies demand it, with a recorded reason. The overall 50%
and 75% objectives and the functionality contract remain fixed.

| Phase | Main simplification | Target maximum compiler lines | Cumulative reduction |
| --- | --- | ---: | ---: |
| S0 | Validate hypotheses using existing code and evidence; no implementation changes | 16,509 baseline | 0% |
| S1 | Remove obsolete implementations and private helpers | 16,000 | about 3% |
| S2 | Explicit terms and direct provenance; retire positional and origin-recovery machinery | 13,500 | about 18% |
| S3 | Keep authoritative checked facts/errors; retire replay and duplicate inference | 10,500 | about 36% |
| S4 | Simplify frontend, book state and boundary plumbing; deliver first milestone | **8,254** | **at least 50%** |
| S5 | Simplify binding and environments; remove repeated renumbering machinery | 6,500 | about 61% |
| S6 | Share backend semantic decisions; remove parallel bookkeeping | 5,000 | about 70% |
| S7 | Factor remaining repeated traversal/control rules; deliver second milestone | **4,127** | **at least 75%** |

### Completion rule for every implementation phase

A phase is complete only when its integrated compiler meets all of these rules:

1. Physical lines, nonblank lines and source bytes are lower than at the previous
   completed phase, using the same responsibility scope. Charge new compiler
   helpers, generators and required host logic wherever they are placed. Moving
   code outside the manifest, into generated text or another language earns no
   reduction. Keep support/runtime/test counts separately visible too.
2. The mechanism ledger shows a net conceptual simplification: identify the
   independent rules, alternate paths or validity contracts removed, and charge
   any new ones. An independent review must find fewer required mechanisms or
   invariants overall; a renamed layer or larger generic framework does not pass.
   Datatype and function counts are supporting metrics, not this verdict.
3. All applicable correctness, compatibility, bootstrap and performance gates pass.
   Keep every existing gap visible and identify intentional semantic repairs.
4. The phase's target ceiling is met, or its intermediate allocation was explicitly
   revised on evidence before completion. S4 cannot be reported as the 50%
   milestone above 8,254 lines, nor S7 as 75% above 4,127 lines.

Prototypes, converters, measurements and release checks are substeps inside these
phases. A temporary increase is allowed in an isolated candidate, but is not a
completed phase or a promoted simplification. Include any surviving bridges in
the final cost. Preserve the last smaller validated compiler if a candidate fails.

### S0 — Validate the hypotheses without implementation changes

Inspect current code, callers, manifests, public interfaces, TypeScript structure
and existing experiment evidence. Record source/API/runtime/Base/host/toolchain
identities and pending candidates without modifying or promoting them. Establish
the mechanism inventory, fixed-task context sets and functionality baseline.

For each proposed simplification, produce one evidence row containing:

- The exact current functions/files and mechanism proposed for removal.
- All consumers, dynamic/public entry points and compatibility obligations.
- The replacement contract and why it can preserve the same behavior.
- A conservative range for removed lines minus replacement, bridge and auxiliary
  costs; assign each deletion to one phase so savings are not counted twice.
- Existing supporting and contradicting evidence, a cheapest falsifier, and a
  verdict of supported for a bounded trial, contradicted or unresolved.

Challenge source provenance overhead, preservation of facts through templates,
explicit-term verbosity, capture safety, stack/sharing requirements and backend
differences. Inspect rejected Phase 6 attempts before proposing the same mechanism
again. Test whether the unique deletion budget plausibly covers roughly 8,255
lines for the first milestone and 12,382 for the second. Identify any unsupported
portion explicitly rather than inventing a saving to balance the table.

No compiler, runtime, host, harness, configuration or instrumentation changes;
no prototype implementation or source migration. Existing read-only counters and
unchanged baseline programs may run if an essential measurement is missing, with
outputs isolated from the source/default artifacts. The deliverable is an audit
report and, if needed, revised planning estimates. Read-only analysis can establish
opportunity and falsify assumptions; it cannot prove an unimplemented replacement
correct or fast.

**Exit:** a reviewed hypothesis/deletion ledger and ranked plan, preserving known
failures and naming unresolved feasibility. No source reduction is claimed. A
contradicted hypothesis must be replaced or deferred before its implementation
phase starts; unresolved feasibility receives a bounded trial inside that phase.

### S1 — Remove proven obsolete implementation

Delete superseded freshening, normalization and diagnostic implementations only
after tracing actual roots, exports, host strings, tests and assembled manifests.
Remove their private helpers, redundant forwarding and duplicate control paths
together. Existing Phase 6 evidence can guide the work; validate the exact patch
against the frozen baseline. Absence from textual search alone is insufficient.

Keep meaningful tests and public contracts. Standardize the working route on the
maintained checked-B1 workflow and index historical experiments so ordinary work
need not load them. Removing a legacy prototype outside the compiler manifest
does not contribute to the compiler target.

**Concepts removed:** alternate obsolete algorithms and the private conventions
needed to call them. **Target:** at most 16,000 lines. **Gate:** unchanged applicable
observations, lower net lines/bytes and a reviewed retirement inventory;
byte-identical representative output is an additional deletion-only control.

### S2 — Make terms and source ownership explicit

**S0/S1 evidence revision:** execute the bounded [S2 provenance consolidation](s2_provenance_consolidation.md) first, with a net 99-line/2,444-byte minimum reduction and 15,862-line ceiling. The original explicit-term/direct-span migration and 13,500-line forecast below remain deferred hypotheses, not completed work or supported savings. This revision does not lower the 50%/75% milestone requirements.

First prove a small slice inside this phase: parse, check, interpret and emit JS
and native code for a dependent application, affine/erased argument, ADT match,
template instance, imported name and located rejection. Keep the production
compiler unchanged while the candidate is incomplete. Count temporary converters.

Then migrate connected producers and consumers to explicit first-order variants
with named fields. Keep explicit binder IDs, lazy sharing and work frames. Remove
positional access helpers, duplicate tag-dispatch conventions and administrative
sentinels embedded in language terms as their replacements become complete.

Carry source identity and UTF-16 offsets through syntax, elaboration and freshening.
Specify imported/generated-node ownership and substitution provenance. Retire
covered origin scans and structural matching. Test Unicode, multiline strings,
repeated equal subterms, changing source graphs and persistent worker histories.
Direct source locations can replace origin recovery while legacy diagnostic
rechecking remains until S3; these are distinct mechanisms and savings.

**Concepts removed:** implicit positional term conventions and reconstructed source
ownership. **Target:** at most 13,500 lines, with net savings including all variant
constructors, spans and remaining bridges. **Gate:** exact parser/core/diagnostic
controls, allocation measurements, B1/H ABI and cache-schema checks, and an initial
checked self-reproduction at the representation integration boundary. Reject or
revise a schema that merely exchanges implicit rules for more machinery.

### S3 — Keep checked information through specialization

**S2 evidence revision:** execute the bounded [authoritative-checker design](s3_authoritative_checker.md), deleting diagnostic replay with at least130net Bend lines removed. Retained type facts and the original10,500-line forecast below remain deferred hypotheses. The50%/75% milestones are unchanged.

Within a bounded slice, turn existing local `KChecked` information into retained
facts and authoritative structured errors. Compare annotated nodes and a compact
side table, including validity and memory costs. The candidate must produce and
consume new facts, not wrap an unchanged reconstruction pipeline.

Preserve declaration visibility, open laws, quantities, termination and first-error
order. Render errors once from the authoritative failure and remove diagnostic
rechecking. Teach specialization to transform terms and facts together, including
dependent types, erased template arguments, instance identity and fresh binders.
Retain source templates and the complete semantic context for conversion.

Migrate erasure, foreign marshalling, layout and readback consumers. Remove
`ka_type`-style reconstruction only when each consumer has valid retained facts;
normalization can still legitimately act on those types. Avoid a new generic cache:
earlier instrumentation did not establish repeated identical annotation inputs.

**Concepts removed:** diagnostic replay and rediscovery of already established
types. **Target:** at most 10,500 lines. **Gate:** dependent/template/quantity/FFI
execution controls, full frontend vector and accepted/rejected request-history
measurements. If facts cannot survive specialization safely, stop that candidate;
do not delete annotation to meet the line budget.

### S4 — Simplify frontend and book state; reach 50%

Consolidate repeated declaration/expression state, loader/elaborator bookkeeping,
error transports and repeated book conversions around the S2/S3 contracts.
One component owns each transformation and its result. Evaluate a direct source
cursor against token materialization only where S0 identifies net savings and a
slice preserves grammar, Unicode positions and first-error order. A separate
lexer is not inherently wrong.

Remove scattered host representation branching by using one boundary adapter,
while continuing to test genuine B1/H forms and preserve their lineage. Simplify
consumer state plumbing without yet conflating JS and native lowering. Delete
superseded result wrappers and migration bridges rather than adding a permanent
parallel pipeline.

**Concepts removed:** redundant intermediate states, error transports and boundary
conversion policies. **Target:** at most **8,254 lines**, meeting the first **50%**
milestone. **Gate:** reduced dependencies and fixed-task context, relevant backend
execution, full frontend comparison, checked B1 to H to H reproduction, release
integrity, relocated CLI and controlled performance comparisons. Ship a usable
smaller compiler as part of this phase. A 10,000-line result is progress, but does
not complete this milestone.

### S5 — Simplify binding and environments

Start from the validated 50% milestone. Investigate a compact first-order binding
contract that avoids whole-program renumbering and duplicated environment handling.
Compare retaining globally unique IDs with local indices plus explicit environment
identity using actual retained costs. Keep the option with fewer independent
binding invariants; TypeScript's function-valued binders are not a drop-in choice.

A bounded candidate must cover shadowing, imports, parallel binders, open terms,
template materialization and substitution of both terms and checked facts. Preserve
sharing and explicit stack bounds. Delete old renumbering and environment adapters
only after producers, transformations and consumers share the replacement contract.

**Concepts removed:** repeated global freshening and competing environment/identity
rules. **Target:** at most 6,500 lines. **Gate:** capture and dependent-substitution
controls, deep/shared terms, ABI validity and checked self-reproduction. If local
indices require more shifting/level machinery than they remove, reject that design;
the target does not justify a more complicated binding model.

### S6 — Share backend semantic decisions

Use retained checked facts and the simpler binding contract to express genuinely
common executable-value decisions once: live definitions, erased arguments,
constructor identities, foreign signatures and result/readback descriptions.
Delete independently maintained decision code and bookkeeping in consumers.

The small shared description must remove more machinery than its construction,
interpretation and validity rules add. Keep backend-specific intrinsic stops and
layouts explicit. JS closures/trampolines and native ownership/segments/fork-join
lowering remain distinct; a flag-driven universal emitter is not the objective.

**Concepts removed:** duplicate semantic plans and parallel identity/erasure/foreign
bookkeeping. **Target:** at most 5,000 lines. **Gate:** actual JS/native execution,
readback/FFI, ownership/disposal, partial applications, large constructors, parallel
joins and generated-size/runtime comparisons. Hardware-gated GPU execution remains
separate from preservation of its generation path.

### S7 — Factor residual traversal/control duplication; reach 75%

Recount the remaining code and revisit S0's residual deletion ledger. Investigate
small first-order worklist or result-handling primitives for structurally identical
walks, such as name/free-variable collection and related bookkeeping. Keep distinct
evaluation, dependent-checking and erasure rules visible. Each abstraction must
retire named duplicate traversal/control implementations and their invariants;
merely shortening syntax or removing comments cannot qualify.

Use one bounded candidate at a time. Charge abstraction drivers, operation tags,
special cases, generated helpers and any extra host logic. Avoid a metacompiler or
universal visitor whose configuration recreates the complexity it hides. Delete
obsolete traversal drivers and private wrappers only after equivalent behavior,
sharing and resource bounds are demonstrated.

**Concepts removed:** repeated traversal/control protocols with the same contract.
**Target:** at most **4,127 lines**, meeting the **75%** milestone. **Gate:** the full
integrated release gate used at S4, plus measured net conceptual reduction, context
sizes and final source accounting. Consolidation and release are included in the
phase; they are not a separate phase without reductions.

### Feasibility and honest milestone reporting

The 75% target is substantially more uncertain than 50%: it would leave fewer
lines than the complete pinned TypeScript compiler. The later phases describe
concrete hypotheses to test, not an established route to that size. If S0 or later
experiments show insufficient safe savings, report the shortfall and retain the
last smaller validated version. Rework the mechanism, not the functionality or
accounting, and do not declare the milestone achieved.

Report byte and review-context reductions separately. A 50% text reduction would
require at most 254,968 bytes; 75% would require at most 127,484 bytes. The line
milestones do not automatically establish those byte targets, or an equal reduction
in semantic concepts. Each phase must show a net decrease in implementation
mechanisms; the language responsibilities remain. Reductions of 90–95% in complete
implementation size remain outside this plan's supported proposals.

## 6. Validation and performance policy

Use the existing checked development workflow for ordinary iterations:

```sh
# From selfhost/, using a configuration whose paths resolve from that file:
node tools/development/workflow.mjs run CONFIG.json build/dev/NEW_ATTEMPT
node tools/development/workflow.mjs validate build/dev/NEW_ATTEMPT \
  SELECTION.json build/dev/NEW_VALIDATION
```

These are command templates; choose fresh attempt paths and appropriate selections.
The default 21 witnesses are not sufficient for representation, template or emitter
changes. Reusing an attempt tests its frozen compiler, not subsequent source edits.

| Gate | When | Required evidence |
| --- | --- | --- |
| Static contract review | Before implementation | Consumers, deleted mechanism, ABI/cache impact and cheapest counterexample. |
| Checked build + focused differential cases | Every meaningful compiler change | Live pinned reference, actual checking, valid/rejected neighbors, exact selected scope. |
| Stress and history cases | Representation/state changes | Deep terms, sharing, source/cache changes, repeated requests and bounded resources. |
| Generated program execution | Backend/fact/ABI changes | JS/native output, exits, IO/foreign behavior and ownership-sensitive cases. |
| Complete frontend vector | Integrated semantic boundary | Every observation accounted for; old failures and intentional repairs distinguished. |
| Checked self-reproduction | First representation integration and final release | Genuine parent identity and equal successive H outputs; never inferred from B1 success. |
| Broad backends, relocation, release integrity | Final frozen candidate | Supported lanes executed, known timeouts retained, hardware gates explicit. |

Use accepted, early-error, late-error, dependent/template, large-record and deep-term
workloads for performance. Track source assembly, build, checking, annotation/fact
processing, emission, Clang and generated execution separately where applicable.
Run equal-workload comparisons with frozen identities, matched flags/cache policy,
serial opposite-order samples and every observation retained. Do not time agents
against competing intentional compiler jobs.

The default promotion budget is no reproducible regression greater than 5% in
representative compilation, focused-loop latency or generated-program execution,
and no greater than 10% in peak memory or generated size. These are proposed
engineering budgets, not statistical guarantees. A breach triggers diagnosis and
revision; noisy results are inconclusive. A justified tradeoff must be explicitly
documented and the affected budget reconsidered before promotion. No timeout,
stack overflow, lost sharing or false acceptance is an acceptable tradeoff.

There is no promised speed multiplier from fewer lines. Retaining information may
remove traversals; larger nodes may increase allocation. Measure the resulting
compiler and emitted programs. Preserve the quick checked loop while using long
full-source/fixed-point jobs only at justified integration boundaries.

## 7. Execution, reporting and stopping rules

Implement a single phase contract at a time. Parallel agents can own independent
consumer migrations, audit dead paths or challenge semantics once the common
schema is agreed. One integrator owns core/checker contracts, combined candidates,
release artifacts and controlled timing. Avoid concurrent incompatible edits to
the shared term model or source assembly.

Continue the existing [experiment method](../../experiments/README.md): one file
per distinct hypothesis, short investigation, cheapest falsifier, frozen evidence
and a decision. Preserve rejected Phase 6 formulations and pending work. Read
their findings before restarting overlapping provenance, typed-fact or ABI ideas.
The old campaign's steering should be superseded when implementation begins;
this design does not rewrite its historical evidence or declare it complete.

Implementation results belong in `implementation/phase7/`, with one concise
phase report and links to exact evidence rather than repeated prose. For each
phase record:

- Before/after source membership, lines, bytes and required auxiliary code.
- Mechanisms removed, contracts added and the three context-task measurements.
- Every changed conformance observation and any intentional semantic repair.
- Applicable B1/H, backend, timing and memory results, including failed attempts.
- Remaining bridges, risks, next decision and promoted artifact identities.

Commit the design before implementation, then commit validated, reviewable
increments and their evidence to the existing `selfhost/bootstrap` fork branch.
Keep unrelated pending work out of those commits. Update the README and current
compiler guide at release milestones; keep historical reports immutable in meaning.

Stop a proposed simplification when its slice cannot preserve the contract, when
it replaces local rules with more complicated global invariants, when it moves
compiler logic out of Bend, or when its savings are only formatting or excluded
files. Reassess the phase target using the evidence. Correctness, a usable compiler
and a fast development loop take precedence over any requested percentage.
