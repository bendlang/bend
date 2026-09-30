#!/usr/bin/env python3
"""Run one bounded acquisition/validation command into a new evidence directory."""
from pathlib import Path
import argparse,hashlib,json,os,signal,subprocess,sys,time
p=argparse.ArgumentParser();p.add_argument('--timeout',type=int,default=180);p.add_argument('--cpu',default='4');p.add_argument('out');p.add_argument('command',nargs=argparse.REMAINDER);a=p.parse_args()
assert a.command and 0<a.timeout<=3600
out=Path(a.out).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
command=a.command[1:] if a.command[0]=='--' else a.command
if a.cpu!='none':command=['taskset','-c',a.cpu,*command]
inputs=[ident(Path(__file__))]
for arg in a.command:
 x=Path(arg)
 if x.is_file():inputs.append(ident(x))
report={'complete':False,'scope':'Descriptive acquisition/validation; not comparative speed.','command':command,'cwd':str(Path.cwd()),'inputs':inputs,'timeoutSeconds':a.timeout,'started':time.time()}
def save(): (out/'run.json').write_text(json.dumps(report,indent=2)+'\n')
save();(out/'consumed-run.py').write_bytes(Path(__file__).read_bytes())
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']};start=time.monotonic()
with (out/'stdout.log').open('w') as stdout,(out/'stderr.log').open('w') as stderr:
 process=subprocess.Popen(command,stdout=stdout,stderr=stderr,env=env,start_new_session=True)
 try: report['returncode']=process.wait(timeout=a.timeout)
 except subprocess.TimeoutExpired:
  report['timeout']=True;os.killpg(process.pid,signal.SIGKILL);report['returncode']=process.wait()
report.update(finished=time.time(),wallSeconds=time.monotonic()-start,stdout=ident(out/'stdout.log'),stderr=ident(out/'stderr.log'))
report['changedInputs']=[r for r in inputs if ident(r['file'])!=r]
report['complete']=report['returncode']==0 and not report.get('timeout') and not report['changedInputs'];save()
print(json.dumps({'complete':report['complete'],'returncode':report['returncode'],'wallSeconds':report['wallSeconds'],'out':str(out)}))
raise SystemExit(0 if report['complete'] else 1)
