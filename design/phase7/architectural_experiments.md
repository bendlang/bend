# Architectural experiments for a smaller compiler

Date: 2026-09-27. Baseline: `22f6e8e21be5390d50831f9cbe4aab1147ff217d`,
the installed S4 B02 compiler. This design records eight research directions and
authorizes isolated trials of the first three recommended mechanisms: checked
output, semantic evaluation, and shared binding operations. It remains inside
S4; it does not declare the 50% milestone or advance S5–S7.

The user asks to write down the ideas, try the recommended experiments, and find
which is best. Historical campaign deadlines do not apply. Start with bounded
feasibility experiments, independently owned, before a broader implementation.

The [completed first comparison](../../implementation/phase7/architecture-report.md)
records actual results and the next decision. The proposals and prospective
budgets below remain hypotheses unless that report explicitly validates them.

## Baseline and success criteria

The 59 manifest modules contain 14,667 physical lines, 12,505 nonblank lines and
470,062 bytes. The original baseline was 16,509 lines; another 6,413 must be
removed to reach 8,254. These experiments do not have a funded 6,413-line budget.
The current checked/focused loop is about 35 seconds in the S4 measurement.
The historical 6.03× TypeScript ratio belongs to the Phase 5 whole-source
workflow, not a newly measured version. All 2,756 frontend observations were
preserved at S4, including 318 strict failures.

Judge each design on four separate axes:

1. Correctness within an explicitly named slice, including negative and boundary
   examples. Unsupported constructs are visible, never counted as passing.
2. Net maintained physical/nonblank lines and bytes, including new datatypes,
   operations, adapters, generators and configuration. Report test/evidence size
   separately. Generated code remains visible; moving complexity earns no credit.
3. Independent concepts and invariants: what semantic responsibility disappears,
   what replaces it, and what a developer must understand for a representative edit.
4. Cost: checked build, request execution, memory and emitted output size where
   meaningful. Small component timing is not a whole-compiler speed claim.

A successful slice justifies another experiment. Promotion requires a complete
replacement contract, appropriate broader gates, independent review and an
explicit integration decision. The ordinary compiler remains the comparison
control during this investigation.

## Eight candidate architectures

### A01 — Successful checking produces executable checked terms

The checker returns rebuilt children, instantiated definitions and compact
backend facts. Erasure/emission consumes those results instead of reconstructing
them. Current `check_lam_done` and `check_ctr_found` return original terms;
upstream retains checked children and checked template instances. Specialization
and annotation total 1,304 lines, but memoization, recursion, dependent types,
book chronology and ABI adapters remain necessary.

Tentative successful-design target: 250–600 net lines, not earned credit.
Capabilities: one authoritative successful result, fewer whole-tree passes,
clearer template semantics and a stable input contract for additional backends.
This changes ownership; it is not the generic type cache rejected by P6-007.

First trial: preserve checked output for lambdas, applications, constructors and
dependent telescopes; emit through an existing backend without its annotation
pass. Include erased arguments and dependent examples. Then explicitly probe
template instantiation and declaration/fill visibility. If the first slice cannot
materialize templates, report that boundary and replacement cost; do not claim
the specialization pass is retired. Reject a broad design that needs annotation
replay or an equally large second checker indefinitely.

### A02 — A first-order semantic value machine

Use immutable syntax with explicit `Closure{body, environment}`, neutrals and
shared thunks. Application extends an environment; conversion compares semantic
values; quotation reconstructs syntax only when needed. One machine could own
weak evaluation, strong forms, template evaluation and dependent conversion.
Normalizer plus graph reducer total 985 lines, with other substitution machinery
elsewhere. A plausible initial net target is 0–500 lines; growth is possible.

Pinned Bend functions are not `Data`, so literal reusable HOAS closures are not
a valid direct port. Use first-order data. Preserve under-application, opaque
heads, parallel-let scope, quantity rules, reduction demand and sharing. NbE
does not automatically provide memoization, stack safety or Bend's conversion.

First trial: Var/Lam/All/App/Let, inert/opaque references and constructor data,
evaluation, quotation and a precisely scoped conversion operation. Compare
existing APIs; include unused arguments and repeated demands. Unsupported
match/rewrite/global unfolding behavior must remain explicit. Reject growth
without a corresponding retired mechanism, evaluation-order mismatches, or
readback that expands sharing pathologically.

Primary precedent: [smalltt semantic elaboration](https://github.com/AndrasKovacs/smalltt#basics).

### A03 — One description of binding scope

Describe which children see old or extended scopes, then use one explicit-stack
traversal for multiple operations. Existing generic child lists are insufficient:
the proposed abstraction owns binding scope, allocation order and stack safety.
Freshening, elaboration and specialization currently encode these independently.

Tentative target: 100–400 net lines, highly uncertain. A new constructor should
require fewer independently maintained binder rules. The first pilot uses
All/Lam/parallel Let/ordinary children and two real operations, preferably
freshening and substitution or specialization's ID transformation. Count common
engine, descriptors, mode handlers, reconstruction and adapters. Substitution's
beta canonicalization must remain; a plain generic map is not equivalent.

Reject if two operations plus the engine exceed their old implementation without
retiring a meaningful invariant, if routine constructs need escape hatches, or if
stack safety and demand order require retaining bespoke traversals.

Primary precedents: [scope-safe syntax universe](https://arxiv.org/abs/2001.11001),
[Free Foil](https://arxiv.org/abs/2405.16384).

### A04 — Stable semantic identities and separate source occurrences

Use owner/local identities for binders and template instances; preserve identities
when loading modules. Store source occurrence information separately from shared
semantic terms. This may remove global freshening, simplify provenance, and enable
per-definition incremental queries. The freshening pair contains 257 lines;
identity allocation and public U32 adapters must be charged. The narrow identity
target is 100–300 net lines; a complete query engine could increase size.

First future trial: colliding local IDs in two modules, shadowing, parallel lets,
two template instances and exact diagnostics. Versioning does not replace ordered
law/fill visibility. Cache keys require complete semantic dependencies, not just
term identity. Prior provenance overhead is a counterexample to free metadata.

Precedents: [Unison code identity](https://www.unison-lang.org/docs/the-big-idea/),
[rust-analyzer syntax views](https://rust-analyzer.github.io/book/contributing/syntax.html).

### A05 — Staged declarative grammar

Represent grammar, precedence, token expectations and source positions in compact
rules, specializing them to ordinary Bend parser code. Shared parser continuations
and error propagation could disappear. The grammar actions, staging machinery and
generated code count. Hundreds of authored lines may be addressable, but net
savings are unbudgeted. No source-language syntax change is proposed.

First future trial: indentation plus quantity prefixes and an error-sensitive
construct. Arithmetic alone is inadequate. Preserve commit/choice policy and
first-error order. Reject if actions merely hide the old parser or the generated
parser regresses behavior/cost.

Precedent: [Staged Selective Parser Combinators](https://mpickering.github.io/papers/parsley-icfp.pdf).

### A06 — One executable representation for both backends

Lower checked output once to values, calls, constructor fields, branches and
non-escaping join points. JS and native interpret that small representation with
explicit ABI/scheduler differences. Existing native segments contain C strings;
they cannot be reused unchanged. JS retains erased ABI slots while native erases
fields. Foreign bridges, scheduling and runtime targets remain.

Tentative target: 300–800 net lines, with substantial growth risk. The payoff is
shared semantic lowering and implementing optimizations once. First future trial:
returned closure, non-escaping helper, match, erased field, tail call and parallel
boundary; actually execute JS/native outputs. Annotation savings overlap A01.

Precedent: [selective continuations](https://www.cs.purdue.edu/homes/rompf/papers/cong-icfp19.pdf).

### A07 — Exact support / co-de-Bruijn terms

Each term records only variables it uses, with scope embeddings. Unused scope
extension and unaffected substitution can skip traversal. This may unify parts
of free-variable, closure-capture and dependency handling. Current unique IDs
already avoid ordinary de Bruijn shifting, so benefits are not automatic.

No net line target: initially neutral or larger is plausible. Quantity accounting
requires more than variable sets. Current `subst` beta-canonicalizes applications
even if its variable is absent; simply returning the original term is wrong.
First future trial: absent substitution over a closed redex, sparse telescopes,
deep closed data, and support-maintenance cost. Compare against A03, not add its
savings. Precedent: [Everybody's Got To Be Somewhere](https://arxiv.org/abs/1807.04085).

### A08 — Derive compilation from executable semantics

One interpreter either evaluates or constructs residual code. Specializing known
syntax/environments should eliminate runtime AST dispatch and lookup. It counts
as simplification only if it retires independently authored emission traversals.
Adding Code values while retaining both emitters is additional machinery.

Net gain unknown; broad success might remove thousands of lines, but no funded
budget supports that claim. Pinned Bend lacks staging operators, and all staging,
closure fallback, recursion control, effects and target interfaces count. Do not
restrict Bend to a first-order runtime language to inherit a research guarantee.

First future trial: the same small evaluator executes and generates both JS/C,
including recursion/sharing, with no runtime AST interpreter in generated code.
This is partly an alternative to A02/A06, not additive savings.

Precedents: [Collapsing Towers of Interpreters](https://namin.seas.harvard.edu/pubs/popl-collapsing-towers.pdf),
[staging with dependent types](https://andraskovacs.github.io/pdfs/2ltt.pdf).

## Execution and evidence protocol

1. Commit and push this prospective design and hypothesis records before source
   experiments. Capture release verification and exact baseline identities.
2. A01, A02 and A03 may be prepared independently in owned evidence directories.
   Root schedules compiler builds and all measurements serially. Begin with a
   60–90 minute implementation feasibility slice per mechanism; this is a review
   checkpoint, not permission to mislabel incomplete work as a result.
3. Full compiler edits use an isolated copied project and the maintained checked
   B1 workflow. New standalone research modules may use `stage0-library.mjs`,
   which actually checks the complete assembled Bend component before emission;
   label these as checked stage0 components, not self-hosted compiler releases.
4. Use real old Bend APIs as differential controls, plus hand-derived expected
   outcomes and adversarial examples. Check exported shapes, metadata, quantities,
   alpha identity, error/forcing order and executable output where applicable.
5. Freeze candidates before timing. Use fresh workers and serial ABBA order, CPU0,
   explicit warmups/repetitions and time/resource limits. Preserve all samples.
   Microbenchmarks establish only the named operation/workload. If a candidate
   already fails its correctness/simplification gate, performance is optional
   diagnostic evidence, not a promotion route.
6. Independently challenge each result. Preserve failed compilation attempts,
   counterexamples, sources, commands, input hashes and actual reports. A static
   idea or unexecuted harness is not an implemented experiment.
7. Write a comparative implementation report, update hypothesis records and
   steering, then commit/push the research checkpoint. Select the next experiment
   by verified benefit, total replacement cost, remaining semantic gap and time
   to a decisive test. Do not promote an incomplete prototype to the default.

Raw runs live under `selfhost/build/phase7/architecture/`; durable sources,
controls, reports and retained evidence live under
`implementation/phase7/architecture-evidence/`. One hypothesis file per candidate
lives in `experiments/phase7/`. Root owns integration, git and publication.
