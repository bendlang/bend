#!/usr/bin/env python3
"""Freeze the promotion rule and validated launchers before first timing."""
from pathlib import Path
import hashlib,json,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];BUILD=ROOT/'selfhost/build/phase30'
out=Path(sys.argv[1]).resolve();out.mkdir(exist_ok=False)
def ident(p):
 p=Path(p).resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
old=BUILD/'review-tail-let-timing-plan-01';plan=json.loads((old/'plan.json').read_text())
for row in plan['inputs']:assert ident(row['file'])==row
check=old/'editdist-check.stdout';assert json.loads(check.read_text())['complete']
inputs=plan['inputs']+[ident(p) for p in [Path(__file__),old/'plan.json',check,ROOT/'design/phase30/general-tail-let-promotion.md',HERE/'prototype-time.py',BUILD/'tree-compiler-plan-12/long-warmup-time.py']]
plan.update(inputs=inputs,launchers={'screen':str(HERE/'prototype-time.py'),'confirm':str(HERE/'prototype-time.py'),'long_warmup':str(BUILD/'tree-compiler-plan-12/long-warmup-time.py')},
 preparationCorrection='The first unexecuted plan recorded a nonexistent generic time.py launcher; this fresh plan binds the maintained prototype-time.py launcher before timing.')
save(out/'plan.json',plan)
for protocol in ['screen','confirm','long_warmup']:
 save(out/(protocol+'.json'),{'protocol':protocol,'inputs':[ident(out/'plan.json'),*inputs],'cases':plan['cases']})
print(json.dumps({'complete':True,'out':str(out)}))
