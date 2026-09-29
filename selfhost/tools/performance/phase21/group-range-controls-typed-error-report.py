#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parents[4]
def load(p):return json.loads(Path(p).read_text())
def identity(p):
 p=Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
a=root/'selfhost/build/phase21/group-range-controls-baseline-04'
b=root/'selfhost/build/phase21/group-range-controls-candidate-07'
i=root/'selfhost/build/phase21/group-range-controls-inputs-04'
ra=load(a/'report.json');rb=load(b/'report.json');assert all(r['complete'] and r['pass'] for r in [ra,rb])
pa=load(a/'selected/paired.json');pb=load(b/'selected/paired.json');assert len(pa['rows'])==len(pb['rows'])==4
old={r['id']+'@'+r['lane']:r for r in pa['rows']}
for r in pb['rows']:
 x=old[r['id']+'@'+r['lane']];assert r['reference']==x['reference'];assert r['candidate']==x['candidate']
 assert r['referenceVerdict']==r['candidateVerdict']=='pass'
 assert r['candidate']['status']=='error' and r['candidate']['phase']=='parse' and r['candidate']['checked'] is False
for r in [ra,rb]:
 for rec in r['inputs']:assert identity(rec['file'])['sha256']==rec['sha256'],rec['file']
inputs=[identity(__file__)]+[identity(p) for p in [a/'report.json',b/'report.json',a/'selected/paired.json',b/'selected/paired.json',i/'plan.json',i/'selection.json']+sorted((i/'fixtures').glob('*.bend'))]
r={'kind':'phase21-group-range-typed-rhs-error-boundary','complete':True,'pass':True,'candidateApiSha256':rb['api']['sha256'],'observations':4,'parentExact':2,'candidateExact':2,'lostExact':0,'newExact':0,'fullCandidateProtocolUnchanged':True,'scope':'Additional typed RHS syntax-error/EOF parser refusal checks; no host source-range error. Original parent syntax diagnostic mismatch retained.','remainingStrict':[x['id'] for x in pb['rows'] if not x['exactAgreement']],'inputs':inputs}
p=root/'implementation/phase21/group-range-controls-typed-error.json';assert not p.exists();p.write_text(json.dumps(r,indent=2)+'\n');print(json.dumps({k:r[k] for k in ['complete','pass','candidateApiSha256','observations','candidateExact','fullCandidateProtocolUnchanged']}))
