#!/usr/bin/env python3
"""Checked baseline emissions only; no comparative runtime timing."""
from pathlib import Path
import hashlib,json,os,subprocess,sys,time
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
NODE=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
source=HERE/'fixture-mandelbrot.bend'; points=HERE/'fixture-points.json'
attempt=ROOT/'selfhost/build/phase27/attempt-02'
def identity(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
report={'kind':'phase29-prototype-acquisition','complete':False,'cpu':6,'scope':'Untimed correctness and descriptive acquisition; no speed claims.','inputs':[identity(p) for p in [Path(__file__),HERE/'prototype-check.mjs',source,points,attempt/'attempt.json',HERE.parent/'phase25/emit.mjs',HERE.parent/'phase26/emit.mjs',NODE]],'variants':{}}
def save(): (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
def run(args,label,timeout):
    command=['taskset','-c','6',str(NODE),'--stack-size=4096','--max-old-space-size=1024',*map(str,args)]
    row={'command':command,'timeoutSeconds':timeout};begin=time.monotonic()
    env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
    with (out/(label+'.stdout')).open('w') as stdout,(out/(label+'.stderr')).open('w') as stderr:
        try:row['exitCode']=subprocess.run(command,stdout=stdout,stderr=stderr,env=env,timeout=timeout).returncode
        except subprocess.TimeoutExpired:row['timeout']=True
    row['acquisitionSeconds']=time.monotonic()-begin
    row['stdout']=identity(out/(label+'.stdout'));row['stderr']=identity(out/(label+'.stderr'))
    lines=(out/(label+'.stdout')).read_text().splitlines()
    if lines:
        try:row['observation']=json.loads(lines[-1])
        except json.JSONDecodeError:pass
    row['complete']=row.get('exitCode')==0 and row.get('observation',{}).get('complete',False)
    return row
save()
for variant in ['upstream','unchanged']:
    module=out/(variant+'.mjs')
    args=[HERE.parent/'phase25/emit.mjs','upstream',source,module] if variant=='upstream' else [HERE.parent/'phase26/emit.mjs',attempt,source,module]
    row={'emission':run(args,variant+'-emit',120)};report['variants'][variant]=row;save()
    if row['emission']['complete']:row['check']=run([HERE/'prototype-check.mjs',module,points],variant+'-check',60)
    save()
for p in report['inputs']:assert identity(Path(p['file']))==p,p['file']
report['complete']=all(v['emission']['complete'] and v.get('check',{}).get('complete',False) for v in report['variants'].values());save()
if not report['complete']:sys.exit(1)
