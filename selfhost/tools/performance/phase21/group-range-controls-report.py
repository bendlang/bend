#!/usr/bin/env python3
"""Freeze the independent R1 outcome without rewriting any consumed report."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[4]
def identity(file):
 p=Path(file).resolve();b=p.read_bytes()
 return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
def read(p): return json.loads(Path(p).read_text())
inputs=[identity(__file__)]
freeze=root/'implementation/phase21/group-range-controls-baseline.json'
basefreeze=read(freeze);inputs.append(identity(freeze))
for rec in basefreeze['inputs']:
 actual=identity(rec['file']);assert actual['sha256']==rec['sha256'],rec['file']
inputs.extend(basefreeze['inputs'])
cohorts=[];apis=set()
for n in (1,2,3):
 a=root/f'selfhost/build/phase21/group-range-controls-baseline-0{n}'
 b=root/f'selfhost/build/phase21/group-range-controls-candidate-0{n}'
 report=read(b/'report.json');assert report['complete'] and report['pass']
 before=read(a/'selected/paired.json');after=read(b/'selected/paired.json')
 apis.add(report['api']['sha256'])
 assert not report['comparison']['lostExact'] and not report['comparison']['changedCandidatePrimitive']
 for rec in report['inputs']:
  assert identity(rec['file'])['sha256']==rec['sha256'],rec['file']
 for f in [b/'report.json',b/'selected/paired.json',b/'selected/reference.json',b/'selected/candidate.json']:
  inputs.append(identity(f))
 cohorts.append(dict(number=n,observations=len(after['rows']),beforeExact=sum(r['exactAgreement'] for r in before['rows']),afterExact=sum(r['exactAgreement'] for r in after['rows']),gainedExact=report['comparison']['gainedExact'],lostExact=[],changedCandidatePrimitive=[],remainingStrict=[r['id'] for r in after['rows'] if not r['exactAgreement']],remainingPrimitive=[r['id'] for r in after['rows'] if not r['semanticAgreement']],rawSelectedComplete=after['selectedComplete'],referenceOracleFailures=report['selected']['referenceOracleFailures']))
assert len(apis)==1
out=root/'implementation/phase21/group-range-controls.json';assert not out.exists()
result=dict(kind='phase21-group-range-independent-controls',complete=True,pass=True,scope='68 real parse/check observations across three independently frozen cohorts; original complete diagnostic protocols, fixture oracles, failed assumptions and parent/reference differences retained. No AST normalization, backend or timing claim.',candidateApiSha256=next(iter(apis)),parentApiSha256=basefreeze['parentApi'],cpu=2,heapMb=4096,stackKb=4096,observations=sum(c['observations'] for c in cohorts),beforeExact=sum(c['beforeExact'] for c in cohorts),afterExact=sum(c['afterExact'] for c in cohorts),gainedExact=sum(len(c['gainedExact']) for c in cohorts),lostExact=0,changedCandidatePrimitive=0,cohorts=cohorts,inputs=inputs,limitations=basefreeze['limitations'])
out.write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:result[k] for k in ['complete','pass','candidateApiSha256','observations','beforeExact','afterExact','gainedExact','lostExact','changedCandidatePrimitive']}))
