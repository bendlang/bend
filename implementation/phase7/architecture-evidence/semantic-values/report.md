# P7-A02: first-order semantic values

Decision: **reject this prototype as a general replacement**. Explicit closures
successfully avoid repeated body substitution on one selected workload, but the
shared heap is substantially slower on closed data, uses more memory, adds code,
and retains a confirmed conversion-demand regression. No production module,
default API, conformance expectation or compiler release was changed.

The [prospective design](../../../../design/phase7/architectural_experiments.md)
was committed as `4b2e4c7` before implementation. This is an isolated, genuinely
checked stage0 component experiment, not a B1 build, self-hosting proof, or a
proof that semantic evaluation cannot benefit the compiler.

## Implemented mechanism and scope

[semantic-values.bend](semantic-values.bend) implements first-order closures as
syntax plus an environment; neutrals carry argument-cell spines. A persistent
binary heap memoizes delayed arguments and constructor fields. Application
extends an environment rather than substituting through a lambda body.
Quotation reconstructs first-order syntax. Conversion handles alpha/eta,
dependent All binders, opaque references, quantities and structural children.

The entry predicates admit Var/Lam/All/App/simultaneous Let/Ann and inert
Ref/Ctr/ADT/Typ/Qnt/Qua/Eql/Rfl forms with specified arities. References always
remain opaque: the book is empty. Matches, rewrite, quantity meet, residual ADT
metadata, definition unfolding, recursive globals and kind subtyping are absent.
`sv_observe_head` returns a head observation, not a complete materialized `wnf`
replacement. Its unquoted body and environment are not a public weak-normal-form
contract. The existing core's globally distinct binder-ID invariant is required;
`sv_supported` checks syntax/arity/ranges but does not prove global uniqueness,
well-typedness, termination or resource validity. Input IDs must be below 2^31.

This avoids function-valued fields, respecting Bend's distinction between
reusable Data and affine functions. Existing KTerm construction/accessors,
maximum-ID traversal and exact structural comparison remain dependencies.
The implementation still uses recursive quotation and conversion; selected deep
cases passing under a 4 MiB Node stack do not establish general stack safety.

## Attempts, corrections and counterexamples

Every attempt below remains immutable under
`selfhost/build/phase7/architecture/`; the phase's evidence archive preserves
those directories. No failed artifact was installed.

| Attempt | Observation |
| --- | --- |
| semantic-values-01 | Prepared only; superseded before compilation to add actual upstream revision/source identities, before/after verification, canonical Base and CPU0 affinity. |
| semantic-values-02 | Checked build and initial 49/49 controls pass. This gate checked semantic equality but missed quotation display names and conversion demand boundaries. |
| semantic-values-03 | Checked build; 72/82 controls pass. Ten stronger metadata comparisons expose bound-variable names becoming `_` instead of the original binder name. |
| semantic-values-04 | Checked build; 73/90 controls pass. Adds a two-second timeout from comparing neutral arguments in reverse order, plus six malformed-shape guard failures. |
| semantic-values-05 | Corrects names, argument order and arities; checked build and 90/90 controls pass. This is the measured normalization candidate. |
| semantic-values-demand-05 | Independent review finds five more two-second conversion timeouts: reflexivity, wrapped reflexivity, nested reflexivity and two arity mismatches. Earlier omega syntax reuses a binder ID, so these alone do not establish the stipulated invariant. |
| semantic-values-demand-05-unique | Repeats the five failures with distinct binders in omega's two lambdas. All old probes finish; all five candidate probes time out. 95/100 controls pass. |
| semantic-values-06 | Adds top-level exact comparison, exact suspended-cell/environment comparisons and arity checks before forcing. Checked build and 100/100 then-current controls pass. |
| semantic-values-07 | Same compiler source/API as 06; fresh checked build and 100/100 strengthened controls pass, including distinct-binder witnesses and distinct IDs in repeated identity terms. |
| semantic-values-residual-07 | One further supported-input demand regression is confirmed; a second proposed counterexample times out in both implementations and is inconclusive. No further fixes were made. |

The final [selected controls](controls-final.json) cover alpha/eta conversion,
dependent telescopes, variable capture, textual shadowing, neutral spine order,
quantity metadata, simultaneous-let scope, opaque references, malformed syntax,
unused divergent arguments, repeated demands and input immutability. Quotation
metadata is compared after explicit alpha-renumbering; this is not byte equality.
Additional 100-, 1,000- and 5,000-deep constructor quotation probes finish under
the recorded 4 MiB stack, outside the claimed general stack-safety contract.

The [final residual probe](residual-07.json) matters more than the selected pass
count. Let omega be `(lambda x1. x1(x1))(lambda x2. x2(x2))`, with distinct IDs.
For `All(x, omega, A)` versus `All(y, omega, B)`, both prototype inputs report
supported and satisfy the distinct-ID check. Existing Bend conversion recognizes
the identical domain without evaluating it and returns false; the prototype
evaluates the domains and hits the two-second deadline. **The supported raw-term
conversion domain is therefore not preserved.** These are demand probes, not
claims that omega is an accepted well-typed Bend program.

For `All(x, A, omega)` versus `All(y, A, omega)`, both implementations time out.
The proposed difference was not established: the existing codomain-opening
substitution beta-canonicalizes the body before comparison. That negative result
is retained rather than counted as a second regression.

## Directional cost screen

[Eight fresh workers](performance-05.json) ran serially on CPU0 in two ABBA
blocks. Each imported the same checked candidate05 component, warmed each
operation ten times, then measured three batches. The closed-data batch contains
100 requests; the beta-chain batch contains 50. The boundary includes the whole
public `strong(emptyBook,input)` versus `sv_observe(input).term`, including the
prototype's supported-syntax scan, maximum-ID setup and observation counters.
Imports, fixture construction and the old Bend definitional-equality oracle are
outside timing. Input hashes agree across all workers; inputs remain unchanged.

| Workload | Existing median | Candidate05 median | Candidate / existing |
| --- | ---: | ---: | ---: |
| Closed Pack with 128 Pair fields | 2.405 ms | 8.214 ms | 3.415x |
| 64 applied lambda binders, returning first/last arguments | 3.421 ms | 1.823 ms | 0.533x |

The second workload is a synthetic substitution-heavy term; despite the raw
worker label mentioning “dependent environment”, it is not a dependent-type
checker benchmark. The new machine takes 46.7% less time there, approximately
1.88x faster. Closed data takes 3.4x as long. Median worker maximum RSS is
104,436 KiB versus 203,768 KiB, approximately 1.95x. RSS includes imports, control
comparisons and both workloads; it is not per-request retained memory.

This is a **directional screen**, with warming trends visible in the samples.
Ten warmups and three batches do not establish steady-state statistical certainty.
These measurements belong to candidate05 and are not relabeled as final07
measurements. Later changes concern conversion, while this benchmark measures
normalization; the original source/API identities and timings remain attached to
05. No whole-compiler speed, TypeScript ratio, developer-loop improvement or
emitted user-program performance is inferred.

Memoization itself has a direct counter check. For 1/2/4/8/32/128 demands of a
24-beta-step delayed argument, evaluator steps are 77/78/80/84/108/204, and cache
hits are 0/1/3/7/31/127. Additional demands perform one variable lookup without
reevaluating the delayed computation. Shared constructor-field controls pass too.
This preserves an important existing mechanism; the current graph reducer
already shares these demands, so this is not a newly discovered speedup.

## Source and conceptual cost

[The census](counts.json), reproducible with [census.py](census.py), records:

- 547 new research Bend lines, 454 nonblank lines, 19,316 bytes;
- 69 definitions, 12 forward laws and 12 datatypes;
- 23 retained existing helper definitions, five associated forward laws and
  KTerm, totaling 194 physical / 192 nonblank lines and 4,015 bytes when counted
  as declaration blocks without trailing separators;
- zero production lines added or deleted; the production compiler remains
  14,667 physical lines;
- test, launch, benchmark, witness and census programs counted separately in
  `counts.json`; reports, frozen snapshots and generated evidence are additional.

The old normalizer and graph reducer total 985 lines, but **985 minus 547 is not
a net saving**. The new module leaves major semantics out, retains 194 helper
lines, and has not replaced a production responsibility. The repository grows
by the research module and its validation tools. Future integration must pay
for the omitted behavior, state transport, public adapters and deep traversal.

The prototype introduces explicit value/closure, environment, cell, memo-heap and
quotation contracts. Its state/result records mostly express first-order plumbing;
12 datatype declarations do not mean 12 independent language concepts. It reduces
substitution in its evaluation path but does not yet retire the production
substitution, weak reducer, graph reducer or conversion algorithms. The exact
demand shortcuts and their residual All gap show that a small textbook evaluator
does not automatically subsume the existing operational contract.

## Recommended next decision

Keep the supported compiler unchanged. The useful positive result is narrower:
**environment-based application can accelerate substitution-heavy work**. If
further research is chosen, first measure whether real dependent telescope
checking spends enough time in that mechanism, then test semantic closures only
there, or a hybrid that leaves closed data on the existing cheap path. Such a
hybrid must earn an actual deletion budget; keeping both whole evaluators would
increase complexity. The current experiment does not justify a broad rewrite.

Final checked component API: 96,298 bytes, SHA256
`a4be15a4d9fe3586aa061291b31426e47470e3f82545558d0bab44b9cc52ca43`.
Measured candidate05 API: 93,862 bytes, SHA256
`49654e6628f9bacc3d56bb7de43512da4e791e9939650731ca9bb77126294869`.
These are selected old-plus-new research APIs, not replacement compiler sizes.

## Reproduce in a fresh directory

With the pinned upstream checkout and Node24.18.0 described in the shared
[evidence guide](../README.md), run from the repository root:

```sh
node implementation/phase7/architecture-evidence/semantic-values/run.mjs prepare NEW_ATTEMPT
node implementation/phase7/architecture-evidence/semantic-values/run.mjs build NEW_ATTEMPT
node implementation/phase7/architecture-evidence/semantic-values/run.mjs test NEW_ATTEMPT
python3 implementation/phase7/architecture-evidence/semantic-values/census.py
```

This rebuilds final07's source and selected 100-control suite; it does not erase
the separately recorded residual failure. The census rewrites its own counts
file. After restoring the verified archive, the residual witness is available
under `raw/semantic-values-residual-07/residual-witness.mjs`; run its old/new
`all-domain` and `all-body` modes in separate two-second child processes as
recorded in `residual-07.json`.

The benchmark tool supports a new measurement against a checked attempt:

```sh
node implementation/phase7/architecture-evidence/semantic-values/benchmark.mjs prepare CHECKED_ATTEMPT NEW_BENCHMARK
node implementation/phase7/architecture-evidence/semantic-values/benchmark.mjs run CHECKED_ATTEMPT NEW_BENCHMARK
```

Using final07 would create a new experiment. To repeat the historical05
normalization screen, use restored `raw/semantic-values-05` as CHECKED_ATTEMPT;
the archive preserves its actual checked API, sources and passing historical
build/test records. Keep later residual findings attached to the overall idea
even when the earlier normalization fixture passes.
