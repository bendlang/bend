#!/usr/bin/env python3
"""Untimed correctness of each saved disposable variant; preserves all results."""
from pathlib import Path
import hashlib,json,os,subprocess,sys
HERE=Path(__file__).resolve().parent
NODE=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
directory=Path(sys.argv[1]).resolve()
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
report={'kind':'phase29-derived-prototype-correctness','complete':False,'cpu':6,'tool':ident(Path(__file__)),'derivation':ident(directory/'derivation.json'),'points':ident(HERE/'fixture-points.json'),'checker':ident(HERE/'prototype-check.mjs'),'variants':{}}
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
for variant in ['unchanged','arithmetic','worker','combined']:
    module=directory/(variant+'.mjs')
    command=['taskset','-c','6',str(NODE),'--stack-size=4096','--max-old-space-size=1024',str(HERE/'prototype-check.mjs'),str(module),str(HERE/'fixture-points.json')]
    row={'module':ident(module),'command':command,'timeoutSeconds':60}
    with (directory/(variant+'-check.stdout')).open('w') as stdout,(directory/(variant+'-check.stderr')).open('w') as stderr:
        try:row['exitCode']=subprocess.run(command,stdout=stdout,stderr=stderr,env=env,timeout=60).returncode
        except subprocess.TimeoutExpired:row['timeout']=True
    row['stdout']=ident(directory/(variant+'-check.stdout'));row['stderr']=ident(directory/(variant+'-check.stderr'))
    lines=(directory/(variant+'-check.stdout')).read_text().splitlines()
    if lines:
        try:row['observation']=json.loads(lines[-1])
        except json.JSONDecodeError:pass
    row['complete']=row.get('exitCode')==0 and row.get('observation',{}).get('complete',False)
    report['variants'][variant]=row
    (directory/'correctness.json').write_text(json.dumps(report,indent=2)+'\n')
report['complete']=all(v['complete'] for v in report['variants'].values())
(directory/'correctness.json').write_text(json.dumps(report,indent=2)+'\n')
if not report['complete']:sys.exit(1)
