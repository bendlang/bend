# Phase 7: a smaller, simpler selfhosted Bend2 compiler

Status: design, not an implemented change. Written 2026-09-26 after the user
redirected work from the interrupted performance/conformance campaign toward
architectural simplification. This document sets the next implementation order;
it does not resume the previous campaign's elapsed time budget or promote its
candidates. Implementation requires a subsequent work assignment.

The objective is to keep the same compiler purpose and language target while
progressively reducing maintained source, repeated work and the knowledge needed
to change it. Start with measured retirement, prove the new information flow on
a small slice, then migrate and delete the old machinery. Aim for roughly half
the present compiler source. More extreme reductions require separate evidence.

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
Choose between annotated nodes and a compact side table in the slice experiment;
include lookup/allocation cost and invalidation rules in that choice.

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

The line bands below are planning hypotheses for the full 16,509-line compiler
scope, including its Bend driver. They are cumulative, overlap and are not additive
savings. They do not authorize removing functionality to hit a quota. Physical
line reduction must be accompanied by byte and mechanism measurements. Some
migrations temporarily increase size; count their bridges and remove them before
claiming completion.

| Phase | Focus | Hypothesized total lines after completion |
| --- | --- | ---: |
| S0 | Freeze baseline, contracts and measurements | 16,509 |
| S1 | Retire obsolete paths and simplify the working route | 16,000–16,400 |
| S2 | Prove the new architecture on a small slice | No whole-compiler reduction promised |
| S3 | Migrate term/provenance contracts and remove old bridges | 13,000–15,000 |
| S4 | Retain checked facts; remove diagnostic/type reconstruction | 11,000–13,500 |
| S5 | Simplify frontend, shared decisions and host boundaries | 9,000–11,500 |
| S6 | Consolidate and release one maintained implementation | 8,000–10,000 |
| S7 | Optional further research | ~4,100 only if a new prototype justifies it |

### S0 — Freeze what we must preserve

Record manifest/source/API/runtime/Base/host/toolchain identities and the current
dirty/candidate inventory. Preserve pending Phase 6 work without folding it into
the baseline. Inventory public CLI/API behavior, actual runtime roots, the eight
mechanism families above, and the three fixed context tasks.

Reuse existing release and conformance evidence when exact identities match.
Prepare focused selections for each proposed change, plus finite limits for large
input and request-history tests. Record same-machine iteration and representative
performance baselines before changing implementation. Reserve full-source timing
for integration; it is not the edit loop.

**Exit:** a reproducible baseline and comparison policy, including known failures,
gated hardware, baseline context sets and a list of external callers. No new
general benchmark framework or compiler rewrite is needed to finish this phase.

### S1 — Remove proven obsolete implementation

Audit superseded freshening, normalization and diagnostic helpers from their
actual entry points, exports, host strings, test roots and assembled manifests.
Existing Phase 6 cleanup evidence can guide the audit; revalidate the exact
candidate before adoption. Absence from a textual call search alone is insufficient.

Delete an obsolete path together with its private helpers. Keep meaningful
behavioral tests and public compatibility wrappers while their callers migrate.
Standardize routine edits on the maintained checked-B1 workflow. Index historical
tools and results so they need not be loaded for ordinary work; retain their
reproducers and original failure status.

**Exit:** measured net source reduction, unchanged applicable observations and
one documented working route. Byte-identical representative output is a useful
additional gate for deletion-only changes. Archiving a legacy prototype outside
the compiler manifest earns no compiler-line savings.

### S2 — Prove an end-to-end slice before a broad rewrite

Use an isolated candidate and a compact set of programs covering a dependent
application, an affine/erased argument, an ADT match, a template instance, an
imported name and a located rejection. Carry explicit term variants, provenance
and checked facts through these cases to interpretation and both emitters. Include
an applicable foreign-signature/readback witness. Exercise actual generated JS and
native programs.

The old and proposed representations can meet at one explicit conversion boundary
for this experiment. Count all converters and support code. The candidate must
actually produce and consume new facts; wrapping an unchanged old pipeline does
not test the proposal. Preserve a separate production implementation throughout.

Compare annotated nodes with a compact fact table, and direct spans with compact
source references. Check sharing, invalidation, errors and allocation in genuine
checked B1 and a self-emitted component where feasible. Existing failed provenance
or typed-cache experiments are relevant counterevidence, not completed solutions.

**Exit:** a reviewed contract and concrete deletion map for S3/S4, with measured
slice cost and no unexplained behavior change. If the design adds more machinery
than it removes, revise or reject it here. If facts cannot survive specialization
safely, retain annotation and lower the forecast instead of forcing migration.

### S3 — Migrate core representation and provenance

Migrate one connected responsibility at a time using the agreed schema. Keep
explicit binder IDs, lazy sharing and explicit work frames. Replace implicit child
indices with named cases; centralize the small operations that genuinely share
binding rules. Migrate producers and consumers together so internal adapters do
not become a permanent second compiler.

Carry source identity and offsets through syntax, elaboration and freshening.
Specify imported and generated-node ownership, then retire obsolete origin scans
and structural matching only for fully covered paths. Test Unicode, multiline
strings, repeated equal subterms, reused request workers and changed source graphs.

**Exit:** the migrated representation has one owner, its obsolete conventions and
adapters are deleted, and parser/core/diagnostic controls pass. Boundaries changing
public data require B1/H ABI checks, cache schema/version checks and an initial
checked self-reproduction gate before dependent work expands.

### S4 — Make checking authoritative through specialization

Publish structured checker failures and retained success facts. Preserve declaration
visibility, open laws, quantity demand, termination checks and first-error order.
Remove rejection replay once all diagnostics consume the authoritative result.
Render errors once, preserving the public API at its boundary.

Teach specialization to transform terms and facts together, including dependent
applications, erased template arguments, instance identity and fresh binders.
Retain source templates and full type context for conversion. Track recursion and
growth limits explicitly. Backends consume the retained facts for erasure, foreign
marshalling, layout and readback. Retire `ka_type`-style reconstruction only after
every live consumer has a valid replacement; normalization still has legitimate
work to do on retained types.

Begin with no new generic memoization layer. Previous instrumentation did not
establish repeated identical annotation inputs; reducing information loss is a
different hypothesis from caching repeated calls.

**Exit:** no diagnostic recheck on migrated paths; no duplicate inference pass for
facts already retained correctly; exact changed-observation accounting; focused
dependent/template/quantity/FFI controls and the full frontend gate. Measure both
accepted and rejected requests, peak memory and persistent-worker contamination.

### S5 — Simplify frontend and consumers around the new contracts

With representation and facts stable, consolidate redundant declaration/expression
bookkeeping, error transports and fresh-ID plumbing. Evaluate a direct source
cursor against the existing token pipeline only if it removes net machinery while
preserving grammar, Unicode offsets and first-error behavior. Do not assume a
separate lexer is itself a defect. Similarly, remove a freshening pass only after
demonstrating capture-safe allocation under imports and specialization.

Share backend reachability and semantic descriptors where the contract is identical.
Keep target-specific erasure/layout choices explicit. Consolidate host conversion
at one boundary while continuing to support and test genuine B1 and H shapes;
removing scattered branching does not erase their provenance differences.
Reduce experiment-specific execution helpers through the existing development
workflow rather than adding a replacement framework.

**Exit:** named mechanisms or state transitions actually disappear, dependencies
and fixed-task review context shrink, and affected backend programs execute with
unchanged observable behavior. Native ownership/disposal, partial applications,
parallel joins, large constructors and readback require dedicated controls.

### S6 — Delete migration scaffolding and ship one compiler

Remove converters, duplicate implementations, dead exports and superseded caches.
Update source assembly, host ABI documentation, the compiler guide and public
examples together. Keep one maintained build/test/release route; historical
artifacts remain evidence, not competing defaults.

Freeze the integrated source. Run full frontend comparison, affected broad backend
lanes, actual checked B1 to H to H reproduction, integrity verification and a
relocated ordinary CLI check. A fixed point requires equal successive self-emitted
bytes for this frozen source; it need not equal the pre-refactor compiler bytes.
Run controlled full-source and generated-program comparisons after correctness.

**Exit:** one reproducible release, a final line/byte/mechanism/context dashboard,
all remaining gaps and unverified hardware stated, and reproducible before/after
evidence. If a sound design reaches 10,000 lines rather than 8,000, report that
result and its remaining costs. Do not compress code to manufacture a 50% claim.

### S7 — Optional research toward 75%, with an explicit stop

Only after S6, profile the remaining source and review burden. Candidates include
a more compact first-order binding/environment model or narrowly shared traversal
descriptions that remove repeated semantic rules. Each needs an independent slice,
all costs counted, and the same bootstrap/behavior/performance gates. Avoid a
general metacompiler whose implementation and generated output hide the real cost.

| Reduction from baseline | Remaining lines | Remaining bytes for the same text reduction | Interpretation |
| --- | ---: | ---: | --- |
| 50% | about 8,250 | about 255 KB | Architectural goal; 8–10k lines and 250–350 KB is the initial planning range. |
| 75% | about 4,130 | about 127 KB | Research hypothesis, below the complete TypeScript compiler's size. |
| 90% | about 1,650 | about 51 KB | No credible complete implementation proposal established. |
| 95% | about 825 | about 25.5 KB | No credible complete implementation proposal established. |

These percentages apply separately to lines and bytes. Achieving one does not
establish the other. Task-specific context might shrink much more than total code
through strong interfaces and concise current documentation, but 75–95% context
reduction also needs the fixed-task measurements rather than an assertion.

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
