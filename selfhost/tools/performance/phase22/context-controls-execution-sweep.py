#!/usr/bin/env python3
"""Run the two frozen ordinary-program cohorts serially with the unchanged runner."""
import json,subprocess,sys,hashlib
from pathlib import Path
R=Path(__file__).resolve().parents[4];attempt=Path(sys.argv[1]).resolve();wave=sys.argv[2];out=R/f'selfhost/build/phase22/context-controls-execution-sweep-{wave}';out.mkdir();runner=R/'selfhost/tools/performance/phase22/context-controls-run-v7.mjs';node='/home/ai/.nvm/versions/node/v24.18.0/bin/node'
def ident(p):return {'file':str(Path(p).resolve()),'sha256':hashlib.sha256(Path(p).read_bytes()).hexdigest()}
r={'kind':'phase22-frozen-program-execution-launcher','complete':False,'pass':False,'inputs':[ident(__file__),ident(runner),ident(attempt/'attempt.json')],'jobs':[]};(out/'consumed-tool.py').write_bytes(Path(__file__).read_bytes())
def save():(out/'report.json').write_text(json.dumps(r,indent=2)+'\n')
save()
for name,selection,prior in [('ordinary','inputs','program-baseline'),('feature','feature-inputs','feature-program-baseline')]:
 dest=R/f'selfhost/build/phase22/context-controls-production-{name}-program-{wave}';assert not dest.exists()
 cmd=['taskset','-c','2',node,'--stack-size=4096','--max-old-space-size=4096',str(runner),str(attempt),str(dest),str(R/f'selfhost/build/phase22/context-controls-{selection}-01/program-selection.json'),str(R/f'selfhost/build/phase22/context-controls-{prior}-01')]
 print(json.dumps({'starting':name,'output':str(dest)}),flush=True);p=subprocess.run(cmd,cwd=R,check=False);j={'name':name,'command':cmd,'exitCode':p.returncode};q=dest/'report.json'
 if q.exists():
  d=json.loads(q.read_text());j.update(report=ident(q),complete=d['complete'],pass_=d['pass'],exactDifferences=d.get('selected',{}).get('exactDifferences'))
 r['jobs'].append(j);save();print(json.dumps({'closed':name,**{k:j.get(k) for k in ['exitCode','exactDifferences']}}),flush=True)
r['complete']=True;r['pass']=all(x['exitCode']==0 and x.get('pass_') for x in r['jobs']);save();print(json.dumps({'complete':True,'pass':r['pass'],'report':str(out/'report.json')}),flush=True)
if not r['pass']:sys.exit(1)
