#!/usr/bin/env python3
"""Freeze five actual/reference ablations after the six focused gates pass."""
from pathlib import Path
import hashlib,json,shutil,sys
ROOT=Path(__file__).resolve().parents[4];RAW=ROOT/'selfhost/build/phase32'
cohort,gates,out=map(lambda x:Path(x).resolve(),sys.argv[1:])
out.mkdir(parents=True,exist_ok=False)
def ident(p):
    p=Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
d=json.loads((cohort/'derive.json').read_text());assert d['complete']
inputs=[ident(__file__),ident(cohort/'derive.json'),ident(gates/'report.json'),
        ident(ROOT/'design/phase32/local-generated-ladder.md'),ident(ROOT/'design/phase32/local-record-vectors.md')]
for x in d['inputs']:
    assert ident(x['file'])['sha256']==x['sha256'];inputs.append(ident(x['file']))
g=json.loads((gates/'report.json').read_text());assert g['complete']
assert {c['name'] for c in g['cases']}=={'pair','fold','order','scope','vectors','types'}
for c in g['cases']:
    p=Path(c['report']['file']);r=json.loads(p.read_text());assert r['complete'] and r['pass'];inputs.append(ident(p))
    for x in r['inputs']:
        assert ident(x['file'])['sha256']==x['sha256'];inputs.append(ident(x['file']))
cases=[]
for name,point in [('pair',dict(args=[0],expected=1866542166)),('fold',dict(args=[4096,17],expected=2339999928))]:
    variants=d['cases'][name]['variants'];assert list(variants)==['baseline','statements','read_fusion','record_vectors','typescript']
    for x in variants.values():assert ident(x['file'])==x;inputs.append(x)
    cases.append(dict(id='local-'+name,point=point,modules={k:x['file'] for k,x in variants.items()}))
inputs=list({x['file']:x for x in inputs}.values())
plan=dict(complete=True,inputs=inputs,cases=cases,
    scope='Same checked sources. Phase31-07 baseline, checked01 statements, checked02 typed read fusion, checked03 record vectors, pinned upstream TypeScript output. No instrumented timing.',
    criterion='At least5% disjoint improvement on an affected case; no greater than3% disjoint regression on another. Inspect drift and report all ablations. Confirm with five fresh rotating samples,100calls AND3seconds warmup,300ms target. Then unchanged original-program transfer/canaries/compiler costs before release.')
save(out/'plan.json',plan)
for mode in ['screen','confirm']:save(out/(mode+'.json'),dict(protocol=mode,inputs=[ident(out/'plan.json'),*inputs],cases=cases))
shutil.copyfile(__file__,out/'consumed-plan.py')
