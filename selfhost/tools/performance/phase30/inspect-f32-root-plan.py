#!/usr/bin/env python3
"""Freeze cheap paired leaf plans only after full F32 and original-value gates."""
from pathlib import Path
import hashlib,json,sys
ROOT=Path(__file__).resolve().parents[4]
RAW=ROOT/'selfhost/build/phase30'
BASE=RAW/'inspection-f32-root-01'
REPORTS=[RAW/(name+'/report.json') for name in
 ['inspection-f32-root-controls-01','inspection-f32-root-original-01','inspection-f32-root-counts-01']]
def identity(p):
 raw=p.read_bytes();return {'file':str(p.resolve()),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
for file in REPORTS:
 report=json.loads(file.read_text());assert report['complete'] and report['pass']
 for item in report['inputs']:assert identity(Path(item['file']))['sha256']==item['sha256']
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
inputs=[identity(p) for p in [Path(__file__),*REPORTS]]
for protocol in ['screen','confirm']:
 source=BASE/(protocol+'.json');cfg=json.loads(source.read_text())
 for item in cfg['inputs']:assert identity(Path(item['file']))['sha256']==item['sha256']
 cfg['inputs'] += [identity(source),*inputs]
 (out/(protocol+'.json')).write_text(json.dumps(cfg,indent=2)+'\n')
(out/'consumed-plan.py').write_bytes(Path(__file__).read_bytes())
(out/'plan.json').write_text(json.dumps({'complete':True,'inputs':inputs,'measurement':'not run',
 'originalCorrectnessPoint':{'args':[80,0],'expected':402971},
 'originalTiming':'Not queued: the maintained transfer warmup/sample floor would repeat a roughly14-second call many times. Budget a separate full-program protocol only if the leaf experiment survives.'},indent=2)+'\n')
print(json.dumps({'complete':True,'out':str(out)}))
