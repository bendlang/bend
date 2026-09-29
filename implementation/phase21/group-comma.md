# C1: group-comma controls on the installed Phase20 compiler

The controls confirm that a simple raw-tag comma guard is unsafe. A completed
inner local can be a valid tuple component, and currently correct earlier
pattern errors must remain earlier than a comma error. No compiler source was
changed or built for this investigation.

All 60 observations were collected successfully on CPU3 against Phase20
`import-diagnostic-build-04`, API `40c8f7f3`, and pinned TypeScript `b2111cf`.
All 60 pinned acceptance/rejection oracles passed; no fixture correction was
needed. The candidate raw suite is **false**, with 53 passing and 7 failed
verdicts. Exact agreement is 39/60: 21 differences, of which 7 change primitive
status/phase/checking outcomes and 14 change only diagnostic text/location.
The selected child exits 1 as expected; the launcher exits 0 while reporting
`pass:false`. Neither is relabeled as compiler conformance success. There were
no worker failures, timeouts, missing rows, signals or output overflows.

| Scope | Observations | Exact | Primitive differences |
| --- | ---: | ---: | ---: |
| 21 new independent neighbors | 42 | 31 | 5 |
| Original `group/body-comma` | 2 | 0 | 2 |
| Eight original stage-order fixtures | 16 | 8 | 0 |
| Total | 60 | 39 | 7 |

The decisive outcomes are:

| Case | Pinned TypeScript | Installed Bend |
| --- | --- | --- |
| `(x = {0n : Nat}; x, 1n)` | Rejects comma during parse | Parses and checks successfully: wrong acceptance |
| `((x = {0n : Nat}; x), 1n)` | Parses/checks successfully | Exact acceptance; extra nested groups also agree |
| `(Type = 0n; 0n, 1n)` | Rejects `Type` as a pattern | Exact earlier-pattern rejection |
| `(Succ{} = 0n; 0n, 1n)` | Rejects constructor-pattern arity | Exact earlier-arity rejection |
| `(Type = return 0n; 0n, 1n)` | Earlier RHS `return` error | Exact RHS-first rejection |
| `(Type = 0n; return 0n, 1n)` | Earlier pattern error | Later `return` error: wrong order |
| `(x = {0n : Nat}; x, return 0n)` | Rejects comma before later tuple syntax | Reports later `return`: wrong order |
| `((x = {0n : Nat}; x), return 0n)` | Admits tuple branch, then rejects `return` | Exact rejection |

Typed-local raw/completed tuple neighbors confirm the same eligibility
distinction. Grouped global/parameter Match heads currently produce their
semantic errors before comma; the equivalent completed nested Match also
agrees. A later row syntax error precedes group flattening, as required.
However, `group-comma/match-pattern-before-comma` loses its earlier invalid row
pattern to the head's flatten error. The saved grouped/ungrouped rows retain
four failing fixture pairs: body-before-later-pattern,
group-before-later-syntax, prior-local-pattern-before-later-syntax and
prior-row-pattern-before-body-syntax. All exact raw diagnostics remain in the
paired report; this investigation did not change their expectations.

## Parallel dispatch is a separate finding, not a safe isolated promotion

`group-comma/completed-parallel-tuple` is accepted by the pin. Bend accepts its
parse but rejects checking with observed `<Parallel:>`. Source inspection
identifies a small dispatch omission: `f_scope_base` sends Local/Match to
`f_flat(f_scope_body(t, env, book), Nil{})`, but a term-position Parallel falls
through generic child scoping and keeps its raw tag. `f_scope_body` already
owns `f_scope_parallel`, and `f_flat` already owns `f_flat_parallel`.
Adding Parallel to that existing branch would reuse those owners without
another traversal or a duplicate pattern validator.

That addition alone is nevertheless **blocked for promotion**. The same run
shows `group-comma/raw-parallel-comma` wrongly parses successfully today but
still fails checking. Routing this raw Parallel through lowering would likely
turn that existing checker refusal into a false checked acceptance. This is a
source-derived prediction, not an executed candidate result. A difference count
alone would conceal the increased severity because both outcomes already differ
from the pin's parse rejection. Completion/eligibility must be correct first,
or be corrected in the same reviewed candidate.

Any later Parallel dispatch experiment needs both written raw/completed forms,
all C1 ordering controls, and additional neighbors: outer parameters used by
RHS values; simultaneous RHS visibility before either binder opens; shadowing
and duplicate spellings; quantities/underscore; closure capture and restoration;
constructor patterns refused in names-only positions; earlier RHS/pattern and
later body/row errors; nested locals/parallel groups in calls, annotations and
tuples; and a no-raw-Parallel escape check on successful lowered terms. Preserve
exact binder/use identity, source ranges and error order. These controls are a
proposal only and were not run in this bounded task.

The narrow architectural requirement established here is a real group-completion
distinction plus first-error ownership. The production raw parser leaves a
completed inner Local tagged Local, so tag-only eligibility loses valid nesting.
An immediate comma Error would discard the body whose Type/Succ error currently
wins correctly. Preserve that boundary and run existing semantic owners at the
proper checkpoint; do not infer it from offsets, validate with an empty lexical
environment or add a second pattern checker. No completion/failure transport
implementation is selected or authorized by this report.

Evidence is under `selfhost/build/phase21/`: `group-comma-controls-01` freezes
the 30 fixture identities, selection, prospective designs, API and pin;
`group-comma-baseline-01/report.json` records collection health and exact artifact
identities; its `selected/{paired,reference,candidate}.json` retain all outcomes,
worker metadata and the copied harness. The unchanged Phase18 paired runner is
copied as the consumed launcher. The corresponding JSON report binds these files.

All owner jobs are closed. No source mutation, build, timing claim, commit or
push occurred. CPU3 is released. The source/fixture/API inputs still match their
pre-run hashes. R1's independent source-range experiment remains separate.
