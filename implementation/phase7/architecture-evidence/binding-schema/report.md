# P7-A03 — Shared binding traversal is rejected in this form

The checked prototype preserves all 965 named control observations, but its
optimistic replacement is **22 physical lines / 15 nonblank lines / 510 bytes
larger**. On the corrected, fixed-arity microbenchmark it is 18.6–22.6% slower
for freshening and 81.2–81.7% slower for template identifier shifting. It is not
promoted. This rejects this runtime traversal design, not every possible binding
schema or generated specialization.

## What was implemented

[binding-schema.bend](binding-schema.bend) replaces the explicit freshener's six
frame variants with one worklist frame. A small scope classifier specifies
ordinary children, a lambda body, a dependent codomain, or parallel-let bindings
with outer RHS scope and extended body scope. One engine executes lexical
freshening or the existing specialization operation that shifts Var/All/Lam/Bind/
Sub identifiers. This second operation is real compiler work, but it does not
exercise substitution or its beta-rebuilding contract.

The design is a hard-coded runtime scope plan, not a generic syntax generator.
It still needs operation dispatch, shape codes, and a Bind/Absent frame marker.
These replace typed variants with more possible invalid state combinations.
The scope/allocation obligations remain. The new engine makes deep identifier
shifting stack-safe, which is an additional capability, but freshening already
had that property.

## Correctness and review

The complete compiler modules plus the research module were actually checked by
the unchanged pinned stage0 builder before four roots were emitted. This is a
checked component, not a B1 release or self-hosting proof. API SHA256:
`dde1f0d1d79aa6783a684a758c5979bf8019a478f1549858dbf82f4995bda77e`.

The first gate passed 805 observations. Independent review requested input
immutability controls; the second gate adds 160, for 965 passes. The two gates
are successive suites, not 1,770 distinct observations. They cover 160 explicit/
deterministically generated trees, freshening with and without an environment,
three shift offsets including U32 wraparound, malformed shape/metadata behavior,
an independently expected simultaneous-let result, 50,000 constructor depth,
12,000 shadowing binders, 15,000 parallel binders, and deep shift readback.
Both the old and new fresheners run the deep/broad cases. Deep shifting has an
independent expected result; no baseline stack-overflow claim is inferred.

The unchanged old Bend functions are compiled alongside the candidate as
comparators. A separate agent reviewed the source and found no mismatch in the
covered modes: All/Lam metadata/extra-child dropping matches the old freshener,
Var payloads stay untouched when freshening, shifts retain fields/metadata, and
let RHSs cannot see sibling bindings. This is scoped evidence, not a proof over
all raw terms or a whole-frontend compatibility run.

## Source and concepts

[counts.json](counts.json) and the two retained old source pools make the budget
reviewable. Old term freshening costs 124 physical / 119 nonblank lines; old
template shifts cost 20 / 17. Candidate costs 166 / 151. All comments/blanks and
bytes are reported; there is no formatting-derived saving. Existing FFresh,
f_rename_var, the definition-list worklist, public caller and core helpers remain.
Any extra compatibility adapter would worsen this optimistic budget.

One traversal loop is shared, but neither operation nor its scoping rules is
retired. The mode/shape/sentinel contracts are new reasoning obligations. This
does not meet the requirement to decrease both code and conceptual complexity.

## Controlled cost and a retained unsuitable first workload

[measure.mjs](measure.mjs) freezes each run and executes fresh workers in serial
A/B/B/A order per operation on CPU0. Each worker warms three requests then times
seven requests of 100 transformations. Input construction, API startup and
output hashing are outside request timing. Outputs and immutable inputs match.
RSS is each worker's process high-water mark, not total simultaneous memory.

The first workload accidentally gave All three children. The raw-API results
still matched, but that workload is unsuitable for a well-formed compiler-term
claim. Its measurements remain in `binding-measure-01` and are superseded for
that purpose, not discarded. The source/API were unchanged; only the frozen
workload generator was corrected. The second workload has valid constructor
arities but is synthetic raw syntax, not a type-checked Bend program.

| Operation | B/A time, first order | B/A time, reverse order | Paired RSS |
| --- | ---: | ---: | ---: |
| Freshening | 1.1864 | 1.2264 | 0.9798 / 1.0127 |
| Template ID shifting | 1.8121 | 1.8167 | 1.0735 / 1.0130 |

These are operation microbenchmarks, not compiler throughput or a TypeScript
comparison. No compiler job was intentionally run alongside these samples.
Other agents performed small code/documentation preparation.

## Reproduction and preservation

From the repository root with Node24.18.0, use new output paths:

```sh
node implementation/phase7/architecture-evidence/build-component.mjs NEW_BUILD implementation/phase7/architecture-evidence/binding-schema/binding-schema.bend a3_fresh a3_shift f_fresh_term sp_shift
taskset -c 0 node --stack-size=4096 --max-old-space-size=4096 implementation/phase7/architecture-evidence/binding-schema/controls.mjs NEW_BUILD/api.mjs NEW_CONTROLS.json
node implementation/phase7/architecture-evidence/binding-schema/measure.mjs run NEW_BUILD/api.mjs NEW_MEASUREMENT
```

Raw directory: `selfhost/build/phase7/architecture/`. The architecture report's
verified shared capsule preserves `binding-build-01`, both controls (including
the original harness), both frozen measurement generators and all eight workers
per measurement. Current prototype/control/measurement source is tracked here.

Decision: reject this implementation for integration. A future binding experiment
must first show that specialization of the scope description removes runtime
dispatch and that a third genuinely different operation amortizes its source
cost. It cannot inherit success from this negative result.
