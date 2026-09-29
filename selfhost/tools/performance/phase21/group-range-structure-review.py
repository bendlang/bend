"""Close source01 structural evidence without approving changed origins."""
from pathlib import Path
from collections import Counter
import json,hashlib
R=Path(__file__).resolve().parents[4]
B=R/'selfhost/build/phase21/group-range-structure-candidate-01'
P=R/'selfhost/build/phase21/group-range-structure-parent-01'
O=R/'implementation/phase21/group-range-structure-source01.json';assert not O.exists()
r=json.loads((B/'report.json').read_text());assert r['complete'] and r['pass'] and r['count']==102
identity=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
tags=Counter(d['tag'] for x in r['rows'] for d in x['differences']['ranges'])
findings=[]
for name in ['typed-ann','typed-outer-pattern','callee','outer-pattern','constructor-plain','constructor-group','constructor-group-pattern','typed-constructor']:
 ref=json.loads((P/f'{name}-reference.json').read_text())
 findings.append({'name':name,'reference':ref,'rows':[x for x in r['rows']if x['name']==name and x['mode'].endswith('indexed')]})
result={'kind':'phase21-independent-r1-source01-structure-review','complete':True,'structuralContractPass':True,'selectionApproved':False,
 'observations':102,'changedRows':sum(bool(x['differences']['ranges'])for x in r['rows']),
 'changedRangePaths':sum(tags.values()),'rangeTags':dict(tags),'nonrangeDifferences':0,'acceptanceChanges':0,
 'changedDiagnostics':sum(not x['diagnosticSame']for x in r['rows']),
 'legacyObservations':sum('legacy'in x['mode']for x in r['rows']),'legacyAllAbsent':all(x.get('legacyOriginsAbsent',True)for x in r['rows']),
 'scope':'23 no-Base fixtures at four raw/lowered indexed/legacy entries, Base raw/lowered, four representative Base fixtures raw/lowered. Full books compared in memory; full-field stream digests include all ranges. No complete compiler-workload graph claim.',
 'blockingFinding':'Grouped typed Ann loses its existing whole-group origin to0/0. Pinned Ann has an explicit binder-through-RHS cursor span. Repair its sole producer before selection; no annotation range should be guessed from child term range.',
 'nonblockingFindings':['Call/App start changes from opening parenthesis to local binder, matching pinned parse_term_ops use of the inner Let span.','Constructor destructuring lowered graphs are byte-identical; both flatteners explicitly retain RHS origin.','Grouped constructor destructuring under an outer parameter has inherited parent/candidate acceptance divergence from pin. Constructor group-as-pattern remains an inherited wrong checkpoint and changed caret does not close it.','251 range paths count repeated Base contents across four seeded books; they are not251 distinct source occurrences.'],
 'findings':findings,'inputs':[identity(Path(__file__)),identity(B/'report.json'),identity(P/'report.json'),identity(R/'design/phase21/group-range-structure.md'),identity(R/'selfhost/build/phase21/group-range-structure-controls-01/plan.json'),identity(R/'selfhost/tools/performance/phase21/group-range-structure-run.mjs')]}
O.write_text(json.dumps(result,indent=2)+'\n');print(O)
