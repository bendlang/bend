#!/usr/bin/env python3
"""Freeze the complete local-array row comparison after semantic gates."""
from pathlib import Path
import hashlib,json,shutil,sys
source,controls,counts,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=Path(p).resolve();raw=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
for p in [controls,counts]:
 d=json.loads(p.read_text());assert d['complete'] and d['pass']
d=json.loads((source/'derive.json').read_text());assert d['complete']
points=json.loads((source/'points.json').read_text());point=next(p for p in points if p['args']==[32,17])
inputs=[ident(p)for p in [Path(__file__),source/'derive.json',source/'points.json',controls,counts]]
modules={k:v['file']for k,v in d['variants'].items()}
for p in modules.values():inputs.append(ident(p))
plan={'kind':'phase30-closed-owned-row-prospective-timing','complete':True,'inputs':inputs,
 'scope':'Same checked scalar-input source and complete128-slot four-array state, including local allocation/gen/init and serialization. One row at n32 seed17. No instrumented/sentinel modules. Private variants retain public descriptors and generic fallback; separate compiler production proof required.',
 'cases':[{'id':'closed-owned-row32','point':point,'modules':modules}]}
save(out/'plan.json',plan);shutil.copyfile(Path(__file__),out/'consumed-plan.py')
for protocol in ['screen','confirm']:save(out/(protocol+'.json'),{'protocol':protocol,'inputs':[ident(out/'plan.json'),*inputs],'cases':plan['cases']})
print(json.dumps({'complete':True,'out':str(out)}))
