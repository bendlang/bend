#!/usr/bin/env python3
"""Serial launcher for unchanged frozen public-control runners on CPU2."""
import hashlib,json,subprocess,sys
from pathlib import Path
R=Path(__file__).resolve().parents[4];attempt=Path(sys.argv[1]).resolve();suffix=sys.argv[2];node='/home/ai/.nvm/versions/node/v24.18.0/bin/node';runner=R/'selfhost/tools/performance/phase22/context-controls-run-v7.mjs';out=R/f'selfhost/build/phase22/context-controls-header-screen-{suffix}';out.mkdir()
def ident(p):
 p=Path(p).resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
cohorts=[('declarations','header-inputs','header-baseline-subset-01'),('alias','feature-alias-inputs','production-alias-05'),('header-demand','header-demand-inputs','production-header-demand-05'),('finalization','finalization-inputs','production-finalization-05')]
report={'kind':'phase22-performance-candidate-correctness-screen','scope':'58 exact observations for the guard-only declaration-header optimization:26 unchanged declaration cases plus alias4/header-demand2/finalization26. No timing claim.','complete':False,'pass':False,'attempt':ident(attempt/'attempt.json'),'inputs':[ident(__file__),ident(runner)],'jobs':[]}
def save():(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
(out/'consumed-tool.py').write_bytes(Path(__file__).read_bytes());save()
for name,selection,prior in cohorts:
 dest=R/f'selfhost/build/phase22/context-controls-header-screen-{suffix}-{name}'
 assert not dest.exists(),str(dest)
 cmd=['taskset','-c','2',node,'--stack-size=4096','--max-old-space-size=4096',str(runner),str(attempt),str(dest),str(R/f'selfhost/build/phase22/context-controls-{selection}-01/selection.json'),str(R/f'selfhost/build/phase22/context-controls-{prior}')]
 print(json.dumps({'starting':name,'output':str(dest)}),flush=True);result=subprocess.run(cmd,cwd=R,check=False);record={'name':name,'command':cmd,'exitCode':result.returncode};p=dest/'report.json'
 if p.exists():
  r=json.loads(p.read_text());record.update(report=ident(p),complete=r['complete'],pass_=r['pass'],exactDifferences=r.get('selected',{}).get('exactDifferences'),comparison=r.get('comparison'))
 report['jobs'].append(record);save();print(json.dumps({'closed':name,'exitCode':result.returncode,'exactDifferences':record.get('exactDifferences')}),flush=True)
report['complete']=True;report['pass']=all(x['exitCode']==0 and x.get('pass_') and x.get('exactDifferences')==0 for x in report['jobs']);save();print(json.dumps({'complete':True,'pass':report['pass'],'report':str(out/'report.json')}),flush=True)
if not report['pass']:sys.exit(1)
