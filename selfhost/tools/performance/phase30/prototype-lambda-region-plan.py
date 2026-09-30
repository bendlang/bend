#!/usr/bin/env python3
"""Freeze ordinary-root original-program and scalar-leaf comparisons."""
from pathlib import Path
import hashlib, json, shutil, sys
ROOT=Path(__file__).resolve().parents[4]
source,controls,counts,out=map(lambda x:Path(x).resolve(),sys.argv[1:])
out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=Path(p).resolve();raw=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
checked=json.loads(controls.read_text());assert checked['pass'] and checked['complete']
assert json.loads(counts.read_text())['pass']
inputs=[ident(p)for p in [Path(__file__),source/'derive.json',controls,counts]]
shutil.copyfile(Path(__file__),out/'consumed-plan.py')
palette=[1,3,7,17,31,63,127,255]
expected=next(x['expected']for x in checked['oracle']if x['name']=='rpix' and x['index']==4095 and x['total']=={'$bigint':'7'} and x['colors']==palette)
marker='export default Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));'
wrapper='''const $lambdaRegionExports=Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));
export default {...$lambdaRegionExports,rpixBench:(iterations,index)=>$lambdaRegionExports.rpix(index,BigInt(iterations),1,3,7,17,31,63,127,255)};'''
whole,leaf={},{}
for variant in ['baseline','pix','rpix','both']:
 p=source/(variant+'.mjs');inputs.append(ident(p));text=p.read_text();assert text.count(marker)==1
 target=out/(variant+'-leaf.mjs');target.write_text(text.replace(marker,wrapper));whole[variant]=str(p);leaf[variant]=str(target)
upstream=ROOT/'selfhost/build/phase28/runtime-01/mandelbrot/upstream.mjs';inputs.append(ident(upstream));whole['typescript']=str(upstream)
plan={'kind':'phase30-ordinary-root-prospective-timing','complete':True,'inputs':inputs,
 'scope':'Four generated-JavaScript variants on checked lexical-only attempt08. Original bench unchanged; identical scalar-leaf host wrapper converts iteration count to BigInt and supplies a fixed eight-scalar palette. No diagnostic modules timed.',
 'wrappers':[ident(p)for p in leaf.values()],
 'cases':[{'id':'original-mandelbrot-small','point':{'args':[2,0],'expected':887240761},'modules':whole},
          {'id':'ordinary-rpix-leaf','point':{'exportName':'rpixBench','args':[7,4095],'expected':expected},'modules':leaf}]}
save(out/'plan.json',plan)
for protocol in ['screen','confirm']:save(out/(protocol+'.json'),{'protocol':protocol,'inputs':[ident(out/'plan.json'),*inputs],'cases':plan['cases']})
print(json.dumps({'complete':True,'out':str(out),'expected':expected}))
