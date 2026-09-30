#!/usr/bin/env python3
"""Run the unchanged fifteen upstream JavaScript execution probes."""
from pathlib import Path
import hashlib,json,os,subprocess,sys,time
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
NODE=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
attempt,out=[Path(p).resolve() for p in sys.argv[1:]]
launcher=out.with_name(out.name+'-launcher');launcher.mkdir(parents=True,exist_ok=False)
selection=HERE/'integration-upstream-selection.json';tool=ROOT/'selfhost/tools/development/workflow.mjs'
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
config=json.loads((attempt/'attempt.json').read_text())['config']
assert config['cpu']=='4' and config['strictExact']
command=[str(NODE),'--stack-size=4096','--max-old-space-size=1024',str(tool),'validate',str(attempt),str(selection),str(out)]
files=[Path(__file__),selection,tool,NODE,attempt/'attempt.json']
report={'kind':'phase29-existing-upstream-js-validation-launch','complete':False,'command':command,'inputs':[ident(p) for p in files],'cpu':config['cpu'],'phaseHeapMb':config['heapMb'],'started':time.time()}
for p in [Path(__file__),selection,tool]:(launcher/p.name).write_bytes(p.read_bytes())
save=lambda:(launcher/'launch.json').write_text(json.dumps(report,indent=2)+'\n')
save();env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
begin=time.monotonic()
with (launcher/'stdout.log').open('w') as stdout,(launcher/'stderr.log').open('w') as stderr:
    process=subprocess.run(command,cwd=ROOT,stdout=stdout,stderr=stderr,env=env)
report['exitCode']=process.returncode;report['validationWallSeconds']=time.monotonic()-begin
report['stdout']=ident(launcher/'stdout.log');report['stderr']=ident(launcher/'stderr.log')
for p in report['inputs']:assert ident(Path(p['file']))==p,p['file']
if (out/'report.json').exists():
    result=json.loads((out/'report.json').read_text())
    report['complete']=process.returncode==0 and result.get('complete',False) and result.get('pass',False) and result['selected']['exactDifferences']==0
save();print(json.dumps({'complete':report['complete'],'exitCode':process.returncode,'validationWallSeconds':report['validationWallSeconds']}))
if not report['complete']:sys.exit(1)
