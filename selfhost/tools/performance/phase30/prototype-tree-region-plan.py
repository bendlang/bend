#!/usr/bin/env python3
"""Freeze whole-program and bounded scalar-tree comparisons after correctness."""
from pathlib import Path
import hashlib, json, shutil, sys
ROOT=Path(__file__).resolve().parents[4]
source,controls,counts,out=map(lambda x:Path(x).resolve(),sys.argv[1:])
out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=Path(p).resolve();raw=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
c=json.loads(controls.read_text());assert c['pass'] and c['complete']
assert json.loads(counts.read_text())['pass']
inputs=[ident(p)for p in [Path(__file__),source/'derive.json',controls,counts]]
expected=next(x['expected']for x in c['oracle']if x.get('depth')==5 and x['index']==0 and x['total']=={'$bigint':'7'} and x['colors']==[1,3,7,17,31,63,127,255])
marker='export default Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));'
wrapper='''const $tree30Exports=Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));
export default {...$tree30Exports,treeBench:(depth,index)=>$tree30Exports.rcol(BigInt(depth),index,7n,1,3,7,17,31,63,127,255)};'''
whole,trees={},{}
for variant in ['baseline','public_leaf','private_leaf']:
 p=source/(variant+'.mjs');inputs.append(ident(p));text=p.read_text();assert text.count(marker)==1
 target=out/(variant+'-tree.mjs');target.write_text(text.replace(marker,wrapper));whole[variant]=str(p);trees[variant]=str(target)
upstream=ROOT/'selfhost/build/phase28/runtime-01/mandelbrot/upstream.mjs';inputs.append(ident(upstream));whole['typescript']=str(upstream)
plan={'kind':'phase30-scalar-tree-prospective-timing','complete':True,'inputs':inputs,
 'scope':'Checked attempt10 baseline versus private iterative scalar tree/public leaf versus complete private closure. Original bench unchanged; identical host tree wrapper converts depth to BigInt and supplies seven inner iterations and a fixed scalar palette. No instrumented outputs timed.',
 'wrappers':[ident(p)for p in trees.values()],
 'cases':[{'id':'original-mandelbrot-small','point':{'args':[2,0],'expected':887240761},'modules':whole},
          {'id':'scalar-tree-depth5','point':{'exportName':'treeBench','args':[5,0],'expected':expected},'modules':trees}]}
shutil.copyfile(Path(__file__),out/'consumed-plan.py');save(out/'plan.json',plan)
for protocol in ['screen','confirm']:save(out/(protocol+'.json'),{'protocol':protocol,'inputs':[ident(out/'plan.json'),*inputs],'cases':plan['cases']})
print(json.dumps({'complete':True,'out':str(out),'expected':expected}))
