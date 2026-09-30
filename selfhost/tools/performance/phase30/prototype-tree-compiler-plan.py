#!/usr/bin/env python3
"""Freeze actual-tree timing and a separately justified longer-warmup protocol."""
from pathlib import Path
import hashlib,json,shutil,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
source,controls,counts,out=map(lambda x:Path(x).resolve(),sys.argv[1:])
out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=Path(p).resolve();raw=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
def edit(s,old,new):
 assert s.count(old)==1,old
 return s.replace(old,new)
c=json.loads(controls.read_text());assert c['pass'] and c['complete']
assert json.loads(counts.read_text())['pass']
comparison=HERE.parent/'phase29/compare.py';launcher=HERE/'prototype-time.py'
design=ROOT/'design/phase30/scalar-tree-long-warmup.md'
inputs=[ident(p)for p in [Path(__file__),source/'derive.json',controls,counts,comparison,launcher,design]]
expected=next(x['expected']for x in c['oracle']if x.get('depth')==5 and x['index']==0 and x['total']=={'$bigint':'7'} and x['colors']==[1,3,7,17,31,63,127,255])
marker='export default Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));'
wrapper='''const $tree30Exports=Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));
export default {...$tree30Exports,treeBench:(depth,index)=>$tree30Exports.rcol(BigInt(depth),index,7n,1,3,7,17,31,63,127,255)};'''
whole,trees={},{}
for label,variant in [('ordinary11','baseline'),('tree12','candidate')]:
 p=source/(variant+'.mjs');inputs.append(ident(p))
 target=out/(label+'-tree.mjs');target.write_text(edit(p.read_text(),marker,wrapper))
 whole[label]=str(p);trees[label]=str(target)
upstream=ROOT/'selfhost/build/phase28/runtime-01/mandelbrot/upstream.mjs'
inputs.append(ident(upstream));whole['typescript']=str(upstream)
# Retain a runner whose only logic change is the prospective protocol entry.
derived=edit(comparison.read_text(),'HERE=Path(__file__).resolve().parent','HERE=Path('+repr(str(comparison.parent))+')')
derived=edit(derived,"protocol=protocols[config['protocol']]",
 "protocols['long_warmup']=dict(samples=3,warmupCalls=3,warmupMs=15000,calibrationMs=100,targetMs=1000,timeout=120)\nprotocol=protocols[config['protocol']]")
runner=out/'long-warmup-compare.py';runner.write_text(derived)
launch=launcher.read_text()
launch=launch.replace("HERE.parent/'phase29/compare.py'","HERE/'long-warmup-compare.py'")
assert launch.count("HERE/'long-warmup-compare.py'")==2
long_launcher=out/'long-warmup-time.py';long_launcher.write_text(launch)
inputs.extend([ident(runner),ident(long_launcher)])
plan={'kind':'phase30-actual-scalar-tree-prospective-timing','complete':True,'inputs':inputs,
 'scope':'Actual checked attempt11 ordinary roots versus checked attempt12 tree region. Whole original plus identical scalar-tree wrapper. Instrumented and sentinel copies excluded.',
 'wrappers':[ident(p)for p in trees.values()],
 'longWarmup':'Separate frozen 15-second warmup, 3 samples, 3-call floor, 1-second target; do not replace ordinary protocol.',
 'cases':[{'id':'actual-tree-original-mandelbrot','point':{'args':[2,0],'expected':887240761},'modules':whole},
          {'id':'actual-tree-depth5','point':{'exportName':'treeBench','args':[5,0],'expected':expected},'modules':trees}]}
shutil.copyfile(Path(__file__),out/'consumed-plan.py');shutil.copyfile(design,out/'long-warmup-design.md');save(out/'plan.json',plan)
for protocol in ['screen','confirm']:
 save(out/(protocol+'.json'),{'protocol':protocol,'inputs':[ident(out/'plan.json'),*inputs],'cases':plan['cases']})
save(out/'long-warmup.json',{'protocol':'long_warmup','inputs':[ident(out/'plan.json'),*inputs],'cases':plan['cases'][:1]})
print(json.dumps({'complete':True,'out':str(out),'expected':expected}))
