#!/usr/bin/env python3
"""Run only a pre-frozen diagnostic CPU profile, preserving its launcher."""
from pathlib import Path
import hashlib,json,os,subprocess,sys,time
HERE=Path(__file__).resolve().parent
config,out=map(lambda x:Path(x).resolve(),sys.argv[1:]);plan=json.loads(config.read_text())
assert not out.exists();prefix=out.parent/(out.name+'-launcher')
for suffix in ['.json','.stdout','.stderr']:assert not Path(str(prefix)+suffix).exists()
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
command=['taskset','-c',str(plan['cpu']),plan['node'],*plan['nodeFlags'],str(HERE/'prototype-profile.mjs'),str(config),str(out)]
report={'kind':'phase30-diagnostic-profile-launcher','complete':False,'scope':'Instrumented diagnostic execution; wall interval is descriptive acquisition cost only. No comparative speed claim.','command':command,'inputs':[ident(p) for p in [Path(__file__),HERE/'prototype-profile.mjs',config]],'environment':'Remove all BEND_ variables, NODE_OPTIONS and NODE_PATH.'}
def save():Path(str(prefix)+'.json').write_text(json.dumps(report,indent=2)+'\n')
save();begin=time.monotonic();env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
with Path(str(prefix)+'.stdout').open('w') as stdout,Path(str(prefix)+'.stderr').open('w') as stderr:
 try:report['exitCode']=subprocess.run(command,stdout=stdout,stderr=stderr,timeout=plan['timeoutSeconds'],env=env).returncode
 except subprocess.TimeoutExpired:report['timeout']=True
report.update(wallSeconds=time.monotonic()-begin,stdout=ident(Path(str(prefix)+'.stdout')),stderr=ident(Path(str(prefix)+'.stderr')))
if (out/'report.json').exists():report['profile']=ident(out/'report.json');report['complete']=report.get('exitCode')==0 and json.loads((out/'report.json').read_text()).get('complete',False)
for p in report['inputs']:assert ident(Path(p['file']))==p
save();print(json.dumps(report));raise SystemExit(0 if report['complete'] else 1)
