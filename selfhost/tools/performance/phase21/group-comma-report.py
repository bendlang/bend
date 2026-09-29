#!/usr/bin/env python3
"""Close diagnostic-only C1 evidence without changing a source or oracle."""
from pathlib import Path
import hashlib,json,collections
R=Path(__file__).resolve().parents[4];P=R/'selfhost/build/phase21';O=R/'implementation/phase21';O.mkdir(exist_ok=True)
def read(p):return json.loads(p.read_text())
def identity(p):return {'file':str(p.relative_to(R)),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
control=read(P/'group-comma-controls-01/manifest.json')
for r in control['inputs']:
 p=Path(r['file']);assert p.stat().st_size==r['bytes'] and hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256'],r['file']
run=read(P/'group-comma-baseline-01/report.json');paired=read(P/'group-comma-baseline-01/selected/paired.json')
assert run['complete'] and run['healthPass'] and run['pass'] is False
assert len(paired['rows'])==60 and not paired['missing']
for p in run['phases']:
 q=p['execution'];assert q['signal'] is None and q['error'] is None and not q['timedOut'] and not q['overflow']
assert run['phases'][0]['execution']['exitCode']==0 and run['phases'][1]['execution']['exitCode']==1
statuses={}
for side in ['reference','candidate']:
 d=read(P/('group-comma-baseline-01/selected/'+side+'.json'))
 assert len(d['results'])==60 and all(not w['errors'] and not w['stats']['timeouts'] and not w['stats']['failures'] for w in d['workers'])
 assert all(r['status'] not in ['crash','timeout','unsupported'] and r.get('result',{}).get('status') not in ['crash','timeout','unsupported'] for r in d['results'])
 statuses[side]=dict(collections.Counter(r['status'] for r in d['results']))
assert statuses=={'reference':{'pass':60},'candidate':{'pass':53,'fail':7}}
assert paired['referenceSelectedComplete'] is True and paired['candidateSelectedComplete'] is False
rows=paired['rows'];exact=sum(r['exactAgreement'] for r in rows);primitive=sum(not r['semanticAgreement'] for r in rows)
assert exact==39 and primitive==7
groups={}
for name,prefix in [('newNeighbors','group-comma/'),('savedComma','group/'),('savedStage','rejected-stage/')]:
 selected=[r for r in rows if r['id'].startswith(prefix)]
 groups[name]={'observations':len(selected),'exact':sum(r['exactAgreement'] for r in selected),'primitiveDifferences':sum(not r['semanticAgreement'] for r in selected)}
record={(r['id'],r['lane']):r for r in rows}
for name in ['invalid-type-pattern-comma','invalid-constructor-pattern-comma','completed-local-tuple','completed-nested-local-tuple','completed-typed-local-tuple','rhs-before-pattern-comma','completed-tuple-reaches-later-syntax','match-later-row-syntax-before-flatten']:
 assert all(record[('group-comma/'+name,l)]['exactAgreement'] for l in ['parse','check'])
assert record[('group-comma/completed-parallel-tuple','check')]['reference']['status']=='ok'
assert record[('group-comma/completed-parallel-tuple','check')]['candidate']['status']=='error'
assert '<Parallel:>' in record[('group-comma/completed-parallel-tuple','check')]['candidate']['diagnostic']
assert record[('group-comma/raw-parallel-comma','check')]['candidate']['phase']=='check'
assert record[('group-comma/raw-parallel-comma','check')]['candidate']['typeAccepted'] is False

text='''# C1: group-comma controls on the installed Phase20 compiler

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
'''
md=O/'group-comma.md'
with md.open('x') as f:f.write(text)
inputs=[Path(__file__),R/'design/phase21/group-comma-controls.md',R/'selfhost/tools/performance/phase21/group-comma-prepare.py',P/'group-comma-controls-01/manifest.json',P/'group-comma-baseline-01/report.json',P/'group-comma-baseline-01/selected/paired.json',P/'group-comma-baseline-01/selected/reference.json',P/'group-comma-baseline-01/selected/candidate.json',md]
report={'kind':'phase21-group-comma-diagnostic-investigation','complete':True,'collectionHealthPass':True,'referenceOraclePass':True,
 'candidateRawPass':False,'candidateApiSha256':control['candidateApiSha256'],'upstream':control['upstream'],
 'observations':60,'exact':exact,'differences':60-exact,'primitiveDifferences':primitive,'diagnosticOnlyDifferences':60-exact-primitive,
 'statuses':statuses,'groups':groups,'inputsUnchanged':True,'fixtureCorrections':0,'compilerSourceChanged':False,'compilerBuildRun':False,
 'jobsClosed':True,'cpu':'3','timingClaim':False,'commitsOrPushesByOwner':False,
 'parallelIsolatedPromotionBlocked':True,'parallelBlocker':'Without C1 eligibility correction the shared lowering branch would likely turn existing raw-parallel-comma checker refusal into false checked acceptance; prediction only.',
 'rows':rows,'inputs':[identity(p)for p in inputs],
 'ownedTrackedFiles':['design/phase21/group-comma-controls.md','selfhost/tools/performance/phase21/group-comma-prepare.py','selfhost/tools/performance/phase21/group-comma-report.py','implementation/phase21/group-comma.md','implementation/phase21/group-comma.json'],
 'ownedClosedRoots':['selfhost/build/phase21/group-comma-controls-01','selfhost/build/phase21/group-comma-baseline-01']}
with (O/'group-comma.json').open('x') as f:json.dump(report,f,indent=2);f.write('\n')
print(json.dumps({'complete':True,'health':True,'referenceOraclePass':True,'candidateRawPass':False,'observations':60,'exact':39,'differences':21,'primitive':7,'report':str(O/'group-comma.json')}))
