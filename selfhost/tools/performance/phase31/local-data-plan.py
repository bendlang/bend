#!/usr/bin/env python3
"""Freeze both local-data ablations after complete scoped semantic gates."""
from pathlib import Path
import hashlib,json,shutil,sys
source,controls,counts,review,out=map(lambda x:Path(x).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
for p in [controls,counts,review]:
 d=json.loads(p.read_text());assert d['complete'] and d['pass'],str(p)
d=json.loads((source/'derive.json').read_text());assert d['complete']
variants=['baseline','private_native','private_setup','private_dp','typescript'];modules={v:d['variants'][v]['file']for v in variants}
for v,p in modules.items():assert ident(p)==d['variants'][v]
inputs=[ident(p)for p in [Path(__file__),source/'derive.json',source/'points.json',controls,counts,review,*modules.values()]]
points=json.loads((source/'points.json').read_text())
cases=[dict(id='local-data-row'+str(n),point=next(p for p in points if p['args']==[n,17]),modules=modules)for n in [32,64]]
plan=dict(kind='phase31-local-data-prospective-timing',complete=True,inputs=inputs,cases=cases,scope='Complete allocation/setup/one row/serialization; checked17 generic and rebound native reference; independent setup and Dp-shell ablations; pinned TypeScript. Standard unmodified intrinsics. Instrumented modules excluded.',criteria='At least 20% less time and disjoint ranges against current17 private_native at n32 and confirmed n64; individual incremental ablations reported separately.')
save(out/'plan.json',plan);shutil.copyfile(Path(__file__),out/'consumed-plan.py')
for protocol in ['screen','confirm']:save(out/(protocol+'.json'),dict(protocol=protocol,inputs=[ident(out/'plan.json'),*inputs],cases=cases))
print(json.dumps(dict(complete=True,out=str(out))))
