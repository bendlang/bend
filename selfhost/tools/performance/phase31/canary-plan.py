#!/usr/bin/env python3
"""Freeze existing scalar and complete generic-row canaries; no timing."""
from pathlib import Path
import importlib.util,hashlib,json,sys
ROOT=Path(__file__).resolve().parents[4]
scalar,row,out=map(lambda x:Path(x).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
inputs=[ident(Path(__file__))]
for p in [scalar,row]:
 r=json.loads(Path(str(p)+'.json').read_text());assert r['complete'] and r['observation']['checked'];assert ident(p)['sha256']==r['output']['sha256'];inputs += [ident(p),ident(str(p)+'.json')]
parser=ROOT/'selfhost/tools/performance/phase30/prototype-owned-derive.py';spec=importlib.util.spec_from_file_location('rowwrap',parser);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
wrapped=out/'generic-row.mjs';wrapped.write_text(m.wrap(row.read_text(),False));inputs += [ident(parser),ident(wrapped)]
prior=ROOT/'selfhost/build/phase30/scalar-scaling-plan-17/confirm.json';config=json.loads(prior.read_text());inputs.append(ident(prior))
cases=[]
for c in config['cases']:
 if c['id'] in ['scalar-region-0','scalar-region-8192']:
  cases.append(dict(id=c['id'],point=c['point'],modules=dict(baseline17=c['modules']['candidate'],candidate=str(scalar),typescript=c['modules']['typescript'])))
prior=ROOT/'selfhost/build/phase31/local-data-plan-01/screen.json';c=json.loads(prior.read_text())['cases'][0];inputs.append(ident(prior))
cases.append(dict(id='complete-generic-row32',point=c['point'],modules=dict(baseline17=c['modules']['baseline'],candidate=str(wrapped),typescript=c['modules']['typescript'])))
for c in cases:
 for p in c['modules'].values():inputs.append(ident(p))
plan=dict(kind='phase31-unmodified-canary-points',complete=True,inputs=inputs,cases=cases,scope='Original scalar0/8192 and complete generic one-row observations, same input sources and checks. Candidate private pair measurements are separate. Three fresh rotating samples screen; prescribed five-sample confirmation follows material regression or uncertainty.')
save(out/'plan.json',plan)
for protocol in ['screen','confirm']:save(out/(protocol+'.json'),dict(protocol=protocol,inputs=[ident(out/'plan.json'),*inputs],cases=cases))
(out/'consumed-plan.py').write_bytes(Path(__file__).read_bytes());print(json.dumps(dict(complete=True,out=str(out))))
