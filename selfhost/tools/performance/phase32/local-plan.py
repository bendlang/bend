#!/usr/bin/env python3
"""Freeze actual statement and separate saved-output local-data ablations."""
from pathlib import Path
import hashlib,json,shutil,sys
ROOT=Path(__file__).resolve().parents[4];RAW=ROOT/'selfhost/build/phase32'
cohort,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
inputs=[ident(Path(__file__)),ident(ROOT/'design/phase32/local-generated-ladder.md'),ident(cohort/'derive.json')]
d=json.loads((cohort/'derive.json').read_text());assert d['complete']
for x in d['inputs']:assert ident(x['file'])==x;inputs.append(x)
for gate in ['local-pair-controls-actual01','local-fold-controls-actual01','local-order-controls-01','local-scope-controls-01']:
 p=RAW/gate/'report.json';r=json.loads(p.read_text());assert r['complete'] and r['pass'],gate;inputs.append(ident(p))
 for x in r['inputs']:
  now=ident(x['file']);assert now['sha256']==x['sha256'];inputs.append(now)
cases=[]
for name,point in [('pair',dict(args=[0],expected=1866542166)),('fold',dict(args=[4096,17],expected=2339999928))]:
 modules={role:x['file']for role,x in d['cases'][name]['variants'].items()}
 assert list(modules)==['baseline','statements','actual_statements','fusion','combined','typescript']
 for x in d['cases'][name]['variants'].values():assert ident(x['file'])==x;inputs.append(x)
 cases.append(dict(id='local-'+name,point=point,modules=modules))
inputs=list({x['file']:x for x in inputs}.values())
plan=dict(kind='phase32-local-data-prospective-comparison',complete=True,inputs=inputs,cases=cases,
 scope='Installed07 output, statement-only derivative, actual checked statement compiler01, fusion-only derivative, combined derivative, pinned TypeScript. All generated input programs and checks unchanged. No instrumented modules.',
 criterion='At least5% less time and disjoint ranges on one case; no greater than3% disjoint slowdown on the other. Overlap/neutral outcomes retained. Statement complexity may independently justify a neutral result.',
 protocol='Existing shortscreen, then5fresh rotating CPU3 samples with>=100warmcalls AND3seconds warmup,300ms target. Root grants exclusive windows; inspect half drift.')
save(out/'plan.json',plan)
for protocol in ['screen','confirm']:save(out/(protocol+'.json'),dict(protocol=protocol,inputs=[ident(out/'plan.json'),*inputs],cases=cases))
shutil.copyfile(Path(__file__),out/'consumed-plan.py');print(json.dumps(dict(complete=True,out=str(out),inputs=len(inputs))))
