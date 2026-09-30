#!/usr/bin/env python3
"""Gate isolated frame-reuse timing on complete value/order/allocation controls."""
from pathlib import Path
import hashlib,json,sys
source,controls,boundaries,counts,out=map(lambda x:Path(x).resolve(),sys.argv[1:])
out.mkdir(parents=True,exist_ok=False)
def identity(p):
 p=Path(p).resolve();raw=p.read_bytes()
 return {'file':str(p),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
inputs=[identity(p)for p in [Path(__file__),source/'derive.json',controls,boundaries,counts]]
data=json.loads(controls.read_text())
assert data['complete'] and data['pass']
for p in [boundaries,counts]:
 check=json.loads(p.read_text());assert check['complete'] and check['pass']
expected=next(x['expected']for x in data['oracle']if x.get('depth')==5 and x['index']==0 and x['total']=={'$bigint':'7'} and x['colors']==[1,3,7,17,31,63,127,255])
marker='export default Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));'
wrapper='const $frameReviewExports=Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));\nexport default {...$frameReviewExports,treeBench:(depth,index)=>$frameReviewExports.rcol(BigInt(depth),index,7n,1,3,7,17,31,63,127,255)};'
whole,trees={},{}
for variant in ['baseline','reuse']:
 p=source/(variant+'.mjs');inputs.append(identity(p));text=p.read_text();assert text.count(marker)==1
 target=out/(variant+'-tree.mjs');target.write_text(text.replace(marker,wrapper))
 whole[variant]=str(p);trees[variant]=str(target)
plan={'kind':'phase30-frame-reuse-gated-timing','complete':True,'inputs':inputs,
 'scope':'Only private frame backing storage lifetime changes. Identical original and depth5 entry points, standard Array intrinsics; diagnostic copies excluded.',
 'wrappers':[identity(p)for p in trees.values()],
 'cases':[{'id':'frame-reuse-original','point':{'args':[2,0],'expected':887240761},'modules':whole},
          {'id':'frame-reuse-depth5','point':{'exportName':'treeBench','args':[5,0],'expected':expected},'modules':trees}]}
(out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n')
(out/'consumed-plan.py').write_bytes(Path(__file__).read_bytes())
for protocol in ['screen','confirm']:
 (out/(protocol+'.json')).write_text(json.dumps({'protocol':protocol,'inputs':[identity(out/'plan.json'),*inputs],'cases':plan['cases']},indent=2)+'\n')
for p in inputs:assert identity(p['file'])==p
print(json.dumps({'complete':True,'out':str(out),'depth5Expected':expected}))
