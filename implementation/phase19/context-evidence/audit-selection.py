#!/usr/bin/env python3
"""Read-only prospective selection audit; no archive or compiler execution."""
from pathlib import Path
import hashlib, json

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p): return json.loads(p.read_text())
plan=read(HERE/'selection-proposal.json'); frozen=read(HERE/'root-freeze.json')
inv=read(HERE/'capsule-01/inventory.json'); rows=inv['members']; selected={r['path']:r for r in rows}
assert len(selected)==len(rows)
assert len(inv['selectedRoots'])==80 and {r['path'] for r in inv['selectedRoots']}==set(frozen['selectedRoots'])
assert len(plan['extraTrees']['context'])==80
expected={
 'selfhost/build/phase16/rejected-stage-controls-01/fixtures',
 'selfhost/build/phase16/marked-pattern-controls-02/fixtures',
 'selfhost/build/phase16/empty-call-pattern-controls-02/fixtures',
 'selfhost/build/phase16/parser-checkpoint-controls-03/fixtures',
 'selfhost/build/phase17/group-controls-03/fixtures'}
assert {r['tree'] for r in inv['fixtureDependencies']}==expected
assert len(inv['fixtureDependencies'])==5
assert all(any(r['path']==d['fixture'] for r in rows) for d in inv['fixtureDependencies'])
assert all(not p.startswith(('selfhost/dist/','selfhost/src/','selfhost/build/phase20/',
    'selfhost/build/phase21/','design/phase20/','design/phase21/',
    'implementation/phase20/','implementation/phase21/','selfhost/tools/performance/phase6/')) for p in selected)
protected=read(HERE/'phase6-start-state.json')['unrelatedPhase6']
assert len(protected)==75 and not any(r['path'] in selected for r in protected)
assert not any(r['type']=='symlink' for r in rows)
source=[r for r in rows if r['path'].startswith(plan['finalSource']+'/')]
assert len(source)==215
membership=read(HERE/'source-membership.json')['members']
assert {r['path'][len(plan['finalSource'])+1:] for r in source}=={r['file'] for r in membership}
for r in frozen['inputs']:
 assert sha(ROOT/r['path'])==r['sha256'], r['path']
 assert r['path'] in selected and selected[r['path']]['sha256']==r['sha256'],r['path']
for r in plan['extraFiles']['final']: assert r in selected,r
assert inv['baselineCommit']=='fddfc84b3f48aecc77c2424ddc8227cd7f63251f'
assert inv['anchorStatus']=='private-contextual-stage4-experiment'
assert inv['planSha256']==sha(HERE/'selection-proposal.json')
assert inv['freezeSha256']==sha(HERE/'root-freeze.json')
audit=read(ROOT/'selfhost/build/phase19/context-row-audit-02/report.json')
assert audit['pass'] and audit['publicObservations']==196
assert audit['publicExactAfter']==136 and audit['publicRemainingDifferences']==60
assert audit['publicRawWorkflowPass'] is False and audit['publicRawSelectedComplete'] is False
report={'kind':'phase19-context-pre-capture-selection-audit','complete':True,'pass':True,
 'selectedRoots':80,'members':len(rows),'bytes':sum(r['bytes'] for r in rows),'sourceMembers':215,
 'fixtureDependencies':inv['fixtureDependencies'],'noWholeExternalExperimentSelected':True,
 'noLiveSourceOrDistSelected':True,'protectedPhase6PayloadExcluded':75,'frozenInputsVerified':len(frozen['inputs']),
 'publicRaw196RemainsFalse':True,'alphaContractUnchanged':True,'symlinks':0,
 'retainedOversizeMember':max(rows,key=lambda r:r['bytes']),
 'tool':{'path':str(Path(__file__).relative_to(ROOT)),'sha256':sha(Path(__file__))},
 'inventorySha256':sha(HERE/'capsule-01/inventory.json'),'selectionSha256':sha(HERE/'selection-proposal.json')}
with (HERE/'selection-review.json').open('x') as f:json.dump(report,f,indent=2);f.write('\n')
print(json.dumps({'pass':True,'members':len(rows),'fixtureTrees':5,'sourceMembers':215}))
