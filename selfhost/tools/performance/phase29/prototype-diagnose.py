#!/usr/bin/env python3
"""Execute counter copies only, after root grants the untimed execution window."""
from pathlib import Path
import hashlib,json,os,subprocess,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
NODE=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
directory=Path(sys.argv[1]).resolve();out=Path(sys.argv[2]).resolve()
out.mkdir(parents=True,exist_ok=False)
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
attempt=ROOT/'selfhost/build/phase27/attempt-02/attempt.json'
runtime=Path(json.loads(attempt.read_text())['runtime']['file'])
assert ident(runtime)['sha256']=='40823818afd57a6c37e055272dc332f461955a7cd225f67d66194f0d43ec823f'
config=HERE/'prototype-counter-point.json'
report={'kind':'phase29-prototype-operation-diagnostic','complete':False,'scope':'Untimed operation accounting, not timing or total allocation measurement.','runtime':ident(runtime),'attempt':ident(attempt),'tool':ident(Path(__file__)),'counterTool':ident(HERE/'prototype-count.mjs'),'points':ident(config),'variants':{}}
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
for variant in ['unchanged','arithmetic','worker','combined']:
    module=directory/(variant+'.mjs');receipt=json.loads(module.with_suffix('.json').read_text())
    original=Path(receipt['source']['file'])
    assert ident(original)==receipt['source']
    assert original.read_bytes().startswith(runtime.read_bytes())
    assert ident(module)==receipt['output']
    command=['taskset','-c','6',str(NODE),'--stack-size=4096','--max-old-space-size=1024',str(HERE/'prototype-count.mjs'),str(module),str(config)]
    row={'module':ident(module),'receipt':ident(module.with_suffix('.json')),'command':command,'timeoutSeconds':60}
    with (out/(variant+'.stdout')).open('w') as stdout,(out/(variant+'.stderr')).open('w') as stderr:
        try:row['exitCode']=subprocess.run(command,stdout=stdout,stderr=stderr,env=env,timeout=60).returncode
        except subprocess.TimeoutExpired:row['timeout']=True
    row['stdout']=ident(out/(variant+'.stdout'));row['stderr']=ident(out/(variant+'.stderr'))
    lines=(out/(variant+'.stdout')).read_text().splitlines()
    if lines:
        try:row['observation']=json.loads(lines[-1])
        except json.JSONDecodeError:pass
    row['complete']=row.get('exitCode')==0 and row.get('observation',{}).get('complete',False)
    if row['complete']:
        observations=row['observation']['observations'];assert len(observations)==10
        row['totals']={k:sum(o['counters'][k] for o in observations) for k in observations[0]['counters']}
    report['variants'][variant]=row
    (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
assert ident(runtime)==report['runtime'];assert ident(config)==report['points']
report['complete']=all(v['complete'] for v in report['variants'].values())
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
if not report['complete']:sys.exit(1)
