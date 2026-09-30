#!/usr/bin/env python3
"""Validate completed gates and freeze, but do not execute, general-Let timings."""
from pathlib import Path
import hashlib,json,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];BUILD=ROOT/'selfhost/build/phase30'
out=Path(sys.argv[1]).resolve();out.mkdir(exist_ok=False)
def ident(p):
 p=Path(p).resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
inputs=[ident(Path(__file__))]
for suffix in ['synthetic','scalar','entry','tree','ordinary','owned','deferred']:
 p=BUILD/f'review-tail-let-{suffix}-01/report.json';r=json.loads(p.read_text());assert r['complete'] and r['pass'];inputs.append(ident(p))
for name in ['mandel','row','editdist']:
 p=BUILD/f'review-tail-let-{name}-01/derive.json';r=json.loads(p.read_text());assert r['complete'];inputs.extend([ident(p),*r['inputs'],*r['outputs'].values()])
control=BUILD/'review-tail-let-controls-plan-01/plan.json';r=json.loads(control.read_text());inputs.extend([ident(control),*r['inputs'],*r['outputs']])
points=json.loads((BUILD/'prototype-owned-01/points.json').read_text());point=next(x for x in points if x['args']==[32,17])
cases=[{'id':'general-tail-let-owned-row32','point':point,'modules':{s:str(BUILD/'review-tail-let-controls-plan-01/row'/(s+'.mjs')) for s in ['baseline','candidate']}},
 {'id':'general-tail-let-mandelbrot','point':{'args':[2,0],'expected':887240761},'modules':{s:str(BUILD/'review-tail-let-mandel-01'/(s+'.mjs')) for s in ['baseline','candidate']}}]
for c in cases:inputs.extend(ident(p) for p in c['modules'].values())
for row in inputs:assert ident(row['file'])==row
plan={'complete':True,'scope':'Disposable general tail-Let rewrite of actual13 generated output. Runtime unchanged; identical owned-row JSON export adapter on both sides. No compiler edit or timing execution.',
 'inputs':inputs,'cases':cases,'launchers':{'screen':'selfhost/tools/performance/phase30/time.py','confirm':'selfhost/tools/performance/phase30/time.py','long_warmup':'selfhost/build/phase30/tree-compiler-plan-12/long-warmup-time.py'}}
save(out/'plan.json',plan)
for protocol in ['screen','confirm','long_warmup']:
 save(out/(protocol+'.json'),{'protocol':protocol,'inputs':[ident(out/'plan.json'),*inputs],'cases':cases})
save(out/'original-editdist-point.json',{'args':[2,0],'expected':2065873279})
print(json.dumps({'complete':True,'out':str(out)}))
