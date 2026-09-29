#!/usr/bin/env python3
"""Serial final acquisitions using frozen existing public/history/component tools."""
from pathlib import Path
import json,hashlib,os,subprocess
R=Path(__file__).resolve().parents[4];attempt=R/'selfhost/build/phase22/context-build-16';out=R/'selfhost/build/phase22/context-controls-release-01';out.mkdir();node='/home/ai/.nvm/versions/node/v24.18.0/bin/node';tools=R/'selfhost/tools/performance/phase22'
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
a=json.loads((attempt/'attempt.json').read_text());assert a['api']['sha256']=='ade8ef020e439b81ecb53057b33a473c34a3cbd993b98a044121ecc3c2b8c9c3';snapshot=Path(a['snapshot']['root'])
report={'kind':'phase22-final-independent-acquisition-launcher','complete':False,'pass':False,'api':a['api'],'attempt':ident(attempt/'attempt.json'),'inputs':[ident(__file__),ident(R/'implementation/phase22/context-controls-release-plan.md')],'jobs':[]};(out/'consumed-tool.py').write_bytes(Path(__file__).read_bytes())
def save():(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
save()
base=['taskset','-c','2',node,'--stack-size=4096','--max-old-space-size=4096'];env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
jobs=[
 ('public154',['python3',str(tools/'context-controls-sweep.py'),str(attempt),'06'],R/'selfhost/build/phase22/context-controls-production-sweep-06/report.json',{}),
 ('public22',['python3',str(tools/'context-controls-materialization-sweep.py'),str(attempt),'06'],R/'selfhost/build/phase22/context-controls-materialization-sweep-06/report.json',{}),
 ('execution36',['python3',str(tools/'context-controls-execution-sweep.py'),str(attempt),'06'],R/'selfhost/build/phase22/context-controls-execution-sweep-06/report.json',{}),
 ('integration198',base+[str(tools/'context-controls-integration-run.mjs'),str(attempt),str(R/'selfhost/build/phase22/context-controls-integration198-02'),str(R/'selfhost/build/phase16/wave9-source-01/selection.json'),str(R/'selfhost/build/phase22/context-controls-integration198-01')],R/'selfhost/build/phase22/context-controls-integration198-02/report.json',{}),
 ('histories226-fresh2',base+[str(tools/'context-controls-history-run-v2.mjs'),str(R/'selfhost/build/phase22/context-controls-history-inputs-04/binding.json'),str(R/'selfhost/build/phase22/context-controls-history-03'),'2'],R/'selfhost/build/phase22/context-controls-history-03/report.json',{}),
 ('standalone-frontend',base+[str(R/'selfhost/tests/frontend/trace-component.mjs'),str(R/'selfhost/build/phase22/context-controls-standalone-01')],R/'selfhost/build/phase22/context-controls-standalone-01/report.json',{'BEND_COMPONENT_PROJECT':str(snapshot),'BEND_UPSTREAM':a['config']['upstream']})]
for name,cmd,target,extra in jobs:
 assert not target.exists(),target
 print(json.dumps({'starting':name,'output':str(target)}),flush=True)
 with (out/(name+'.stdout')).open('x') as stdout,(out/(name+'.stderr')).open('x') as stderr:
  p=subprocess.run(cmd,cwd=R,env={**env,**extra},stdout=stdout,stderr=stderr,check=False)
 row={'name':name,'command':cmd,'environmentAdditions':extra,'exitCode':p.returncode,'stdout':ident(out/(name+'.stdout')),'stderr':ident(out/(name+'.stderr'))}
 if target.exists():
  r=json.loads(target.read_text());row.update(report=ident(target),complete=r.get('complete'),pass_=r.get('pass',r.get('complete') and r.get('status')==0))
 report['jobs'].append(row);save();print(json.dumps({'closed':name,'exitCode':p.returncode,'complete':row.get('complete'),'pass':row.get('pass_')}),flush=True)
 if p.returncode or not row.get('complete') or not row.get('pass_'):raise SystemExit(1)
report['complete']=True;report['pass']=True;save();print(json.dumps({'complete':True,'pass':True,'report':str(out/'report.json')}),flush=True)
