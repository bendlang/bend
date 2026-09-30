#!/usr/bin/env python3
"""Freeze the four independent ablations with the existing consumed worker."""
import sys,json,hashlib,shutil
from pathlib import Path
root=Path.cwd();derive=Path(sys.argv[1]).resolve();controls=Path(sys.argv[2]).resolve();out=Path(sys.argv[3]).resolve();out.mkdir(parents=True,exist_ok=False)
def identity(p):
 p=Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
d=json.loads(derive.read_text());c=json.loads(controls.read_text());assert d['complete'] and d['pass'] and c['complete'] and c['pass']
assert list(d['variants'])==['baseline','direct','fields','combined']
tool=root/'selfhost/tools/performance/phase32';node=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
for name in ['checker-timing-worker.mjs','checker-fixtures.mjs','checker-timing-run.py']:shutil.copyfile(tool/name,out/name)
inputs=[identity(p) for p in [derive,controls,__file__,out/'checker-timing-worker.mjs',out/'checker-fixtures.mjs',out/'checker-timing-run.py',root/'design/phase32/checker-private-fields.md',node]]+list(d['variants'].values())
plan=dict(kind='phase32-checker-private-fields-timing-plan',complete=True,executed=False,variants=d['variants'],inputs=inputs,cpu=3,campaignTimeoutSeconds=90,node=str(node),nodeArgs=['--stack-size=4096','--max-old-space-size=2048'],warmMs=300,targetMs=100,samples=3,order=[['baseline','direct','fields','combined'],['combined','fields','direct','baseline']],workloads=['cached','uncached','infer_ref'],worker=str(out/'checker-timing-worker.mjs'),scope='Private immutable graphs only. Independent call-only, field-only, combined ablations; retains force; unchanged original public H program. Complete batches, full values checked outside intervals. No public admission or compiler request result.')
(out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n');shutil.copyfile(__file__,out/'consumed-plan.py');print(out/'plan.json')
