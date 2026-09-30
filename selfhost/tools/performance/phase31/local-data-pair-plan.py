#!/usr/bin/env python3
"""Freeze one complete pair under the unchanged original-program protocol."""
from pathlib import Path
import hashlib,json,shutil,sys
source,controls,counts,review,out=map(lambda x:Path(x).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=p.resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
for p in [controls,counts,review]:
 d=json.loads(p.read_text());assert d['complete'] and d['pass'],str(p)
d=json.loads((source/'derive.json').read_text());assert d['complete']
modules={k:v['file']for k,v in d['variants'].items()};assert list(modules) in [['baseline','private_full','private_setup','private_dp','actual','typescript'],['baseline','previous','actual','typescript']]
for k,p in modules.items():assert ident(Path(p))==d['variants'][k]
inputs=[ident(p)for p in [Path(__file__),source/'derive.json',source/'points.json',controls,counts,review,*map(Path,modules.values())]]
point=next(p for p in json.loads((source/'points.json').read_text())if p['args']==[0]);assert point['expected']==1866542166
case=dict(id='full-editdist-pair0',point=point,modules=modules)
plan=dict(kind='phase31-full-pair-prospective-timing',complete=True,inputs=inputs,cases=[case],scope='Unchanged 256x256 canonical pair0 including all allocation/generation/init, DP and checksum; standard prototypes. Generic17, recorded earlier prototypes or previous checked compiler, actual checked compiler and pinned TypeScript; exact roles are named in modules. Diagnostic modules excluded.',criteria='All outputs and >=20% lower median time than generic17 with disjoint sample ranges for actual/compiler feasibility; separate increments and remaining TypeScript gap are reported.',protocolReason='Use maintained transfer:5 fresh samples,at least3 warm calls AND1 second,300ms timed target,serial rotating CPU3. Unlike confirm100calls,this remains bounded for the half-second generic pair. No fullpair timing preceded this choice.')
save(out/'plan.json',plan);save(out/'transfer.json',dict(protocol='transfer',inputs=[ident(out/'plan.json'),*inputs],cases=[case]));shutil.copyfile(Path(__file__),out/'consumed-plan.py');print(json.dumps(dict(complete=True,out=str(out))))
