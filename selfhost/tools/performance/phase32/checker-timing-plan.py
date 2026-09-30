#!/usr/bin/env python3
import argparse,hashlib,json,shutil
from pathlib import Path
ap=argparse.ArgumentParser();ap.add_argument('derive');ap.add_argument('controls');ap.add_argument('out');ap.add_argument('--confirm',action='store_true');ap.add_argument('--cpu',type=int,default=3);args=ap.parse_args()
out=Path(args.out).resolve();out.mkdir(parents=True,exist_ok=False)
def identity(p):
 p=Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
d=json.loads(Path(args.derive).read_text());c=json.loads(Path(args.controls).read_text());assert d['complete'] and d['pass'] and c['complete'] and c['pass']
root=Path.cwd();tool=root/'selfhost/tools/performance/phase32';node=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
for name in ['checker-timing-worker.mjs','checker-fixtures.mjs']:
 shutil.copyfile(tool/name,out/name)
inputs=[identity(p) for p in [args.derive,args.controls,__file__,out/'checker-timing-worker.mjs',out/'checker-fixtures.mjs',tool/'checker-timing-run.py',root/'design/phase32/checker-direct-calls.md',node]]
inputs.extend(d['variants'].values())
plan=dict(kind='phase32-checker-helper-timing-plan',complete=True,executed=False,variants=d['variants'],inputs=inputs,cpu=args.cpu,campaignTimeoutSeconds=90 if not args.confirm else 180,node=str(node),nodeArgs=['--stack-size=4096','--max-old-space-size=2048'],warmMs=1000 if args.confirm else 300,targetMs=200 if args.confirm else 100,samples=5 if args.confirm else 3,order=[['baseline','direct'],['direct','baseline'],['baseline','direct']] if args.confirm else [['baseline','direct'],['direct','baseline']],workloads=['cached','uncached','infer_ref'],worker=str(out/'checker-timing-worker.mjs'),scope='Complete private immutable helper batches; construction/import/checking outside sample; per-role calibration; all samples and half drift retained. No ordinary compiler request or production speed claim.')
(out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n')
shutil.copyfile(__file__,out/'consumed-plan.py');print(out/'plan.json')
